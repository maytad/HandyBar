import HandyBarUI
import Testing

@Test func panelListsTheThreeFeaturesInOrder() {
    #expect(FeatureEntry.all.map(\.title) == ["Alarm", "Auto Click", "Cleanup"])
}

@Test func unavailableFeaturesAreListedAsDisabled() {
    #expect(FeatureEntry.all.allSatisfy { !$0.isAvailable })
}
