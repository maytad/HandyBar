import HandyBarAlarm

/// UserDefaults keys for what new Alarms start with, set in Settings > Alarm.
enum AlarmDefaults {
    static let soundKey = "defaultAlarmSound"
    static let snoozeKey = "defaultAlarmSnooze"
}

extension AlarmSnooze {
    public var title: String {
        self == .off ? "Off" : "\(minutes) min"
    }
}
