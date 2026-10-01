import HandyBarAlarm
import SwiftUI

/// The content of the window shown while Alarms are Ringing.
public struct RingingView: View {
    private let alarms: [Alarm]
    private let onSnooze: () -> Void
    private let onStop: () -> Void

    public init(alarms: [Alarm], onSnooze: @escaping () -> Void, onStop: @escaping () -> Void) {
        self.alarms = alarms
        self.onSnooze = onSnooze
        self.onStop = onStop
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Alarm", systemImage: "alarm.waves.left.and.right.fill")
                .font(.headline)
                .foregroundStyle(.orange)
                .symbolEffect(.pulse)

            ForEach(alarms) { alarm in
                VStack(alignment: .leading, spacing: 2) {
                    Text(AlarmText.time(hour: alarm.hour, minute: alarm.minute))
                        .font(.system(size: 44, weight: .semibold).monospacedDigit())
                    if !alarm.label.isEmpty {
                        Text(alarm.label).font(.title3).lineLimit(2)
                    }
                }
                .accessibilityElement(children: .combine)
            }

            HStack(spacing: 10) {
                Button(action: onSnooze) {
                    Text("Snooze \(Int(AlarmEngine.snoozeInterval / 60)) min")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)
                Button(action: onStop) {
                    Text("Stop").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .controlSize(.extraLarge)
        }
        .padding(20)
        .frame(width: 320)
    }
}

#Preview {
    RingingView(alarms: [Alarm(hour: 10, minute: 0, label: "Standup")], onSnooze: {}, onStop: {})
}
