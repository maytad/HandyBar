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

/// The built-in sound an Alarm plays while Ringing.
public enum AlarmSound: String, CaseIterable, Codable, Sendable {
    case beeps
    case chime
    case rising
    case rapid
    case soft
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
    public var sound: AlarmSound
    /// When the Alarm rings next, maintained by `AlarmEngine`.
    public internal(set) var nextOccurrence: Date?

    public init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        label: String = "",
        repeatDays: Set<Weekday> = [],
        isEnabled: Bool = true,
        sound: AlarmSound = .beeps
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.sound = sound
    }

    public var repeats: Bool { !repeatDays.isEmpty }
}

extension Alarm {
    /// Alarms saved before sounds existed, or with a sound this version doesn't know,
    /// play `.beeps`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        hour = try container.decode(Int.self, forKey: .hour)
        minute = try container.decode(Int.self, forKey: .minute)
        label = try container.decode(String.self, forKey: .label)
        repeatDays = try container.decode(Set<Weekday>.self, forKey: .repeatDays)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        let soundName = try container.decodeIfPresent(String.self, forKey: .sound)
        sound = soundName.flatMap(AlarmSound.init(rawValue:)) ?? .beeps
        nextOccurrence = try container.decodeIfPresent(Date.self, forKey: .nextOccurrence)
    }
}
