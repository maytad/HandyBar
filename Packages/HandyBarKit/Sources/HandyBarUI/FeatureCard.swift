import SwiftUI

/// One feature on the panel: its icon, name, and status, with content below.
struct FeatureCard<Content: View>: View {
    let entry: FeatureEntry
    let tint: Color
    let status: String
    var statusIsAlert = false
    /// Nil when the card has nothing to expand.
    let isExpanded: Bool?
    var onToggle: () -> Void = {}
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Image(systemName: entry.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(tint.gradient, in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.title).font(.headline)
                        Text(status)
                            .font(.subheadline)
                            .foregroundStyle(
                                statusIsAlert ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary)
                            )
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if let isExpanded {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isExpanded == nil)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(entry.title), \(status)")
            .accessibilityHint(
                isExpanded.map { $0 ? "Collapses \(entry.title)" : "Shows all \(entry.title)s" }
                    ?? "")

            content
        }
        .padding(12)
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .opacity(entry.isAvailable ? 1 : 0.6)
    }
}
