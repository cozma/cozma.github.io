import Foundation

/// One day's board payload. Published by the iPhone companion; rendered by Apple TV.
/// Keep this small — derived summaries only, not raw HealthKit samples.
public struct MorningSnapshot: Codable, Equatable, Sendable, Identifiable {
    public var id: String { dayKey }

    /// Calendar day in the user's local timezone, `yyyy-MM-dd`.
    public var dayKey: String
    public var generatedAt: Date
    public var sleepHours: Double?
    public var sleepScore: Int?
    public var hrvNightMs: Double?
    public var restingHeartRate: Double?
    public var readinessScore: Int
    public var readinessBand: ReadinessBand
    public var stepsYesterday: Int?
    public var moveCaloriesYesterday: Double?
    public var lastWorkout: WorkoutSummary?
    public var insight: String
    public var sources: [MetricSource]
    public var isDemo: Bool

    public init(
        dayKey: String,
        generatedAt: Date = Date(),
        sleepHours: Double? = nil,
        sleepScore: Int? = nil,
        hrvNightMs: Double? = nil,
        restingHeartRate: Double? = nil,
        readinessScore: Int,
        readinessBand: ReadinessBand,
        stepsYesterday: Int? = nil,
        moveCaloriesYesterday: Double? = nil,
        lastWorkout: WorkoutSummary? = nil,
        insight: String,
        sources: [MetricSource] = [],
        isDemo: Bool = false
    ) {
        self.dayKey = dayKey
        self.generatedAt = generatedAt
        self.sleepHours = sleepHours
        self.sleepScore = sleepScore
        self.hrvNightMs = hrvNightMs
        self.restingHeartRate = restingHeartRate
        self.readinessScore = readinessScore
        self.readinessBand = readinessBand
        self.stepsYesterday = stepsYesterday
        self.moveCaloriesYesterday = moveCaloriesYesterday
        self.lastWorkout = lastWorkout
        self.insight = insight
        self.sources = sources
        self.isDemo = isDemo
    }
}

public enum ReadinessBand: String, Codable, Equatable, Sendable, CaseIterable {
    case recover
    case maintain
    case push

    public var displayName: String {
        switch self {
        case .recover: return "Recover"
        case .maintain: return "Maintain"
        case .push: return "Push"
        }
    }

    public var cueVerb: String {
        switch self {
        case .recover: return "take it easy"
        case .maintain: return "keep a steady pace"
        case .push: return "go hard if you want"
        }
    }
}

public struct WorkoutSummary: Codable, Equatable, Sendable {
    public var name: String
    public var activityType: String
    public var durationMinutes: Int
    public var endedAt: Date

    public init(name: String, activityType: String, durationMinutes: Int, endedAt: Date) {
        self.name = name
        self.activityType = activityType
        self.durationMinutes = durationMinutes
        self.endedAt = endedAt
    }
}

public struct MetricSource: Codable, Equatable, Sendable {
    public var metric: String
    public var bundleId: String
    public var displayName: String

    public init(metric: String, bundleId: String, displayName: String) {
        self.metric = metric
        self.bundleId = bundleId
        self.displayName = displayName
    }
}
