import Foundation
import Observation
import SwiftUI

/// Which features the panel shows, in what order, and which one is open.
@MainActor
@Observable
public final class FeaturePreferences {
    public private(set) var ordered: [FeatureEntry]
    private var hidden: Set<FeatureEntry.ID>
    private var selectedID: FeatureEntry.ID?
    @ObservationIgnored private let defaults: UserDefaults

    private enum Key {
        static let order = "featureOrder"
        static let hidden = "hiddenFeatures"
        static let selected = "selectedFeature"
    }

    public init(all: [FeatureEntry] = FeatureEntry.all, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.stringArray(forKey: Key.order) ?? []
        let known = stored.compactMap { id in all.first { $0.id == id } }
        ordered = known + all.filter { entry in !known.contains(entry) }
        hidden = Set(defaults.stringArray(forKey: Key.hidden) ?? [])
        selectedID = defaults.string(forKey: Key.selected)
    }

    public var visible: [FeatureEntry] {
        let visible = ordered.filter { !hidden.contains($0.id) }
        return visible.isEmpty ? Array(ordered.prefix(1)) : visible
    }

    /// The open feature: the last one selected if still visible, otherwise the first visible.
    public var selected: FeatureEntry {
        visible.first { $0.id == selectedID } ?? visible[0]
    }

    public func select(_ id: FeatureEntry.ID) {
        selectedID = id
        defaults.set(id, forKey: Key.selected)
    }

    public func isHidden(_ id: FeatureEntry.ID) -> Bool { hidden.contains(id) }

    public func canHide(_ id: FeatureEntry.ID) -> Bool {
        visible.contains { $0.id != id }
    }

    public func setHidden(_ id: FeatureEntry.ID, _ isHidden: Bool) {
        if isHidden {
            guard canHide(id) else { return }
            hidden.insert(id)
        } else {
            hidden.remove(id)
        }
        defaults.set(Array(hidden).sorted(), forKey: Key.hidden)
    }

    public func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        ordered.move(fromOffsets: source, toOffset: destination)
        defaults.set(ordered.map(\.id), forKey: Key.order)
    }
}
