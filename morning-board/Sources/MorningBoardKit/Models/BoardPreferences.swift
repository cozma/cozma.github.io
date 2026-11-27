import Foundation

public struct BoardPreferences: Codable, Equatable, Sendable {
    public var publishEnabled: Bool
    public var cueStyle: CueStyle
    public var preferredSleepSource: String?
    public var preferredHRVSource: String?

    public init(
        publishEnabled: Bool = true,
        cueStyle: CueStyle = .quiet,
        preferredSleepSource: String? = nil,
        preferredHRVSource: String? = nil
    ) {
        self.publishEnabled = publishEnabled
        self.cueStyle = cueStyle
        self.preferredSleepSource = preferredSleepSource
        self.preferredHRVSource = preferredHRVSource
    }
}

public enum CueStyle: String, Codable, Equatable, Sendable, CaseIterable {
    case quiet
    case coachy
}
