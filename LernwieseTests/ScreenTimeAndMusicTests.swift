import XCTest
@testable import Lernwiese

final class ScreenTimeTests: XCTestCase {
    private func freshDefaults() -> UserDefaults {
        let name = "ScreenTimeTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testRecommendationFollowsTheGuideline() {
        XCTAssertEqual(ScreenTime.recommendedMinutes(age: 4), 30)
        XCTAssertEqual(ScreenTime.recommendedMinutes(age: 5), 30)
        XCTAssertEqual(ScreenTime.recommendedMinutes(age: 6), 45)
        XCTAssertEqual(ScreenTime.recommendedMinutes(age: 8), 45)
        XCTAssertEqual(ScreenTime.limit(choice: ScreenTime.automatic, age: 5), 30)
        XCTAssertEqual(ScreenTime.limit(choice: 20, age: 5), 20)
        XCTAssertNil(ScreenTime.limit(choice: ScreenTime.off, age: 5))
    }

    func testStatusWarnsThenStops() {
        XCTAssertEqual(ScreenTime.status(playedSeconds: 0, limitMinutes: 30, extraMinutes: 0), .free)
        XCTAssertEqual(ScreenTime.status(playedSeconds: 24 * 60, limitMinutes: 30, extraMinutes: 0), .free)
        XCTAssertEqual(ScreenTime.status(playedSeconds: 25 * 60, limitMinutes: 30, extraMinutes: 0), .almost(minutesLeft: 5))
        XCTAssertEqual(ScreenTime.status(playedSeconds: 29 * 60 + 30, limitMinutes: 30, extraMinutes: 0), .almost(minutesLeft: 1))
        XCTAssertEqual(ScreenTime.status(playedSeconds: 30 * 60, limitMinutes: 30, extraMinutes: 0), .over)
        XCTAssertEqual(ScreenTime.status(playedSeconds: 30 * 60, limitMinutes: 30, extraMinutes: 15), .free)
        XCTAssertEqual(ScreenTime.status(playedSeconds: 999 * 60, limitMinutes: nil, extraMinutes: 0), .free)
    }

    func testStoreCountsPerDayAndKeepsAMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        var date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 9))!
        let defaults = freshDefaults()
        let store = PlayTimeStore(defaults: defaults, calendar: calendar, now: { date })
        store.add(seconds: 600)
        XCTAssertEqual(store.todaySeconds, 600)
        date = calendar.date(byAdding: .day, value: 1, to: date)!
        XCTAssertEqual(store.todaySeconds, 0)
        store.add(seconds: 120)
        let history = store.history(days: 7)
        XCTAssertEqual(history.count, 7)
        XCTAssertEqual(history.last?.minutes, 2)
        XCTAssertEqual(history[history.count - 2].minutes, 10)

        store.allowExtraTime()
        XCTAssertEqual(store.todayExtraMinutes, ScreenTime.extraMinutes)
        store.save()
        let reloaded = PlayTimeStore(defaults: defaults, calendar: calendar, now: { date })
        XCTAssertEqual(reloaded.todaySeconds, 120)
        XCTAssertEqual(reloaded.todayExtraMinutes, ScreenTime.extraMinutes)

        date = calendar.date(byAdding: .day, value: 40, to: date)!
        reloaded.add(seconds: 1)
        reloaded.save()
        XCTAssertEqual(reloaded.secondsByDay.count, 1, "old days are removed")
    }

    func testSettingsDefaults() {
        let settings = AppSettings(defaults: freshDefaults())
        XCTAssertTrue(settings.musicEnabled)
        XCTAssertEqual(settings.timeLimitMinutes, ScreenTime.automatic)
        XCTAssertEqual(settings.dailyLimitMinutes, 30)
        settings.childAge = 7
        XCTAssertEqual(settings.dailyLimitMinutes, 45)
        XCTAssertTrue(settings.isVisible(.echo))
        settings.setVisible(false, .echo)
        XCTAssertFalse(settings.isVisible(.echo))
    }

    func testBreakIdeasAreShortAndOffScreen() {
        XCTAssertGreaterThanOrEqual(ScreenTime.breakIdeas.count, 8)
        for idea in ScreenTime.breakIdeas {
            XCTAssertLessThan(idea.text.count, 90)
            XCTAssertTrue(idea.text.hasSuffix(".") || idea.text.hasSuffix("?"))
        }
    }
}

final class MusicTests: XCTestCase {
    func testNoteNames() {
        XCTAssertEqual(Track.midi("C4"), 60)
        XCTAssertEqual(Track.midi("A4"), 69)
        XCTAssertEqual(Track.midi("F#3"), 54)
        XCTAssertEqual(Track.midi("Bb2"), 46)
        XCTAssertNil(Track.midi("r"))
        XCTAssertEqual(Synth.frequency(of: 69), 440, accuracy: 0.001)
    }

    func testSongsAreCalmAndLoopCleanly() {
        for song in Songs.all {
            XCTAssertLessThanOrEqual(song.tempo, 80, song.title)
            XCTAssertFalse(song.events.isEmpty)
            for event in song.events {
                XCTAssertTrue((36...88).contains(event.pitch), "\(song.title): note \(event.pitch) out of the calm range")
                XCTAssertLessThanOrEqual(event.volume, 0.6)
            }
        }
    }

    func testAllTracksOfASongHaveTheSameLength() {
        XCTAssertEqual(Track(notes: "C4:1 | r:0.5 E4:2.5", instrument: .pad, volume: 1).beats, 4)
        XCTAssertEqual(Songs.meadow.beats, 64)
        XCTAssertEqual(Songs.play.beats, 32)
        XCTAssertEqual(Songs.lullaby.beats, 24)
        for song in Songs.all {
            let ends = song.events.map { $0.start + $0.length }
            XCTAssertEqual(ends.max() ?? 0, song.beats, accuracy: 0.001, song.title)
        }
    }

    func testRenderingIsQuietAndHasTheRightLength() {
        let samples = Synth.render(Songs.play, looping: true)
        XCTAssertEqual(Double(samples.count), Songs.play.seconds * Synth.sampleRate, accuracy: 2)
        let peak = samples.reduce(0) { max($0, abs($1)) }
        XCTAssertGreaterThan(peak, 0.1)
        XCTAssertLessThanOrEqual(peak, 0.81)
        let sound = Synth.render(Songs.correct, looping: false)
        XCTAssertGreaterThan(sound.count, Int(Synth.sampleRate))
        XCTAssertEqual(sound.last ?? 1, 0, accuracy: 0.001, "short sounds fade out")
    }

    func testFlowerTonesAreDifferent() {
        XCTAssertEqual(Set(Songs.flowerPitches).count, EchoPlan.flowerCount)
    }
}
