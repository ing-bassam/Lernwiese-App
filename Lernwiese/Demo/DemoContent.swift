import Foundation

/// Fixed content for the App Store screenshots taken in the Simulator.
/// Only active when the app is launched with `-demo YES`; then it never speaks or vibrates.
enum DemoContent {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-demo")
    }

    /// Screen to open on launch: `-screen home`, a game (`-screen counting`) or `-screen parents`.
    static var launchScreen: String? {
        isActive ? UserDefaults.standard.string(forKey: "screen") : nil
    }

    static var launchGame: GameID? {
        launchScreen.flatMap { GameID(rawValue: $0) }
    }

    /// `-solved YES` shows the first round already answered.
    static var startsSolved: Bool {
        isActive && UserDefaults.standard.bool(forKey: "solved")
    }

    static let seed: UInt64 = 2026
    static let level = 1
    /// Items already counted in the counting screenshot.
    static let countedItems = 3

    static let stars: [GameID: Int] = [
        .counting: 3, .compare: 2, .arithmetic: 1,
        .habitat: 3, .foodPairs: 2, .babies: 1,
        .seasons: 2, .weather: 1, .fruitVeg: 3, .growth: 0,
    ]

    static func prepareIfNeeded() {
        guard isActive else { return }
        AppSettings.shared.isDemo = true
        for (game, count) in stars {
            ProgressStore.shared.set(count, for: game)
        }
    }
}
