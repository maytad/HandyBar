import Foundation
import HandyBarAlarm
import HandyBarUI
import Testing

private func calendar(firstWeekday: Int) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US")
    calendar.firstWeekday = firstWeekday
    return calendar
}

@Test func noRepeatDaysReadsOnce() {
    #expect(AlarmText.repeatDays([], calendar: calendar(firstWeekday: 1)) == "Once")
}

@Test func allDaysReadEveryDay() {
    #expect(
        AlarmText.repeatDays(Set(Weekday.allCases), calendar: calendar(firstWeekday: 1))
            == "Every day")
}

@Test func mondayToFridayReadsWeekdays() {
    let days: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    #expect(AlarmText.repeatDays(days, calendar: calendar(firstWeekday: 1)) == "Weekdays")
}

@Test func saturdayAndSundayReadWeekends() {
    #expect(
        AlarmText.repeatDays([.saturday, .sunday], calendar: calendar(firstWeekday: 1))
            == "Weekends")
}

@Test func otherDaysAreListedInTheCalendarsWeekOrder() {
    let days: Set<Weekday> = [.sunday, .wednesday, .monday]
    #expect(AlarmText.repeatDays(days, calendar: calendar(firstWeekday: 1)) == "Sun, Mon, Wed")
    #expect(AlarmText.repeatDays(days, calendar: calendar(firstWeekday: 2)) == "Mon, Wed, Sun")
}

@Test func twelveHourClockFollowsTheLocale() {
    #expect(AlarmText.uses12HourClock(locale: Locale(identifier: "en_US")))
    #expect(!AlarmText.uses12HourClock(locale: Locale(identifier: "en_GB")))
}

@Test func dayNamesTodayTomorrowOrTheWeekday() {
    let calendar = calendar(firstWeekday: 1)
    let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 12))!
    let day = { (offset: Int) in calendar.date(byAdding: .day, value: offset, to: now)! }
    #expect(AlarmText.day(day(0), now: now, calendar: calendar) == "today")
    #expect(AlarmText.day(day(1), now: now, calendar: calendar) == "tomorrow")
    #expect(AlarmText.day(day(3), now: now, calendar: calendar) == "Sun")
}

@Test func repeatPresetsMatchTheirDays() {
    for preset in RepeatPreset.allCases where preset != .custom {
        #expect(RepeatPreset(preset.days) == preset)
    }
    #expect(RepeatPreset([.monday, .wednesday]) == .custom)
    #expect(RepeatPreset([]) == .never)
}

@Test func weekdaysFollowTheCalendarsFirstWeekday() {
    #expect(AlarmText.orderedWeekdays(calendar: calendar(firstWeekday: 2)).first == .monday)
    #expect(AlarmText.orderedWeekdays(calendar: calendar(firstWeekday: 1)).first == .sunday)
}
