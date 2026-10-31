import Foundation

/// An emoji together with the word a child hears and VoiceOver reads for it.
struct Picture: Hashable {
    let emoji: String
    let name: String
}

/// Colours of tiles and category boxes; mapped to SwiftUI colours in `Palette`.
enum Tint: String, CaseIterable {
    case green, yellow, orange, blue, red, purple, teal, pink
}

/// What is shown in the middle of the screen, above the answers.
enum Stage: Equatable {
    case none
    case item(Picture)
    case count(Picture, plural: String, number: Int)
    case equation(Picture, first: Int, second: Int, isPlus: Bool)
    case sequence([Picture], missing: Int)
}

/// One answer button.
enum Choice: Hashable {
    case picture(Picture)
    case number(Int)
    case word(String)
    case group(Picture, plural: String, count: Int)
    case bin(title: String, examples: [String], tint: Tint)

    /// Read by VoiceOver.
    var spokenName: String {
        switch self {
        case .picture(let picture): return picture.name
        case .number(let number): return "\(number)"
        case .word(let word): return word
        case .group(let picture, let plural, let count): return count == 1 ? "1 \(picture.name)" : "\(count) \(plural)"
        case .bin(let title, _, _): return title
        }
    }
}

/// One task of a game: a question, a picture and two to four answers, exactly one of them right.
struct Round: Identifiable, Equatable {
    let id: Int
    /// Short text on screen.
    let prompt: String
    /// Read aloud when the round starts.
    let spoken: String
    let stage: Stage
    let choices: [Choice]
    /// Index of the right answer in `choices`.
    let answer: Int
    /// Read aloud after the right answer, so every round teaches something.
    let fact: String
}

extension String {
    /// "der Fuchs" -> "Der Fuchs"
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
