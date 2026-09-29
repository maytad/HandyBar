import AVFoundation

/// HandyBar's built-in Alarm sound: a two-beep pattern synthesized at runtime and looped.
@MainActor
final class AlarmSound {
    private let player: AVAudioPlayer?

    init() {
        player = try? AVAudioPlayer(data: Self.pattern())
        player?.numberOfLoops = -1
        player?.prepareToPlay()
    }

    func play() {
        player?.play()
    }

    func stop() {
        player?.stop()
    }

    /// One second of 16-bit mono PCM: beep, gap, beep, rest.
    private static func pattern() -> Data {
        let sampleRate = 44_100
        let segments: [(frequency: Double, seconds: Double)] = [
            (880, 0.15), (0, 0.08), (880, 0.15), (0, 0.62),
        ]
        var samples: [Int16] = []
        for segment in segments {
            let count = Int(Double(sampleRate) * segment.seconds)
            let fade = min(count / 2, sampleRate / 200)
            for index in 0..<count {
                guard segment.frequency > 0 else {
                    samples.append(0)
                    continue
                }
                let envelope = Double(min(index, count - 1 - index, fade)) / Double(max(fade, 1))
                let value = sin(2 * .pi * segment.frequency * Double(index) / Double(sampleRate))
                samples.append(Int16(value * min(envelope, 1) * 0.6 * Double(Int16.max)))
            }
        }
        return wav(samples: samples, sampleRate: sampleRate)
    }

    private static func wav(samples: [Int16], sampleRate: Int) -> Data {
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
