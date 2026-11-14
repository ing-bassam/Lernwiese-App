import Foundation

/// One game of "Formen-Garten": the outlines on the ground and the things the child sorts into them.
struct ShapeRound: Equatable {
    let shapes: [ShapeKind]
    let items: [ShapeItem]

    static func make<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> ShapeRound {
        let shapes = ShapeKind.shapes(level: level)
        // Every outline gets at least one thing, the rest is random; never the same thing twice.
        var pool = ThinkingContent.shapeItems.filter { shapes.contains($0.shape) }.shuffled(using: &rng)
        var items: [ShapeItem] = []
        for shape in shapes {
            if let index = pool.firstIndex(where: { $0.shape == shape }) {
                items.append(pool.remove(at: index))
            }
        }
        while items.count < RoundFactory.roundsPerGame, !pool.isEmpty {
            items.append(pool.removeFirst())
        }
        items = Array(items.prefix(max(RoundFactory.roundsPerGame, shapes.count))).shuffled(using: &rng)
        return ShapeRound(shapes: shapes, items: items)
    }
}

/// One game of "Klang-Echo": how many tones the child repeats in each round.
enum EchoPlan {
    static let flowerCount = 4

    static func lengths(level: Int) -> [Int] {
        switch RoundFactory.clamped(level) {
        case 0: return [2, 2, 3, 3, 3]
        case 1: return [3, 3, 4, 4, 4]
        default: return [3, 4, 4, 5, 5]
        }
    }

    /// Tone sequences; no tone repeats directly, so every step is easy to hear.
    static func sequences<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> [[Int]] {
        lengths(level: level).map { length in
            var tones: [Int] = []
            while tones.count < length {
                let tone = Int.random(in: 0..<flowerCount, using: &rng)
                if tone != tones.last {
                    tones.append(tone)
                }
            }
            return tones
        }
    }
}
