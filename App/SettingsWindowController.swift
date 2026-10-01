import AppKit
import HandyBarUI
import SwiftUI

/// Shows the Settings window, created on demand and released when closed.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let features: FeaturePreferences
    private let openAtLogin: OpenAtLoginModel
    private var window: NSWindow?

    init(features: FeaturePreferences, openAtLogin: OpenAtLoginModel) {
        self.features = features
        self.openAtLogin = openAtLogin
    }

    func show() {
        if window == nil {
            let hosting = NSHostingController(
                rootView: SettingsView(features: features, openAtLogin: openAtLogin))
            let window = NSWindow(contentViewController: hosting)
            window.title = "HandyBar Settings"
            window.styleMask = [.titled, .closable, .resizable, .fullSizeContentView]
            window.toolbarStyle = .unified
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 680, height: 420))
            window.center()
            window.delegate = self
            self.window = window
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        window?.contentViewController = nil
        window = nil
    }
}
