import HandyBarAlarm
import SwiftUI

struct AlarmEditView: View {
    let alarm: Alarm?
    let onSave: (Alarm) -> Void
    let onDelete: (() -> Void)?
    let onCancel: () -> Void

    @State private var time: Date
    @State private var label: String
    @State private var repeatDays: Set<Weekday>

    init(
        alarm: Alarm?,
        onSave: @escaping (Alarm) -> Void,
        onDelete: (() -> Void)?,
        onCancel: @escaping () -> Void
    ) {
        self.alarm = alarm
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        let calendar = Calendar.current
        let start =
            alarm.flatMap {
                calendar.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: Date())
            }
            ?? calendar.nextDate(
                after: Date(), matching: DateComponents(minute: 0), matchingPolicy: .nextTime)
            ?? Date()
        _time = State(initialValue: start)
        _label = State(initialValue: alarm?.label ?? "")
        _repeatDays = State(initialValue: alarm?.repeatDays ?? [])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(alarm == nil ? "New Alarm" : "Edit Alarm").font(.headline)

            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.stepperField)

            TextField("Label (optional)", text: $label)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 4) {
                Text("Repeat").font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    ForEach(AlarmText.orderedWeekdays(), id: \.self) { day in
                        Toggle(AlarmText.veryShortName(day), isOn: dayBinding(day))
                            .toggleStyle(.button)
                            .controlSize(.small)
                            .accessibilityLabel(AlarmText.shortName(day))
                    }
                }
                Text(AlarmText.repeatDays(repeatDays)).font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                if let onDelete {
                    Button("Delete", role: .destructive, action: onDelete)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func dayBinding(_ day: Weekday) -> Binding<Bool> {
        Binding(
            get: { repeatDays.contains(day) },
            set: { isOn in
                if isOn { repeatDays.insert(day) } else { repeatDays.remove(day) }
            }
        )
    }

    private func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        var edited = alarm ?? Alarm(hour: 0, minute: 0)
        edited.hour = components.hour ?? 0
        edited.minute = components.minute ?? 0
        edited.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.repeatDays = repeatDays
        edited.isEnabled = true
        onSave(edited)
    }
}
