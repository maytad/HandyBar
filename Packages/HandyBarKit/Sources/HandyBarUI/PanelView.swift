import HandyBarAlarm
import SwiftUI

/// The menu bar panel: a sidebar of features, and the selected feature beside it.
public struct PanelView: View {
    static let sidebarWidth: CGFloat = 180
    static let detailWidth: CGFloat = 340
    static let height: CGFloat = 460

    private let features: FeaturePreferences
    private let alarms: AlarmPanelModel
    private let openAtLogin: OpenAtLoginModel
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void

    public init(
        features: FeaturePreferences,
        alarms: AlarmPanelModel,
        openAtLogin: OpenAtLoginModel,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.features = features
        self.alarms = alarms
        self.openAtLogin = openAtLogin
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
    }

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail(features.selected)
                .frame(width: Self.detailWidth, alignment: .topLeading)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        // A fixed size: resizing the popover while rows animate makes it flicker.
        .frame(height: Self.height)
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("HandyBar")
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            ForEach(Array(features.visible.enumerated()), id: \.element.id) { index, entry in
                SidebarRow(
                    entry: entry,
                    status: status(of: entry),
                    isSelected: entry.id == features.selected.id,
                    shortcut: index < 9 ? KeyEquivalent(Character("\(index + 1)")) : nil
                ) {
                    features.select(entry.id)
                }
            }
            Spacer(minLength: 12)
            Divider().padding(.bottom, 4)
            HStack {
                Button(action: onOpenSettings) {
                    Label("Settings…", systemImage: "gearshape")
                }
                .keyboardShortcut(",")
                Spacer()
                Button(action: onQuit) {
                    Image(systemName: "power")
                }
                .keyboardShortcut("q")
                .help("Quit HandyBar")
                .accessibilityLabel("Quit HandyBar")
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 8)
        }
        .padding(10)
        .frame(width: Self.sidebarWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.quaternary.opacity(0.35))
    }

    private func status(of entry: FeatureEntry) -> FeatureStatus {
        switch entry.title {
        case "Alarm": AlarmStatus(alarms).feature
        default: FeatureStatus(text: "Coming soon")
        }
    }

    // MARK: Detail

    @ViewBuilder
    private func detail(_ entry: FeatureEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title).font(.title2.weight(.semibold))
                Text(entry.summary).font(.subheadline).foregroundStyle(.secondary)
            }
            switch entry.title {
            case "Alarm":
                AlarmView(model: alarms, openAtLogin: openAtLogin)
            default:
                comingSoon(entry)
            }
        }
        .padding(14)
        .id(entry.id)
    }

    private func comingSoon(_ entry: FeatureEntry) -> some View {
        VStack(spacing: 10) {
            Image(systemName: entry.symbol)
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("Coming soon").font(.headline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

/// A feature's one-line status in the sidebar.
struct FeatureStatus {
    var text: String
    /// Needs attention now, such as a Ringing or Missed Alarm.
    var isAlert = false
}

private struct SidebarRow: View {
    let entry: FeatureEntry
    let status: FeatureStatus
    let isSelected: Bool
    let shortcut: KeyEquivalent?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: entry.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        FeatureTint.color(entry).gradient, in: RoundedRectangle(cornerRadius: 6)
                    )
                    .opacity(entry.isAvailable ? 1 : 0.5)
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(entry.isAvailable ? .primary : .secondary)
                    Text(status.text)
                        .font(.caption)
                        .foregroundStyle(
                            status.isAlert ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary)
                        )
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if status.isAlert {
                    Circle().fill(.red).frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor.opacity(0.22)) : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: 7)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(OptionalShortcut(key: shortcut))
        .accessibilityLabel("\(entry.title), \(status.text)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OptionalShortcut: ViewModifier {
    let key: KeyEquivalent?

    func body(content: Content) -> some View {
        if let key {
            content.keyboardShortcut(key, modifiers: .command)
        } else {
            content
        }
    }
}

enum FeatureTint {
    static func color(_ entry: FeatureEntry) -> Color {
        switch entry.title {
        case "Alarm": .orange
        case "Auto Click": .blue
        default: .green
        }
    }
}

/// The one-line summary of Alarms.
struct AlarmStatus {
    let text: String
    let isAlert: Bool

    var feature: FeatureStatus { FeatureStatus(text: text, isAlert: isAlert) }

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
            (text, isAlert) = ("All off", false)
        }
    }
}
