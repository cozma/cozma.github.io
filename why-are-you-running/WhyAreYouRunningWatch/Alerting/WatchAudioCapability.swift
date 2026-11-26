import Foundation

#if os(watchOS)
import WatchKit
#endif

/// Decides whether this hardware/OS combo should blast audio through the speaker.
///
/// Assumption: watchOS 9+ is the "newer watch" cut line. Those builds have reliable
/// `AVAudioPlayer` + `.playback` routing to the built-in speaker. Older watchOS
/// versions get the text + image notification path instead.
enum WatchAudioCapability {
    static var minimumSpeakerWatchOSMajor: Int { 9 }

    static func canPlayThroughSpeaker(
        systemMajorVersion: Int = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    ) -> Bool {
        systemMajorVersion >= minimumSpeakerWatchOSMajor
    }
}
