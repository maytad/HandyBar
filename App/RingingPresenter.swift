import AppKit
import HandyBarAlarm
import HandyBarUI
import SwiftUI

/// Shows Ringing Alarms in a window above everything and plays their sound.
@MainActor
final class RingingPresenter {
    var onStop: () -> Void = {}
    var onSnooze: () -> Void = {}

    private var panel: RingingPanel?
    private var sound: AlarmSound?
    private var volumeBoost: VolumeBoost?
    private let output = SystemOutputVolume()
    private var shownAlarms: [Alarm] = []

    func show(_ alarms: [Alarm]) {
        guard alarms != shownAlarms else { return }
        shownAlarms = alarms
        if alarms.isEmpty {
            stop()
            return
        }

        let content = RingingView(
            alarms: alarms,
            onSnooze: { [weak self] in self?.onSnooze() },
            onStop: { [weak self] in self?.onStop() }
        )
        if let panel {
            panel.setContent(content)
        } else {
            let panel = RingingPanel(content: content)
            panel.present()
            self.panel = panel
            volumeBoost = VolumeBoost.begin(on: output)
            sound = AlarmSound()
            sound?.play()
        }
    }

    private func stop() {
        sound?.stop()
        sound = nil
        volumeBoost?.end(on: output)
        volumeBoost = nil
        panel?.close()
        panel = nil
    }
}

/// A panel that floats on every Space and beside full-screen apps. It appears without
/// taking keyboard focus, and takes it only when clicked so Return and Escape work.
private final class RingingPanel: NSPanel {
    init(content: RingingView) {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            standardWindowButton(button)?.isHidden = true
        }
        setContent(content)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func setContent(_ content: RingingView) {
        let hosting = NSHostingView(rootView: content)
        contentView = hosting
        setContentSize(hosting.fittingSize)
        position()
    }

    func present() {
        position()
        orderFrontRegardless()
    }

    private func position() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        setFrameOrigin(
            NSPoint(x: visible.maxX - frame.width - 16, y: visible.maxY - frame.height - 16))
    }
}
