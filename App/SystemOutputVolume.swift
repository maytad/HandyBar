import AudioToolbox
import CoreAudio
import HandyBarAlarm

/// The default output device's volume and mute state through Core Audio.
@MainActor
final class SystemOutputVolume: OutputVolumeControl {
    func currentVolume() -> OutputVolume? {
        guard let device = defaultOutputDevice(),
            let level: Float32 = read(device, Self.volumeAddress)
        else { return nil }
        let muted: UInt32 = read(device, Self.muteAddress) ?? 0
        return OutputVolume(level: level, isMuted: muted != 0)
    }

    func setVolume(_ volume: OutputVolume) -> Bool {
        guard let device = defaultOutputDevice(), isSettable(device, Self.volumeAddress) else {
            return false
        }
        if isSettable(device, Self.muteAddress) {
            guard write(device, Self.muteAddress, UInt32(volume.isMuted ? 1 : 0)) else {
                return false
            }
        } else if volume.isMuted != (currentVolume()?.isMuted ?? false) {
            return false
        }
        return write(device, Self.volumeAddress, Float32(volume.level))
    }

    private static let volumeAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain)

    private static let muteAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyMute,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain)

    private func defaultOutputDevice() -> AudioObjectID? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let device: AudioObjectID? = read(AudioObjectID(kAudioObjectSystemObject), address)
        return device == AudioObjectID(kAudioObjectUnknown) ? nil : device
    }

    private func read<T>(_ object: AudioObjectID, _ address: AudioObjectPropertyAddress) -> T? {
        var address = address
        guard AudioObjectHasProperty(object, &address) else { return nil }
        var size = UInt32(MemoryLayout<T>.size)
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        guard AudioObjectGetPropertyData(object, &address, 0, nil, &size, pointer) == noErr else {
            return nil
        }
        return pointer.pointee
    }

    private func write<T>(
        _ object: AudioObjectID, _ address: AudioObjectPropertyAddress, _ value: T
    ) -> Bool {
        var address = address
        var value = value
        return AudioObjectSetPropertyData(
            object, &address, 0, nil, UInt32(MemoryLayout<T>.size), &value) == noErr
    }

    private func isSettable(_ object: AudioObjectID, _ address: AudioObjectPropertyAddress) -> Bool
    {
        var address = address
        var settable: DarwinBoolean = false
        guard AudioObjectHasProperty(object, &address),
            AudioObjectIsPropertySettable(object, &address, &settable) == noErr
        else { return false }
        return settable.boolValue
    }
}
