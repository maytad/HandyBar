import AppKit
import HandyBarUI

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var alarmController: AlarmController?
    private var autoClickController: AutoClickController?
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
        let autoClick = AutoClickController()
        let settings = SettingsWindowController(
            features: features, openAtLogin: openAtLogin, soundPreview: alarms.model.soundPreview)

        alarmController = alarms
        autoClickController = autoClick
        settingsController = settings
        statusItemController = StatusItemController(
            alarms: alarms, autoClick: autoClick, features: features, openAtLogin: openAtLogin,
            settings: settings)
    }
}
