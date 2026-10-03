import Foundation
import HandyBarAlarm
import Testing

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Bangkok")!
    return calendar
}()

private func today(_ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: hour, minute: minute))!
}

private func parse(_ text: String, twelveHour: Bool = false, at now: Date = today(12))
    -> TimeEntry?
{
    TimeEntry.parse(text, uses12HourClock: twelveHour, now: now, calendar: calendar)
}

@Test(arguments: [
    ("7:30", 7, 30), ("7.30", 7, 30), ("730", 7, 30), ("19:30", 19, 30), ("1930", 19, 30),
    ("0:05", 0, 5), ("7", 7, 0), ("  7:30  ", 7, 30),
])
func readsTimesOnA24HourClock(text: String, hour: Int, minute: Int) {
    #expect(parse(text) == TimeEntry(hour: hour, minute: minute))
}

@Test(arguments: [
    ("7pm", 19, 0), ("7 PM", 19, 0), ("7:30p", 19, 30), ("7:30 pm", 19, 30),
    ("7:30 a.m.", 7, 30), ("12am", 0, 0), ("12pm", 12, 0), ("730a", 7, 30),
])
func readsAMAndPM(text: String, hour: Int, minute: Int) {
    #expect(parse(text) == TimeEntry(hour: hour, minute: minute))
    #expect(parse(text, twelveHour: true) == TimeEntry(hour: hour, minute: minute))
}

@Test func anHourWithoutAMOrPMOnA12HourClockMeansTheNextOneToCome() {
    #expect(parse("7", twelveHour: true, at: today(6)) == TimeEntry(hour: 7, minute: 0))
    #expect(parse("7", twelveHour: true, at: today(8)) == TimeEntry(hour: 19, minute: 0))
    #expect(parse("7:30", twelveHour: true, at: today(20)) == TimeEntry(hour: 7, minute: 30))
    #expect(parse("12", twelveHour: true, at: today(13)) == TimeEntry(hour: 0, minute: 0))
}

@Test func anHourPast12IsAlways24Hour() {
    #expect(parse("19:30", twelveHour: true, at: today(6)) == TimeEntry(hour: 19, minute: 30))
}

@Test func textAfterTheTimeIsTheLabel() {
    #expect(parse("7:30 Standup") == TimeEntry(hour: 7, minute: 30, label: "Standup"))
    #expect(parse("7pm  take pills ") == TimeEntry(hour: 19, minute: 0, label: "take pills"))
    #expect(parse("7 apple") == TimeEntry(hour: 7, minute: 0, label: "apple"))
}

@Test(arguments: ["", "  ", "Standup", "25:00", "7:60", "13pm", "0am", "7:5", "12345", "7:30x"])
func rejectsTextThatIsNotATime(text: String) {
    #expect(parse(text) == nil)
}
