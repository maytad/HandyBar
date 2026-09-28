import HandyBarUI
import Testing

@Test func clickWhenClosedShowsThePanel() {
    var toggle = PanelToggle()
    #expect(toggle.click() == .show)
}

@Test func clickWhenShownClosesThePanel() {
    var toggle = PanelToggle()
    _ = toggle.click()
    #expect(toggle.click() == .close)
}

@Test func clickWhileThePanelIsClosingReopensItOnceClosed() {
    var toggle = PanelToggle()
    _ = toggle.click()
    toggle.willClose()

    #expect(toggle.click() == .none)
    #expect(toggle.didClose() == .show)
    #expect(toggle.click() == .close)
}

@Test func closingWithoutAnotherClickLeavesThePanelClosed() {
    var toggle = PanelToggle()
    _ = toggle.click()
    toggle.willClose()

    #expect(toggle.didClose() == .none)
    #expect(toggle.click() == .show)
}
