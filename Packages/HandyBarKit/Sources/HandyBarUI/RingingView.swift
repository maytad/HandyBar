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
        VStack(alignment: .leading, spacing: 10) {
            Label("Alarm", systemImage: "alarm.fill")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(alarms) { alarm in
                VStack(alignment: .leading, spacing: 0) {
                    Text(AlarmText.time(hour: alarm.hour, minute: alarm.minute))
                        .font(.system(size: 28, weight: .semibold).monospacedDigit())
                    if !alarm.label.isEmpty {
                        Text(alarm.label).font(.body).lineLimit(2)
                    }
                }
            }

            HStack {
                Button("Snooze 5 min", action: onSnooze)
                Spacer()
                Button("Stop", action: onStop)
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .padding(16)
        .frame(width: 280)
    }
}

#Preview {
    RingingView(alarms: [Alarm(hour: 10, minute: 0, label: "Standup")], onSnooze: {}, onStop: {})
}
