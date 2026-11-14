import Foundation

enum World: String, CaseIterable, Identifiable {
    case numbers
    case animals
    case nature
    case thinking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numbers: return "Zahlen"
        case .animals: return "Tiere"
        case .nature: return "Natur"
        case .thinking: return "Knobeln"
        }
    }

    var emoji: String {
        switch self {
        case .numbers: return "🔢"
        case .animals: return "🐾"
        case .nature: return "🌻"
        case .thinking: return "🧩"
        }
    }

    var games: [GameID] {
        GameID.allCases.filter { $0.world == self }
    }
}

enum GameID: String, CaseIterable, Identifiable {
    case counting
    case compare
    case arithmetic
    case habitat
    case foodPairs
    case babies
    case seasons
    case weather
    case fruitVeg
    case growth
    case shapes
    case patterns
    case shadows
    case oddOne
    case echo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .counting: return "Zählen"
        case .compare: return "Mehr oder weniger"
        case .arithmetic: return "Plus und Minus"
        case .habitat: return "Wo wohnt das Tier?"
        case .foodPairs: return "Futter-Paare"
        case .babies: return "Tierbabys"
        case .seasons: return "Jahreszeiten"
        case .weather: return "Wetter"
        case .fruitVeg: return "Obst oder Gemüse"
        case .growth: return "Was kommt danach?"
        case .shapes: return "Formen-Garten"
        case .patterns: return "Muster legen"
        case .shadows: return "Schatten-Rätsel"
        case .oddOne: return "Was passt nicht?"
        case .echo: return "Klang-Echo"
        }
    }

    var emoji: String {
        switch self {
        case .counting: return "🐞"
        case .compare: return "⚖️"
        case .arithmetic: return "🧮"
        case .habitat: return "🦊"
        case .foodPairs: return "🥕"
        case .babies: return "🐣"
        case .seasons: return "🍂"
        case .weather: return "🌦️"
        case .fruitVeg: return "🍓"
        case .growth: return "🌱"
        case .shapes: return "🔺"
        case .patterns: return "🔁"
        case .shadows: return "🌗"
        case .oddOne: return "🤔"
        case .echo: return "🎶"
        }
    }

    var world: World {
        switch self {
        case .counting, .compare, .arithmetic: return .numbers
        case .habitat, .foodPairs, .babies: return .animals
        case .seasons, .weather, .fruitVeg, .growth: return .nature
        case .shapes, .patterns, .shadows, .oddOne, .echo: return .thinking
        }
    }

    var tint: Tint {
        switch self {
        case .counting: return .red
        case .compare: return .orange
        case .arithmetic: return .blue
        case .habitat: return .green
        case .foodPairs: return .pink
        case .babies: return .yellow
        case .seasons: return .orange
        case .weather: return .teal
        case .fruitVeg: return .red
        case .growth: return .green
        case .shapes: return .purple
        case .patterns: return .blue
        case .shadows: return .teal
        case .oddOne: return .orange
        case .echo: return .pink
        }
    }

    /// Read aloud when the game opens.
    var intro: String {
        switch self {
        case .counting: return "Zählen. Zähle genau und tippe auf die richtige Zahl."
        case .compare: return "Mehr oder weniger. Schau genau hin."
        case .arithmetic: return "Plus und Minus. Wie viele sind es am Ende?"
        case .habitat: return "Wo wohnt das Tier? Finde das richtige Zuhause."
        case .foodPairs: return "Futter-Paare. Finde jedes Tier und sein Lieblingsfutter."
        case .babies: return "Tierbabys. Wie heißen die Tierkinder?"
        case .seasons: return "Jahreszeiten. Wann passt das am besten?"
        case .weather: return "Wetter. Was passt zu Regen, Sonne und Schnee?"
        case .fruitVeg: return "Obst oder Gemüse? Tippe auf die richtige Kiste."
        case .growth: return "Was kommt danach? So wächst und verändert sich die Natur."
        case .shapes: return "Formen-Garten. Zieh jedes Ding in die Form, die passt."
        case .patterns: return "Muster legen. Was kommt als Nächstes?"
        case .shadows: return "Schatten-Rätsel. Wem gehört der Schatten?"
        case .oddOne: return "Was passt nicht? Ein Bild gehört nicht dazu."
        case .echo: return "Klang-Echo. Hör gut zu und spiel die Töne nach."
        }
    }

    /// What the game trains, shown to parents.
    var skill: String {
        switch self {
        case .counting, .compare, .arithmetic: return "Zahlen und Mengen"
        case .habitat, .babies, .seasons, .weather, .fruitVeg: return "Wissen und Wortschatz"
        case .foodPairs: return "Gedächtnis"
        case .growth, .patterns: return "Reihenfolgen und Logik"
        case .shapes: return "Formen und Feinmotorik"
        case .shadows: return "Genaues Hinsehen"
        case .oddOne: return "Oberbegriffe und Denken"
        case .echo: return "Hören, Merken und Rhythmus"
        }
    }

    enum Kind {
        case quiz, memory, shapes, echo
    }

    var kind: Kind {
        switch self {
        case .foodPairs: return .memory
        case .shapes: return .shapes
        case .echo: return .echo
        default: return .quiz
        }
    }

    /// The pairs game has its own screen.
    var isMemory: Bool { kind == .memory }
}
