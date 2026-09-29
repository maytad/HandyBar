import Foundation

public enum Weekday: Int, CaseIterable, Codable, Comparable, Sendable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A user-set time of day at which HandyBar rings, either once or on chosen Repeat days.
public struct Alarm: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var hour: Int
    public var minute: Int
    public var label: String
    /// Weekdays on which the Alarm rings again; empty means it rings once.
    public var repeatDays: Set<Weekday>
    public var isEnabled: Bool
    /// When the Alarm rings next, maintained by `AlarmEngine`.
    public internal(set) var nextOccurrence: Date?

    public init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        label: String = "",
        repeatDays: Set<Weekday> = [],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
    }

    public var repeats: Bool { !repeatDays.isEmpty }
}
