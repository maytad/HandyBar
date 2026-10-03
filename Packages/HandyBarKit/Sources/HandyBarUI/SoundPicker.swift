import HandyBarAlarm
import SwiftUI

/// The UserDefaults key for the sound new Alarms start with.
let defaultAlarmSoundKey = "defaultAlarmSound"

/// A pop-up of Alarm sounds that plays each one as it's picked, with a play/stop button.
struct SoundPicker: View {
    @Binding var sound: AlarmSound
    let preview: AlarmSoundPreview

    var body: some View {
        HStack(spacing: 6) {
            Picker("Sound", selection: selection) {
                ForEach(AlarmSound.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .labelsHidden()
            .fixedSize()

            let isPlaying = preview.playing == sound
            Button {
                preview.toggle(sound)
            } label: {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.borderless)
            .disabled(preview.isBlocked)
            .help(isPlaying ? "Stop" : "Play \(sound.title)")
            .accessibilityLabel(isPlaying ? "Stop Sound" : "Play \(sound.title)")
        }
    }

    private var selection: Binding<AlarmSound> {
        Binding(
            get: { sound },
            set: { new in
                sound = new
                preview.play(new)
            }
        )
    }
}
