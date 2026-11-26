# Why Are You Running? (Apple Watch)

Independent watchOS app that notices when you start a run and delivers the classic question:

- **Newer watches (watchOS 9+):** plays a short “why are you running?” phrase through the watch speaker and shows a banner.
- **Older watches (watchOS 8 on supported hardware):** shows a text notification with an attached still image (custom `UNNotificationSound.soundNamed` is unavailable on watchOS).

Minimum install target is **watchOS 8**; speaker vs. image is chosen at runtime.

## How detection works

1. **Core Motion** – rising edge into `CMMotionActivity.running` (confidence not `.low`).
2. **HealthKit** – background observer on running `HKWorkout` samples that started in the last two minutes.

A **30-minute cooldown** stops a long jog from re-firing the joke.

Use **Test alert** on the main screen to exercise the speaker / image path without going outside.

## Assumption (flagged)

“Newer watch” is defined as **watchOS 9.0+**, where `AVAudioPlayer` with `.playback` reliably routes to the built-in speaker. Change `WatchAudioCapability.minimumSpeakerWatchOSMajor` if you want a different cut line.

## Copyright note

The original Vine audio/video is copyrighted and is **not** redistributed here. The repo ships:

- an **original TTS placeholder** (`Resources/why_are_you_running.wav`)
- an **original illustrated still** (`Resources/vine_still.png`)

Replace the `.wav` with your own licensed clip if you want the authentic sound.

## Open in Xcode

1. Open `WhyAreYouRunning.xcodeproj` on a Mac with Xcode 15+.
2. Select the **WhyAreYouRunningWatch** scheme.
3. Choose an Apple Watch simulator or paired device (watchOS 9+ for speaker mode).
4. Enable the **HealthKit** capability for your team signing (entitlements are already listed).
5. Build & run. Grant Motion, Health, and Notification permission when prompted.

## Tests

On this Linux portfolio host (no Xcode):

```bash
python3 -m unittest discover -s why-are-you-running/tests -v
```

On a Mac with Xcode:

```bash
xcodebuild test -scheme WhyAreYouRunningWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'
```

## Layout

```
why-are-you-running/
  WhyAreYouRunning.xcodeproj/
  WhyAreYouRunningWatch/          # SwiftUI watch app
    Alerting/                    # router, speaker, notifications
    RunDetection/                # motion + HealthKit
    Resources/                   # wav + png placeholders
  WhyAreYouRunningWatchTests/    # XCTest
  tests/                         # Python mirrors of pure logic
```
