import Foundation

public struct HealthSampleBundle: Equatable, Sendable {
    public var day: Date
    public var sleepHours: Double?
    public var sleepScore: Int?
    public var hrvNightMs: Double?
    public var hrvBaselineMs: Double?
    public var restingHeartRate: Double?
    public var rhrBaseline: Double?
    public var stepsYesterday: Int?
    public var moveCaloriesYesterday: Double?
    public var lastWorkout: WorkoutSummary?
    public var sources: [MetricSource]
    public var sleepTargetHours: Double
    public var cueStyle: CueStyle

    public init(
        day: Date = Date(),
        sleepHours: Double? = nil,
        sleepScore: Int? = nil,
        hrvNightMs: Double? = nil,
        hrvBaselineMs: Double? = nil,
        restingHeartRate: Double? = nil,
        rhrBaseline: Double? = nil,
        stepsYesterday: Int? = nil,
        moveCaloriesYesterday: Double? = nil,
        lastWorkout: WorkoutSummary? = nil,
        sources: [MetricSource] = [],
        sleepTargetHours: Double = 7.5,
        cueStyle: CueStyle = .quiet
    ) {
        self.day = day
        self.sleepHours = sleepHours
        self.sleepScore = sleepScore
        self.hrvNightMs = hrvNightMs
        self.hrvBaselineMs = hrvBaselineMs
        self.restingHeartRate = restingHeartRate
        self.rhrBaseline = rhrBaseline
        self.stepsYesterday = stepsYesterday
        self.moveCaloriesYesterday = moveCaloriesYesterday
        self.lastWorkout = lastWorkout
        self.sources = sources
        self.sleepTargetHours = sleepTargetHours
        self.cueStyle = cueStyle
    }
}

public enum SnapshotBuilder {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public static func build(
        from samples: HealthSampleBundle,
        generatedAt: Date = Date(),
        isDemo: Bool = false
    ) -> MorningSnapshot {
        let readiness = ReadinessCalculator.score(
            for: .init(
                hrvNightMs: samples.hrvNightMs,
                hrvBaselineMs: samples.hrvBaselineMs,
                restingHeartRate: samples.restingHeartRate,
                rhrBaseline: samples.rhrBaseline,
                sleepHours: samples.sleepHours,
                sleepTargetHours: samples.sleepTargetHours
            )
        )

        let insight = InsightWriter.line(
            band: readiness.band,
            sleepHours: samples.sleepHours,
            sleepTargetHours: samples.sleepTargetHours,
            style: samples.cueStyle
        )

        return MorningSnapshot(
            dayKey: dayFormatter.string(from: samples.day),
            generatedAt: generatedAt,
            sleepHours: samples.sleepHours,
            sleepScore: samples.sleepScore,
            hrvNightMs: samples.hrvNightMs,
            restingHeartRate: samples.restingHeartRate,
            readinessScore: readiness.score,
            readinessBand: readiness.band,
            stepsYesterday: samples.stepsYesterday,
            moveCaloriesYesterday: samples.moveCaloriesYesterday,
            lastWorkout: samples.lastWorkout,
            insight: insight,
            sources: samples.sources,
            isDemo: isDemo
        )
    }
}

public enum InsightWriter {
    public static func line(
        band: ReadinessBand,
        sleepHours: Double?,
        sleepTargetHours: Double,
        style: CueStyle
    ) -> String {
        let sleepNote: String
        if let sleepHours {
            if sleepHours + 0.35 < sleepTargetHours {
                sleepNote = style == .coachy
                    ? "Sleep came in light at \(formatHours(sleepHours))."
                    : "You slept \(formatHours(sleepHours))."
            } else {
                sleepNote = style == .coachy
                    ? "Solid night — \(formatHours(sleepHours)) of sleep."
                    : "\(formatHours(sleepHours)) of sleep on the board."
            }
        } else {
            sleepNote = "Waiting on last night’s sleep sync."
        }

        switch (band, style) {
        case (.recover, .quiet):
            return "\(sleepNote) Today’s cue: recover."
        case (.recover, .coachy):
            return "\(sleepNote) Protect the day — walk, stretch, skip the hammer session."
        case (.maintain, .quiet):
            return "\(sleepNote) Today’s cue: maintain."
        case (.maintain, .coachy):
            return "\(sleepNote) Steady work fits — keep intensity in the middle."
        case (.push, .quiet):
            return "\(sleepNote) Today’s cue: push."
        case (.push, .coachy):
            return "\(sleepNote) Green light — stack a hard session if the schedule allows."
        }
    }

    private static func formatHours(_ value: Double) -> String {
        let hours = Int(value)
        let minutes = Int(((value - Double(hours)) * 60).rounded())
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }
}
