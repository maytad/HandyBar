import AppKit
import Carbon
import CoreGraphics
import HandyBarAutoClick
import HandyBarUI
import os

/// Connects the Auto Click engine to the system: posts clicks, monitors events, and checks permissions.
@MainActor
final class AutoClickController {
    let model = AutoClickPanelModel()

    private var engine: AutoClickEngine
    private var timer: DispatchSourceTimer?
    private var activity: NSObjectProtocol?
    private var globalMouseMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var sleepObserver: Any?
    private var sessionObserver: Any?
    private var baselineMouseLocation: CGPoint?
    private var hotKeyID: EventHotKeyID?
    nonisolated(unsafe) private var hotKeyRef: EventHotKeyRef?
    private let log = Logger(subsystem: "io.github.maytad.HandyBar", category: "autoclick")

    init() {
        self.engine = AutoClickEngine(settings: AutoClickSettings())
        model.hasPermission = hasPostEventAccess()

        model.onStart = { [weak self] in
            guard let self else { return }
            let settings = AutoClickSettings(
                intervalMilliseconds: model.intervalMilliseconds,
                clickLimit: model.clickLimit
            )
            engine = AutoClickEngine(settings: settings)
            start()
        }
        model.onStop = { [weak self] in self?.stop() }
        model.onRequestPermission = { [weak self] in self?.requestPermissionIfNeeded() }

        registerHotKey()
    }

    deinit {
        unregisterHotKey()
    }

    func panelOpened() {
        model.hasPermission = hasPostEventAccess()
        updateModel()
    }

    func panelClosed() {
        // Keep running if active
    }

    private func updateModel() {
        model.isRunning = engine.isRunning
        model.clicksDone = engine.clicksDone
    }

    // MARK: - Hot Key (⌥⌘C)

    private func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x48424143) // "HBAC"
        hotKeyID.id = 1
        self.hotKeyID = hotKeyID

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        let handler: EventHandlerUPP = { _, event, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let controller = Unmanaged<AutoClickController>.fromOpaque(userData).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            if status == noErr {
                Task { @MainActor in
                    controller.toggleAutoClick()
                }
            }

            return noErr
        }

        var eventHandler: EventHandlerRef?
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_C),  // C key
            UInt32(optionKey | cmdKey),  // ⌥⌘
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr {
            hotKeyRef = ref
            log.info("Hot key ⌥⌘C registered")
        } else {
            log.warning("Failed to register hot key: \(status)")
        }
    }

    private nonisolated func unregisterHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
    }

    private func toggleAutoClick() {
        if engine.isRunning {
            stop()
            NSSound.beep()
            log.info("Auto Click stopped via hot key")
        } else if model.hasPermission {
            model.onStart?()
            NSSound.beep()
            log.info("Auto Click started via hot key")
        } else {
            NSSound.beep()
            log.warning("Auto Click hot key pressed but no permission")
        }
    }

    // MARK: - Permissions

    private func hasPostEventAccess() -> Bool {
        CGPreflightPostEventAccess()
    }

    func start() {
        guard hasPostEventAccess() else {
            log.warning("Cannot start: no Accessibility permission")
            return
        }

        let poster = CGClickPoster()
        engine.handle(.start(Date()), poster: poster)
        updateModel()

        // Hold activity to opt out of App Nap
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiated,
            reason: "Auto Click is running"
        )

        // Capture baseline mouse position for move detection
        baselineMouseLocation = NSEvent.mouseLocation

        armTimer()
        startMonitors()
        log.info("Auto Click started")
    }

    func stop() {
        let poster = CGClickPoster()
        engine.handle(.stop, poster: poster)
        updateModel()
        tearDown()
        log.info("Auto Click stopped: \(String(describing: self.engine.stopReason))")
    }

    func requestPermissionIfNeeded() {
        guard !hasPostEventAccess() else { return }
        // Open System Settings > Privacy & Security > Accessibility
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    private func armTimer() {
        guard let nextTick = engine.nextTickAt else { return }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        let deadline = nextTick.timeIntervalSinceNow
        timer.schedule(deadline: .now() + max(0, deadline))
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        timer.resume()
        self.timer = timer
    }

    private func tick() {
        guard hasPostEventAccess() else {
            handlePermissionLost()
            return
        }

        let poster = CGClickPoster()
        engine.handle(.tick(Date()), poster: poster)
        updateModel()

        if engine.isRunning {
            armTimer()
        } else {
            tearDown()
            log.info("Auto Click stopped: \(String(describing: self.engine.stopReason))")
        }
    }

    private func startMonitors() {
        // Monitor mouse moves globally
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) {
            [weak self] event in
            self?.checkMouseMove(event)
        }

        // Monitor Esc key globally
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) {
            [weak self] event in
            if event.keyCode == 53 { // Esc
                self?.stop()
            }
        }

        // Monitor Esc key locally (in HandyBar's own windows)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) {
            [weak self] event in
            if event.keyCode == 53 { // Esc
                self?.stop()
                return nil
            }
            return event
        }

        // Monitor sleep and screen lock
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stop()
            }
        }

        sessionObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stop()
            }
        }
    }

    private func checkMouseMove(_ event: NSEvent) {
        guard let baseline = baselineMouseLocation else { return }

        // Ignore events posted by HandyBar
        guard let cgEvent = event.cgEvent else { return }
        if cgEvent.getIntegerValueField(.eventSourceUserData) != 0 { return }

        let current = NSEvent.mouseLocation
        let dx = abs(current.x - baseline.x)
        let dy = abs(current.y - baseline.y)
        let threshold: CGFloat = 20.0

        if dx > threshold || dy > threshold {
            let poster = CGClickPoster()
            engine.handle(.userMovedMouse, poster: poster)
            tearDown()
            log.info("Auto Click stopped: mouse moved")
        }
    }

    private func handlePermissionLost() {
        let poster = CGClickPoster()
        engine.handle(.postAccessLost, poster: poster)
        tearDown()
        log.warning("Auto Click stopped: Accessibility permission lost")
    }

    private func tearDown() {
        timer?.cancel()
        timer = nil

        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }

        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }

        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }

        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }

        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            sleepObserver = nil
        }

        if let observer = sessionObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            sessionObserver = nil
        }

        baselineMouseLocation = nil
    }
}

/// Real click poster using CoreGraphics events.
private struct CGClickPoster: ClickPoster {
    private static let userDataTag: Int64 = 0x48425F4143 // "HB_AC" in hex

    func post(_ click: Click) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        // Read current cursor position
        let location = NSEvent.mouseLocation
        let screenHeight = NSScreen.screens.first?.frame.height ?? 0
        let cgPoint = CGPoint(x: location.x, y: screenHeight - location.y)

        // Create and post mouse down event
        guard let down = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: cgPoint,
            mouseButton: .left
        ) else { return }

        down.setIntegerValueField(.eventSourceUserData, value: Self.userDataTag)
        down.post(tap: .cghidEventTap)

        // Create and post mouse up event
        guard let up = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: cgPoint,
            mouseButton: .left
        ) else { return }

        up.setIntegerValueField(.eventSourceUserData, value: Self.userDataTag)
        up.post(tap: .cghidEventTap)
    }
}
