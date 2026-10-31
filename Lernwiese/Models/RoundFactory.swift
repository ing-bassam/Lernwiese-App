import Foundation

/// Builds the rounds of every question game. Level 0 is for the youngest (few answers, small numbers);
/// each star a child earns in a game moves it up one level, up to level 2.
enum RoundFactory {
    static let roundsPerGame = 5
    static let maxLevel = 2

    /// Answers per round: 2, 3 or 4.
    static func choiceCount(level: Int) -> Int {
        clamped(level) + 2
    }

    static func rounds<R: RandomNumberGenerator>(for game: GameID, level: Int, using rng: inout R) -> [Round] {
        let level = clamped(level)
        switch game {
        case .counting: return counting(level: level, using: &rng)
        case .compare: return compare(level: level, using: &rng)
        case .arithmetic: return arithmetic(level: level, using: &rng)
        case .habitat: return habitat(level: level, using: &rng)
        case .babies: return babies(level: level, using: &rng)
        case .seasons: return seasons(level: level, using: &rng)
        case .weather: return weather(level: level, using: &rng)
        case .fruitVeg: return fruitVeg(level: level, using: &rng)
        case .growth: return growth(level: level, using: &rng)
        case .foodPairs: return []
        }
    }

    // MARK: - Zahlen

    static func counting<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let range = [1...5, 3...8, 5...10][level]
        let numbers = distinctNumbers(in: range, count: roundsPerGame, using: &rng)
        let things = Content.countables.shuffled(using: &rng)
        var rounds: [Round] = []
        for index in 0..<roundsPerGame {
            let number = numbers[index]
            let thing = things[index % things.count]
            let options = numberOptions(around: number, count: choiceCount(level: level), in: 1...10, using: &rng)
            rounds.append(Round(
                id: index,
                prompt: "Wie viele?",
                spoken: "Wie viele \(thing.plural) siehst du?",
                stage: .count(thing.picture, plural: thing.plural, number: number),
                choices: options.map { Choice.number($0) },
                answer: options.firstIndex(of: number) ?? 0,
                fact: number == 1 ? "Das ist \(thing.one)." : "Das sind \(number) \(thing.plural)."))
        }
        return rounds
    }

    static func compare<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let range = [1...5, 1...8, 1...10][level]
        let minimumDifference = level == 2 ? 1 : 2
        let things = Content.countables.shuffled(using: &rng)
        var rounds: [Round] = []
        for index in 0..<roundsPerGame {
            let thing = things[index % things.count]
            var first = 0
            var second = 0
            repeat {
                first = Int.random(in: range, using: &rng)
                second = Int.random(in: range, using: &rng)
            } while abs(first - second) < minimumDifference
            let asksFewer: Bool
            switch level {
            case 0: asksFewer = false
            case 1: asksFewer = Int.random(in: 0..<3, using: &rng) == 0
            default: asksFewer = Bool.random(using: &rng)
            }
            let winner = asksFewer ? min(first, second) : max(first, second)
            let loser = asksFewer ? max(first, second) : min(first, second)
            let fact: String
            if asksFewer {
                let here = winner == 1 ? "Hier ist nur \(thing.one)" : "Hier sind nur \(winner) \(thing.plural)"
                fact = "\(here), dort sind es \(loser)."
            } else {
                let there = loser == 1 ? thing.one : "\(loser)"
                fact = "\(thing.here(winner)), dort nur \(there)."
            }
            rounds.append(Round(
                id: index,
                prompt: asksFewer ? "Wo sind weniger?" : "Wo sind mehr?",
                spoken: asksFewer ? "Wo sind weniger \(thing.plural)?" : "Wo sind mehr \(thing.plural)?",
                stage: .none,
                choices: [first, second].map { Choice.group(thing.picture, plural: thing.plural, count: $0) },
                answer: first == winner ? 0 : 1,
                fact: fact))
        }
        return rounds
    }

    static func arithmetic<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let things = Content.countables.shuffled(using: &rng)
        let firstIsPlus = Bool.random(using: &rng)
        var rounds: [Round] = []
        for index in 0..<roundsPerGame {
            let thing = things[index % things.count]
            let isPlus = level == 0 || (index % 2 == 0) == firstIsPlus
            let first: Int
            let second: Int
            let result: Int
            if isPlus {
                let maximum = level == 0 ? 5 : 10
                first = Int.random(in: 1...(maximum - 1), using: &rng)
                second = Int.random(in: 1...(maximum - first), using: &rng)
                result = first + second
            } else {
                first = Int.random(in: 2...10, using: &rng)
                second = Int.random(in: 1...(first - 1), using: &rng)
                result = first - second
            }
            let options = numberOptions(around: result, count: choiceCount(level: level), in: 0...10, using: &rng)
            let spoken: String
            let fact: String
            if isPlus {
                spoken = "\(thing.here(first)). Dazu \(second == 1 ? "kommt" : "kommen") \(thing.amount(second)). Wie viele sind es jetzt?"
                fact = "\(first) plus \(second) gleich \(result)."
            } else {
                let leaves = second == 1 ? thing.leavesOne : thing.leavesMany
                spoken = "\(thing.here(first)). \(thing.amount(second).capitalizedFirst) \(leaves). Wie viele bleiben übrig?"
                fact = "\(first) minus \(second) gleich \(result)."
            }
            rounds.append(Round(
                id: index,
                prompt: isPlus ? "Wie viele sind es zusammen?" : "Wie viele bleiben übrig?",
                spoken: spoken,
                stage: .equation(thing.picture, first: first, second: second, isPlus: isPlus),
                choices: options.map { Choice.number($0) },
                answer: options.firstIndex(of: result) ?? 0,
                fact: fact))
        }
        return rounds
    }

    // MARK: - Tiere

    static func habitat<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let animals = Array(Content.animals.shuffled(using: &rng).prefix(roundsPerGame))
        var rounds: [Round] = []
        for (index, animal) in animals.enumerated() {
            let others = Content.habitats
                .filter { $0 != animal.habitat && !Content.areRelated($0, animal.habitat) }
                .shuffled(using: &rng)
                .prefix(choiceCount(level: level) - 1)
            let arranged = arrange(.picture(animal.habitat.picture), others.map { .picture($0.picture) }, using: &rng)
            rounds.append(Round(
                id: index,
                prompt: "Wo wohnt das Tier?",
                spoken: "Wo wohnt \(animal.subject)?",
                stage: .item(animal.picture),
                choices: arranged.choices,
                answer: arranged.answer,
                fact: "\(animal.subject.capitalizedFirst) wohnt \(animal.habitat.phrase)."))
        }
        return rounds
    }

    static func babies<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let picked = Array(Content.babies.shuffled(using: &rng).prefix(roundsPerGame))
        var rounds: [Round] = []
        for (index, baby) in picked.enumerated() {
            let others = Content.babies
                .filter { $0.baby != baby.baby }
                .shuffled(using: &rng)
                .prefix(choiceCount(level: level) - 1)
            let arranged = arrange(.word(baby.baby), others.map { .word($0.baby) }, using: &rng)
            let names = arranged.choices.map(\.spokenName)
            rounds.append(Round(
                id: index,
                prompt: "Wie heißt das Baby?",
                spoken: "Wie heißt das Baby \(baby.ofParent)? \(spokenList(names))?",
                stage: .item(baby.parent),
                choices: arranged.choices,
                answer: arranged.answer,
                fact: "Das Baby \(baby.ofParent) heißt \(baby.baby)."))
        }
        return rounds
    }

    // MARK: - Natur

    static func seasons<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let items = Array(Content.seasonItems.shuffled(using: &rng).prefix(roundsPerGame))
        var rounds: [Round] = []
        for (index, item) in items.enumerated() {
            let others = Content.seasons
                .filter { $0.id != item.season }
                .shuffled(using: &rng)
                .prefix(choiceCount(level: level) - 1)
            // The boxes always keep the order of the year.
            let shown = (Array(others) + Content.seasons.filter { $0.id == item.season }).sorted { $0.id < $1.id }
            rounds.append(Round(
                id: index,
                prompt: "Welche Jahreszeit?",
                spoken: "\(item.subject.capitalizedFirst). Zu welcher Jahreszeit passt das?",
                stage: .item(item.picture),
                choices: shown.map { .bin(title: $0.name, examples: [$0.icon], tint: $0.tint) },
                answer: shown.firstIndex { $0.id == item.season } ?? 0,
                fact: item.fact))
        }
        return rounds
    }

    static func weather<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        // Every kind of weather once, then one more round with a different item.
        var pairs: [(weather: Weather, item: WeatherItem)] = []
        var rest: [(weather: Weather, item: WeatherItem)] = []
        for weather in Content.weathers {
            let items = weather.items.shuffled(using: &rng)
            pairs.append((weather, items[0]))
            rest += items.dropFirst().map { (weather: weather, item: $0) }
        }
        pairs.shuffle(using: &rng)
        pairs += rest.shuffled(using: &rng)
        var rounds: [Round] = []
        for (index, pair) in pairs.prefix(roundsPerGame).enumerated() {
            // Wrong answers always come from the opposite kind of weather, so they are clearly wrong.
            let wrong = Content.weathers
                .filter { $0.isSunny != pair.weather.isSunny }
                .flatMap { $0.items.filter(\.canBeWrongAnswer) }
                .shuffled(using: &rng)
                .prefix(choiceCount(level: level) - 1)
            let arranged = arrange(.picture(pair.item.picture), wrong.map { .picture($0.picture) }, using: &rng)
            rounds.append(Round(
                id: index,
                prompt: "Was passt zum Wetter?",
                spoken: "\(pair.weather.sentence) Was passt dazu?",
                stage: .item(pair.weather.picture),
                choices: arranged.choices,
                answer: arranged.answer,
                fact: pair.item.fact))
        }
        return rounds
    }

    static func fruitVeg<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let pool = level == 0 ? Content.produce.filter(\.isCommon) : Content.produce
        let fruitCount = Int.random(in: 2...3, using: &rng)
        let fruits = pool.filter(\.isFruit).shuffled(using: &rng).prefix(fruitCount)
        let vegetables = pool.filter { !$0.isFruit }.shuffled(using: &rng).prefix(roundsPerGame - fruitCount)
        let items = (Array(fruits) + Array(vegetables)).shuffled(using: &rng)
        var rounds: [Round] = []
        for (index, item) in items.enumerated() {
            rounds.append(Round(
                id: index,
                prompt: "Obst oder Gemüse?",
                spoken: "\(item.subject.capitalizedFirst). Ist das Obst oder Gemüse?",
                stage: .item(item.picture),
                choices: [
                    .bin(title: "Obst", examples: examples(fruit: true, except: item), tint: .red),
                    .bin(title: "Gemüse", examples: examples(fruit: false, except: item), tint: .green),
                ],
                answer: item.isFruit ? 0 : 1,
                fact: item.fact))
        }
        return rounds
    }

    /// Three typical items drawn on a box – never the item that is being asked for.
    static func examples(fruit: Bool, except item: Produce) -> [String] {
        Content.produce
            .filter { $0.isFruit == fruit && $0.picture != item.picture }
            .prefix(3)
            .map(\.picture.emoji)
    }

    static func growth<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let sequences = Array(Content.growth.shuffled(using: &rng).prefix(roundsPerGame))
        var rounds: [Round] = []
        for (index, sequence) in sequences.enumerated() {
            let last = sequence.steps.count - 1
            let missing: Int
            switch level {
            case 0: missing = last
            case 1: missing = Int.random(in: 1...last, using: &rng)
            default: missing = Int.random(in: 0...last, using: &rng)
            }
            let wrong = sequence.wrong.shuffled(using: &rng).prefix(choiceCount(level: level) - 1)
            let arranged = arrange(.picture(sequence.steps[missing]), wrong.map { .picture($0) }, using: &rng)
            let question = missing == last ? "Was kommt danach?" : "Was fehlt?"
            rounds.append(Round(
                id: index,
                prompt: question,
                spoken: question,
                stage: .sequence(sequence.steps, missing: missing),
                choices: arranged.choices,
                answer: arranged.answer,
                fact: sequence.fact))
        }
        return rounds
    }

    // MARK: - Helpers

    static func clamped(_ level: Int) -> Int {
        max(0, min(level, maxLevel))
    }

    /// Puts the right answer at a random place among the wrong ones.
    static func arrange<R: RandomNumberGenerator>(_ correct: Choice, _ wrong: [Choice],
                                                   using rng: inout R) -> (choices: [Choice], answer: Int) {
        var all = wrong + [correct]
        all.shuffle(using: &rng)
        return (all, all.firstIndex(of: correct) ?? 0)
    }

    /// Consecutive numbers like on a number line; the right one sits at a random place among them.
    static func numberOptions<R: RandomNumberGenerator>(around correct: Int, count: Int, in range: ClosedRange<Int>,
                                                         using rng: inout R) -> [Int] {
        let count = min(count, range.count)
        let lowest = max(range.lowerBound, correct - count + 1)
        let highest = min(correct, range.upperBound - count + 1)
        let start = Int.random(in: lowest...max(lowest, highest), using: &rng)
        return Array(start..<(start + count))
    }

    /// Different numbers from the range where possible, in random order.
    static func distinctNumbers<R: RandomNumberGenerator>(in range: ClosedRange<Int>, count: Int,
                                                           using rng: inout R) -> [Int] {
        var numbers: [Int] = []
        while numbers.count < count {
            numbers += Array(range).shuffled(using: &rng)
        }
        return Array(numbers.prefix(count))
    }

    /// ["Kalb", "Lamm", "Ferkel"] -> "Kalb, Lamm oder Ferkel"
    static func spokenList(_ words: [String]) -> String {
        guard words.count > 1 else { return words.first ?? "" }
        return words.dropLast().joined(separator: ", ") + " oder " + (words.last ?? "")
    }
}
