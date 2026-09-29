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

@Test func weekdaysFollowTheCalendarsFirstWeekday() {
    #expect(AlarmText.orderedWeekdays(calendar: calendar(firstWeekday: 2)).first == .monday)
    #expect(AlarmText.orderedWeekdays(calendar: calendar(firstWeekday: 1)).first == .sunday)
}
