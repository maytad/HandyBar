import AppKit
import HandyBarUI
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private var toggle = PanelToggle()

    override init() {
        super.init()
        popover.behavior = .transient
        popover.delegate = self

        if let button = statusItem.button {
            let image = NSImage(named: "MenuBarIcon")
            image?.isTemplate = true
            image?.size = NSSize(width: 18, height: 18)
            image?.accessibilityDescription = "HandyBar"
            button.image = image
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        perform(toggle.click())
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
            rootView: PanelView(onQuit: { NSApp.terminate(nil) })
        )
        hostingController.sizingOptions = .preferredContentSize
        popover.contentViewController = hostingController
        popover.animates = true
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate()
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
        perform(toggle.didClose())
    }
}
