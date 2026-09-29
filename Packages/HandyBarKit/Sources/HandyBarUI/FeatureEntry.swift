import HandyBarAutoClick
import HandyBarCleanup

public struct FeatureEntry: Identifiable, Equatable, Sendable {
    public let title: String
    public let isAvailable: Bool

    public var id: String { title }

    public static let all: [FeatureEntry] = [
        FeatureEntry(title: "Alarm", isAvailable: true),
        FeatureEntry(title: "Auto Click", isAvailable: AutoClick.isAvailable),
        FeatureEntry(title: "Cleanup", isAvailable: Cleanup.isAvailable),
    ]
}
