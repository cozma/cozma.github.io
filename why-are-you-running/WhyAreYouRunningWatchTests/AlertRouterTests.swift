import XCTest
@testable import WhyAreYouRunningWatch

final class AlertRouterTests: XCTestCase {
    func testSpeakerPresentationWhenCapable() {
        XCTAssertEqual(
            AlertRouter.presentation(canPlayThroughSpeaker: true),
            .speakerAndBanner
        )
    }

    func testImagePresentationWhenNotCapable() {
        XCTAssertEqual(
            AlertRouter.presentation(canPlayThroughSpeaker: false),
            .textAndImage
        )
    }

    func testTriggersOnRunningStarted() {
        let event = RunEvent(kind: .runningStarted, detectedAt: Date(timeIntervalSince1970: 100))
        XCTAssertTrue(
            AlertRouter.shouldTrigger(
                for: event,
                lastTriggeredAt: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )
    }

    func testIgnoresNonRunningEvents() {
        let event = RunEvent(kind: .other, detectedAt: Date(timeIntervalSince1970: 100))
        XCTAssertFalse(
            AlertRouter.shouldTrigger(
                for: event,
                lastTriggeredAt: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )
    }

    func testRespectsCooldown() {
        let event = RunEvent(kind: .runningStarted, detectedAt: Date(timeIntervalSince1970: 200))
        XCTAssertFalse(
            AlertRouter.shouldTrigger(
                for: event,
                lastTriggeredAt: Date(timeIntervalSince1970: 100),
                now: Date(timeIntervalSince1970: 200),
                cooldown: 300
            )
        )
    }

    func testAllowsTriggerAfterCooldown() {
        let event = RunEvent(kind: .runningStarted, detectedAt: Date(timeIntervalSince1970: 500))
        XCTAssertTrue(
            AlertRouter.shouldTrigger(
                for: event,
                lastTriggeredAt: Date(timeIntervalSince1970: 100),
                now: Date(timeIntervalSince1970: 500),
                cooldown: 300
            )
        )
    }

    func testSpeakerCapabilityCutoff() {
        XCTAssertFalse(WatchAudioCapability.canPlayThroughSpeaker(systemMajorVersion: 8))
        XCTAssertTrue(WatchAudioCapability.canPlayThroughSpeaker(systemMajorVersion: 9))
        XCTAssertTrue(WatchAudioCapability.canPlayThroughSpeaker(systemMajorVersion: 11))
    }
}
