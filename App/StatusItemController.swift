import AppKit
import HandyBarUI
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private var toggle = PanelToggle()
    private let alarms: AlarmController

    init(alarms: AlarmController) {
        self.alarms = alarms
        super.init()
        popover.behavior = .transient
        popover.delegate = self

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        setIcon(showsMissedDot: !alarms.model.missedIDs.isEmpty)
        alarms.onMissedChange = { [weak self] in self?.setIcon(showsMissedDot: $0) }
    }

    private func setIcon(showsMissedDot: Bool) {
        guard let base = NSImage(named: "MenuBarIcon") else { return }
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            base.draw(in: rect)
            if showsMissedDot {
                NSBezierPath(
                    ovalIn: NSRect(x: rect.maxX - 6, y: rect.maxY - 6, width: 6, height: 6)
                ).fill()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = showsMissedDot ? "HandyBar, Missed Alarm" : "HandyBar"
        statusItem.button?.image = image
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            perform(toggle.click())
        }
    }

    private func showMenu() {
        if popover.isShown { popover.performClose(nil) }
        let menu = NSMenu()
        menu.addItem(withTitle: "About HandyBar", action: #selector(showAbout), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit HandyBar", action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    private func perform(_ command: PanelToggle.Command) {
        switch command {
        case .show: showPopover()
        case .close: popover.performClose(nil)
        case .none: break
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        let hostingController = NSHostingController(
            rootView: PanelView(alarms: alarms.model, onQuit: { NSApp.terminate(nil) })
        )
        hostingController.sizingOptions = .preferredContentSize
        popover.contentViewController = hostingController
        popover.animates = true
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate()
        popover.contentViewController?.view.window?.makeKey()
    }

    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        // Close instantly, like a menu: the close animation outlasts rapid clicks
        // on the menu bar item, which would otherwise land on a closing panel.
        popover.animates = false
        return true
    }

    func popoverWillClose(_ notification: Notification) {
        toggle.willClose()
    }

    func popoverDidClose(_ notification: Notification) {
        // Release the SwiftUI hierarchy so a closed panel holds no view state.
        popover.contentViewController = nil
        alarms.panelClosed()
        perform(toggle.didClose())
    }
}
