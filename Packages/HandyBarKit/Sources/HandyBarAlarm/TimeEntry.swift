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
        guard let reading = Reading(text) else { return nil }
        var hour = reading.hour
        if let isPM = reading.isPM {
            hour = hour % 12 + (isPM ? 12 : 0)
        } else if uses12HourClock, reading.isAmbiguous {
            hour = [hour % 12, hour % 12 + 12].min {
                next($0, reading.minute, after: now, calendar)
                    < next($1, reading.minute, after: now, calendar)
            }!
        }
        return TimeEntry(hour: hour, minute: reading.minute, label: reading.label)
    }

    /// The likely meanings of `text`, best first: the parsed time, then its quarter
    /// hours when only an hour was typed, or the other half of the day when AM or PM
    /// was left out.
    public static func suggestions(
        for text: String, uses12HourClock: Bool, now: Date, calendar: Calendar
    ) -> [TimeEntry] {
        guard
            let reading = Reading(text),
            let best = parse(text, uses12HourClock: uses12HourClock, now: now, calendar: calendar)
        else { return [] }
        if !reading.hasMinutes, reading.isPM == nil {
            return [0, 15, 30, 45].map { TimeEntry(hour: best.hour, minute: $0, label: best.label) }
        }
        if reading.isAmbiguous {
            let other = TimeEntry(
                hour: (best.hour + 12) % 24, minute: best.minute, label: best.label)
            return [best, other]
        }
        return [best]
    }

    private static func next(_ hour: Int, _ minute: Int, after date: Date, _ calendar: Calendar)
        -> Date
    {
        calendar.nextDate(
            after: date, matching: DateComponents(hour: hour, minute: minute, second: 0),
            matchingPolicy: .nextTime) ?? .distantFuture
    }
}

/// What was typed, before choosing between AM and PM.
private struct Reading {
    var hour: Int
    var minute: Int
    var hasMinutes: Bool
    var isPM: Bool?
    var label: String

    /// An hour from 1 to 12 with no AM or PM could mean either half of the day.
    var isAmbiguous: Bool { isPM == nil && (1...12).contains(hour) }

    init?(_ text: String) {
        let pattern = #"^(\d{1,4})(?:[:.](\d{2}))?\s*(a\.m\.|p\.m\.|am|pm|a|p)?(?=\s|$)\s*(.*)$"#
        guard
            let regex = try? Regex(pattern).ignoresCase(),
            let match = try? regex.wholeMatch(
                in: text.trimmingCharacters(in: .whitespacesAndNewlines)),
            let digits = match.output[1].substring
        else { return nil }

        minute = 0
        hasMinutes = true
        if let minutes = match.output[2].substring {
            guard digits.count <= 2 else { return nil }
            hour = Int(digits)!
            minute = Int(minutes)!
        } else if digits.count <= 2 {
            hour = Int(digits)!
            hasMinutes = false
        } else {
            hour = Int(digits.dropLast(2))!
            minute = Int(digits.suffix(2))!
        }
        guard (0...59).contains(minute) else { return nil }

        label = match.output[4].substring.map(String.init) ?? ""
        if let meridiem = match.output[3].substring?.lowercased() {
            guard (1...12).contains(hour) else { return nil }
            isPM = meridiem.hasPrefix("p")
        } else {
            guard (0...23).contains(hour) else { return nil }
        }
    }
}
