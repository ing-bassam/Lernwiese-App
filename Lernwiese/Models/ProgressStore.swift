import Foundation

/// Stars per game (0 to 3), stored only on the device. Every finished game earns a star – there are no
/// points to lose. The stars also set the difficulty of the next game.
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()
    static let maxStars = 3

    @Published private(set) var starsByGame: [String: Int]

    private let defaults: UserDefaults
    private let key = "stars"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        starsByGame = defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    func stars(for game: GameID) -> Int {
        max(0, min(starsByGame[game.rawValue] ?? 0, Self.maxStars))
    }

    func level(for game: GameID) -> Int {
        min(stars(for: game), RoundFactory.maxLevel)
    }

    var total: Int {
        GameID.allCases.reduce(0) { $0 + stars(for: $1) }
    }

    var maximum: Int {
        GameID.allCases.count * Self.maxStars
    }

    /// Returns true when the game earned a new star.
    @discardableResult
    func recordCompletion(of game: GameID) -> Bool {
        let current = stars(for: game)
        guard current < Self.maxStars else { return false }
        starsByGame[game.rawValue] = current + 1
        save()
        return true
    }

    func set(_ stars: Int, for game: GameID) {
        starsByGame[game.rawValue] = max(0, min(stars, Self.maxStars))
        save()
    }

    func reset() {
        starsByGame = [:]
        save()
    }

    private func save() {
        defaults.set(starsByGame, forKey: key)
    }
}
