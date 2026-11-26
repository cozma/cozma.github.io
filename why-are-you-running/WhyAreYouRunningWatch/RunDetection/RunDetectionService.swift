import Foundation
import CoreMotion
import HealthKit

enum DetectionWakeReason: String {
    case foreground
    case healthKit
    case scheduledRefresh
    case test
}

/// Watches motion + HealthKit for the moment a run begins, including background wakes.
@MainActor
final class RunDetectionService: ObservableObject {
    private static let lastTriggeredKey = "runDetection.lastTriggeredAt"

    @Published private(set) var isMonitoring = false
    @Published private(set) var lastStatus: String = "Idle"
    @Published private(set) var lastTriggeredAt: Date? {
        didSet {
            if let lastTriggeredAt {
                UserDefaults.standard.set(lastTriggeredAt.timeIntervalSince1970, forKey: Self.lastTriggeredKey)
            }
        }
    }

    private let motionManager = CMMotionActivityManager()
    private let healthStore = HKHealthStore()
    private var wasRunning = false
    private var observerQuery: HKObserverQuery?

    private var onRunStarted: (@MainActor (DetectionWakeReason) -> Void)?

    init(onRunStarted: (@MainActor (DetectionWakeReason) -> Void)? = nil) {
        self.onRunStarted = onRunStarted
        if UserDefaults.standard.object(forKey: Self.lastTriggeredKey) != nil {
            let ts = UserDefaults.standard.double(forKey: Self.lastTriggeredKey)
            lastTriggeredAt = Date(timeIntervalSince1970: ts)
        }
    }

    func setOnRunStarted(_ handler: @escaping @MainActor (DetectionWakeReason) -> Void) {
        onRunStarted = handler
    }

    var isMotionAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func start() async {
        let motionOK = await startMotionUpdates()
        let healthOK = await startHealthKitObserver()

        isMonitoring = motionOK || healthOK
        if isMonitoring {
            lastStatus = "Listening in background…"
            // Catch a run that started while we were suspended.
            await scanForRecentRun(reason: .foreground)
        } else {
            lastStatus = "Need Motion or Health permission"
        }
    }

    func stop() {
        motionManager.stopActivityUpdates()
        if let observerQuery {
            healthStore.stop(observerQuery)
            self.observerQuery = nil
        }
        isMonitoring = false
        lastStatus = "Paused"
    }

    /// Called from HealthKit / scheduled background refresh while the watch may be locked.
    func handleBackgroundWake(reason: DetectionWakeReason) async {
        if !isMonitoring {
            // Process may have been relaunched by HealthKit — re-arm observers first.
            await start()
            return
        }
        lastStatus = "Background check (\(reason.rawValue))…"
        await scanForRecentRun(reason: reason)
    }

    func simulateRunStart() {
        handlePossibleRunStart(source: .test)
    }

    private func startMotionUpdates() async -> Bool {
        guard isMotionAvailable else { return false }

        motionManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            Task { @MainActor in
                self.handleMotionActivity(activity)
            }
        }
        return true
    }

    private func handleMotionActivity(_ activity: CMMotionActivity) {
        let isRunning = activity.running && activity.confidence != .low
        defer { wasRunning = isRunning }

        if isRunning && !wasRunning {
            handlePossibleRunStart(source: .foreground)
        }
    }

    private func startHealthKitObserver() async -> Bool {
        guard isHealthDataAvailable else { return false }

        let workoutType = HKObjectType.workoutType()
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [workoutType])
        } catch {
            return false
        }

        if let observerQuery {
            healthStore.stop(observerQuery)
        }

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }
            Task { @MainActor in
                // HealthKit may deliver this while the watch is locked mid-workout.
                await self?.handleBackgroundWake(reason: .healthKit)
                completionHandler()
            }
        }

        observerQuery = query
        healthStore.execute(query)

        do {
            try await healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate)
        } catch {
            // Observer still helps while the process is alive.
        }
        return true
    }

    private func scanForRecentRun(reason: DetectionWakeReason) async {
        let workoutHit = await hasRecentRunningWorkout()
        if workoutHit {
            handlePossibleRunStart(source: reason == .healthKit ? .healthKit : reason)
            return
        }

        let motionHit = await hasRecentRunningMotion()
        if motionHit {
            handlePossibleRunStart(source: reason)
        } else if reason == .scheduledRefresh {
            lastStatus = "Listening in background…"
        }
    }

    private func hasRecentRunningWorkout() async -> Bool {
        let workoutType = HKObjectType.workoutType()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let predicate = HKQuery.predicateForWorkouts(with: .running)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let workout = samples?.first as? HKWorkout else {
                    continuation.resume(returning: false)
                    return
                }
                let age = Date().timeIntervalSince(workout.startDate)
                continuation.resume(returning: age >= 0 && age < 180)
            }
            healthStore.execute(query)
        }
    }

    private func hasRecentRunningMotion() async -> Bool {
        guard isMotionAvailable else { return false }

        let end = Date()
        let start = end.addingTimeInterval(-180)

        return await withCheckedContinuation { continuation in
            motionManager.queryActivityStarting(from: start, to: end, to: .main) { activities, _ in
                let running = activities?.contains { activity in
                    activity.running && activity.confidence != .low
                } ?? false
                continuation.resume(returning: running)
            }
        }
    }

    private func handlePossibleRunStart(source: DetectionWakeReason) {
        let event = RunEvent(kind: .runningStarted, detectedAt: Date())
        let now = Date()
        guard AlertRouter.shouldTrigger(
            for: event,
            lastTriggeredAt: lastTriggeredAt,
            now: now
        ) else {
            lastStatus = "Run ignored (cooldown)"
            return
        }

        lastTriggeredAt = now
        lastStatus = "Run detected (\(source.rawValue))"
        onRunStarted?(source)
    }
}
