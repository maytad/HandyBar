import Foundation
import HandyBarAlarm

public enum AlarmText {
    /// The time of day in the user's 12- or 24-hour format.
    public static func time(hour: Int, minute: Int, calendar: Calendar = .current) -> String {
        let date =
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return date.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened, calendar: calendar))
    }

    public static func uses12HourClock(locale: Locale = .current) -> Bool {
        DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale)?.contains("a")
            ?? false
    }

    /// "today", "tomorrow", or the short weekday name of `date`.
    public static func day(_ date: Date, now: Date = Date(), calendar: Calendar = .current)
        -> String
    {
        if calendar.isDate(date, inSameDayAs: now) { return "today" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
            calendar.isDate(date, inSameDayAs: tomorrow)
        {
            return "tomorrow"
        }
        return shortName(
            Weekday(rawValue: calendar.component(.weekday, from: date))!, calendar: calendar)
    }

    public static func repeatDays(_ days: Set<Weekday>, calendar: Calendar = .current) -> String {
        switch RepeatPreset(days) {
        case .custom:
            return orderedWeekdays(calendar: calendar)
                .filter(days.contains)
                .map { shortName($0, calendar: calendar) }
                .joined(separator: ", ")
        case let preset:
            return preset.title
        }
    }

    public static func orderedWeekdays(calendar: Calendar = .current) -> [Weekday] {
        let all = Weekday.allCases
        let start = all.firstIndex { $0.rawValue == calendar.firstWeekday } ?? 0
        return Array(all[start...] + all[..<start])
    }

    public static func shortName(_ day: Weekday, calendar: Calendar = .current) -> String {
        calendar.shortWeekdaySymbols[day.rawValue - 1]
    }

    public static func fullName(_ day: Weekday, calendar: Calendar = .current) -> String {
        calendar.weekdaySymbols[day.rawValue - 1]
    }
}

/// The Repeat days choices offered before picking individual days.
public enum RepeatPreset: CaseIterable, Hashable, Sendable {
    case never
    case everyDay
    case weekdays
    case weekends
    case custom

    public init(_ days: Set<Weekday>) {
        self = Self.allCases.first { $0 != .custom && $0.days == days } ?? .custom
    }

    public var days: Set<Weekday> {
        switch self {
        case .never, .custom: []
        case .everyDay: Set(Weekday.allCases)
        case .weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        case .weekends: [.saturday, .sunday]
        }
    }

    public var title: String {
        switch self {
        case .never: "Once"
        case .everyDay: "Every day"
        case .weekdays: "Weekdays"
        case .weekends: "Weekends"
        case .custom: "Custom"
        }
    }
}
