import Foundation

/// Pure helpers for watchOS background refresh timing.
enum BackgroundRefreshPolicy {
    /// Ask the system to wake us about this often. watchOS may delay or coalesce.
    static let preferredInterval: TimeInterval = 10 * 60

    static func nextPreferredRefreshDate(after now: Date) -> Date {
        now.addingTimeInterval(preferredInterval)
    }
}
