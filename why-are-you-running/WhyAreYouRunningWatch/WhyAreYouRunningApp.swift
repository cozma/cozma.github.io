import SwiftUI
import UserNotifications

@main
struct WhyAreYouRunningApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var appDelegate
    @ObservedObject private var coordinator = RunAlertCoordinator.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .task {
                    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                    await coordinator.bootstrap()
                }
        }
    }
}

/// Show banners while the app is in the foreground (useful for the Test button).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
