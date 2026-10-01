import HandyBarAutoClick
import HandyBarCleanup

public struct FeatureEntry: Identifiable, Equatable, Sendable {
    public let title: String
    /// The SF Symbol that stands for the feature.
    public let symbol: String
    /// One line saying what the feature does.
    public let summary: String
    public let isAvailable: Bool

    public var id: String { title }

    public static let all: [FeatureEntry] = [
        FeatureEntry(
            title: "Alarm", symbol: "alarm.fill", summary: "Ring at set times of day",
            isAvailable: true),
        FeatureEntry(
            title: "Auto Click", symbol: "cursorarrow.click.2",
            summary: "Repeat mouse clicks automatically", isAvailable: AutoClick.isAvailable),
        FeatureEntry(
            title: "Cleanup", symbol: "sparkles", summary: "Free disk space with Mole",
            isAvailable: Cleanup.isAvailable),
    ]
}
