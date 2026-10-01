import Foundation
import HandyBarUI
import Testing

@MainActor
struct FeaturePreferencesTests {
    let defaults = UserDefaults(suiteName: "FeaturePreferencesTests-\(UUID())")!

    private func preferences() -> FeaturePreferences {
        FeaturePreferences(defaults: defaults)
    }

    private func titles(_ entries: [FeatureEntry]) -> [String] { entries.map(\.title) }

    @Test func showsEveryFeatureInDefaultOrderAndSelectsTheFirst() {
        let preferences = preferences()
        #expect(titles(preferences.visible) == ["Alarm", "Auto Click", "Cleanup"])
        #expect(preferences.selected.title == "Alarm")
    }

    @Test func reorderingIsKeptAcrossLaunches() {
        preferences().move(fromOffsets: [2], toOffset: 0)
        #expect(titles(preferences().ordered) == ["Cleanup", "Alarm", "Auto Click"])
    }

    @Test func hiddenFeaturesLeaveThePanelButStayInTheOrder() {
        preferences().setHidden("Auto Click", true)
        let preferences = preferences()
        #expect(titles(preferences.visible) == ["Alarm", "Cleanup"])
        #expect(titles(preferences.ordered) == ["Alarm", "Auto Click", "Cleanup"])
        #expect(preferences.isHidden("Auto Click"))
    }

    @Test func theLastVisibleFeatureCannotBeHidden() {
        let preferences = preferences()
        preferences.setHidden("Alarm", true)
        preferences.setHidden("Auto Click", true)
        preferences.setHidden("Cleanup", true)
        #expect(titles(preferences.visible) == ["Cleanup"])
        #expect(!preferences.canHide("Cleanup"))
    }

    @Test func theSelectedFeatureIsRestored() {
        preferences().select("Cleanup")
        #expect(preferences().selected.title == "Cleanup")
    }

    @Test func hidingTheSelectedFeatureSelectsTheFirstVisible() {
        let preferences = preferences()
        preferences.select("Alarm")
        preferences.setHidden("Alarm", true)
        #expect(preferences.selected.title == "Auto Click")
    }

    @Test func unknownStoredFeaturesAreIgnoredAndNewOnesAppended() {
        defaults.set(["Gone", "Cleanup", "Alarm"], forKey: "featureOrder")
        #expect(titles(preferences().ordered) == ["Cleanup", "Alarm", "Auto Click"])
    }
}
