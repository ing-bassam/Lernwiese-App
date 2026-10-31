import XCTest
@testable import Lernwiese

/// Guards against ambiguous or broken learning content.
final class ContentTests: XCTestCase {
    func testEveryWorldHasGames() {
        for world in World.allCases {
            XCTAssertFalse(world.games.isEmpty)
        }
        XCTAssertEqual(GameID.allCases.count, 10)
    }

    func testAnimalsAreUnique() {
        let emoji = Content.animals.map(\.picture.emoji)
        XCTAssertEqual(Set(emoji).count, emoji.count)
        for habitat in Content.habitats {
            XCTAssertTrue(Content.animals.contains { $0.habitat == habitat }, "\(habitat.id) has no animal")
        }
    }

    func testFoodPairsAreUnambiguous() {
        let animals = Content.foodPairs.map(\.animal.emoji)
        let foods = Content.foodPairs.map(\.food.emoji)
        XCTAssertEqual(Set(animals).count, animals.count)
        XCTAssertEqual(Set(foods).count, foods.count)
        XCTAssertTrue(Set(animals).isDisjoint(with: foods), "a card must be clearly animal or food")
        XCTAssertGreaterThanOrEqual(Content.foodPairs.count, MemoryDeck.pairCount(level: 2))
    }

    func testBabyNamesAreUnique() {
        let names = Content.babies.map(\.baby)
        XCTAssertEqual(Set(names).count, names.count)
        XCTAssertGreaterThanOrEqual(names.count, 4)
    }

    func testSeasonItemsNeverRepeatTheBoxIcons() {
        let icons = Set(Content.seasons.map(\.icon))
        for item in Content.seasonItems {
            XCTAssertFalse(icons.contains(item.picture.emoji), item.picture.name)
            XCTAssertTrue(Content.seasons.indices.contains(item.season))
            XCTAssertTrue(item.fact.contains(Content.seasons[item.season].name), item.fact)
        }
        for season in Content.seasons {
            XCTAssertGreaterThanOrEqual(Content.seasonItems.filter { $0.season == season.id }.count, 4)
        }
    }

    func testWeatherHasEnoughClearWrongAnswers() {
        for weather in Content.weathers {
            let wrong = Content.weathers
                .filter { $0.isSunny != weather.isSunny }
                .flatMap { $0.items.filter(\.canBeWrongAnswer) }
            XCTAssertGreaterThanOrEqual(wrong.count, 3, weather.picture.name)
        }
    }

    func testProduceIsSortedCorrectly() {
        let fruit = Content.produce.filter(\.isFruit)
        let vegetables = Content.produce.filter { !$0.isFruit }
        XCTAssertTrue(fruit.allSatisfy { $0.fact.contains("Obst") })
        XCTAssertTrue(vegetables.allSatisfy { $0.fact.contains("Gemüse") })
        XCTAssertGreaterThanOrEqual(fruit.filter(\.isCommon).count, 4)
        XCTAssertGreaterThanOrEqual(vegetables.filter(\.isCommon).count, 4)
        let emoji = Content.produce.map(\.picture.emoji)
        XCTAssertEqual(Set(emoji).count, emoji.count)
    }

    func testGrowthSequencesHaveEnoughWrongAnswers() {
        for sequence in Content.growth {
            XCTAssertGreaterThanOrEqual(sequence.steps.count, 3)
            XCTAssertGreaterThanOrEqual(sequence.wrong.count, 3)
            let steps = Set(sequence.steps.map(\.emoji))
            XCTAssertTrue(sequence.wrong.allSatisfy { !steps.contains($0.emoji) })
            XCTAssertEqual(Set(sequence.wrong.map(\.emoji)).count, sequence.wrong.count)
        }
        XCTAssertGreaterThanOrEqual(Content.growth.count, RoundFactory.roundsPerGame)
    }

    func testCountablesHaveGrammarForOne() {
        for thing in Content.countables {
            XCTAssertTrue(thing.one.hasPrefix("ein"), thing.one)
            XCTAssertEqual(thing.amount(1), thing.one)
            XCTAssertEqual(thing.amount(3), "3 \(thing.plural)")
            XCTAssertEqual(thing.here(1), "Hier ist \(thing.one)")
        }
    }
}
