import HandyBarAlarm
import SwiftUI

struct AlarmListView: View {
    let model: AlarmPanelModel
    let onBack: () -> Void
    let onAdd: () -> Void
    let onEdit: (Alarm) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: onBack) {
                    Label("Alarm", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add Alarm")
            }
            .font(.headline)

            if model.alarms.isEmpty {
                Text("No Alarms")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(model.alarms) { alarm in
                            row(alarm)
                            if alarm.id != model.alarms.last?.id { Divider() }
                        }
                    }
                }
                .frame(maxHeight: 320)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func row(_ alarm: Alarm) -> some View {
        HStack(alignment: .center) {
            Button {
                onEdit(alarm)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(AlarmText.time(hour: alarm.hour, minute: alarm.minute))
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(alarm.isEnabled ? .primary : .secondary)
                    HStack(spacing: 4) {
                        if !alarm.label.isEmpty { Text(alarm.label).lineLimit(1) }
                        Text(AlarmText.repeatDays(alarm.repeatDays)).foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    if model.missedIDs.contains(alarm.id) {
                        Text("Missed").font(.caption.bold()).foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle(
                "Enabled",
                isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { model.onSetEnabled(alarm.id, $0) }
                )
            )
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
        }
        .padding(.vertical, 6)
    }
}
