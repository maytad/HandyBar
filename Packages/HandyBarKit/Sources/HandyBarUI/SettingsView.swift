import AppKit
import HandyBarAlarm
import SwiftUI

/// The Settings window: General options, Alarm defaults, and which features the panel shows.
public struct SettingsView: View {
    enum Pane: String, CaseIterable, Identifiable {
        case general = "General"
        case alarm = "Alarm"
        case features = "Features"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .general: "gearshape"
            case .alarm: "alarm"
            case .features: "square.grid.2x2"
            }
        }
    }

    private let features: FeaturePreferences
    private let openAtLogin: OpenAtLoginModel
    private let soundPreview: AlarmSoundPreview
    @AppStorage("settingsPane") private var pane = Pane.general

    public init(
        features: FeaturePreferences, openAtLogin: OpenAtLoginModel,
        soundPreview: AlarmSoundPreview
    ) {
        self.features = features
        self.openAtLogin = openAtLogin
        self.soundPreview = soundPreview
    }

    public var body: some View {
        NavigationSplitView {
            List(Pane.allCases, selection: paneSelection) { pane in
                Label(pane.rawValue, systemImage: pane.symbol).tag(pane)
            }
            .navigationSplitViewColumnWidth(180)
        } detail: {
            switch pane {
            case .general: GeneralPane(openAtLogin: openAtLogin)
            case .alarm: AlarmPane(preview: soundPreview)
            case .features: FeaturesPane(features: features)
            }
        }
        .frame(minWidth: 620, minHeight: 380)
    }

    private var paneSelection: Binding<Pane?> {
        Binding(get: { pane }, set: { if let new = $0 { pane = new } })
    }
}

private struct GeneralPane: View {
    let openAtLogin: OpenAtLoginModel

    var body: some View {
        Form {
            Section {
                Toggle(
                    "Open at login",
                    isOn: Binding(
                        get: { openAtLogin.status != .disabled },
                        set: { openAtLogin.setEnabled($0) }))
                Text("Alarms ring only while HandyBar is running.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if openAtLogin.needsApproval {
                    HStack {
                        Label(
                            "Allow HandyBar in Login Items to finish turning this on.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                        Spacer()
                        Button("Open Login Items…", action: openAtLogin.openSystemSettings)
                    }
                }
                if let message = openAtLogin.errorMessage {
                    Text(message).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .onAppear(perform: openAtLogin.refresh)
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in openAtLogin.refresh() }
    }
}

private struct AlarmPane: View {
    let preview: AlarmSoundPreview
    @AppStorage(AlarmDefaults.soundKey) private var defaultSound = AlarmSound.beeps
    @AppStorage(AlarmDefaults.snoozeKey) private var defaultSnooze = AlarmSnooze.fiveMinutes

    var body: some View {
        Form {
            Section {
                LabeledContent("Sound for new Alarms") {
                    SoundPicker(sound: $defaultSound, preview: preview)
                }
                LabeledContent("Snooze for new Alarms") {
                    SnoozePicker(snooze: $defaultSnooze)
                }
            } footer: {
                Text(
                    "Each Alarm can have its own sound and snooze. Click an Alarm in the panel to change them."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Alarm")
        .onDisappear(perform: preview.stop)
    }
}

private struct FeaturesPane: View {
    let features: FeaturePreferences

    var body: some View {
        Form {
            Section {
                List {
                    ForEach(features.ordered) { entry in
                        HStack(spacing: 10) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.tertiary)
                            Image(systemName: entry.symbol)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(
                                    FeatureTint.color(entry).gradient,
                                    in: RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(entry.title)
                                Text(entry.summary).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle(
                                "Show \(entry.title)",
                                isOn: Binding(
                                    get: { !features.isHidden(entry.id) },
                                    set: { features.setHidden(entry.id, !$0) })
                            )
                            .labelsHidden()
                            .disabled(!features.isHidden(entry.id) && !features.canHide(entry.id))
                        }
                        .padding(.vertical, 2)
                    }
                    .onMove { features.move(fromOffsets: $0, toOffset: $1) }
                }
                .frame(minHeight: CGFloat(features.ordered.count) * 44)
            } header: {
                Text("Shown in the menu bar panel")
            } footer: {
                Text("Drag to reorder. At least one feature stays shown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Features")
    }
}
