import Foundation

public enum DemoSnapshots {
    public static func restedMorning(now: Date = Date()) -> MorningSnapshot {
        SnapshotBuilder.build(
            from: HealthSampleBundle(
                day: now,
                sleepHours: 7.7,
                sleepScore: 88,
                hrvNightMs: 62,
                hrvBaselineMs: 55,
                restingHeartRate: 52,
                rhrBaseline: 56,
                stepsYesterday: 9_420,
                moveCaloriesYesterday: 540,
                lastWorkout: WorkoutSummary(
                    name: "Zone 2 run",
                    activityType: "running",
                    durationMinutes: 42,
                    endedAt: now.addingTimeInterval(-60 * 60 * 18)
                ),
                sources: [
                    MetricSource(metric: "sleep", bundleId: "com.ouraring.oura", displayName: "Oura"),
                    MetricSource(metric: "hrv", bundleId: "com.apple.health", displayName: "Apple Watch"),
                    MetricSource(metric: "steps", bundleId: "com.apple.health", displayName: "Apple Watch")
                ],
                cueStyle: .quiet
            ),
            generatedAt: now,
            isDemo: true
        )
    }

    public static func depletedMorning(now: Date = Date()) -> MorningSnapshot {
        SnapshotBuilder.build(
            from: HealthSampleBundle(
                day: now,
                sleepHours: 5.4,
                sleepScore: 61,
                hrvNightMs: 38,
                hrvBaselineMs: 55,
                restingHeartRate: 61,
                rhrBaseline: 56,
                stepsYesterday: 12_800,
                moveCaloriesYesterday: 820,
                lastWorkout: WorkoutSummary(
                    name: "Intervals",
                    activityType: "running",
                    durationMinutes: 55,
                    endedAt: now.addingTimeInterval(-60 * 60 * 14)
                ),
                sources: [
                    MetricSource(metric: "sleep", bundleId: "com.apple.health", displayName: "Apple Watch"),
                    MetricSource(metric: "hrv", bundleId: "com.apple.health", displayName: "Apple Watch")
                ],
                cueStyle: .coachy
            ),
            generatedAt: now,
            isDemo: true
        )
    }

    public static func waitingOnSleep(now: Date = Date()) -> MorningSnapshot {
        SnapshotBuilder.build(
            from: HealthSampleBundle(
                day: now,
                sleepHours: nil,
                hrvNightMs: nil,
                restingHeartRate: 54,
                rhrBaseline: 56,
                stepsYesterday: 7_100,
                moveCaloriesYesterday: 410,
                sources: [
                    MetricSource(metric: "steps", bundleId: "com.apple.health", displayName: "Apple Watch")
                ],
                cueStyle: .quiet
            ),
            generatedAt: now,
            isDemo: true
        )
    }
}
