import HandyBarAlarm
import Observation

/// What the Alarm card shows, and where its edits go.
@MainActor
@Observable
public final class AlarmPanelModel {
    public var alarms: [Alarm] = []
    public var missedIDs: Set<Alarm.ID> = []
    public var ringingIDs: [Alarm.ID] = []

    @ObservationIgnored public var onAdd: (Alarm) -> Void = { _ in }
    @ObservationIgnored public var onUpdate: (Alarm) -> Void = { _ in }
    @ObservationIgnored public var onDelete: (Alarm.ID) -> Void = { _ in }
    @ObservationIgnored public var onSetEnabled: (Alarm.ID, Bool) -> Void = { _, _ in }
    @ObservationIgnored public var onStop: () -> Void = {}
    @ObservationIgnored public var onSnooze: () -> Void = {}

    public init() {}

    public var hasMissedAlarms: Bool { !missedIDs.isEmpty }

    public var ringingAlarms: [Alarm] {
        ringingIDs.compactMap { id in alarms.first { $0.id == id } }
    }

    /// An edit not saved yet, such as a time still being adjusted.
    @ObservationIgnored var pendingEdit: (() -> Void)?

    /// Saves an edit still waiting, for example because the panel is closing.
    public func savePendingEdit() {
        let edit = pendingEdit
        pendingEdit = nil
        edit?()
    }

    /// Applies `transform` to the current version of an Alarm and saves it.
    func edit(_ id: Alarm.ID, _ transform: (inout Alarm) -> Void) {
        guard var alarm = alarms.first(where: { $0.id == id }) else { return }
        transform(&alarm)
        onUpdate(alarm)
    }
}
