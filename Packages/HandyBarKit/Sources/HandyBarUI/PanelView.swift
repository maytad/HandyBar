import HandyBarAlarm
import SwiftUI

public struct PanelView: View {
    private enum Page: Equatable {
        case features
        case alarms
        case editAlarm(Alarm?)
    }

    private let entries: [FeatureEntry]
    private let alarms: AlarmPanelModel
    private let onQuit: () -> Void
    @State private var page = Page.features

    public init(
        entries: [FeatureEntry] = FeatureEntry.all,
        alarms: AlarmPanelModel,
        onQuit: @escaping () -> Void
    ) {
        self.entries = entries
        self.alarms = alarms
        self.onQuit = onQuit
    }

    public var body: some View {
        Group {
            switch page {
            case .features:
                features
            case .alarms:
                AlarmListView(
                    model: alarms,
                    onBack: { page = .features },
                    onAdd: { page = .editAlarm(nil) },
                    onEdit: { page = .editAlarm($0) }
                )
            case .editAlarm(let alarm):
                AlarmEditView(
                    alarm: alarm,
                    onSave: { edited in
                        if alarm == nil { alarms.onAdd(edited) } else { alarms.onUpdate(edited) }
                        page = .alarms
                    },
                    onDelete: alarm.map { existing in
                        {
                            alarms.onDelete(existing.id)
                            page = .alarms
                        }
                    },
                    onCancel: { page = .alarms }
                )
            }
        }
        .padding(12)
        .frame(width: 260)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entries) { entry in
                Button {
                    if entry.title == "Alarm" { page = .alarms }
                } label: {
                    HStack {
                        Text(entry.title)
                        Spacer()
                        if entry.title == "Alarm", alarms.hasMissedAlarms {
                            Circle().fill(.red).frame(width: 7, height: 7)
                                .accessibilityLabel("Missed Alarm")
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .disabled(!entry.isAvailable)
                .padding(.vertical, 4)
            }
            Divider()
            Button("Quit HandyBar", action: onQuit)
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
        }
    }
}

#Preview {
    PanelView(alarms: AlarmPanelModel(), onQuit: {})
}
