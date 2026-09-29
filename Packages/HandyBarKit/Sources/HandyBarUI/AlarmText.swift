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

    public static func repeatDays(_ days: Set<Weekday>, calendar: Calendar = .current) -> String {
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        switch days {
        case []: return "Once"
        case Set(Weekday.allCases): return "Every day"
        case weekdays: return "Weekdays"
        case [.saturday, .sunday]: return "Weekends"
        default:
            return orderedWeekdays(calendar: calendar)
                .filter(days.contains)
                .map { shortName($0, calendar: calendar) }
                .joined(separator: ", ")
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

    public static func veryShortName(_ day: Weekday, calendar: Calendar = .current) -> String {
        calendar.veryShortWeekdaySymbols[day.rawValue - 1]
    }
}
