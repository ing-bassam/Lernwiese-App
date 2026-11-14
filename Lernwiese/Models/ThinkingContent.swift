import Foundation

/// A picture with the article, for sentences like "Das ist die Giraffe."
struct Thing: Hashable {
    let emoji: String
    let name: String
    /// "die Giraffe"
    let subject: String

    init(_ emoji: String, _ name: String, _ subject: String) {
        self.emoji = emoji
        self.name = name
        self.subject = subject
    }

    var picture: Picture { Picture(emoji: emoji, name: name) }
}

/// Things that belong together, for "Was passt nicht?".
struct ThingGroup {
    let id: String
    /// "Die anderen sind alle …"
    let label: String
    let members: [Thing]
}

enum ShapeKind: String, CaseIterable, Identifiable {
    case circle, square, triangle, star, heart

    var id: String { rawValue }

    var name: String {
        switch self {
        case .circle: return "Kreis"
        case .square: return "Quadrat"
        case .triangle: return "Dreieck"
        case .star: return "Stern"
        case .heart: return "Herz"
        }
    }

    /// "Der Ball" + "ist rund wie ein Kreis."
    var likeness: String {
        switch self {
        case .circle: return "ist rund wie ein Kreis"
        case .square: return "hat vier gleiche Seiten wie ein Quadrat"
        case .triangle: return "hat drei Ecken wie ein Dreieck"
        case .star: return "hat fünf Zacken"
        case .heart: return "hat die Form von einem Herz"
        }
    }

    var tint: Tint {
        switch self {
        case .circle: return .blue
        case .square: return .orange
        case .triangle: return .green
        case .star: return .yellow
        case .heart: return .pink
        }
    }

    /// Outlines offered on each level: 3, 4, then all 5.
    static func shapes(level: Int) -> [ShapeKind] {
        Array(allCases.prefix(3 + max(0, min(level, 2))))
    }
}

struct ShapeItem: Hashable {
    let thing: Thing
    let shape: ShapeKind
}

enum ThinkingContent {
    // MARK: - Formen-Garten

    static let shapeItems: [ShapeItem] = [
        ShapeItem(thing: Thing("⚽️", "Ball", "der Ball"), shape: .circle),
        ShapeItem(thing: Thing("🍪", "Keks", "der Keks"), shape: .circle),
        ShapeItem(thing: Thing("🍊", "Orange", "die Orange"), shape: .circle),
        ShapeItem(thing: Thing("🕒", "Uhr", "die Uhr"), shape: .circle),
        ShapeItem(thing: Thing("🍩", "Donut", "der Donut"), shape: .circle),
        ShapeItem(thing: Thing("🎁", "Geschenk", "das Geschenk"), shape: .square),
        ShapeItem(thing: Thing("🎲", "Würfel", "der Würfel"), shape: .square),
        ShapeItem(thing: Thing("🧇", "Waffel", "die Waffel"), shape: .square),
        ShapeItem(thing: Thing("🧊", "Eiswürfel", "der Eiswürfel"), shape: .square),
        ShapeItem(thing: Thing("🍕", "Pizzastück", "das Pizzastück"), shape: .triangle),
        ShapeItem(thing: Thing("⛺️", "Zelt", "das Zelt"), shape: .triangle),
        ShapeItem(thing: Thing("🍙", "Reisdreieck", "das Reisdreieck"), shape: .triangle),
        ShapeItem(thing: Thing("🎄", "Tannenbaum", "der Tannenbaum"), shape: .triangle),
        ShapeItem(thing: Thing("⭐️", "Stern", "der Stern"), shape: .star),
        ShapeItem(thing: Thing("🌟", "Glitzerstern", "der Glitzerstern"), shape: .star),
        ShapeItem(thing: Thing("❤️", "rotes Herz", "das rote Herz"), shape: .heart),
        ShapeItem(thing: Thing("💚", "grünes Herz", "das grüne Herz"), shape: .heart),
        ShapeItem(thing: Thing("💜", "lila Herz", "das lila Herz"), shape: .heart),
    ]

    // MARK: - Muster legen

    /// Pictures that are easy to tell apart by colour and form.
    static let patternPieces: [Picture] = [
        Picture(emoji: "🍎", name: "Apfel"),
        Picture(emoji: "🍌", name: "Banane"),
        Picture(emoji: "🍇", name: "Trauben"),
        Picture(emoji: "⭐️", name: "Stern"),
        Picture(emoji: "🌙", name: "Mond"),
        Picture(emoji: "☀️", name: "Sonne"),
        Picture(emoji: "❤️", name: "Herz"),
        Picture(emoji: "🔵", name: "blauer Kreis"),
        Picture(emoji: "🟩", name: "grünes Quadrat"),
        Picture(emoji: "🐞", name: "Marienkäfer"),
        Picture(emoji: "🐟", name: "Fisch"),
        Picture(emoji: "🌸", name: "Blüte"),
        Picture(emoji: "🍄", name: "Pilz"),
    ]

    /// Repeating units per level, as positions in the unit: AB; AAB and ABC; ABB, AABB and ABCD.
    static let patternUnits: [[[Int]]] = [
        [[0, 1]],
        [[0, 0, 1], [0, 1, 2]],
        [[0, 1, 1], [0, 0, 1, 1], [0, 1, 2, 3]],
    ]

    // MARK: - Schatten-Rätsel

    static let shadowAnimals: [Thing] = [
        Thing("🦒", "Giraffe", "die Giraffe"),
        Thing("🐘", "Elefant", "der Elefant"),
        Thing("🐇", "Hase", "der Hase"),
        Thing("🦀", "Krabbe", "die Krabbe"),
        Thing("🐌", "Schnecke", "die Schnecke"),
        Thing("🦋", "Schmetterling", "der Schmetterling"),
        Thing("🐢", "Schildkröte", "die Schildkröte"),
        Thing("🦆", "Ente", "die Ente"),
        Thing("🐿️", "Eichhörnchen", "das Eichhörnchen"),
        Thing("🦕", "Dinosaurier", "der Dinosaurier"),
        Thing("🐓", "Hahn", "der Hahn"),
        Thing("🦘", "Känguru", "das Känguru"),
    ]

    static let shadowObjects: [Thing] = [
        Thing("🚲", "Fahrrad", "das Fahrrad"),
        Thing("✂️", "Schere", "die Schere"),
        Thing("🔑", "Schlüssel", "der Schlüssel"),
        Thing("☂️", "Regenschirm", "der Regenschirm"),
        Thing("🎸", "Gitarre", "die Gitarre"),
        Thing("🚁", "Hubschrauber", "der Hubschrauber"),
        Thing("⚓️", "Anker", "der Anker"),
        Thing("🍐", "Birne", "die Birne"),
        Thing("🥕", "Möhre", "die Möhre"),
        Thing("🌵", "Kaktus", "der Kaktus"),
        Thing("✈️", "Flugzeug", "das Flugzeug"),
        Thing("🍄", "Pilz", "der Pilz"),
    ]

    // MARK: - Was passt nicht?

    static let groups: [ThingGroup] = [
        ThingGroup(id: "fruit", label: "Obst", members: [
            Thing("🍎", "Apfel", "der Apfel"), Thing("🍌", "Banane", "die Banane"),
            Thing("🍐", "Birne", "die Birne"), Thing("🍇", "Trauben", "die Trauben"),
            Thing("🍓", "Erdbeere", "die Erdbeere"), Thing("🍒", "Kirschen", "die Kirschen"),
        ]),
        ThingGroup(id: "vegetables", label: "Gemüse", members: [
            Thing("🥕", "Möhre", "die Möhre"), Thing("🥦", "Brokkoli", "der Brokkoli"),
            Thing("🌽", "Mais", "der Mais"), Thing("🥒", "Gurke", "die Gurke"),
            Thing("🥔", "Kartoffel", "die Kartoffel"), Thing("🫑", "Paprika", "die Paprika"),
        ]),
        ThingGroup(id: "vehicles", label: "Fahrzeuge", members: [
            Thing("🚗", "Auto", "das Auto"), Thing("🚌", "Bus", "der Bus"),
            Thing("🚲", "Fahrrad", "das Fahrrad"), Thing("🚂", "Zug", "der Zug"),
            Thing("🚜", "Traktor", "der Traktor"), Thing("✈️", "Flugzeug", "das Flugzeug"),
        ]),
        ThingGroup(id: "clothes", label: "Kleidung", members: [
            Thing("👕", "T-Shirt", "das T-Shirt"), Thing("👖", "Hose", "die Hose"),
            Thing("🧦", "Socken", "die Socken"), Thing("🧢", "Mütze", "die Mütze"),
            Thing("👗", "Kleid", "das Kleid"), Thing("🧤", "Handschuhe", "die Handschuhe"),
        ]),
        ThingGroup(id: "music", label: "Musikinstrumente", members: [
            Thing("🎸", "Gitarre", "die Gitarre"), Thing("🥁", "Trommel", "die Trommel"),
            Thing("🎺", "Trompete", "die Trompete"), Thing("🎻", "Geige", "die Geige"),
            Thing("🎹", "Klavier", "das Klavier"), Thing("🪗", "Akkordeon", "das Akkordeon"),
        ]),
        ThingGroup(id: "sea", label: "Tiere im Meer", members: [
            Thing("🐳", "Wal", "der Wal"), Thing("🐬", "Delfin", "der Delfin"),
            Thing("🐙", "Krake", "der Krake"), Thing("🦀", "Krabbe", "die Krabbe"),
            Thing("🐠", "Fisch", "der Fisch"), Thing("🦈", "Hai", "der Hai"),
        ]),
        ThingGroup(id: "toys", label: "Spielsachen", members: [
            Thing("🧸", "Teddy", "der Teddy"), Thing("🪀", "Jo-Jo", "das Jo-Jo"),
            Thing("🪁", "Drachen", "der Drachen"), Thing("⚽️", "Ball", "der Ball"),
            Thing("🎈", "Luftballon", "der Luftballon"), Thing("🧩", "Puzzle", "das Puzzle"),
        ]),
    ]

    /// Groups that are too close for the youngest (fruit and vegetables); only mixed on the hardest level.
    static func areClose(_ first: ThingGroup, _ second: ThingGroup) -> Bool {
        Set([first.id, second.id]) == Set(["fruit", "vegetables"])
    }
}
