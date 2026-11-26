import Foundation
import WatchKit

/// Asks watchOS to wake the app periodically so we can re-check for a run
/// even when the UI is gone and the watch is locked.
enum BackgroundRefreshScheduler {
    static func scheduleNext(after now: Date = Date()) {
        let when = BackgroundRefreshPolicy.nextPreferredRefreshDate(after: now)
        WKApplication.shared.scheduleBackgroundRefresh(
            withPreferredDate: when,
            userInfo: nil
        ) { _ in
            // System may deny/delay; HealthKit background delivery remains the
            // primary locked-watch path when a Running workout starts.
        }
    }
}
