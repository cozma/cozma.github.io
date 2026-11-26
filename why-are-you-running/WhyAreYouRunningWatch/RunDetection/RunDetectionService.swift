import Foundation
import CoreMotion
import HealthKit

/// Watches motion + HealthKit for the moment a run begins.
@MainActor
final class RunDetectionService: ObservableObject {
    @Published private(set) var isMonitoring = false
    @Published private(set) var lastStatus: String = "Idle"
    @Published private(set) var lastTriggeredAt: Date?

    private let motionManager = CMMotionActivityManager()
    private let healthStore = HKHealthStore()
    private var wasRunning = false
    private var observerQuery: HKObserverQuery?

    private var onRunStarted: (@MainActor () -> Void)?

    init(onRunStarted: (@MainActor () -> Void)? = nil) {
        self.onRunStarted = onRunStarted
    }

    func setOnRunStarted(_ handler: @escaping @MainActor () -> Void) {
        onRunStarted = handler
    }

    var isMotionAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func start() async {
        guard !isMonitoring else { return }

        let motionOK = await startMotionUpdates()
        let healthOK = await startHealthKitObserver()

        isMonitoring = motionOK || healthOK
        if isMonitoring {
            lastStatus = "Listening for a run…"
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

    /// Manual trigger used by the Test button (and by unit-style previews).
    func simulateRunStart() {
        handlePossibleRunStart(source: "test")
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

        // Rising edge only: transition into running.
        if isRunning && !wasRunning {
            handlePossibleRunStart(source: "motion")
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

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }
            Task { @MainActor in
                await self?.inspectLatestWorkout()
                completionHandler()
            }
        }

        observerQuery = query
        healthStore.execute(query)
        try? await healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate)
        return true
    }

    private func inspectLatestWorkout() async {
        let workoutType = HKObjectType.workoutType()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let predicate = HKQuery.predicateForWorkouts(with: .running)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { [weak self] _, samples, _ in
                defer { continuation.resume() }
                guard
                    let self,
                    let workout = samples?.first as? HKWorkout
                else { return }

                // Treat a workout that started in the last two minutes as "just started".
                let age = Date().timeIntervalSince(workout.startDate)
                if age >= 0 && age < 120 {
                    Task { @MainActor in
                        self.handlePossibleRunStart(source: "healthkit")
                    }
                }
            }
            healthStore.execute(query)
        }
    }

    private func handlePossibleRunStart(source: String) {
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
        lastStatus = "Run detected via \(source)"
        onRunStarted?()
    }
}
