import Foundation

/// Rounds of the "Knobeln" world.
extension RoundFactory {
    // MARK: - Muster legen

    static func patterns<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let units = ThinkingContent.patternUnits[clamped(level)]
        var rounds: [Round] = []
        for index in 0..<roundsPerGame {
            let unit = units[index % units.count]
            let kinds = (unit.max() ?? 0) + 1
            let pieces = Array(ThinkingContent.patternPieces.shuffled(using: &rng).prefix(kinds))
            // AB: "A B A B A ?", three pieces: twice the unit, four pieces: once and a half. Never more than 6.
            let shownCount = patternLength(unit: unit)
            let sequence = (0...shownCount).map { pieces[unit[$0 % unit.count]] }
            let shown = Array(sequence.dropLast())
            let correct = sequence[sequence.count - 1]
            let others = ThinkingContent.patternPieces.filter { !pieces.contains($0) }.shuffled(using: &rng)
            let wrongPool = pieces.filter { $0 != correct } + others
            let wrong = Array(wrongPool.prefix(choiceCount(level: level) - 1)).map(Choice.picture)
            let arranged = arrange(.picture(correct), wrong, using: &rng)
            let unitNames = unit.map { pieces[$0].name }
            rounds.append(Round(
                id: index,
                prompt: "Was kommt als Nächstes?",
                spoken: "Schau dir das Muster an. Was kommt als Nächstes?",
                stage: .pattern(shown),
                choices: arranged.choices,
                answer: arranged.answer,
                fact: "Das Muster geht immer so: \(unitNames.joined(separator: ", "))."))
        }
        return rounds
    }

    /// Pieces shown before the gap.
    static func patternLength(unit: [Int]) -> Int {
        unit.count == 2 ? 5 : 6
    }

    // MARK: - Schatten-Rätsel

    static func shadows<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let level = clamped(level)
        let animals = ThinkingContent.shadowAnimals.shuffled(using: &rng)
        let objects = ThinkingContent.shadowObjects.shuffled(using: &rng)
        var rounds: [Round] = []
        for index in 0..<roundsPerGame {
            let useAnimal = index.isMultiple(of: 2)
            let pool = useAnimal ? animals : objects
            let otherPool = useAnimal ? objects : animals
            let correct = pool[index / 2 % pool.count]
            // Easy: the other answers come from the other kind (animal or object). Hard: from the same kind.
            let source = level == 2 ? pool : (level == 1 ? pool + otherPool : otherPool)
            let wrong = Array(source.filter { $0 != correct }.shuffled(using: &rng).prefix(choiceCount(level: level) - 1))
            let arranged = arrange(.picture(correct.picture), wrong.map { .picture($0.picture) }, using: &rng)
            rounds.append(Round(
                id: index,
                prompt: "Wem gehört der Schatten?",
                spoken: "Wem gehört dieser Schatten?",
                stage: .shadow(correct.picture),
                choices: arranged.choices,
                answer: arranged.answer,
                fact: "Das ist \(correct.subject)."))
        }
        return rounds
    }

    // MARK: - Was passt nicht?

    /// Three answers on the first level, then four.
    static func oddOneCount(level: Int) -> Int {
        clamped(level) == 0 ? 3 : 4
    }

    static func oddOne<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [Round] {
        let level = clamped(level)
        let groups = ThinkingContent.groups.shuffled(using: &rng)
        var rounds: [Round] = []
        for index in 0..<roundsPerGame {
            let group = groups[index % groups.count]
            let others = ThinkingContent.groups.filter {
                $0.id != group.id && (level == 2 || !ThinkingContent.areClose($0, group))
            }
            let otherGroup = others[Int.random(in: 0..<others.count, using: &rng)]
            let odd = otherGroup.members[Int.random(in: 0..<otherGroup.members.count, using: &rng)]
            let members = Array(group.members.filter { $0.emoji != odd.emoji }.shuffled(using: &rng)
                .prefix(oddOneCount(level: level) - 1))
            let arranged = arrange(.picture(odd.picture), members.map { .picture($0.picture) }, using: &rng)
            rounds.append(Round(
                id: index,
                prompt: "Was passt nicht dazu?",
                spoken: "Ein Bild passt nicht dazu. Welches ist es?",
                stage: .none,
                choices: arranged.choices,
                answer: arranged.answer,
                fact: "\(odd.subject.capitalizedFirst) passt nicht dazu. Die anderen sind alle \(group.label)."))
        }
        return rounds
    }
}
