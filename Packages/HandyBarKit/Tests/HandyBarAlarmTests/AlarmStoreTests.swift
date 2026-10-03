import Foundation
import HandyBarAlarm
import Testing

private func temporaryFile() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("alarms.json")
}

@Test func missingFileLoadsNoAlarms() throws {
    let store = AlarmStore(fileURL: temporaryFile())
    #expect(try store.load() == AlarmEngine.Snapshot())
}

@Test func savedAlarmsLoadBack() throws {
    let store = AlarmStore(fileURL: temporaryFile())
    let alarm = Alarm(hour: 10, minute: 0, label: "Standup", repeatDays: [.monday, .friday])
    let snapshot = AlarmEngine.Snapshot(alarms: [alarm], missedIDs: [alarm.id])

    try store.save(snapshot)
    #expect(try store.load() == snapshot)
}

@Test func alarmSoundAndSnoozeAreSavedAndLoadedBack() throws {
    let store = AlarmStore(fileURL: temporaryFile())
    let alarm = Alarm(hour: 6, minute: 30, sound: .chime, snooze: .off)
    try store.save(AlarmEngine.Snapshot(alarms: [alarm]))
    #expect(try store.load().alarms.map(\.sound) == [.chime])
    #expect(try store.load().alarms.map(\.snooze) == [.off])
}

@Test(arguments: [
    #"{"id":"6B1F2C1E-3D2A-4E5F-8A9B-0C1D2E3F4A5B","hour":7,"minute":0,"label":"","repeatDays":[],"isEnabled":true}"#,
    #"{"id":"6B1F2C1E-3D2A-4E5F-8A9B-0C1D2E3F4A5B","hour":7,"minute":0,"label":"","repeatDays":[],"isEnabled":true,"sound":"future-sound","snooze":7}"#,
])
func alarmWithoutAKnownSoundOrSnoozeUsesTheDefaults(json: String) throws {
    let alarm = try JSONDecoder().decode(Alarm.self, from: Data(json.utf8))
    #expect(alarm.sound == .beeps)
    #expect(alarm.snooze == .fiveMinutes)
    #expect(alarm.hour == 7)
}

@Test func unreadableFileIsReportedNotSilentlyReplaced() throws {
    let url = temporaryFile()
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: url)

    #expect(throws: (any Error).self) { try AlarmStore(fileURL: url).load() }
}
