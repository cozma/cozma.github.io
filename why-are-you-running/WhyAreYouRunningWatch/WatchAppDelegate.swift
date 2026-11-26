import WatchKit

/// Handles process launch and background wakes while the watch is locked / wrist-down.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        Task { @MainActor in
            await RunAlertCoordinator.shared.bootstrap()
        }
        BackgroundRefreshScheduler.scheduleNext()
    }

    func applicationDidBecomeActive() {
        BackgroundRefreshScheduler.scheduleNext()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                Task { @MainActor in
                    await RunAlertCoordinator.shared.handleBackgroundWake(reason: .scheduledRefresh)
                    BackgroundRefreshScheduler.scheduleNext()
                    refreshTask.setTaskCompletedWithSnapshot(false)
                }

            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: .distantFuture,
                    userInfo: nil
                )

            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(false)

            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)

            case let intentTask as WKIntentDidRunRefreshBackgroundTask:
                intentTask.setTaskCompletedWithSnapshot(false)

            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
