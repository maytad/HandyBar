import Foundation
import HandyBarAlarm
import Testing

@Test func addingMinutesCarriesIntoHoursAndWrapsAroundMidnight() {
    #expect(ClockTime(hour: 7, minute: 55).adding(minutes: 15) == ClockTime(hour: 8, minute: 10))
    #expect(ClockTime(hour: 23, minute: 50).adding(minutes: 15) == ClockTime(hour: 0, minute: 5))
    #expect(ClockTime(hour: 0, minute: 5).adding(minutes: -15) == ClockTime(hour: 23, minute: 50))
    #expect(ClockTime(hour: 23, minute: 0).adding(minutes: 60) == ClockTime(hour: 0, minute: 0))
}

@Test func typingAnHourTakesTwoDigitsOrOneThatCannotStartALargerHour() {
    var typing = ClockDigitTyping(component: .hour)
    #expect(typing.type(1) == .init(value: 1, isComplete: false))
    #expect(typing.type(9) == .init(value: 19, isComplete: true))

    typing = ClockDigitTyping(component: .hour)
    #expect(typing.type(7) == .init(value: 7, isComplete: true))

    typing = ClockDigitTyping(component: .hour)
    _ = typing.type(2)
    #expect(typing.type(5) == .init(value: 5, isComplete: true))
}

@Test func typingAMinuteTakesTwoDigitsOrOneAbove5() {
    var typing = ClockDigitTyping(component: .minute)
    _ = typing.type(3)
    #expect(typing.type(0) == .init(value: 30, isComplete: true))

    typing = ClockDigitTyping(component: .minute)
    #expect(typing.type(8) == .init(value: 8, isComplete: true))
}

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Bangkok")!
    return calendar
}()

private let noon = calendar.date(
    from: DateComponents(year: 2026, month: 10, day: 1, hour: 12))!

private func suggestions(_ text: String, twelveHour: Bool = false) -> [TimeEntry] {
    TimeEntry.suggestions(for: text, uses12HourClock: twelveHour, now: noon, calendar: calendar)
}

@Test func aBareHourSuggestsItsQuarterHours() {
    #expect(
        suggestions("7").map { [$0.hour, $0.minute] } == [[7, 0], [7, 15], [7, 30], [7, 45]])
}

@Test func anAmbiguousTimeAlsoSuggestsTheOtherHalfOfTheDay() {
    #expect(suggestions("7:30").map { [$0.hour, $0.minute] } == [[7, 30], [19, 30]])
    #expect(
        suggestions("7:30", twelveHour: true).map { [$0.hour, $0.minute] } == [[19, 30], [7, 30]])
}

@Test func anUnambiguousTimeSuggestsOnlyItself() {
    #expect(suggestions("19:30 Gym") == [TimeEntry(hour: 19, minute: 30, label: "Gym")])
    #expect(suggestions("7pm").map { [$0.hour, $0.minute] } == [[19, 0]])
}

@Test func suggestionsKeepTheLabel() {
    #expect(suggestions("7 Standup").allSatisfy { $0.label == "Standup" })
}

@Test func textThatIsNotATimeSuggestsNothing() {
    #expect(suggestions("Standup").isEmpty)
    #expect(suggestions("").isEmpty)
}
