import Foundation
import HandyBarAutoClick
import Testing

@Test func autoClickIsNotAvailableYet() {
    #expect(AutoClick.isAvailable == false)
}

// MARK: - Settings

@Test func settingsHasDefaultInterval() {
    let settings = AutoClickSettings()
    #expect(settings.intervalMilliseconds == 100)
}

@Test func settingsHasDefaultClickLimit() {
    let settings = AutoClickSettings()
    #expect(settings.clickLimit == 100)
}

@Test func settingsAcceptsValidInterval() {
    let settings = AutoClickSettings(intervalMilliseconds: 50)
    #expect(settings.intervalMilliseconds == 50)
}

@Test func settingsClampsIntervalToMinimum() {
    let settings = AutoClickSettings(intervalMilliseconds: 5)
    #expect(settings.intervalMilliseconds == 10)
}

@Test func settingsClampsIntervalToMaximum() {
    let settings = AutoClickSettings(intervalMilliseconds: 4_000_000)
    #expect(settings.intervalMilliseconds == 3_600_000)
}

// MARK: - Engine: Basic lifecycle

@Test func engineStartsIdle() {
    let engine = AutoClickEngine(settings: AutoClickSettings())
    #expect(engine.isRunning == false)
    #expect(engine.clicksDone == 0)
}

@Test func engineStartsClickingAfterStart() {
    var engine = AutoClickEngine(settings: AutoClickSettings())
    let poster = FakeClickPoster()
    let now = Date()

    engine.handle(.start(now), poster: poster)

    #expect(engine.isRunning == true)
    #expect(engine.clicksDone == 0)
    #expect(engine.nextTickAt == now.addingTimeInterval(0.1)) // 100ms default
}

@Test func engineStopsAfterStopEvent() {
    var engine = AutoClickEngine(settings: AutoClickSettings())
    let poster = FakeClickPoster()
    let now = Date()

    engine.handle(.start(now), poster: poster)
    engine.handle(.stop, poster: poster)

    #expect(engine.isRunning == false)
}

// MARK: - Engine: Tick behavior

@Test func enginePostsClickOnTick() {
    var engine = AutoClickEngine(settings: AutoClickSettings())
    let poster = FakeClickPoster()
    let start = Date()

    engine.handle(.start(start), poster: poster)
    let firstTick = start.addingTimeInterval(0.1)
    engine.handle(.tick(firstTick), poster: poster)

    #expect(poster.clicks.count == 1)
    #expect(engine.clicksDone == 1)
}

@Test func engineStopsAfterReachingClickLimit() {
    var engine = AutoClickEngine(settings: AutoClickSettings(clickLimit: 3))
    let poster = FakeClickPoster()
    var now = Date()

    engine.handle(.start(now), poster: poster)

    // Tick 3 times
    for _ in 1...3 {
        now = now.addingTimeInterval(0.1)
        engine.handle(.tick(now), poster: poster)
    }

    #expect(engine.isRunning == false)
    #expect(engine.clicksDone == 3)
    #expect(engine.stopReason == .limitReached)
}

@Test func engineContinuesWhenClickLimitIsZero() {
    var engine = AutoClickEngine(settings: AutoClickSettings(clickLimit: 0))
    let poster = FakeClickPoster()
    var now = Date()

    engine.handle(.start(now), poster: poster)

    // Tick 100 times — should not stop
    for _ in 1...100 {
        now = now.addingTimeInterval(0.1)
        engine.handle(.tick(now), poster: poster)
    }

    #expect(engine.isRunning == true)
    #expect(engine.clicksDone == 100)
}

// MARK: - Engine: Stop conditions

@Test func engineStopsWhenUserMovedMouse() {
    var engine = AutoClickEngine(settings: AutoClickSettings())
    let poster = FakeClickPoster()
    let now = Date()

    engine.handle(.start(now), poster: poster)
    engine.handle(.userMovedMouse, poster: poster)

    #expect(engine.isRunning == false)
    #expect(engine.stopReason == .mouseMoved)
}

@Test func engineStopsWhenPermissionLost() {
    var engine = AutoClickEngine(settings: AutoClickSettings())
    let poster = FakeClickPoster()
    let now = Date()

    engine.handle(.start(now), poster: poster)
    engine.handle(.postAccessLost, poster: poster)

    #expect(engine.isRunning == false)
    #expect(engine.stopReason == .permissionLost)
}

@Test func engineIgnoresStopEventsWhenIdle() {
    var engine = AutoClickEngine(settings: AutoClickSettings())
    let poster = FakeClickPoster()

    engine.handle(.userMovedMouse, poster: poster)
    engine.handle(.postAccessLost, poster: poster)
    engine.handle(.stop, poster: poster)

    #expect(engine.stopReason == nil)
}

// MARK: - Engine: Timing

@Test func engineSchedulesNextTickAtCorrectInterval() {
    var engine = AutoClickEngine(settings: AutoClickSettings(intervalMilliseconds: 250))
    let poster = FakeClickPoster()
    let start = Date(timeIntervalSince1970: 1000.0)

    engine.handle(.start(start), poster: poster)

    #expect(engine.nextTickAt == Date(timeIntervalSince1970: 1000.25))
}

@Test func engineMaintainsAverageRate() {
    var engine = AutoClickEngine(settings: AutoClickSettings(intervalMilliseconds: 100))
    let poster = FakeClickPoster()
    let start = Date(timeIntervalSince1970: 1000.0)

    engine.handle(.start(start), poster: poster)

    // Tick 1: on time at 1000.1
    engine.handle(.tick(Date(timeIntervalSince1970: 1000.1)), poster: poster)
    #expect(engine.nextTickAt == Date(timeIntervalSince1970: 1000.2))

    // Tick 2: late at 1000.25 (should still schedule 1000.3, not 1000.35)
    engine.handle(.tick(Date(timeIntervalSince1970: 1000.25)), poster: poster)
    #expect(engine.nextTickAt == Date(timeIntervalSince1970: 1000.3))

    // Tick 3: on time
    engine.handle(.tick(Date(timeIntervalSince1970: 1000.3)), poster: poster)
    #expect(engine.nextTickAt == Date(timeIntervalSince1970: 1000.4))
}

// MARK: - Fake helpers

final class FakeClickPoster: ClickPoster, @unchecked Sendable {
    var clicks: [Click] = []

    func post(_ click: Click) {
        clicks.append(click)
    }
}

