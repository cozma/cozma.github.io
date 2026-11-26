import Foundation
import UserNotifications

/// Builds and posts the local notification for a detected run.
/// Uses time-sensitive delivery so the alert can show while the watch is locked mid-workout.
@MainActor
final class RunAlertNotifier {
    static let shared = RunAlertNotifier()

    static let title = "Why are you running?"
    static let body = "We caught you mid-jog."

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .timeSensitive])
        } catch {
            return false
        }
    }

    /// Posts a local notification. When `includeImage` is true, attaches the
    /// bundled still so older watches still get a visual without speaker audio.
    func postRunAlert(includeImage: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = Self.title
        content.body = Self.body
        // Custom `soundNamed` is unavailable on watchOS; default tick + our
        // AVAudioPlayer path covers newer hardware.
        content.sound = .default
        // Helps surface the alert on a locked watch / during Focus while exercising.
        content.interruptionLevel = .timeSensitive

        if includeImage, let attachment = makeImageAttachment() {
            content.attachments = [attachment]
        }

        let request = UNNotificationRequest(
            identifier: "why-are-you-running-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }

    private func makeImageAttachment() -> UNNotificationAttachment? {
        guard let bundled = Bundle.main.url(forResource: "run_alert_still", withExtension: "png") else {
            return nil
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("run_alert_still-\(UUID().uuidString).png")

        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: bundled, to: tempURL)
            return try UNNotificationAttachment(
                identifier: "run-alert-still",
                url: tempURL,
                options: [UNNotificationAttachmentOptionsTypeHintKey: "public.png"]
            )
        } catch {
            return nil
        }
    }
}
