import HandyBarAlarm
import SwiftUI

/// The Alarm feature: Ringing controls, quick add, and every Alarm.
struct AlarmView: View {
    let model: AlarmPanelModel
    let openAtLogin: OpenAtLoginModel

    @State private var entryText = ""
    @State private var editingID: Alarm.ID?
    @State private var deleted: Alarm?
    @FocusState private var isEntryFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !model.ringingAlarms.isEmpty { ringing }
            quickAdd
            if openAtLogin.isSuggesting { loginSuggestion }
            if let deleted { undoBar(deleted) }
            list
        }
        .onAppear { isEntryFocused = true }
    }

    private var loginSuggestion: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                "Alarms ring only while HandyBar is running. Open it when you log in?",
                systemImage: "info.circle"
            )
            .font(.callout)
            .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("Not Now", action: openAtLogin.declineSuggestion)
                Button("Open at Login", action: openAtLogin.acceptSuggestion)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(10)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private var ringing: some View {
        HStack(spacing: 8) {
            Image(systemName: "alarm.waves.left.and.right.fill")
                .foregroundStyle(.red)
                .symbolEffect(.pulse)
            Text(
                model.ringingAlarms.map { AlarmText.time(hour: $0.hour, minute: $0.minute) }
                    .joined(separator: ", ")
            )
            .font(.headline.monospacedDigit())
            Spacer(minLength: 0)
            Button("Snooze", action: model.onSnooze)
            Button("Stop", action: model.onStop)
                .buttonStyle(.borderedProminent)
                .tint(.red)
        }
        .padding(8)
        .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Quick add

    private var parsedEntry: TimeEntry? {
        TimeEntry.parse(
            entryText, uses12HourClock: AlarmText.uses12HourClock(), now: Date(),
            calendar: .current)
    }

    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                TextField("Add alarm, e.g. 7:30 Standup", text: $entryText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isEntryFocused)
                    .onSubmit(add)
                Button(action: add) {
                    Image(systemName: "plus")
                        .frame(width: 14, height: 14)
                }
                .disabled(parsedEntry == nil)
                .accessibilityLabel("Add Alarm")
            }
            .controlSize(.large)

            if !entryText.trimmingCharacters(in: .whitespaces).isEmpty {
                Group {
                    if let entry = parsedEntry {
                        Text(preview(entry))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Type a time like 7:30, 19:30, or 7pm")
                            .foregroundStyle(.red)
                    }
                }
                .font(.caption)
                .padding(.leading, 4)
            }
        }
    }

    private func preview(_ entry: TimeEntry) -> String {
        let now = Date()
        let date =
            Calendar.current.nextDate(
                after: now, matching: DateComponents(hour: entry.hour, minute: entry.minute),
                matchingPolicy: .nextTime) ?? now
        let time = AlarmText.time(hour: entry.hour, minute: entry.minute)
        let ring = "Rings \(AlarmText.day(date, now: now)) at \(time)"
        return entry.label.isEmpty ? ring : "\(ring) · \(entry.label)"
    }

    private func add() {
        guard let entry = parsedEntry else { return }
        model.onAdd(Alarm(hour: entry.hour, minute: entry.minute, label: entry.label))
        entryText = ""
        deleted = nil
        isEntryFocused = true
    }

    private func undoBar(_ alarm: Alarm) -> some View {
        HStack {
            Text("Deleted \(AlarmText.time(hour: alarm.hour, minute: alarm.minute))")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Undo") {
                model.onAdd(alarm)
                deleted = nil
            }
        }
        .font(.callout)
        .padding(.horizontal, 4)
    }

    // MARK: List

    @ViewBuilder
    private var list: some View {
        if model.alarms.isEmpty {
            Text("No Alarms yet. Type a time above and press Return.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(model.alarms) { alarm in
                        if alarm.id != model.alarms.first?.id { Divider() }
                        AlarmRow(
                            alarm: alarm,
                            isMissed: model.missedIDs.contains(alarm.id),
                            isEditing: editingID == alarm.id,
                            onTap: {
                                withAnimation(.snappy) {
                                    editingID = editingID == alarm.id ? nil : alarm.id
                                }
                            },
                            onSetEnabled: { model.onSetEnabled(alarm.id, $0) },
                            onChange: model.onUpdate,
                            onDelete: {
                                editingID = nil
                                deleted = alarm
                                model.onDelete(alarm.id)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 380)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AlarmRow: View {
    let alarm: Alarm
    let isMissed: Bool
    let isEditing: Bool
    let onTap: () -> Void
    let onSetEnabled: (Bool) -> Void
    let onChange: (Alarm) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AlarmText.time(hour: alarm.hour, minute: alarm.minute))
                            .font(.system(size: 24, weight: .medium).monospacedDigit())
                            .foregroundStyle(alarm.isEnabled ? .primary : .secondary)
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if isMissed {
                            Label("Missed", systemImage: "exclamationmark.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(isEditing ? "Hides options" : "Shows options")

                Toggle("On", isOn: Binding(get: { alarm.isEnabled }, set: { onSetEnabled($0) }))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .accessibilityLabel(
                        "\(AlarmText.time(hour: alarm.hour, minute: alarm.minute)) Alarm")
            }
            if isEditing {
                AlarmEditor(alarm: alarm, onChange: onChange, onDelete: onDelete)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private var summary: String {
        let label = alarm.label.isEmpty ? "Alarm" : alarm.label
        return "\(label) · \(AlarmText.repeatDays(alarm.repeatDays))"
    }
}

/// Inline options for one Alarm; every change is saved as it is made.
private struct AlarmEditor: View {
    let alarm: Alarm
    let onChange: (Alarm) -> Void
    let onDelete: () -> Void

    @State private var showsCustomDays: Bool

    init(alarm: Alarm, onChange: @escaping (Alarm) -> Void, onDelete: @escaping () -> Void) {
        self.alarm = alarm
        self.onChange = onChange
        self.onDelete = onDelete
        _showsCustomDays = State(initialValue: RepeatPreset(alarm.repeatDays) == .custom)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                GridRow {
                    Text("Time").gridColumnAlignment(.trailing)
                    DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.field)
                        .labelsHidden()
                }
                GridRow {
                    Text("Label")
                    TextField("Alarm", text: label)
                        .textFieldStyle(.roundedBorder)
                }
                GridRow {
                    Text("Repeat")
                    Picker("Repeat", selection: preset) {
                        ForEach(RepeatPreset.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
            }
            .foregroundStyle(.secondary)

            if showsCustomDays { days }

            HStack {
                Spacer()
                Button("Delete Alarm", role: .destructive, action: onDelete)
            }
        }
        .padding(10)
        .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
    }

    private var days: some View {
        HStack(spacing: 4) {
            ForEach(AlarmText.orderedWeekdays(), id: \.self) { day in
                let isOn = alarm.repeatDays.contains(day)
                Button {
                    var days = alarm.repeatDays
                    if isOn { days.remove(day) } else { days.insert(day) }
                    change { $0.repeatDays = days }
                } label: {
                    Text(AlarmText.shortName(day))
                        .font(.caption.weight(.medium))
                        .frame(maxWidth: .infinity, minHeight: 26)
                        .foregroundStyle(isOn ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                        .background(
                            isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AlarmText.fullName(day))
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }

    private var time: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: Date())
                    ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                change {
                    $0.hour = parts.hour ?? 0
                    $0.minute = parts.minute ?? 0
                }
            }
        )
    }

    private var label: Binding<String> {
        Binding(
            get: { alarm.label },
            set: { text in
                var edited = alarm
                edited.label = text
                onChange(edited)
            }
        )
    }

    private var preset: Binding<RepeatPreset> {
        Binding(
            get: { showsCustomDays ? .custom : RepeatPreset(alarm.repeatDays) },
            set: { preset in
                showsCustomDays = preset == .custom
                if preset != .custom { change { $0.repeatDays = preset.days } }
            }
        )
    }

    /// Applies a schedule edit; changing when an Alarm rings switches it on.
    private func change(_ edit: (inout Alarm) -> Void) {
        var edited = alarm
        edit(&edited)
        edited.isEnabled = true
        onChange(edited)
    }
}
