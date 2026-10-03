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

/// How long Snooze holds off an Alarm before it rings again; `.off` hides Snooze.
public enum AlarmSnooze: Int, CaseIterable, Codable, Sendable {
    case off = 0
    case oneMinute = 1
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30

    public var minutes: Int { rawValue }

    /// Alarms Ringing together snooze for the first one's length, skipping any with
    /// Snooze off; `.off` when none of them can snooze.
    public static func length(forRinging alarms: [Alarm]) -> AlarmSnooze {
        alarms.lazy.map(\.snooze).first { $0 != .off } ?? .off
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
    public var sound: AlarmSound
    public var snooze: AlarmSnooze
    /// When the Alarm rings next, maintained by `AlarmEngine`.
    public internal(set) var nextOccurrence: Date?

    public init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        label: String = "",
        repeatDays: Set<Weekday> = [],
        isEnabled: Bool = true,
        sound: AlarmSound = .beeps,
        snooze: AlarmSnooze = .fiveMinutes
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.sound = sound
        self.snooze = snooze
    }

    public var repeats: Bool { !repeatDays.isEmpty }
}

extension Alarm {
    /// Alarms saved before sounds and snooze lengths existed, or with values this version
    /// doesn't know, play `.beeps` and snooze for five minutes.
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
        let snoozeMinutes = try container.decodeIfPresent(Int.self, forKey: .snooze)
        snooze = snoozeMinutes.flatMap(AlarmSnooze.init(rawValue:)) ?? .fiveMinutes
        nextOccurrence = try container.decodeIfPresent(Date.self, forKey: .nextOccurrence)
    }
}
