import Foundation

/// Derives a 0–100 readiness score from overnight HRV + resting HR vs personal baselines.
/// This is a prototype heuristic — not a medical score.
public enum ReadinessCalculator {
    public struct Input: Equatable, Sendable {
        public var hrvNightMs: Double?
        public var hrvBaselineMs: Double?
        public var restingHeartRate: Double?
        public var rhrBaseline: Double?
        public var sleepHours: Double?
        public var sleepTargetHours: Double

        public init(
            hrvNightMs: Double? = nil,
            hrvBaselineMs: Double? = nil,
            restingHeartRate: Double? = nil,
            rhrBaseline: Double? = nil,
            sleepHours: Double? = nil,
            sleepTargetHours: Double = 7.5
        ) {
            self.hrvNightMs = hrvNightMs
            self.hrvBaselineMs = hrvBaselineMs
            self.restingHeartRate = restingHeartRate
            self.rhrBaseline = rhrBaseline
            self.sleepHours = sleepHours
            self.sleepTargetHours = sleepTargetHours
        }
    }

    public static func score(for input: Input) -> (score: Int, band: ReadinessBand) {
        var weighted = 0.0
        var weightSum = 0.0

        if let hrv = input.hrvNightMs, let baseline = input.hrvBaselineMs, baseline > 0 {
            let ratio = hrv / baseline
            let hrvScore = clamp((ratio - 0.7) / 0.5 * 100) // 0.7× → 0, 1.2× → 100
            weighted += hrvScore * 0.45
            weightSum += 0.45
        }

        if let rhr = input.restingHeartRate, let baseline = input.rhrBaseline, baseline > 0 {
            // Lower RHR than baseline is better.
            let delta = (baseline - rhr) / baseline
            let rhrScore = clamp(50 + delta * 200)
            weighted += rhrScore * 0.25
            weightSum += 0.25
        }

        if let sleep = input.sleepHours, input.sleepTargetHours > 0 {
            let ratio = sleep / input.sleepTargetHours
            let sleepScore = clamp(ratio * 100)
            weighted += sleepScore * 0.30
            weightSum += 0.30
        }

        let raw = weightSum > 0 ? weighted / weightSum : 55
        let score = Int(raw.rounded())
        return (score, band(for: score))
    }

    public static func band(for score: Int) -> ReadinessBand {
        switch score {
        case ..<45: return .recover
        case 45..<70: return .maintain
        default: return .push
        }
    }

    private static func clamp(_ value: Double) -> Double {
        min(100, max(0, value))
    }
}
