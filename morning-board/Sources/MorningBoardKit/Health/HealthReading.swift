import Foundation

/// Boundary between MorningBoardKit and HealthKit. iOS provides the real reader;
/// demos and tests use fixtures.
public protocol HealthReading: Sendable {
    func requestAuthorization() async throws -> Bool
    func loadTodaySamples(cueStyle: CueStyle) async throws -> HealthSampleBundle
}

public struct DemoHealthReader: HealthReading {
    public init() {}

    public func requestAuthorization() async throws -> Bool { true }

    public func loadTodaySamples(cueStyle: CueStyle) async throws -> HealthSampleBundle {
        HealthSampleBundle(
            sleepHours: 7.4,
            sleepScore: 84,
            hrvNightMs: 58,
            hrvBaselineMs: 54,
            restingHeartRate: 53,
            rhrBaseline: 56,
            stepsYesterday: 8_760,
            moveCaloriesYesterday: 490,
            sources: [
                MetricSource(metric: "sleep", bundleId: "demo.sleep", displayName: "Demo Sleep"),
                MetricSource(metric: "hrv", bundleId: "demo.hrv", displayName: "Demo HRV")
            ],
            cueStyle: cueStyle
        )
    }
}
