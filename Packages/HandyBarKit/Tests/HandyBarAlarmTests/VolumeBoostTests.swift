import HandyBarAlarm
import Testing

private final class FakeOutput: OutputVolumeControl {
    var volume: OutputVolume?
    var isSettable = true
    /// Like a device whose mute can be set but whose level write fails.
    var levelIsSettable = true
    private(set) var writes: [OutputVolume] = []

    init(_ volume: OutputVolume?) { self.volume = volume }

    func currentVolume() -> OutputVolume? { volume }

    func setVolume(_ newVolume: OutputVolume) -> Bool {
        guard isSettable else { return false }
        writes.append(newVolume)
        guard levelIsSettable else {
            volume?.isMuted = newVolume.isMuted
            return false
        }
        volume = newVolume
        return true
    }
}

@MainActor @Test func mutedOutputIsUnmutedAndRaisedWhileRinging() {
    let output = FakeOutput(OutputVolume(level: 0.8, isMuted: true))
    _ = VolumeBoost.begin(on: output)
    #expect(output.volume == OutputVolume(level: 0.8, isMuted: false))
}

@MainActor @Test func quietOutputIsRaisedToHalfWhileRinging() {
    let output = FakeOutput(OutputVolume(level: 0.2, isMuted: false))
    _ = VolumeBoost.begin(on: output)
    #expect(output.volume == OutputVolume(level: 0.5, isMuted: false))
}

@MainActor @Test func mutedQuietOutputIsUnmutedAndRaised() {
    let output = FakeOutput(OutputVolume(level: 0.1, isMuted: true))
    _ = VolumeBoost.begin(on: output)
    #expect(output.volume == OutputVolume(level: 0.5, isMuted: false))
}

@MainActor @Test func loudEnoughOutputIsLeftAlone() {
    let output = FakeOutput(OutputVolume(level: 0.7, isMuted: false))
    #expect(VolumeBoost.begin(on: output) == nil)
    #expect(output.writes.isEmpty)
}

@MainActor @Test func previousVolumeIsRestoredWhenRingingEnds() {
    let output = FakeOutput(OutputVolume(level: 0.2, isMuted: true))
    let boost = VolumeBoost.begin(on: output)
    boost?.end(on: output)
    #expect(output.volume == OutputVolume(level: 0.2, isMuted: true))
}

@MainActor @Test func volumeTheUserChangedWhileRingingIsKept() {
    let output = FakeOutput(OutputVolume(level: 0.2, isMuted: false))
    let boost = VolumeBoost.begin(on: output)
    output.volume = OutputVolume(level: 0.9, isMuted: false)
    boost?.end(on: output)
    #expect(output.volume == OutputVolume(level: 0.9, isMuted: false))
}

@MainActor @Test func deviceRoundingOfTheRaisedVolumeStillRestores() {
    let output = FakeOutput(OutputVolume(level: 0.2, isMuted: false))
    let boost = VolumeBoost.begin(on: output)
    output.volume = OutputVolume(level: 0.498, isMuted: false)
    boost?.end(on: output)
    #expect(output.volume == OutputVolume(level: 0.2, isMuted: false))
}

@MainActor @Test func deviceWithoutVolumeControlIsSkipped() {
    let unreadable = FakeOutput(nil)
    #expect(VolumeBoost.begin(on: unreadable) == nil)

    let unsettable = FakeOutput(OutputVolume(level: 0.1, isMuted: false))
    unsettable.isSettable = false
    #expect(VolumeBoost.begin(on: unsettable) == nil)
    #expect(unsettable.volume == OutputVolume(level: 0.1, isMuted: false))
}

@MainActor @Test func failedRaiseLeavesTheOutputAsItWas() {
    let output = FakeOutput(OutputVolume(level: 0.1, isMuted: true))
    output.levelIsSettable = false
    #expect(VolumeBoost.begin(on: output) == nil)
    #expect(output.volume == OutputVolume(level: 0.1, isMuted: true))
}
