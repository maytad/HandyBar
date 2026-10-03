import HandyBarUI
import Testing

@Test func panelListsTheThreeFeaturesInOrder() {
    #expect(FeatureEntry.all.map(\.title) == ["Alarm", "Auto Click", "Cleanup"])
}

@Test func onlyAlarmIsAvailable() {
    #expect(FeatureEntry.all.filter(\.isAvailable).map(\.title) == ["Alarm"])
}
