import HandyBarAutoClick
import HandyBarCleanup

public struct FeatureEntry: Identifiable, Equatable, Sendable {
    public let title: String
    /// The SF Symbol shown on the feature's card.
    public let symbol: String
    public let isAvailable: Bool

    public var id: String { title }

    public static let all: [FeatureEntry] = [
        FeatureEntry(title: "Alarm", symbol: "alarm.fill", isAvailable: true),
        FeatureEntry(
            title: "Auto Click", symbol: "cursorarrow.click.2", isAvailable: AutoClick.isAvailable),
        FeatureEntry(title: "Cleanup", symbol: "sparkles", isAvailable: Cleanup.isAvailable),
    ]
}
