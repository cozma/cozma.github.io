import XCTest
@testable import MorningBoardKit

final class SnapshotBuilderTests: XCTestCase {
    func testHighHRVAndSleepMapsToPush() {
        let snapshot = SnapshotBuilder.build(
            from: HealthSampleBundle(
                sleepHours: 8.0,
                hrvNightMs: 70,
                hrvBaselineMs: 55,
                restingHeartRate: 50,
                rhrBaseline: 56
            )
        )

        XCTAssertEqual(snapshot.readinessBand, .push)
        XCTAssertGreaterThanOrEqual(snapshot.readinessScore, 70)
        XCTAssertTrue(snapshot.insight.lowercased().contains("push"))
    }

    func testLowSleepAndHRVMapsToRecover() {
        let snapshot = SnapshotBuilder.build(
            from: HealthSampleBundle(
                sleepHours: 5.0,
                hrvNightMs: 35,
                hrvBaselineMs: 55,
                restingHeartRate: 62,
                rhrBaseline: 56,
                cueStyle: .coachy
            )
        )

        XCTAssertEqual(snapshot.readinessBand, .recover)
        XCTAssertLessThan(snapshot.readinessScore, 45)
        XCTAssertTrue(snapshot.insight.lowercased().contains("protect") || snapshot.insight.lowercased().contains("recover"))
    }

    func testMissingSleepStillProducesSnapshot() {
        let snapshot = DemoSnapshots.waitingOnSleep()
        XCTAssertNil(snapshot.sleepHours)
        XCTAssertTrue(snapshot.insight.contains("Waiting"))
        XCTAssertFalse(snapshot.dayKey.isEmpty)
    }

    func testInMemoryStoreRoundTrip() async throws {
        let store = InMemoryBoardStore()
        let snapshot = DemoSnapshots.restedMorning()
        try await store.save(snapshot)
        let latest = try await store.latestSnapshot()
        XCTAssertEqual(latest, snapshot)
    }
}
