import XCTest
@testable import Lernwiese

final class ProgressStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "LernwieseTests.progress"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func testStartsEmptyAtTheEasiestLevel() {
        let store = ProgressStore(defaults: defaults)
        XCTAssertEqual(store.total, 0)
        XCTAssertEqual(store.maximum, 30)
        for game in GameID.allCases {
            XCTAssertEqual(store.level(for: game), 0)
        }
    }

    func testEveryFinishedGameEarnsAStarUpToThree() {
        let store = ProgressStore(defaults: defaults)
        XCTAssertTrue(store.recordCompletion(of: .counting))
        XCTAssertEqual(store.level(for: .counting), 1)
        XCTAssertTrue(store.recordCompletion(of: .counting))
        XCTAssertTrue(store.recordCompletion(of: .counting))
        XCTAssertFalse(store.recordCompletion(of: .counting))
        XCTAssertEqual(store.stars(for: .counting), 3)
        XCTAssertEqual(store.level(for: .counting), 2)
        XCTAssertEqual(store.total, 3)
    }

    func testStarsAreKeptOnTheDevice() {
        ProgressStore(defaults: defaults).recordCompletion(of: .habitat)
        XCTAssertEqual(ProgressStore(defaults: defaults).stars(for: .habitat), 1)
    }

    func testResetClearsAllStars() {
        let store = ProgressStore(defaults: defaults)
        store.set(3, for: .weather)
        store.set(9, for: .growth)
        XCTAssertEqual(store.stars(for: .growth), 3)
        store.reset()
        XCTAssertEqual(store.total, 0)
        XCTAssertEqual(ProgressStore(defaults: defaults).total, 0)
    }
}

final class ParentalGateTests: XCTestCase {
    func testAcceptsOnlyTheRightAnswer() {
        let gate = ParentalGate(first: 14, second: 7)
        XCTAssertEqual(gate.answer, 98)
        XCTAssertTrue(gate.accepts("98"))
        XCTAssertTrue(gate.accepts(" 98 "))
        XCTAssertFalse(gate.accepts("97"))
        XCTAssertFalse(gate.accepts(""))
        XCTAssertFalse(gate.accepts("abc"))
    }

    func testTasksAreTooHardForYoungChildren() {
        var rng = SeededGenerator(seed: 9)
        for _ in 0..<500 {
            let gate = ParentalGate.random(using: &rng)
            XCTAssertGreaterThanOrEqual(gate.first, 12)
            XCTAssertGreaterThanOrEqual(gate.second, 3)
            XCTAssertGreaterThanOrEqual(gate.answer, 36)
            XCTAssertLessThanOrEqual(String(gate.answer).count, 3)
        }
    }
}

final class SettingsTests: XCTestCase {
    func testDefaultsReadAloudAndVibrate() {
        let suite = "LernwieseTests.settings"
        UserDefaults().removePersistentDomain(forName: suite)
        let settings = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        XCTAssertTrue(settings.speechEnabled)
        XCTAssertFalse(settings.slowSpeech)
        XCTAssertTrue(settings.hapticsEnabled)
        XCTAssertEqual(settings.voiceIdentifier, "", "the most natural voice is picked automatically")
        settings.speechEnabled = false
        settings.voiceIdentifier = "com.apple.voice.premium.de-DE.Anna"
        let reloaded = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        XCTAssertFalse(reloaded.speechEnabled)
        XCTAssertEqual(reloaded.voiceIdentifier, "com.apple.voice.premium.de-DE.Anna")
        UserDefaults().removePersistentDomain(forName: suite)
    }
}
