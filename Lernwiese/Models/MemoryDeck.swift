import Foundation

struct MemoryCard: Identifiable, Equatable {
    let id: Int
    let pairID: Int
    let picture: Picture
    let isAnimal: Bool
    var isFaceUp = false
    var isMatched = false
}

/// "Futter-Paare": find each animal and its food. Unlike classic pairs games the two cards of a pair
/// show different pictures, so children have to know which food belongs to which animal.
struct MemoryDeck {
    enum FlipResult: Equatable {
        case ignored
        case first
        case match(pairID: Int)
        case mismatch
    }

    private(set) var cards: [MemoryCard]
    /// Facts read aloud after a match, indexed by `pairID`.
    let facts: [String]
    private var waitingIndex: Int?

    init(cards: [MemoryCard], facts: [String]) {
        self.cards = cards
        self.facts = facts
    }

    static func pairCount(level: Int) -> Int {
        [3, 4, 6][max(0, min(level, 2))]
    }

    static func make<R: RandomNumberGenerator>(pairs: Int, using rng: inout R) -> MemoryDeck {
        let chosen = Array(Content.foodPairs.shuffled(using: &rng).prefix(pairs))
        var cards: [MemoryCard] = []
        for (pairID, pair) in chosen.enumerated() {
            cards.append(MemoryCard(id: pairID * 2, pairID: pairID, picture: pair.animal, isAnimal: true))
            cards.append(MemoryCard(id: pairID * 2 + 1, pairID: pairID, picture: pair.food, isAnimal: false))
        }
        cards.shuffle(using: &rng)
        return MemoryDeck(cards: cards, facts: chosen.map(\.fact))
    }

    var pairCount: Int { facts.count }

    var matchedPairs: Int { cards.filter(\.isMatched).count / 2 }

    var isComplete: Bool { !cards.isEmpty && cards.allSatisfy(\.isMatched) }

    /// Two open cards that do not belong together are still showing.
    var hasOpenMismatch: Bool {
        cards.filter { $0.isFaceUp && !$0.isMatched }.count >= 2
    }

    mutating func flip(at index: Int) -> FlipResult {
        guard cards.indices.contains(index) else { return .ignored }
        if hasOpenMismatch {
            hideMismatched()
        }
        guard !cards[index].isFaceUp, !cards[index].isMatched else { return .ignored }
        cards[index].isFaceUp = true

        guard let waiting = waitingIndex else {
            waitingIndex = index
            return .first
        }
        waitingIndex = nil
        if cards[waiting].pairID == cards[index].pairID {
            cards[waiting].isMatched = true
            cards[index].isMatched = true
            return .match(pairID: cards[index].pairID)
        }
        return .mismatch
    }

    /// Turns two open cards that do not belong together face down again.
    mutating func hideMismatched() {
        guard hasOpenMismatch else { return }
        for index in cards.indices where cards[index].isFaceUp && !cards[index].isMatched {
            cards[index].isFaceUp = false
        }
        waitingIndex = nil
    }

    /// Screenshot state: one pair found and one more card open.
    mutating func revealForDemo() {
        guard let first = cards.indices.first,
              let partner = cards.indices.first(where: { $0 != first && cards[$0].pairID == cards[first].pairID })
        else { return }
        _ = flip(at: first)
        _ = flip(at: partner)
        if let open = cards.indices.first(where: { !cards[$0].isMatched && cards[$0].isAnimal }) {
            _ = flip(at: open)
        }
    }
}
