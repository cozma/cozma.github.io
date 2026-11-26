import Combine
import Foundation

/// Ties detection → routing → speaker / notification.
@MainActor
final class RunAlertCoordinator: ObservableObject {
    static let shared = RunAlertCoordinator()

    @Published private(set) var lastPresentation: AlertPresentation?
    @Published private(set) var canPlayThroughSpeaker: Bool
    @Published private(set) var detection: RunDetectionService

    private let soundPlayer: RunAlertSoundPlayer
    private let notifier: RunAlertNotifier
    private var detectionCancellable: AnyCancellable?
    private var didBootstrap = false

    init(
        soundPlayer: RunAlertSoundPlayer = .shared,
        notifier: RunAlertNotifier = .shared,
        canPlayThroughSpeaker: Bool = WatchAudioCapability.canPlayThroughSpeaker()
    ) {
        self.soundPlayer = soundPlayer
        self.notifier = notifier
        self.canPlayThroughSpeaker = canPlayThroughSpeaker
        self.detection = RunDetectionService()

        detectionCancellable = detection.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

        detection.setOnRunStarted { [weak self] _ in
            Task { @MainActor in
                await self?.deliverAlert()
            }
        }
    }

    func bootstrap() async {
        guard !didBootstrap else {
            // Process may already be monitoring after a HealthKit relaunch.
            if !detection.isMonitoring {
                await detection.start()
            }
            return
        }
        didBootstrap = true
        _ = await notifier.requestAuthorization()
        await detection.start()
        BackgroundRefreshScheduler.scheduleNext()
    }

    func handleBackgroundWake(reason: DetectionWakeReason) async {
        if !didBootstrap {
            await bootstrap()
        }
        await detection.handleBackgroundWake(reason: reason)
    }

    func deliverAlert() async {
        let presentation = AlertRouter.presentation(canPlayThroughSpeaker: canPlayThroughSpeaker)
        lastPresentation = presentation

        switch presentation {
        case .speakerAndBanner:
            // Brief background wakes (HealthKit / refresh) still get speaker audio
            // when the system allows it; the notification covers locked-screen delivery.
            soundPlayer.play()
            await notifier.postRunAlert(includeImage: false)
        case .textAndImage:
            await notifier.postRunAlert(includeImage: true)
        }

        BackgroundRefreshScheduler.scheduleNext()
    }

    func testAlert() async {
        await deliverAlert()
    }
}
