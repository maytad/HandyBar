import HandyBarAutoClick
import SwiftUI

/// Auto Click feature panel.
public struct AutoClickView: View {
    @ObservedObject public var model: AutoClickPanelModel

    public init(model: AutoClickPanelModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !model.hasPermission {
                permissionPrompt
            } else {
                controls
                if model.isRunning {
                    statusSection
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var permissionPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("Accessibility Permission Required")
                .font(.headline)
            Text("Auto Click needs Accessibility permission to post mouse clicks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open System Settings") {
                model.requestPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Interval
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Interval")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(intervalText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(model.intervalMilliseconds) },
                        set: { model.intervalMilliseconds = Int($0) }
                    ),
                    in: 10...3_600_000,
                    step: logStep(model.intervalMilliseconds)
                )
                .disabled(model.isRunning)
            }

            // Click Limit
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Click Limit")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(limitText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(model.clickLimit) },
                            set: { model.clickLimit = Int($0) }
                        ),
                        in: 0...1000,
                        step: 10
                    )
                    .disabled(model.isRunning)
                }
            }

            Divider().padding(.vertical, 4)

            // Start/Stop button
            HStack {
                Spacer()
                if model.isRunning {
                    Button("Stop") {
                        model.stop()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button("Start") {
                        model.start()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().padding(.bottom, 4)
            HStack {
                Image(systemName: "arrow.trianglehead.clockwise")
                    .foregroundStyle(.blue)
                Text("Running")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(model.clicksDone) clicks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text("Press Esc or ⌥⌘C to stop, or move your mouse.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var intervalText: String {
        let ms = model.intervalMilliseconds
        if ms < 1000 {
            return "\(ms) ms"
        } else if ms < 60_000 {
            let sec = Double(ms) / 1000.0
            return String(format: "%.1f sec", sec)
        } else {
            let min = Double(ms) / 60_000.0
            return String(format: "%.1f min", min)
        }
    }

    private var limitText: String {
        model.clickLimit == 0 ? "Unlimited" : "\(model.clickLimit) clicks"
    }

    private func logStep(_ value: Int) -> Double {
        if value < 100 { return 10 }
        if value < 1000 { return 50 }
        if value < 10_000 { return 100 }
        if value < 60_000 { return 1000 }
        return 10_000
    }
}
