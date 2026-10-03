import AppKit
import HandyBarAlarm
import HandyBarUI
import os

/// Connects the Alarm engine to time, the system, storage, and the ringing window.
@MainActor
final class AlarmController {
    let model = AlarmPanelModel()
    /// Called when the first Alarm is created; used to suggest Open at login.
    var onFirstAlarmCreated: (() -> Void)?
    /// Called when the menu bar's Missed Alarm dot should appear or disappear.
    var onMissedDotChange: ((Bool) -> Void)?
    /// The dot shows Missed Alarms the user hasn't opened the panel to see.
    private(set) var showsMissedDot = false

    private var engine: AlarmEngine
    private let store: AlarmStore
    private let ringing = RingingPresenter()
    private var timer: DispatchSourceTimer?
    private var armedDeadline: Date?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    /// False when an unreadable Alarms file couldn't be set aside, so it isn't overwritten.
    private var canSave = true
    private var isPanelOpen = false
    private let log = Logger(subsystem: "io.github.maytad.HandyBar", category: "alarm")

    init(store: AlarmStore = .standard) {
        self.store = store
        var snapshot = AlarmEngine.Snapshot()
        do {
            snapshot = try store.load()
        } catch {
            log.error("Could not read Alarms: \(error.localizedDescription, privacy: .public)")
            canSave = Self.setAside(store.fileURL, log: log)
        }
        engine = AlarmEngine(snapshot: snapshot, calendar: .current)

        model.onAdd = { [weak self] alarm in
            guard let self else { return }
            let isFirst = engine.alarms.isEmpty
            handle(.add(alarm))
            if isFirst { onFirstAlarmCreated?() }
        }
        model.onUpdate = { [weak self] in self?.handle(.update($0)) }
        model.onDelete = { [weak self] in self?.handle(.delete($0)) }
        model.onSetEnabled = { [weak self] in self?.handle(.setEnabled($0, $1)) }
        model.onStop = { [weak self] in self?.handle(.stop) }
        model.onSnooze = { [weak self] in self?.handle(.snooze) }
        ringing.onStop = { [weak self] in self?.handle(.stop) }
        ringing.onSnooze = { [weak self] in self?.handle(.snooze) }

        observe(NSWorkspace.shared.notificationCenter, NSWorkspace.didWakeNotification) { .woke }
        observe(.default, .NSSystemClockDidChange) { .clockChanged(.current) }
        observe(.default, .NSSystemTimeZoneDidChange) {
            NSTimeZone.resetSystemTimeZone()
            return .clockChanged(.current)
        }

        handle(.launched)
    }

    /// Opening the panel shows Missed Alarms, so the menu bar dot goes away.
    func panelOpened() {
        isPanelOpen = true
        updateMissedDot()
    }

    /// The user has seen the panel, so Missed Alarm marks on rows can be cleared.
    func panelClosed() {
        isPanelOpen = false
        model.savePendingEdit()
        model.soundPreview.stop()
        if !engine.missedAlarms.isEmpty { handle(.missedAlarmsSeen) }
        updateMissedDot()
    }

    private func updateMissedDot() {
        let shows = !isPanelOpen && !engine.missedAlarms.isEmpty
        guard shows != showsMissedDot else { return }
        showsMissedDot = shows
        onMissedDotChange?(shows)
    }

    private func handle(_ event: AlarmEvent) {
        let before = engine.snapshot
        engine.handle(event, at: Date())

        if engine.snapshot != before { save() }
        model.alarms = engine.alarms
        model.missedIDs = Set(engine.missedAlarms.map(\.id))
        model.ringingIDs = engine.ringingAlarms.map(\.id)
        model.soundPreview.isBlocked = engine.isRinging
        ringing.show(engine.ringingAlarms)
        armTimer()
        updateMissedDot()
    }

    private func armTimer() {
        let deadline = engine.nextDeadline
        guard deadline != armedDeadline else { return }
        timer?.cancel()
        timer = nil
        armedDeadline = deadline
        guard let deadline else { return }

        let seconds = deadline.timeIntervalSince1970
        let wall = DispatchWallTime(
            timespec: timespec(
                tv_sec: Int(seconds.rounded(.down)),
                tv_nsec: Int((seconds - seconds.rounded(.down)) * 1_000_000_000)))
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(wallDeadline: wall, leeway: .milliseconds(100))
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                self?.armedDeadline = nil
                self?.handle(.deadlineReached)
            }
        }
        source.resume()
        timer = source
    }

    private func save() {
        guard canSave else { return }
        do {
            try store.save(engine.snapshot)
        } catch {
            log.error("Could not save Alarms: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        event: @escaping @MainActor () -> AlarmEvent
    ) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.handle(event()) }
        }
        observers.append((center, token))
    }

    /// Keeps an unreadable Alarms file instead of overwriting it; false if it stayed in place.
    private static func setAside(_ url: URL, log: Logger) -> Bool {
        let backup = url.deletingPathExtension()
            .appendingPathExtension("unreadable-\(Int(Date().timeIntervalSince1970)).json")
        do {
            try FileManager.default.moveItem(at: url, to: backup)
            return true
        } catch {
            log.error(
                "Could not set aside Alarms: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
