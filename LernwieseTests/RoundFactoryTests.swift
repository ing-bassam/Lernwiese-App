import XCTest
@testable import Lernwiese

final class RoundFactoryTests: XCTestCase {
    private let questionGames = GameID.allCases.filter { !$0.isMemory }

    private func rounds(_ game: GameID, level: Int, seed: UInt64) -> [Round] {
        var rng = SeededGenerator(seed: seed)
        return RoundFactory.rounds(for: game, level: level, using: &rng)
    }

    func testEveryGameHasFiveValidRoundsOnEveryLevel() {
        for game in questionGames {
            for level in 0...2 {
                for seed in 1...200 {
                    let rounds = rounds(game, level: level, seed: UInt64(seed))
                    XCTAssertEqual(rounds.count, RoundFactory.roundsPerGame, "\(game) level \(level)")
                    for round in rounds {
                        XCTAssertTrue(round.choices.indices.contains(round.answer), "\(game): answer out of range")
                        XCTAssertEqual(Set(round.choices).count, round.choices.count, "\(game): duplicate answers")
                        XCTAssertGreaterThanOrEqual(round.choices.count, 2)
                        XCTAssertFalse(round.prompt.isEmpty)
                        XCTAssertFalse(round.spoken.isEmpty)
                        XCTAssertFalse(round.fact.isEmpty)
                    }
                    XCTAssertEqual(Set(rounds.map(\.id)).count, rounds.count)
                }
            }
        }
    }

    func testDifficultyAddsAnswers() {
        for game in [GameID.counting, .arithmetic, .habitat, .babies, .seasons, .weather, .growth] {
            for level in 0...2 {
                for round in rounds(game, level: level, seed: 7) {
                    XCTAssertEqual(round.choices.count, level + 2, "\(game) level \(level)")
                }
            }
        }
    }

    func testSameSeedGivesSameRounds() {
        for game in questionGames {
            XCTAssertEqual(rounds(game, level: 1, seed: 42), rounds(game, level: 1, seed: 42))
        }
    }

    func testCountingAnswerMatchesPicture() {
        let ranges = [1...5, 3...8, 5...10]
        for level in 0...2 {
            for seed in 1...300 {
                for round in rounds(.counting, level: level, seed: UInt64(seed)) {
                    guard case .count(_, _, let number) = round.stage else { return XCTFail("missing count stage") }
                    XCTAssertTrue(ranges[level].contains(number))
                    XCTAssertEqual(round.choices[round.answer], .number(number))
                    let numbers = round.choices.compactMap { choice -> Int? in
                        if case .number(let value) = choice { return value }
                        return nil
                    }
                    XCTAssertEqual(numbers, numbers.sorted(), "numbers are shown in order")
                }
            }
        }
    }

    func testRightNumberIsNotAlwaysInTheSamePlace() {
        var places = Set<Int>()
        for seed in 1...100 {
            for round in rounds(.counting, level: 2, seed: UInt64(seed)) {
                places.insert(round.answer)
            }
        }
        XCTAssertEqual(places, [0, 1, 2, 3])
    }

    func testCompareAnswerHasMoreOrFewer() {
        for level in 0...2 {
            for seed in 1...300 {
                for round in rounds(.compare, level: level, seed: UInt64(seed)) {
                    let counts = round.choices.compactMap { choice -> Int? in
                        if case .group(_, _, let count) = choice { return count }
                        return nil
                    }
                    XCTAssertEqual(counts.count, 2)
                    XCTAssertNotEqual(counts[0], counts[1])
                    let expected = round.prompt.contains("weniger") ? counts.min() : counts.max()
                    XCTAssertEqual(counts[round.answer], expected)
                    if level == 0 {
                        XCTAssertTrue(round.prompt.contains("mehr"), "the youngest only get 'more' questions")
                    }
                }
            }
        }
    }

    func testArithmeticResultsStayBetweenZeroAndTen() {
        for level in 0...2 {
            for seed in 1...300 {
                for round in rounds(.arithmetic, level: level, seed: UInt64(seed)) {
                    guard case .equation(_, let first, let second, let isPlus) = round.stage else {
                        return XCTFail("missing equation")
                    }
                    let result = isPlus ? first + second : first - second
                    XCTAssertTrue((1...10).contains(result))
                    XCTAssertGreaterThan(second, 0)
                    XCTAssertEqual(round.choices[round.answer], .number(result))
                    if level == 0 {
                        XCTAssertTrue(isPlus)
                        XCTAssertLessThanOrEqual(result, 5)
                    }
                }
            }
        }
    }

    func testArithmeticTextUsesSingularForOne() {
        for seed in 1...300 {
            for round in rounds(.arithmetic, level: 2, seed: UInt64(seed)) {
                XCTAssertFalse(round.spoken.contains(" 1 "), round.spoken)
                XCTAssertFalse(round.spoken.hasPrefix("1 "), round.spoken)
            }
        }
    }

    func testHabitatNeverOffersTwoHomesThatCouldBothBeRight() {
        for seed in 1...300 {
            for round in rounds(.habitat, level: 2, seed: UInt64(seed)) {
                let names = round.choices.map(\.spokenName)
                guard case .picture(let correct) = round.choices[round.answer] else { return XCTFail() }
                if correct.name == "Dschungel" { XCTAssertFalse(names.contains("Savanne")) }
                if correct.name == "Savanne" { XCTAssertFalse(names.contains("Dschungel")) }
                guard case .item(let animal) = round.stage else { return XCTFail() }
                let expected = Content.animals.first { $0.picture == animal }?.habitat.picture
                XCTAssertEqual(correct, expected)
            }
        }
    }

    func testWeatherWrongAnswersComeFromOppositeWeather() {
        let houseName = "Ins Haus"
        for seed in 1...300 {
            for round in rounds(.weather, level: 2, seed: UInt64(seed)) {
                guard case .item(let weatherPicture) = round.stage,
                      let weather = Content.weathers.first(where: { $0.picture == weatherPicture }) else {
                    return XCTFail("missing weather")
                }
                for (index, choice) in round.choices.enumerated() where index != round.answer {
                    XCTAssertNotEqual(choice.spokenName, houseName)
                    guard case .picture(let picture) = choice else { return XCTFail() }
                    let source = Content.weathers.first { $0.items.contains { $0.picture == picture } }
                    XCTAssertEqual(source?.isSunny, !weather.isSunny)
                }
            }
        }
    }

    func testSequenceAnswerIsTheMissingStep() {
        for level in 0...2 {
            for seed in 1...300 {
                for round in rounds(.growth, level: level, seed: UInt64(seed)) {
                    guard case .sequence(let steps, let missing) = round.stage else { return XCTFail() }
                    XCTAssertEqual(round.choices[round.answer], .picture(steps[missing]))
                    if level == 0 { XCTAssertEqual(missing, steps.count - 1) }
                    if level == 1 { XCTAssertGreaterThan(missing, 0) }
                    let shown = Set(steps.map(\.emoji))
                    for (index, choice) in round.choices.enumerated() where index != round.answer {
                        guard case .picture(let picture) = choice else { return XCTFail() }
                        XCTAssertFalse(shown.contains(picture.emoji), "a wrong answer must not be part of the row")
                    }
                }
            }
        }
    }

    func testFruitBoxesNeverShowTheAskedItem() {
        for seed in 1...300 {
            for round in rounds(.fruitVeg, level: 2, seed: UInt64(seed)) {
                guard case .item(let item) = round.stage else { return XCTFail() }
                for choice in round.choices {
                    guard case .bin(_, let examples, _) = choice else { return XCTFail() }
                    XCTAssertEqual(examples.count, 3)
                    XCTAssertFalse(examples.contains(item.emoji))
                }
                let produce = Content.produce.first { $0.picture == item }
                XCTAssertEqual(round.answer, produce?.isFruit == true ? 0 : 1)
            }
        }
    }

    func testSeasonBoxesKeepTheOrderOfTheYear() {
        for seed in 1...200 {
            for round in rounds(.seasons, level: 1, seed: UInt64(seed)) {
                let order = round.choices.compactMap { choice in Content.seasons.firstIndex { $0.name == choice.spokenName } }
                XCTAssertEqual(order, order.sorted())
                guard case .item(let picture) = round.stage,
                      let item = Content.seasonItems.first(where: { $0.picture == picture }) else { return XCTFail() }
                XCTAssertEqual(round.choices[round.answer].spokenName, Content.seasons[item.season].name)
            }
        }
    }

    func testBabyQuestionReadsAllAnswersAloud() {
        for round in rounds(.babies, level: 2, seed: 3) {
            for choice in round.choices {
                XCTAssertTrue(round.spoken.contains(choice.spokenName))
            }
        }
    }

    func testSpokenList() {
        XCTAssertEqual(RoundFactory.spokenList(["Kalb"]), "Kalb")
        XCTAssertEqual(RoundFactory.spokenList(["Kalb", "Lamm"]), "Kalb oder Lamm")
        XCTAssertEqual(RoundFactory.spokenList(["Kalb", "Lamm", "Ferkel"]), "Kalb, Lamm oder Ferkel")
    }

    func testNumberOptionsStayInRange() {
        var rng = SeededGenerator(seed: 1)
        for correct in 0...10 {
            for count in 2...4 {
                let options = RoundFactory.numberOptions(around: correct, count: count, in: 0...10, using: &rng)
                XCTAssertEqual(options.count, count)
                XCTAssertTrue(options.contains(correct))
                XCTAssertTrue(options.allSatisfy { (0...10).contains($0) })
            }
        }
    }
}
