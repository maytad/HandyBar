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

@Test func unreadableFileIsReportedNotSilentlyReplaced() throws {
    let url = temporaryFile()
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: url)

    #expect(throws: (any Error).self) { try AlarmStore(fileURL: url).load() }
}
