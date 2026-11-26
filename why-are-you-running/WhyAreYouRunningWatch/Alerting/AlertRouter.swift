import Foundation

/// How the watch should deliver the "why are you running?" beat.
enum AlertPresentation: Equatable {
    /// Play the bundled phrase through the watch speaker and show a short banner.
    case speakerAndBanner
    /// Text notification plus the still image (no custom speaker playback).
    case textAndImage
}

enum RunEventKind: Equatable {
    case runningStarted
    case other
}

struct RunEvent: Equatable {
    var kind: RunEventKind
    var detectedAt: Date
}

/// Pure decision helpers — no Watch/HealthKit imports so they stay easy to test.
enum AlertRouter {
    static let defaultCooldown: TimeInterval = 30 * 60

    static func presentation(canPlayThroughSpeaker: Bool) -> AlertPresentation {
        canPlayThroughSpeaker ? .speakerAndBanner : .textAndImage
    }

    /// Fires only on a fresh run start, and respects a cooldown so a long jog
    /// does not re-trigger the alert every few minutes.
    static func shouldTrigger(
        for event: RunEvent,
        lastTriggeredAt: Date?,
        now: Date,
        cooldown: TimeInterval = defaultCooldown
    ) -> Bool {
        guard event.kind == .runningStarted else { return false }
        if let lastTriggeredAt, now.timeIntervalSince(lastTriggeredAt) < cooldown {
            return false
        }
        return true
    }
}
