import HandyBarAlarm
import Observation

/// What the Alarm pages show, and where their edits go.
@MainActor
@Observable
public final class AlarmPanelModel {
    public var alarms: [Alarm] = []
    public var missedIDs: Set<Alarm.ID> = []

    @ObservationIgnored public var onAdd: (Alarm) -> Void = { _ in }
    @ObservationIgnored public var onUpdate: (Alarm) -> Void = { _ in }
    @ObservationIgnored public var onDelete: (Alarm.ID) -> Void = { _ in }
    @ObservationIgnored public var onSetEnabled: (Alarm.ID, Bool) -> Void = { _, _ in }

    public init() {}

    public var hasMissedAlarms: Bool { !missedIDs.isEmpty }
}
