public struct OutputVolume: Equatable, Sendable {
    public var level: Float
    public var isMuted: Bool

    public init(level: Float, isMuted: Bool) {
        self.level = level
        self.isMuted = isMuted
    }
}

/// The default output device's volume, as the Alarm volume policy sees it.
@MainActor
public protocol OutputVolumeControl: AnyObject {
    /// Returns nil when the device's volume cannot be read.
    func currentVolume() -> OutputVolume?
    /// Returns false when the device's volume cannot be set.
    func setVolume(_ volume: OutputVolume) -> Bool
}

/// Makes a Ringing Alarm audible, then puts the user's volume back.
@MainActor
public struct VolumeBoost: Equatable {
    public static let minimumLevel: Float = 0.5
    private static let matchTolerance: Float = 0.01

    private let original: OutputVolume
    private let applied: OutputVolume

    /// Unmutes and raises the output to `minimumLevel` if needed; nil when nothing changed.
    public static func begin(on output: OutputVolumeControl) -> VolumeBoost? {
        guard let original = output.currentVolume() else { return nil }
        let applied = OutputVolume(level: max(original.level, minimumLevel), isMuted: false)
        guard applied != original else { return nil }
        guard output.setVolume(applied) else {
            // A device can take the unmute and then refuse the level.
            _ = output.setVolume(original)
            return nil
        }
        return VolumeBoost(original: original, applied: applied)
    }

    /// Restores the previous volume unless the user changed it while ringing.
    public func end(on output: OutputVolumeControl) {
        guard let current = output.currentVolume(),
            current.isMuted == applied.isMuted,
            abs(current.level - applied.level) <= Self.matchTolerance
        else { return }
        _ = output.setVolume(original)
    }
}
