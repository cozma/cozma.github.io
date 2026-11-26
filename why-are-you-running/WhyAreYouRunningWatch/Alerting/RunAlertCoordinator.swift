import Combine
import Foundation

/// Ties detection → routing → speaker / notification.
@MainActor
final class RunAlertCoordinator: ObservableObject {
    @Published private(set) var lastPresentation: AlertPresentation?
    @Published private(set) var canPlayThroughSpeaker: Bool
    @Published private(set) var detection: RunDetectionService

    private let soundPlayer: RunAlertSoundPlayer
    private let notifier: RunAlertNotifier
    private var detectionCancellable: AnyCancellable?

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

        detection.setOnRunStarted { [weak self] in
            Task { @MainActor in
                await self?.deliverAlert()
            }
        }
    }

    func bootstrap() async {
        _ = await notifier.requestAuthorization()
        await detection.start()
    }

    func deliverAlert() async {
        let presentation = AlertRouter.presentation(canPlayThroughSpeaker: canPlayThroughSpeaker)
        lastPresentation = presentation

        switch presentation {
        case .speakerAndBanner:
            soundPlayer.play()
            // Banner without the still — the audio is the punchline.
            await notifier.postRunAlert(includeImage: false)
        case .textAndImage:
            await notifier.postRunAlert(includeImage: true)
        }
    }

    func testAlert() async {
        await deliverAlert()
    }
}
