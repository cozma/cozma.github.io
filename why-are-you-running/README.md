# Why Are You Running? (Apple Watch)

Independent watchOS app that notices when you start a run and asks the question:

- **Newer watches (watchOS 9+):** plays your bundled audio through the watch speaker and shows a banner.
- **Older watches (watchOS 8 on supported hardware):** shows a text notification with an attached still image (custom `UNNotificationSound.soundNamed` is unavailable on watchOS).

Minimum install target is **watchOS 8**; speaker vs. image is chosen at runtime.

## Your audio

Replace `WhyAreYouRunningWatch/Resources/run_alert.wav` with your own track (keep that filename). A short placeholder wav is there so the project builds and **Test alert** works until you drop yours in.

Supported easily: short linear PCM `.wav` (a few seconds is ideal for the watch speaker).

## How detection works

1. **Core Motion** – rising edge into `CMMotionActivity.running` (confidence not `.low`).
2. **HealthKit** – background observer on running `HKWorkout` samples that started in the last two minutes.

A **30-minute cooldown** stops a long jog from re-firing the alert.

Use **Test alert** on the main screen to exercise the speaker / image path without going outside.

## Assumption (flagged)

“Newer watch” is defined as **watchOS 9.0+**, where `AVAudioPlayer` with `.playback` reliably routes to the built-in speaker. Change `WatchAudioCapability.minimumSpeakerWatchOSMajor` if you want a different cut line.

## Open in Xcode

1. Open `WhyAreYouRunning.xcodeproj` on a Mac with Xcode 15+.
2. Drop your audio onto `Resources/run_alert.wav`.
3. Select the **WhyAreYouRunningWatch** scheme.
4. Choose an Apple Watch simulator or paired device (watchOS 9+ for speaker mode).
5. Enable the **HealthKit** capability for your team signing (entitlements are already listed).
6. Build & run. Grant Motion, Health, and Notification permission when prompted.

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
    Resources/                   # run_alert.wav + run_alert_still.png
  WhyAreYouRunningWatchTests/    # XCTest
  tests/                         # Python mirrors of pure logic
```
