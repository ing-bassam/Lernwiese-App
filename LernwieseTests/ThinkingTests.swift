import XCTest
@testable import Lernwiese

/// The "Knobeln" world: every task must have exactly one sensible answer.
final class ThinkingTests: XCTestCase {
    private func rounds(_ game: GameID, level: Int, seed: UInt64) -> [Round] {
        var rng = SeededGenerator(seed: seed)
        return RoundFactory.rounds(for: game, level: level, using: &rng)
    }

    func testPatternAnswerContinuesThePattern() {
        for level in 0...2 {
            for seed in 1...300 {
                for round in rounds(.patterns, level: level, seed: UInt64(seed)) {
                    guard case .pattern(let shown) = round.stage else { return XCTFail("missing pattern stage") }
                    XCTAssertLessThanOrEqual(shown.count, 6)
                    guard case .picture(let answer) = round.choices[round.answer] else { return XCTFail("no picture") }
                    // Some unit length explains everything shown and predicts the answer.
                    let full = shown + [answer]
                    let fits = (2...4).contains { unit in
                        unit < shown.count && full.indices.allSatisfy { full[$0] == full[$0 % unit] }
                    }
                    XCTAssertTrue(fits, "\(shown.map(\.name)) -> \(answer.name)")
                    // No wrong answer would continue the pattern as well.
                    for (index, choice) in round.choices.enumerated() where index != round.answer {
                        guard case .picture(let wrong) = choice else { continue }
                        let other = shown + [wrong]
                        let alsoFits = (2...4).contains { unit in
                            unit < shown.count && other.indices.allSatisfy { other[$0] == other[$0 % unit] }
                        }
                        XCTAssertFalse(alsoFits)
                    }
                }
            }
        }
    }

    func testShadowAnswerIsTheShadowedThing() {
        for level in 0...2 {
            for seed in 1...200 {
                for round in rounds(.shadows, level: level, seed: UInt64(seed)) {
                    guard case .shadow(let picture) = round.stage else { return XCTFail("missing shadow stage") }
                    XCTAssertEqual(round.choices[round.answer], .picture(picture))
                    XCTAssertEqual(round.choices.count, level + 2)
                }
            }
        }
    }

    func testOddOneIsFromAnotherGroup() {
        for level in 0...2 {
            for seed in 1...300 {
                for round in rounds(.oddOne, level: level, seed: UInt64(seed)) {
                    XCTAssertEqual(round.choices.count, RoundFactory.oddOneCount(level: level))
                    let emoji = round.choices.compactMap { choice -> String? in
                        if case .picture(let picture) = choice { return picture.emoji }
                        return nil
                    }
                    let odd = emoji[round.answer]
                    let rest = emoji.enumerated().filter { $0.offset != round.answer }.map(\.element)
                    let sharedGroup = ThinkingContent.groups.first { group in
                        rest.allSatisfy { item in group.members.contains { $0.emoji == item } }
                    }
                    XCTAssertNotNil(sharedGroup, "the others belong together")
                    XCTAssertFalse(sharedGroup?.members.contains { $0.emoji == odd } ?? true, "the odd one is not in it")
                }
            }
        }
    }

    func testFruitAndVegetablesAreOnlyMixedOnTheHardestLevel() {
        for level in 0...1 {
            for seed in 1...300 {
                for round in rounds(.oddOne, level: level, seed: UInt64(seed)) {
                    let emoji = Set(round.choices.compactMap { choice -> String? in
                        if case .picture(let picture) = choice { return picture.emoji }
                        return nil
                    })
                    let fruit = Set(ThinkingContent.groups.first { $0.id == "fruit" }!.members.map(\.emoji))
                    let vegetables = Set(ThinkingContent.groups.first { $0.id == "vegetables" }!.members.map(\.emoji))
                    XCTAssertFalse(!emoji.isDisjoint(with: fruit) && !emoji.isDisjoint(with: vegetables))
                }
            }
        }
    }

    func testGroupsDoNotOverlap() {
        var seen: [String: String] = [:]
        for group in ThinkingContent.groups {
            XCTAssertGreaterThanOrEqual(group.members.count, 4)
            for member in group.members {
                XCTAssertNil(seen[member.emoji], "\(member.name) is in \(seen[member.emoji] ?? "") and \(group.id)")
                seen[member.emoji] = group.id
            }
        }
    }

    func testShapeRoundUsesEveryOutline() {
        for level in 0...2 {
            for seed in 1...200 {
                var rng = SeededGenerator(seed: UInt64(seed))
                let round = ShapeRound.make(level: level, using: &rng)
                XCTAssertEqual(round.shapes.count, 3 + level)
                XCTAssertEqual(Set(round.items.map(\.shape)), Set(round.shapes))
                XCTAssertEqual(Set(round.items).count, round.items.count)
                XCTAssertGreaterThanOrEqual(round.items.count, RoundFactory.roundsPerGame)
            }
        }
    }

    func testEchoSequencesGrowAndNeverRepeatATone() {
        for level in 0...2 {
            var rng = SeededGenerator(seed: 9)
            let sequences = EchoPlan.sequences(level: level, using: &rng)
            XCTAssertEqual(sequences.map(\.count), EchoPlan.lengths(level: level))
            XCTAssertEqual(EchoPlan.lengths(level: level), EchoPlan.lengths(level: level).sorted())
            for sequence in sequences {
                XCTAssertTrue(sequence.allSatisfy { (0..<EchoPlan.flowerCount).contains($0) })
                XCTAssertFalse(zip(sequence, sequence.dropFirst()).contains { $0 == $1 })
            }
        }
    }
}
