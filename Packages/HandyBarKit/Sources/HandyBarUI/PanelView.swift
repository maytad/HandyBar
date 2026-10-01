import HandyBarAlarm
import SwiftUI

/// The menu bar panel: one card per feature, with at most one card expanded.
public struct PanelView: View {
    public static let width: CGFloat = 320

    private let entries: [FeatureEntry]
    private let alarms: AlarmPanelModel
    private let onQuit: () -> Void
    @AppStorage("expandedFeature") private var expanded = "Alarm"

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
        VStack(spacing: 10) {
            header
            ForEach(entries) { entry in
                card(entry)
            }
        }
        .padding(12)
        .frame(width: Self.width)
    }

    private var header: some View {
        HStack {
            Text("HandyBar").font(.title3.weight(.semibold))
            Spacer()
            Menu {
                Button("Quit HandyBar", action: onQuit)
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel("HandyBar menu")
        }
        .padding(.horizontal, 4)
    }

    private func toggle(_ entry: FeatureEntry) -> () -> Void {
        {
            withAnimation(.snappy) { expanded = expanded == entry.id ? "" : entry.id }
        }
    }

    @ViewBuilder
    private func card(_ entry: FeatureEntry) -> some View {
        if entry.title == "Alarm" {
            let isExpanded = expanded == entry.id
            let status = AlarmStatus(alarms)
            FeatureCard(
                entry: entry, tint: .orange, status: status.text, statusIsAlert: status.isAlert,
                isExpanded: isExpanded, onToggle: toggle(entry)
            ) {
                AlarmCard(model: alarms, isExpanded: isExpanded)
            }
        } else {
            FeatureCard(
                entry: entry, tint: entry.title == "Auto Click" ? .blue : .green,
                status: "Coming soon", isExpanded: nil
            ) {
                EmptyView()
            }
        }
    }
}

/// The one-line summary on the Alarm card.
struct AlarmStatus {
    let text: String
    let isAlert: Bool

    @MainActor
    init(_ model: AlarmPanelModel, now: Date = Date(), calendar: Calendar = .current) {
        let time = { (alarm: Alarm) in AlarmText.time(hour: alarm.hour, minute: alarm.minute) }
        if let ringing = model.ringingAlarms.first {
            (text, isAlert) = ("Ringing · \(time(ringing))", true)
        } else if let missed = model.alarms.first(where: { model.missedIDs.contains($0.id) }) {
            (text, isAlert) = ("Missed \(time(missed))", true)
        } else if let (alarm, date) = model.alarms
            .compactMap({ alarm in alarm.nextOccurrence.map { (alarm, $0) } })
            .min(by: { $0.1 < $1.1 })
        {
            let day = AlarmText.day(date, now: now, calendar: calendar)
            (text, isAlert) = ("Next \(time(alarm)) \(day)", false)
        } else if model.alarms.isEmpty {
            (text, isAlert) = ("No Alarms", false)
        } else {
            (text, isAlert) = ("All Alarms off", false)
        }
    }
}

#Preview {
    PanelView(alarms: AlarmPanelModel(), onQuit: {})
}
