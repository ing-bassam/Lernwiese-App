import Foundation

/// Gate in front of the parents' area (settings and links that leave the app), as required for the
/// Kids category: a multiplication with a two-digit number that children of 4 to 8 cannot solve.
struct ParentalGate: Equatable {
    let first: Int
    let second: Int

    var answer: Int { first * second }
    var question: String { "\(first) × \(second)" }
    var spokenQuestion: String { "\(first) mal \(second)" }

    static let firstRange = 12...19
    static let secondRange = 3...9

    static func random<R: RandomNumberGenerator>(using rng: inout R) -> ParentalGate {
        ParentalGate(first: Int.random(in: firstRange, using: &rng), second: Int.random(in: secondRange, using: &rng))
    }

    static func random() -> ParentalGate {
        var rng = SystemRandomNumberGenerator()
        return random(using: &rng)
    }

    func accepts(_ input: String) -> Bool {
        Int(input.trimmingCharacters(in: .whitespacesAndNewlines)) == answer
    }
}
