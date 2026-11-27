import Foundation

/// Abstraction over CloudKit so unit tests and the web prototype can share the same flow.
public protocol BoardStore: Sendable {
    func save(_ snapshot: MorningSnapshot) async throws
    func latestSnapshot() async throws -> MorningSnapshot?
}

/// In-memory store used by demos and tests. Swap for `CloudKitBoardStore` on device.
public actor InMemoryBoardStore: BoardStore {
    private var snapshots: [String: MorningSnapshot] = [:]

    public init(seed: MorningSnapshot? = nil) {
        if let seed {
            snapshots[seed.dayKey] = seed
        }
    }

    public func save(_ snapshot: MorningSnapshot) async throws {
        snapshots[snapshot.dayKey] = snapshot
    }

    public func latestSnapshot() async throws -> MorningSnapshot? {
        snapshots.values.sorted { $0.dayKey > $1.dayKey }.first
    }
}

#if canImport(CloudKit)
import CloudKit

/// Production writer/reader. iPhone is the writer of record; TV mostly reads.
public final class CloudKitBoardStore: BoardStore, @unchecked Sendable {
    public static let recordType = "DailyBoard"
    public static let defaultContainerID = "iCloud.com.cozma.MorningBoard"

    private let database: CKDatabase
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(containerIdentifier: String = CloudKitBoardStore.defaultContainerID) {
        let container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func save(_ snapshot: MorningSnapshot) async throws {
        let recordID = CKRecord.ID(recordName: snapshot.dayKey)
        let record: CKRecord
        if let existing = try? await database.record(for: recordID) {
            record = existing
        } else {
            record = CKRecord(recordType: Self.recordType, recordID: recordID)
        }
        let data = try encoder.encode(snapshot)
        record["payload"] = String(data: data, encoding: .utf8) as CKRecordValue?
        record["dayKey"] = snapshot.dayKey as CKRecordValue
        record["readinessScore"] = snapshot.readinessScore as CKRecordValue
        record["generatedAt"] = snapshot.generatedAt as CKRecordValue
        try await database.save(record)
    }

    public func latestSnapshot() async throws -> MorningSnapshot? {
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "generatedAt", ascending: false)]
        let (results, _) = try await database.records(matching: query, resultsLimit: 1)
        guard let first = results.first else { return nil }
        let record = try first.1.get()
        guard let payload = record["payload"] as? String,
              let data = payload.data(using: .utf8) else {
            return nil
        }
        return try decoder.decode(MorningSnapshot.self, from: data)
    }
}
#endif
