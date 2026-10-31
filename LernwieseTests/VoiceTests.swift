import XCTest
@testable import Lernwiese

final class VoiceTests: XCTestCase {
    private func voice(_ name: String, _ language: String = "de-DE", quality: Int = 1, female: Bool = true,
                       excluded: Bool = false) -> VoiceCandidate {
        VoiceCandidate(identifier: "id.\(name).\(language).\(quality)", name: name, language: language,
                       quality: quality, isFemale: female, isExcluded: excluded)
    }

    func testPremiumBeatsEnhancedBeatsStandard() {
        let voices = [voice("Anna"), voice("Markus", quality: 2, female: false), voice("Petra", quality: 3)]
        XCTAssertEqual(VoiceChooser.best(from: voices)?.name, "Petra")
        XCTAssertEqual(VoiceChooser.ranked(voices).map(\.name), ["Petra", "Markus", "Anna"])
    }

    func testPrefersGermanyThenFemaleThenFriendlyNames() {
        XCTAssertEqual(VoiceChooser.best(from: [voice("Leni", "de-AT"), voice("Anna")])?.name, "Anna")
        XCTAssertEqual(VoiceChooser.best(from: [voice("Markus", female: false), voice("Helena")])?.name, "Helena")
        XCTAssertEqual(VoiceChooser.best(from: [voice("Zora"), voice("Anna")])?.name, "Anna")
    }

    func testRoboticAndForeignVoicesAreNeverUsed() {
        let voices = [voice("Sandy", quality: 3, excluded: true), voice("Samantha", "en-US", quality: 3), voice("Anna")]
        XCTAssertEqual(VoiceChooser.ranked(voices).map(\.name), ["Anna"])
        XCTAssertNil(VoiceChooser.best(from: [voice("Samantha", "en-US")]))
    }

    func testTipOnlyWhenNoBetterVoiceIsInstalled() {
        XCTAssertTrue(VoiceChooser.onlyStandardVoices(in: [voice("Anna")]))
        XCTAssertTrue(VoiceChooser.onlyStandardVoices(in: []))
        XCTAssertFalse(VoiceChooser.onlyStandardVoices(in: [voice("Anna"), voice("Petra", quality: 2)]))
    }

    func testLabels() {
        XCTAssertEqual(voice("Anna", quality: 3).label, "Anna – Premium")
        XCTAssertEqual(voice("Leni", "de-AT", quality: 2).label, "Leni (Österreich) – Erweitert")
        XCTAssertEqual(voice("Jan", "de-CH").label, "Jan (Schweiz) – Standard")
    }

    func testTextIsSplitIntoSentencesForNaturalPauses() {
        XCTAssertEqual(SpeechStyle.sentences("Super! Das sind 3 Enten."), ["Super!", "Das sind 3 Enten."])
        XCTAssertEqual(SpeechStyle.sentences("Hier sind 5 Enten. 2 Enten watscheln weg. Wie viele bleiben übrig?"),
                       ["Hier sind 5 Enten.", "2 Enten watscheln weg.", "Wie viele bleiben übrig?"])
        XCTAssertEqual(SpeechStyle.sentences("7"), ["7"])
        XCTAssertEqual(SpeechStyle.sentences("Wie heißt das Baby vom Frosch? Kalb, Kaulquappe oder Lamm?"),
                       ["Wie heißt das Baby vom Frosch?", "Kalb, Kaulquappe oder Lamm?"])
        XCTAssertTrue(SpeechStyle.sentences("").isEmpty)
    }

    func testEveryRoundSoundsCalm() {
        XCTAssertEqual(SpeechStyle.pitch, 1.0)
        XCTAssertLessThan(SpeechStyle.normalRate, 1.0)
        XCTAssertLessThan(SpeechStyle.slowRate, SpeechStyle.normalRate)
        for game in GameID.allCases where !game.isMemory {
            var rng = SeededGenerator(seed: 5)
            for round in RoundFactory.rounds(for: game, level: 2, using: &rng) {
                XCTAssertFalse(SpeechStyle.sentences(round.spoken).isEmpty)
                XCTAssertEqual(SpeechStyle.sentences(round.spoken).joined(separator: " "), round.spoken)
            }
        }
    }
}
