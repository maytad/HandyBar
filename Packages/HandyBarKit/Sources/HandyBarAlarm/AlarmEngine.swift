import Foundation

public enum AlarmEvent: Sendable {
    case launched
    case deadlineReached
    case woke
    /// The system clock or time zone changed; carries the calendar for the new local time.
    case clockChanged(Calendar)
    case stop
    case snooze
    case missedAlarmsSeen
    case add(Alarm)
    case update(Alarm)
    case delete(Alarm.ID)
    case setEnabled(Alarm.ID, Bool)
}

/// Decides when Alarms ring, stop, and become Missed Alarms.
///
/// It performs no I/O and owns no timers: the caller arms one wall-clock timer for
/// `nextDeadline` and reports events with the current time.
public struct AlarmEngine: Sendable {
    public static let snoozeInterval: TimeInterval = 5 * 60
    public static let ringingLimit: TimeInterval = 15 * 60
    /// How late a deadline may be handled and still ring; later means the Mac slept through it.
    public static let lateTolerance: TimeInterval = 30

    public struct PendingSnooze: Codable, Equatable, Sendable {
        public var alarmIDs: [Alarm.ID]
        public var ringsAt: Date
    }

    /// The state that must survive a relaunch.
    public struct Snapshot: Codable, Equatable, Sendable {
        public var alarms: [Alarm]
        public var missedIDs: Set<Alarm.ID>
        public var snooze: PendingSnooze?

        public init(
            alarms: [Alarm] = [], missedIDs: Set<Alarm.ID> = [], snooze: PendingSnooze? = nil
        ) {
            self.alarms = alarms
            self.missedIDs = missedIDs
            self.snooze = snooze
        }
    }

    public private(set) var alarms: [Alarm]
    private var missedIDs: Set<Alarm.ID>
    private var snooze: PendingSnooze?
    private var ringingIDs: [Alarm.ID] = []
    private var ringingEndsAt: Date?
    private var calendar: Calendar

    public init(snapshot: Snapshot = Snapshot(), calendar: Calendar) {
        self.alarms = snapshot.alarms
        self.missedIDs = snapshot.missedIDs
        self.snooze = snapshot.snooze
        self.calendar = calendar
        sortAlarms()
    }

    public var snapshot: Snapshot {
        Snapshot(alarms: alarms, missedIDs: missedIDs, snooze: snooze)
    }

    public var ringingAlarms: [Alarm] {
        ringingIDs.compactMap { id in alarms.first { $0.id == id } }
    }

    public var missedAlarms: [Alarm] {
        alarms.filter { missedIDs.contains($0.id) }
    }

    public var isRinging: Bool { !ringingIDs.isEmpty }

    /// The earliest moment at which `deadlineReached` must be reported.
    public var nextDeadline: Date? {
        let occurrences = alarms.lazy.filter(\.isEnabled).compactMap(\.nextOccurrence)
        return ([ringingEndsAt, snooze?.ringsAt].compactMap { $0 } + occurrences).min()
    }

    public mutating func handle(_ event: AlarmEvent, at now: Date) {
        switch event {
        case .deadlineReached:
            evaluate(at: now, mayRing: true)
        case .launched, .woke:
            evaluate(at: now, mayRing: false)
        case .clockChanged(let newCalendar):
            evaluate(at: now, mayRing: false)
            calendar = newCalendar
            for index in alarms.indices where alarms[index].isEnabled {
                alarms[index].nextOccurrence = nextOccurrence(of: alarms[index], after: now)
            }
        case .stop:
            endRinging()
        case .snooze:
            guard isRinging else { return }
            let pending = snooze?.alarmIDs ?? []
            snooze = PendingSnooze(
                alarmIDs: pending + ringingIDs.filter { !pending.contains($0) },
                ringsAt: now.addingTimeInterval(Self.snoozeInterval))
            endRinging()
        case .missedAlarmsSeen:
            missedIDs.removeAll()
        case .add(let alarm):
            alarms.append(scheduled(alarm, after: now))
            sortAlarms()
        case .update(let alarm):
            guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
            alarms[index] = scheduled(alarm, after: now)
            missedIDs.remove(alarm.id)
            sortAlarms()
        case .delete(let id):
            alarms.removeAll { $0.id == id }
            missedIDs.remove(id)
            silence(id)
        case .setEnabled(let id, let isEnabled):
            guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
            var alarm = alarms[index]
            alarm.isEnabled = isEnabled
            alarms[index] = scheduled(alarm, after: now)
            if !isEnabled { silence(id) }
        }
    }

    /// Stops an Alarm ringing now or after a snooze, leaving any others ringing.
    private mutating func silence(_ id: Alarm.ID) {
        removeFromSnooze(id)
        let wasRinging = isRinging
        ringingIDs.removeAll { $0 == id }
        if wasRinging, ringingIDs.isEmpty { endRinging() }
    }

    private mutating func evaluate(at now: Date, mayRing: Bool) {
        if let endsAt = ringingEndsAt, now >= endsAt {
            missedIDs.formUnion(ringingIDs)
            endRinging()
        }

        if let pending = snooze, pending.ringsAt <= now {
            snooze = nil
            let ids = pending.alarmIDs.filter { id in alarms.contains { $0.id == id } }
            resolve(ids, dueAt: pending.ringsAt, now: now, mayRing: mayRing)
        }

        for index in alarms.indices {
            let alarm = alarms[index]
            guard alarm.isEnabled, let occurrence = alarm.nextOccurrence, occurrence <= now else {
                continue
            }
            resolve([alarm.id], dueAt: occurrence, now: now, mayRing: mayRing)
            if alarm.repeats {
                alarms[index].nextOccurrence = nextOccurrence(of: alarm, after: now)
            } else {
                alarms[index].isEnabled = false
                alarms[index].nextOccurrence = nil
            }
        }
    }

    private mutating func resolve(_ ids: [Alarm.ID], dueAt: Date, now: Date, mayRing: Bool) {
        guard !ids.isEmpty else { return }
        if mayRing, now.timeIntervalSince(dueAt) <= Self.lateTolerance {
            ringingIDs += ids.filter { !ringingIDs.contains($0) }
            ringingEndsAt = now.addingTimeInterval(Self.ringingLimit)
        } else {
            missedIDs.formUnion(ids)
        }
    }

    private mutating func endRinging() {
        ringingIDs.removeAll()
        ringingEndsAt = nil
    }

    private mutating func removeFromSnooze(_ id: Alarm.ID) {
        snooze?.alarmIDs.removeAll { $0 == id }
        if snooze?.alarmIDs.isEmpty == true { snooze = nil }
    }

    private mutating func sortAlarms() {
        alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    private func scheduled(_ alarm: Alarm, after now: Date) -> Alarm {
        var alarm = alarm
        alarm.nextOccurrence = alarm.isEnabled ? nextOccurrence(of: alarm, after: now) : nil
        return alarm
    }

    private func nextOccurrence(of alarm: Alarm, after date: Date) -> Date? {
        let days: [Int?] = alarm.repeats ? alarm.repeatDays.map(\.rawValue) : [nil]
        return days.compactMap { weekday in
            calendar.nextDate(
                after: date,
                matching: DateComponents(
                    hour: alarm.hour, minute: alarm.minute, second: 0, weekday: weekday),
                matchingPolicy: .nextTime
            )
        }.min()
    }
}
