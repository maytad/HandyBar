import Foundation
import HandyBarAlarm
import Testing

private let bangkok = TimeZone(identifier: "Asia/Bangkok")!

private func calendar(_ timeZone: TimeZone = bangkok) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar
}

/// Monday 28 September 2026 at the given local time in Bangkok.
private func monday(_ hour: Int, _ minute: Int = 0, second: Int = 0, dayOffset: Int = 0) -> Date {
    let components = DateComponents(
        year: 2026, month: 9, day: 28 + dayOffset, hour: hour, minute: minute, second: second)
    return calendar().date(from: components)!
}

private func engine(with alarms: [Alarm], at now: Date) -> AlarmEngine {
    var engine = AlarmEngine(calendar: calendar())
    for alarm in alarms {
        engine.handle(.add(alarm), at: now)
    }
    return engine
}

// MARK: - Next deadline

@Test func oneTimeAlarmIsDueLaterToday() {
    let engine = engine(with: [Alarm(hour: 10, minute: 0)], at: monday(9))
    #expect(engine.nextDeadline == monday(10))
}

@Test func oneTimeAlarmWhoseTimePassedTodayIsDueTomorrow() {
    let engine = engine(with: [Alarm(hour: 8, minute: 30)], at: monday(9))
    #expect(engine.nextDeadline == monday(8, 30, dayOffset: 1))
}

@Test func repeatingAlarmIsDueOnItsNextRepeatDay() {
    let friday = Alarm(hour: 10, minute: 0, repeatDays: [.friday])
    let engine = engine(with: [friday], at: monday(9))
    #expect(engine.nextDeadline == monday(10, dayOffset: 4))
}

@Test func repeatingAlarmCrossesTheWeekBoundary() {
    let sunday = Alarm(hour: 7, minute: 0, repeatDays: [.sunday])
    let engine = engine(with: [sunday], at: monday(9))
    #expect(engine.nextDeadline == monday(7, dayOffset: 6))
}

@Test func nextDeadlineIsTheEarliestEnabledAlarm() {
    let engine = engine(
        with: [Alarm(hour: 15, minute: 0), Alarm(hour: 10, minute: 0)], at: monday(9))
    #expect(engine.nextDeadline == monday(10))
}

@Test func disabledAlarmHasNoDeadlineAndNeverRings() {
    var engine = engine(with: [Alarm(hour: 10, minute: 0, isEnabled: false)], at: monday(9))
    #expect(engine.nextDeadline == nil)
    engine.handle(.deadlineReached, at: monday(10))
    #expect(engine.ringingAlarms.isEmpty)
}

@Test func alarmsAreListedByTimeOfDay() {
    let engine = engine(
        with: [Alarm(hour: 15, minute: 0), Alarm(hour: 7, minute: 30), Alarm(hour: 10, minute: 0)],
        at: monday(9))
    #expect(engine.alarms.map(\.hour) == [7, 10, 15])
}

// MARK: - Ringing

@Test func alarmRingsAtItsTime() {
    let alarm = Alarm(hour: 10, minute: 0, label: "Standup")
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    #expect(engine.ringingAlarms.map(\.id) == [alarm.id])
}

@Test func oneTimeAlarmSwitchesOffAfterRinging() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    #expect(engine.alarms.first?.isEnabled == false)
}

@Test func repeatingAlarmMovesToItsNextRepeatDayAfterRinging() {
    let alarm = Alarm(hour: 10, minute: 0, repeatDays: [.monday, .wednesday])
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.stop, at: monday(10, 1))
    #expect(engine.alarms.first?.isEnabled == true)
    #expect(engine.nextDeadline == monday(10, dayOffset: 2))
}

@Test func stopEndsRinging() {
    var engine = engine(with: [Alarm(hour: 10, minute: 0)], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.stop, at: monday(10, 1))
    #expect(engine.ringingAlarms.isEmpty)
    #expect(engine.missedAlarms.isEmpty)
}

@Test func alarmsDueTogetherRingTogether() {
    let first = Alarm(hour: 10, minute: 0, label: "A")
    let second = Alarm(hour: 10, minute: 0, label: "B")
    var engine = engine(with: [first, second], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    #expect(Set(engine.ringingAlarms.map(\.id)) == [first.id, second.id])
}

@Test func alarmDueWhileRingingJoinsTheRingingAlarms() {
    let first = Alarm(hour: 10, minute: 0)
    let second = Alarm(hour: 10, minute: 5)
    var engine = engine(with: [first, second], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.deadlineReached, at: monday(10, 5))
    #expect(engine.ringingAlarms.map(\.id) == [first.id, second.id])

    engine.handle(.stop, at: monday(10, 6))
    #expect(engine.ringingAlarms.isEmpty)
}

// MARK: - Snooze

@Test func snoozeRingsAgainFiveMinutesLater() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.snooze, at: monday(10, 1))
    #expect(engine.ringingAlarms.isEmpty)
    #expect(engine.nextDeadline == monday(10, 6))

    engine.handle(.deadlineReached, at: monday(10, 6))
    #expect(engine.ringingAlarms.map(\.id) == [alarm.id])
}

@Test func snoozeDoesNotChangeTheAlarm() {
    let alarm = Alarm(hour: 10, minute: 0, repeatDays: [.monday])
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.snooze, at: monday(10, 1))
    engine.handle(.deadlineReached, at: monday(10, 6))
    engine.handle(.stop, at: monday(10, 7))

    #expect(engine.alarms.first?.hour == 10)
    #expect(engine.alarms.first?.minute == 0)
    #expect(engine.alarms.first?.repeatDays == [.monday])
    #expect(engine.nextDeadline == monday(10, dayOffset: 7))
}

@Test func snoozeAppliesToEveryRingingAlarm() {
    let first = Alarm(hour: 10, minute: 0)
    let second = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [first, second], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.snooze, at: monday(10, 1))
    engine.handle(.deadlineReached, at: monday(10, 6))
    #expect(Set(engine.ringingAlarms.map(\.id)) == [first.id, second.id])
}

// MARK: - Unattended

@Test func unattendedRingingStopsAfterFifteenMinutesAndIsMissed() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    #expect(engine.nextDeadline == monday(10, 15))

    engine.handle(.deadlineReached, at: monday(10, 15))
    #expect(engine.ringingAlarms.isEmpty)
    #expect(engine.missedAlarms.map(\.id) == [alarm.id])
}

@Test func unattendedSnoozedRingingIsAlsoMissed() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.snooze, at: monday(10, 1))
    engine.handle(.deadlineReached, at: monday(10, 6))
    engine.handle(.deadlineReached, at: monday(10, 21))
    #expect(engine.ringingAlarms.isEmpty)
    #expect(engine.missedAlarms.map(\.id) == [alarm.id])
}

@Test func alarmJoiningRingingGetsItsOwnFifteenMinutes() {
    var engine = engine(
        with: [Alarm(hour: 10, minute: 0), Alarm(hour: 10, minute: 10)], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.deadlineReached, at: monday(10, 10))
    #expect(engine.nextDeadline == monday(10, 25))
}

// MARK: - Missed Alarms

@Test func wakingAfterAnAlarmsTimeMarksItMissedWithoutRinging() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.woke, at: monday(11))
    #expect(engine.ringingAlarms.isEmpty)
    #expect(engine.missedAlarms.map(\.id) == [alarm.id])
}

@Test func launchingAfterAnAlarmsTimeMarksItMissedWithoutRinging() {
    let alarm = Alarm(hour: 10, minute: 0)
    let before = engine(with: [alarm], at: monday(9))

    var relaunched = AlarmEngine(snapshot: before.snapshot, calendar: calendar())
    relaunched.handle(.launched, at: monday(11))
    #expect(relaunched.ringingAlarms.isEmpty)
    #expect(relaunched.missedAlarms.map(\.id) == [alarm.id])
}

@Test func lateDeadlineAfterSleepIsMissedNotRung() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10, 40))
    #expect(engine.ringingAlarms.isEmpty)
    #expect(engine.missedAlarms.map(\.id) == [alarm.id])
}

@Test func slightlyLateDeadlineStillRings() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10, second: 2))
    #expect(engine.ringingAlarms.map(\.id) == [alarm.id])
}

@Test func missedOneTimeAlarmSwitchesOff() {
    var engine = engine(with: [Alarm(hour: 10, minute: 0)], at: monday(9))
    engine.handle(.woke, at: monday(11))
    #expect(engine.alarms.first?.isEnabled == false)
    #expect(engine.nextDeadline == nil)
}

@Test func missedRepeatingAlarmKeepsItsNextRepeatDay() {
    let alarm = Alarm(hour: 10, minute: 0, repeatDays: [.monday, .tuesday])
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.woke, at: monday(11))
    #expect(engine.alarms.first?.isEnabled == true)
    #expect(engine.nextDeadline == monday(10, dayOffset: 1))
}

@Test func seeingMissedAlarmsClearsThem() {
    var engine = engine(with: [Alarm(hour: 10, minute: 0)], at: monday(9))
    engine.handle(.woke, at: monday(11))
    engine.handle(.missedAlarmsSeen, at: monday(11, 1))
    #expect(engine.missedAlarms.isEmpty)
}

@Test func missedAlarmsSurviveARelaunch() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.woke, at: monday(11))

    let relaunched = AlarmEngine(snapshot: engine.snapshot, calendar: calendar())
    #expect(relaunched.missedAlarms.map(\.id) == [alarm.id])
}

@Test func snoozeDueAfterRelaunchIsMissed() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.snooze, at: monday(10, 1))

    var relaunched = AlarmEngine(snapshot: engine.snapshot, calendar: calendar())
    relaunched.handle(.launched, at: monday(10, 30))
    #expect(relaunched.ringingAlarms.isEmpty)
    #expect(relaunched.missedAlarms.map(\.id) == [alarm.id])
}

// MARK: - Editing

@Test func editingAnAlarmMovesItsDeadline() {
    var alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    alarm.hour = 14
    engine.handle(.update(alarm), at: monday(9, 5))
    #expect(engine.nextDeadline == monday(14))
}

@Test func switchingAnAlarmOnSchedulesItsNextOccurrence() {
    let alarm = Alarm(hour: 10, minute: 0, isEnabled: false)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.setEnabled(alarm.id, true), at: monday(9, 5))
    #expect(engine.nextDeadline == monday(10))
}

@Test func deletingARingingAlarmStopsRingingWhenNoneAreLeft() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.delete(alarm.id), at: monday(10, 1))
    #expect(engine.ringingAlarms.isEmpty)
    #expect(engine.alarms.isEmpty)
    #expect(engine.nextDeadline == nil)
}

@Test func deletingOneOfTwoRingingAlarmsKeepsTheOtherRinging() {
    let first = Alarm(hour: 10, minute: 0)
    let second = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [first, second], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.delete(first.id), at: monday(10, 1))
    #expect(engine.ringingAlarms.map(\.id) == [second.id])
}

@Test func editingARingingAlarmKeepsItRinging() {
    var alarm = Alarm(hour: 10, minute: 0, repeatDays: [.monday])
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    alarm.label = "Renamed"
    engine.handle(.update(alarm), at: monday(10, 1))
    #expect(engine.ringingAlarms.map(\.label) == ["Renamed"])
}

@Test func editingAMissedAlarmClearsItsMissedMark() {
    var alarm = Alarm(hour: 10, minute: 0, repeatDays: [.monday])
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.woke, at: monday(11))
    alarm.minute = 30
    engine.handle(.update(alarm), at: monday(11, 1))
    #expect(engine.missedAlarms.isEmpty)
}

// MARK: - Clock and time zone changes

@Test func timeZoneChangeFollowsTheNewLocalTime() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    let tokyo = calendar(TimeZone(identifier: "Asia/Tokyo")!)

    // 09:30 in Bangkok is 11:30 in Tokyo, so 10:00 local has passed today in Tokyo.
    engine.handle(.clockChanged(tokyo), at: monday(9, 30))
    let tomorrowTenInTokyo = tokyo.date(
        from: DateComponents(year: 2026, month: 9, day: 29, hour: 10, minute: 0))!
    #expect(engine.nextDeadline == tomorrowTenInTokyo)
    #expect(engine.missedAlarms.isEmpty)
}

@Test func clockSetPastAnAlarmMarksItMissed() {
    let alarm = Alarm(hour: 10, minute: 0)
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.clockChanged(calendar()), at: monday(10, 30))
    #expect(engine.ringingAlarms.isEmpty)
    #expect(engine.missedAlarms.map(\.id) == [alarm.id])
}

@Test func switchingOffARingingAlarmStopsIt() {
    let first = Alarm(hour: 10, minute: 0, repeatDays: [.monday])
    let second = Alarm(hour: 10, minute: 0, repeatDays: [.monday])
    var engine = engine(with: [first, second], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.setEnabled(first.id, false), at: monday(10, 1))
    #expect(engine.ringingAlarms.map(\.id) == [second.id])
    engine.handle(.setEnabled(second.id, false), at: monday(10, 1))
    #expect(!engine.isRinging)
}

@Test func switchingOffASnoozedAlarmCancelsItsSnooze() {
    let alarm = Alarm(hour: 10, minute: 0, repeatDays: [.monday])
    var engine = engine(with: [alarm], at: monday(9))
    engine.handle(.deadlineReached, at: monday(10))
    engine.handle(.snooze, at: monday(10))
    engine.handle(.setEnabled(alarm.id, false), at: monday(10, 1))
    engine.handle(.deadlineReached, at: monday(10, 5))
    #expect(!engine.isRinging)
    #expect(engine.nextDeadline == nil)
}
