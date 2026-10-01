import AppKit
import HandyBarUI

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var alarmController: AlarmController?
    private var settingsController: SettingsWindowController?
    private var statusItemController: StatusItemController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let features = FeaturePreferences()
        let openAtLogin = OpenAtLoginModel(service: SystemLoginItem())
        let alarms = AlarmController()
        alarms.onFirstAlarmCreated = { openAtLogin.firstAlarmCreated() }
        let settings = SettingsWindowController(features: features, openAtLogin: openAtLogin)

        alarmController = alarms
        settingsController = settings
        statusItemController = StatusItemController(
            alarms: alarms, features: features, openAtLogin: openAtLogin, settings: settings)
    }
}
