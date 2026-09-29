import Foundation

/// Keeps Alarms on this Mac as a JSON file.
public struct AlarmStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// `~/Library/Application Support/HandyBar/alarms.json`.
    public static var standard: AlarmStore {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return AlarmStore(fileURL: support.appendingPathComponent("HandyBar/alarms.json"))
    }

    public func load() throws -> AlarmEngine.Snapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AlarmEngine.Snapshot()
        }
        return try JSONDecoder().decode(AlarmEngine.Snapshot.self, from: Data(contentsOf: fileURL))
    }

    public func save(_ snapshot: AlarmEngine.Snapshot) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: fileURL, options: .atomic)
    }
}
