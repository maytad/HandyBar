import Foundation

/// A time of day and optional label typed as one line, such as `7:30 Standup` or `7pm`.
public struct TimeEntry: Equatable, Sendable {
    public var hour: Int
    public var minute: Int
    public var label: String

    public init(hour: Int, minute: Int, label: String = "") {
        self.hour = hour
        self.minute = minute
        self.label = label
    }

    /// Reads `7`, `730`, `7:30`, `7.30`, `19:30`, `7pm`, or `7:30 a.m.`, followed by an optional label.
    ///
    /// On a 12-hour clock an hour from 1 to 12 without AM or PM means whichever of the
    /// two times comes next after `now`.
    public static func parse(
        _ text: String, uses12HourClock: Bool, now: Date, calendar: Calendar
    ) -> TimeEntry? {
        let pattern = #"^(\d{1,4})(?:[:.](\d{2}))?\s*(a\.m\.|p\.m\.|am|pm|a|p)?(?=\s|$)\s*(.*)$"#
        guard
            let regex = try? Regex(pattern).ignoresCase(),
            let match = try? regex.wholeMatch(
                in: text.trimmingCharacters(in: .whitespacesAndNewlines)),
            let digits = match.output[1].substring
        else { return nil }

        var hour: Int
        var minute = 0
        if let minutes = match.output[2].substring {
            guard digits.count <= 2 else { return nil }
            hour = Int(digits)!
            minute = Int(minutes)!
        } else if digits.count <= 2 {
            hour = Int(digits)!
        } else {
            hour = Int(digits.dropLast(2))!
            minute = Int(digits.suffix(2))!
        }
        guard (0...59).contains(minute) else { return nil }

        let label = match.output[4].substring.map(String.init) ?? ""
        if let meridiem = match.output[3].substring?.lowercased() {
            guard (1...12).contains(hour) else { return nil }
            hour = hour % 12 + (meridiem.hasPrefix("p") ? 12 : 0)
        } else {
            guard (0...23).contains(hour) else { return nil }
            if uses12HourClock, (1...12).contains(hour) {
                hour = [hour % 12, hour % 12 + 12].min {
                    next(hour: $0, minute: minute, after: now, calendar)
                        < next(hour: $1, minute: minute, after: now, calendar)
                }!
            }
        }
        return TimeEntry(hour: hour, minute: minute, label: label)
    }

    private static func next(hour: Int, minute: Int, after date: Date, _ calendar: Calendar)
        -> Date
    {
        calendar.nextDate(
            after: date, matching: DateComponents(hour: hour, minute: minute, second: 0),
            matchingPolicy: .nextTime) ?? .distantFuture
    }
}
