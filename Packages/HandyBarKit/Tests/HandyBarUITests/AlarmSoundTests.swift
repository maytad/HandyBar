import AVFoundation
import HandyBarAlarm
import HandyBarUI
import Testing

private func samples(_ sound: AlarmSound) -> [Int16] {
    sound.wavData.dropFirst(44).withUnsafeBytes { Array($0.bindMemory(to: Int16.self)) }
}

@Test(arguments: AlarmSound.allCases)
func soundIsAPlayableLoop(sound: AlarmSound) throws {
    let player = try AVAudioPlayer(data: sound.wavData)
    #expect((0.5...3).contains(player.duration))
}

@Test(arguments: AlarmSound.allCases)
func soundIsAudibleWithoutClipping(sound: AlarmSound) {
    let peak = samples(sound).map { abs(Int($0)) }.max() ?? 0
    #expect(peak > Int(Int16.max) / 4)
    #expect(peak < Int(Int16.max))
}

@Test(arguments: AlarmSound.allCases)
func soundStartsAndEndsSilentSoItLoopsWithoutAClick(sound: AlarmSound) {
    let samples = samples(sound)
    #expect(abs(Int(samples.first ?? 1)) < 50)
    #expect(abs(Int(samples.last ?? 1)) < 50)
}

@Test func everySoundIsDifferent() {
    let all = AlarmSound.allCases.map(samples)
    #expect(Set(all.map { $0.hashValue }).count == all.count)
    #expect(Set(AlarmSound.allCases.map(\.title)).count == AlarmSound.allCases.count)
}
