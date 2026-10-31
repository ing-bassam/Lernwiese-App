import Foundation

enum World: String, CaseIterable, Identifiable {
    case numbers
    case animals
    case nature

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numbers: return "Zahlen"
        case .animals: return "Tiere"
        case .nature: return "Natur"
        }
    }

    var emoji: String {
        switch self {
        case .numbers: return "🔢"
        case .animals: return "🐾"
        case .nature: return "🌻"
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
        }
    }

    var world: World {
        switch self {
        case .counting, .compare, .arithmetic: return .numbers
        case .habitat, .foodPairs, .babies: return .animals
        case .seasons, .weather, .fruitVeg, .growth: return .nature
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
        }
    }

    /// The pairs game has its own screen; all others are question rounds.
    var isMemory: Bool { self == .foodPairs }
}
