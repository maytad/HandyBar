import HandyBarAlarm
import SwiftUI

/// The Alarm feature: Ringing controls, quick add, and every Alarm.
struct AlarmView: View {
    let model: AlarmPanelModel
    let openAtLogin: OpenAtLoginModel

    @State private var entryText = ""
    @State private var highlighted = 0
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
        .onDisappear { model.savePendingEdit() }
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

    private var suggestions: [TimeEntry] {
        TimeEntry.suggestions(
            for: entryText, uses12HourClock: AlarmText.uses12HourClock(), now: Date(),
            calendar: .current)
    }

    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                TextField("Add alarm: type a time, e.g. 7:30", text: $entryText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isEntryFocused)
                    .onSubmit { add(at: highlighted) }
                    .onKeyPress(.downArrow) { moveHighlight(by: 1) }
                    .onKeyPress(.upArrow) { moveHighlight(by: -1) }
                    .onChange(of: entryText) { highlighted = 0 }
                Button {
                    add(at: highlighted)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 14, height: 14)
                }
                .disabled(suggestions.isEmpty)
                .accessibilityLabel("Add Alarm")
            }
            .controlSize(.large)

            if !entryText.trimmingCharacters(in: .whitespaces).isEmpty {
                if suggestions.isEmpty {
                    Text("Type a time like 7, 7:30, 1930, or 7pm, then a label if you like")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.leading, 4)
                } else {
                    suggestionList
                }
            }
        }
    }

    private var suggestionList: some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, entry in
                Button {
                    add(at: index)
                } label: {
                    HStack {
                        Text(AlarmText.time(hour: entry.hour, minute: entry.minute))
                            .font(.body.monospacedDigit().weight(.medium))
                        Text(details(entry)).foregroundStyle(.secondary)
                        Spacer()
                        if index == highlighted {
                            Image(systemName: "return").foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        index == highlighted
                            ? AnyShapeStyle(Color.accentColor.opacity(0.18))
                            : AnyShapeStyle(.clear),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { if $0 { highlighted = index } }
            }
        }
        .padding(4)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private func details(_ entry: TimeEntry) -> String {
        let now = Date()
        let date =
            Calendar.current.nextDate(
                after: now, matching: DateComponents(hour: entry.hour, minute: entry.minute),
                matchingPolicy: .nextTime) ?? now
        let day = "Rings \(AlarmText.day(date, now: now))"
        return entry.label.isEmpty ? day : "\(day) · \(entry.label)"
    }

    private func moveHighlight(by offset: Int) -> KeyPress.Result {
        guard !suggestions.isEmpty else { return .ignored }
        highlighted = min(max(highlighted + offset, 0), suggestions.count - 1)
        return .handled
    }

    private func add(at index: Int) {
        let suggestions = suggestions
        guard suggestions.indices.contains(index) else { return }
        let entry = suggestions[index]
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
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(model.alarms) { alarm in
                            if alarm.id != model.alarms.first?.id { Divider() }
                            AlarmRow(
                                alarm: alarm,
                                model: model,
                                isEditing: editingID == alarm.id,
                                onTap: { toggleEditing(alarm.id) },
                                onDelete: {
                                    editingID = nil
                                    deleted = alarm
                                    model.onDelete(alarm.id)
                                }
                            )
                            .id(alarm.id)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .onChange(of: model.alarms.map(\.id)) {
                    if let editingID { proxy.scrollTo(editingID, anchor: .top) }
                }
                .onChange(of: editingID) {
                    guard let editingID else { return }
                    // Scrolling before the row finishes expanding targets the collapsed layout.
                    Task {
                        try? await Task.sleep(for: .seconds(0.35))
                        withAnimation(.snappy) { proxy.scrollTo(editingID, anchor: .top) }
                    }
                }
            }
        }
    }

    private func toggleEditing(_ id: Alarm.ID) {
        model.savePendingEdit()
        withAnimation(.snappy) {
            editingID = editingID == id ? nil : id
        }
    }
}

private struct AlarmRow: View {
    let alarm: Alarm
    let model: AlarmPanelModel
    let isEditing: Bool
    let onTap: () -> Void
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
                        if model.missedIDs.contains(alarm.id) {
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

                Toggle(
                    "On",
                    isOn: Binding(
                        get: { alarm.isEnabled }, set: { model.onSetEnabled(alarm.id, $0) })
                )
                .toggleStyle(.switch)
                .labelsHidden()
                .accessibilityLabel(
                    "\(AlarmText.time(hour: alarm.hour, minute: alarm.minute)) Alarm")
            }
            if isEditing {
                AlarmEditor(alarm: alarm, model: model, onDelete: onDelete)
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

/// Inline options for one Alarm. Label and Repeat days save as they change; the time
/// saves a moment after the user stops adjusting it, so the list doesn't re-sort mid-edit.
private struct AlarmEditor: View {
    let alarm: Alarm
    let model: AlarmPanelModel
    let onDelete: () -> Void

    @State private var time: ClockTime
    @State private var showsCustomDays: Bool
    @State private var saveTask: Task<Void, Never>?

    init(alarm: Alarm, model: AlarmPanelModel, onDelete: @escaping () -> Void) {
        self.alarm = alarm
        self.model = model
        self.onDelete = onDelete
        _time = State(initialValue: ClockTime(hour: alarm.hour, minute: alarm.minute))
        _showsCustomDays = State(initialValue: RepeatPreset(alarm.repeatDays) == .custom)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ClockDigitsEditor(time: $time, focusOnAppear: true, onSubmit: saveTime)
                .onChange(of: time) { scheduleTimeSave() }

            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                GridRow {
                    Text("Label").gridColumnAlignment(.trailing)
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
        .onDisappear(perform: saveTime)
    }

    private func scheduleTimeSave() {
        saveTask?.cancel()
        guard time != ClockTime(hour: alarm.hour, minute: alarm.minute) else {
            model.pendingEdit = nil
            return
        }
        let id = alarm.id
        let time = time
        model.pendingEdit = { [model] in
            model.edit(id) {
                $0.hour = time.hour
                $0.minute = time.minute
                $0.isEnabled = true
            }
        }
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1.2))
            if !Task.isCancelled { model.savePendingEdit() }
        }
    }

    private func saveTime() {
        scheduleTimeSave()
        saveTask?.cancel()
        model.savePendingEdit()
    }

    private var days: some View {
        HStack(spacing: 4) {
            ForEach(AlarmText.orderedWeekdays(), id: \.self) { day in
                let isOn = alarm.repeatDays.contains(day)
                Button {
                    change {
                        if isOn { $0.repeatDays.remove(day) } else { $0.repeatDays.insert(day) }
                    }
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

    private var label: Binding<String> {
        Binding(
            get: { alarm.label },
            set: { text in model.edit(alarm.id) { $0.label = text } }
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
        model.savePendingEdit()
        model.edit(alarm.id) {
            edit(&$0)
            $0.isEnabled = true
        }
    }
}
