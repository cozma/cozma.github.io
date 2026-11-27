#if canImport(HealthKit)
import Foundation
import HealthKit
import MorningBoardKit

/// Production HealthKit reader. Wire this into `CompanionModel` on a real iPhone.
public final class HealthKitReader: HealthReading, @unchecked Sendable {
    private let store = HKHealthStore()

    public init() {}

    public func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        try await store.requestAuthorization(toShare: [], read: readTypes)
        return true
    }

    public func loadTodaySamples(cueStyle: CueStyle) async throws -> HealthSampleBundle {
        // Prototype stub: real anchored queries land in the next slice.
        // Returning DemoHealthReader output keeps the companion runnable in Simulator
        // before Health permissions + query plumbing are finished.
        try await DemoHealthReader().loadTodaySamples(cueStyle: cueStyle)
    }
}
#endif
