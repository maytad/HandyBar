import AVFoundation
import HandyBarAlarm
import Observation

extension AlarmSound {
    public var title: String {
        switch self {
        case .beeps: "Beeps"
        case .chime: "Chime"
        case .rising: "Rising"
        case .rapid: "Rapid"
        case .soft: "Soft"
        }
    }

    /// One loop of the sound as a 16-bit mono WAV file, synthesized so no audio files ship.
    public var wavData: Data { AlarmSoundWave.wav(AlarmSoundWave.samples(self)) }
}

/// Plays an Alarm sound, looping until stopped or for a set number of times.
@MainActor
public final class AlarmSoundPlayer {
    private var player: AVAudioPlayer?

    public init() {}

    /// Plays `sound` `times` times in a row; `nil` loops until `stop()`.
    public func play(_ sound: AlarmSound, times: Int? = nil) {
        stop()
        player = try? AVAudioPlayer(data: sound.wavData)
        player?.numberOfLoops = times.map { max($0 - 1, 0) } ?? -1
        player?.play()
    }

    public func stop() {
        player?.stop()
        player = nil
    }
}

/// Plays a short sample of a sound when the user picks one, so they can hear it.
@MainActor
@Observable
public final class AlarmSoundPreview {
    public private(set) var playing: AlarmSound?

    @ObservationIgnored private let player = AlarmSoundPlayer()
    @ObservationIgnored private var finish: Task<Void, Never>?

    public init() {}

    public func play(_ sound: AlarmSound) {
        let times = 2
        player.play(sound, times: times)
        playing = sound
        finish?.cancel()
        finish = Task { [weak self] in
            try? await Task.sleep(for: .seconds(AlarmSoundWave.length(sound) * Double(times)))
            if !Task.isCancelled { self?.playing = nil }
        }
    }

    public func toggle(_ sound: AlarmSound) {
        if playing == sound { stop() } else { play(sound) }
    }

    public func stop() {
        finish?.cancel()
        player.stop()
        playing = nil
    }
}

enum AlarmSoundWave {
    static let sampleRate = 44_100

    struct Note {
        var start: Double
        var length: Double
        var frequency: Double
        var gain = 0.6
        var attack = 0.005
        var release = 0.005
        /// Seconds for the note to fade to about a third, like a struck bell; `nil` holds.
        var decay: Double?
    }

    /// The seconds in one loop, including the rest before it repeats.
    static func length(_ sound: AlarmSound) -> Double {
        switch sound {
        case .beeps: 1.0
        case .chime: 2.0
        case .rising: 1.3
        case .rapid: 0.9
        case .soft: 2.6
        }
    }

    static func notes(_ sound: AlarmSound) -> [Note] {
        switch sound {
        case .beeps:
            [
                Note(start: 0, length: 0.15, frequency: 880),
                Note(start: 0.23, length: 0.15, frequency: 880),
            ]
        case .chime:
            [
                Note(
                    start: 0, length: 0.9, frequency: 1318.5, gain: 0.5, release: 0.1, decay: 0.35),
                Note(
                    start: 0.45, length: 1.3, frequency: 1046.5, gain: 0.5, release: 0.2,
                    decay: 0.45),
            ]
        case .rising:
            [523.25, 659.25, 783.99, 1046.5].enumerated().map { index, frequency in
                Note(start: Double(index) * 0.16, length: 0.14, frequency: frequency, gain: 0.5)
            }
        case .rapid:
            (0..<4).map { Note(start: Double($0) * 0.12, length: 0.07, frequency: 1200) }
        case .soft:
            [
                Note(
                    start: 0, length: 1.0, frequency: 523.25, gain: 0.35, attack: 0.3,
                    release: 0.4),
                Note(
                    start: 1.1, length: 1.0, frequency: 659.25, gain: 0.35, attack: 0.3,
                    release: 0.4),
            ]
        }
    }

    /// Bell-like overtones for the chime; the others are pure tones.
    static func partials(_ sound: AlarmSound) -> [(multiple: Double, gain: Double)] {
        sound == .chime ? [(1, 1), (2, 0.35), (3, 0.12)] : [(1, 1)]
    }

    static func samples(_ sound: AlarmSound) -> [Int16] {
        let rate = Double(sampleRate)
        var mix = [Double](repeating: 0, count: Int(length(sound) * rate))
        let partials = partials(sound)
        let partialsGain = partials.reduce(0) { $0 + $1.gain }
        for note in notes(sound) {
            let first = Int(note.start * rate)
            let count = min(Int(note.length * rate), mix.count - first)
            for index in 0..<max(count, 0) {
                let time = Double(index) / rate
                var envelope = note.gain
                envelope *= min(1, time / note.attack, (note.length - time) / note.release)
                if let decay = note.decay { envelope *= exp(-time / decay) }
                let wave = partials.reduce(0) { sum, partial in
                    sum + partial.gain * sin(2 * .pi * note.frequency * partial.multiple * time)
                }
                mix[first + index] += max(envelope, 0) * wave / partialsGain
            }
        }
        return mix.map { Int16(max(-1, min(1, $0)) * Double(Int16.max)) }
    }

    static func wav(_ samples: [Int16]) -> Data {
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let dataSize = samples.count * 2
        data.append(contentsOf: Array("RIFF".utf8))
        append(UInt32(36 + dataSize))
        data.append(contentsOf: Array("WAVEfmt ".utf8))
        append(UInt32(16))
        append(UInt16(1))
        append(UInt16(1))
        append(UInt32(sampleRate))
        append(UInt32(sampleRate * 2))
        append(UInt16(2))
        append(UInt16(16))
        data.append(contentsOf: Array("data".utf8))
        append(UInt32(dataSize))
        for sample in samples { append(sample) }
        return data
    }
}
