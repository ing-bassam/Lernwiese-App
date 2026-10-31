import XCTest
@testable import Lernwiese

final class MemoryDeckTests: XCTestCase {
    private func deck(pairs: Int = 3, seed: UInt64 = 1) -> MemoryDeck {
        var rng = SeededGenerator(seed: seed)
        return MemoryDeck.make(pairs: pairs, using: &rng)
    }

    private func partner(of index: Int, in deck: MemoryDeck) -> Int {
        deck.cards.indices.first { $0 != index && deck.cards[$0].pairID == deck.cards[index].pairID }!
    }

    private func stranger(of index: Int, in deck: MemoryDeck) -> Int {
        deck.cards.indices.first { deck.cards[$0].pairID != deck.cards[index].pairID }!
    }

    func testDeckHasOneAnimalAndOneFoodPerPair() {
        for level in 0...2 {
            let pairs = MemoryDeck.pairCount(level: level)
            let deck = deck(pairs: pairs)
            XCTAssertEqual(deck.cards.count, pairs * 2)
            XCTAssertEqual(deck.pairCount, pairs)
            for pairID in 0..<pairs {
                let cards = deck.cards.filter { $0.pairID == pairID }
                XCTAssertEqual(cards.count, 2)
                XCTAssertEqual(cards.filter(\.isAnimal).count, 1)
            }
            XCTAssertTrue(deck.cards.allSatisfy { !$0.isFaceUp && !$0.isMatched })
        }
    }

    func testMatchingPairStaysOpen() {
        var deck = deck()
        let other = partner(of: 0, in: deck)
        XCTAssertEqual(deck.flip(at: 0), .first)
        XCTAssertEqual(deck.flip(at: other), .match(pairID: deck.cards[0].pairID))
        XCTAssertTrue(deck.cards[0].isMatched)
        XCTAssertTrue(deck.cards[other].isMatched)
        XCTAssertEqual(deck.matchedPairs, 1)
        XCTAssertFalse(deck.hasOpenMismatch)
    }

    func testMismatchTurnsBackWithoutPenalty() {
        var deck = deck()
        let other = stranger(of: 0, in: deck)
        XCTAssertEqual(deck.flip(at: 0), .first)
        XCTAssertEqual(deck.flip(at: other), .mismatch)
        XCTAssertTrue(deck.hasOpenMismatch)
        deck.hideMismatched()
        XCTAssertFalse(deck.cards[0].isFaceUp)
        XCTAssertFalse(deck.cards[other].isFaceUp)
        XCTAssertEqual(deck.matchedPairs, 0)
    }

    func testTappingDuringMismatchStartsNewTurn() {
        var deck = deck()
        let other = stranger(of: 0, in: deck)
        _ = deck.flip(at: 0)
        _ = deck.flip(at: other)
        let third = deck.cards.indices.first { $0 != 0 && $0 != other }!
        XCTAssertEqual(deck.flip(at: third), .first)
        XCTAssertFalse(deck.cards[0].isFaceUp)
        XCTAssertFalse(deck.cards[other].isFaceUp)
        XCTAssertTrue(deck.cards[third].isFaceUp)
    }

    func testTappingOpenCardIsIgnored() {
        var deck = deck()
        _ = deck.flip(at: 0)
        XCTAssertEqual(deck.flip(at: 0), .ignored)
        XCTAssertEqual(deck.flip(at: 99), .ignored)
    }

    func testFindingAllPairsCompletesTheGame() {
        var deck = deck(pairs: 4)
        for pairID in 0..<4 {
            let indices = deck.cards.indices.filter { deck.cards[$0].pairID == pairID }
            _ = deck.flip(at: indices[0])
            XCTAssertEqual(deck.flip(at: indices[1]), .match(pairID: pairID))
        }
        XCTAssertTrue(deck.isComplete)
        XCTAssertEqual(deck.matchedPairs, 4)
    }

    func testDemoStateShowsOnePairAndOneOpenCard() {
        var deck = deck(pairs: 4)
        deck.revealForDemo()
        XCTAssertEqual(deck.matchedPairs, 1)
        XCTAssertEqual(deck.cards.filter { $0.isFaceUp && !$0.isMatched }.count, 1)
    }
}
