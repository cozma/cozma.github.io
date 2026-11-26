import Foundation
import AVFoundation

/// Plays the bundled "why are you running?" phrase through the watch speaker.
@MainActor
final class VineSoundPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = VineSoundPlayer()

    private var player: AVAudioPlayer?
    private let resourceName = "why_are_you_running"
    private let resourceExtension = "wav"

    func play() {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, policy: .default, options: [])
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
