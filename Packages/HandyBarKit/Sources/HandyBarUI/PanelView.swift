import SwiftUI

public struct PanelView: View {
    private let entries: [FeatureEntry]
    private let onQuit: () -> Void

    public init(entries: [FeatureEntry] = FeatureEntry.all, onQuit: @escaping () -> Void) {
        self.entries = entries
        self.onQuit = onQuit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entries) { entry in
                Button(entry.title) {}
                    .buttonStyle(.borderless)
                    .disabled(!entry.isAvailable)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            Divider()
            Button("Quit HandyBar", action: onQuit)
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
        }
        .padding(12)
        .frame(width: 220)
    }
}

#Preview {
    PanelView(onQuit: {})
}
