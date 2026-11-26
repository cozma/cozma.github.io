import Foundation
import AVFoundation

/// Plays the bundled `run_alert` audio through the watch speaker.
/// Drop your own track at `Resources/run_alert.wav` (same filename) before shipping.
@MainActor
final class RunAlertSoundPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = RunAlertSoundPlayer()

    private var player: AVAudioPlayer?
    private let resourceName = "run_alert"
    private let resourceExtension = "wav"

    func play() {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            // Playback category so a brief HealthKit/background wake can still
            // route audio to the speaker while the watch is locked.
            try session.setCategory(.playback, mode: .default, policy: .default, options: [.duckOthers])
            try session.setActive(true)

            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            player = audioPlayer
            audioPlayer.play()
        } catch {
            // Speaker path failed — caller still shows the notification banner.
            player = nil
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.player = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }
}
