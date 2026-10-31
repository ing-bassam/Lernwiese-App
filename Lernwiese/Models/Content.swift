import Foundation

/// Things to count, compare and calculate with.
struct Countable {
    let emoji: String
    let singular: String
    let plural: String
    /// "ein Apfel" – used instead of "1 Äpfel".
    let one: String
    let leavesOne: String
    let leavesMany: String

    var picture: Picture { Picture(emoji: emoji, name: singular) }

    /// "ein Apfel", "3 Äpfel"
    func amount(_ number: Int) -> String {
        number == 1 ? one : "\(number) \(plural)"
    }

    /// "Hier ist ein Apfel", "Hier sind 3 Äpfel"
    func here(_ number: Int) -> String {
        number == 1 ? "Hier ist \(one)" : "Hier sind \(number) \(plural)"
    }
}

struct Habitat: Hashable {
    let id: String
    let picture: Picture
    /// "im Wald"
    let phrase: String
}

struct Animal {
    let picture: Picture
    /// "der Fuchs"
    let subject: String
    let habitat: Habitat
}

struct FoodPair {
    let animal: Picture
    let food: Picture
    let fact: String
}

struct AnimalBaby {
    let parent: Picture
    /// "von der Kuh"
    let ofParent: String
    let baby: String
}

struct Season: Hashable {
    let id: Int
    let name: String
    let icon: String
    let tint: Tint
}

struct SeasonItem {
    let picture: Picture
    let subject: String
    let season: Int
    let fact: String
}

struct WeatherItem {
    let picture: Picture
    let fact: String
    /// False for answers that would also be sensible in other weather (going inside).
    let canBeWrongAnswer: Bool
}

struct Weather {
    let picture: Picture
    let sentence: String
    let isSunny: Bool
    let items: [WeatherItem]
}

struct Produce {
    let picture: Picture
    let subject: String
    let isFruit: Bool
    /// Well-known items for the first level.
    let isCommon: Bool
    let fact: String
}

struct GrowthSequence {
    let steps: [Picture]
    /// Wrong answers that can never be mistaken for a step of this sequence.
    let wrong: [Picture]
    let fact: String
}

/// All learning content. Every list is checked for ambiguities in `ContentTests`.
enum Content {
    // MARK: - Zahlen

    static let countables: [Countable] = [
        Countable(emoji: "🐞", singular: "Marienkäfer", plural: "Marienkäfer", one: "ein Marienkäfer",
                  leavesOne: "krabbelt weg", leavesMany: "krabbeln weg"),
        Countable(emoji: "🍎", singular: "Apfel", plural: "Äpfel", one: "ein Apfel",
                  leavesOne: "wird gegessen", leavesMany: "werden gegessen"),
        Countable(emoji: "🐟", singular: "Fisch", plural: "Fische", one: "ein Fisch",
                  leavesOne: "schwimmt weg", leavesMany: "schwimmen weg"),
        Countable(emoji: "🌼", singular: "Blume", plural: "Blumen", one: "eine Blume",
                  leavesOne: "wird gepflückt", leavesMany: "werden gepflückt"),
        Countable(emoji: "🐥", singular: "Küken", plural: "Küken", one: "ein Küken",
                  leavesOne: "läuft weg", leavesMany: "laufen weg"),
        Countable(emoji: "🦋", singular: "Schmetterling", plural: "Schmetterlinge", one: "ein Schmetterling",
                  leavesOne: "fliegt weg", leavesMany: "fliegen weg"),
        Countable(emoji: "🍓", singular: "Erdbeere", plural: "Erdbeeren", one: "eine Erdbeere",
                  leavesOne: "wird gegessen", leavesMany: "werden gegessen"),
        Countable(emoji: "🐌", singular: "Schnecke", plural: "Schnecken", one: "eine Schnecke",
                  leavesOne: "kriecht weg", leavesMany: "kriechen weg"),
        Countable(emoji: "🦆", singular: "Ente", plural: "Enten", one: "eine Ente",
                  leavesOne: "watschelt weg", leavesMany: "watscheln weg"),
        Countable(emoji: "🌰", singular: "Kastanie", plural: "Kastanien", one: "eine Kastanie",
                  leavesOne: "wird eingesammelt", leavesMany: "werden eingesammelt"),
    ]

    // MARK: - Tiere

    static let forest = Habitat(id: "forest", picture: Picture(emoji: "🌲", name: "Wald"), phrase: "im Wald")
    static let sea = Habitat(id: "sea", picture: Picture(emoji: "🌊", name: "Meer"), phrase: "im Meer")
    static let farm = Habitat(id: "farm", picture: Picture(emoji: "🚜", name: "Bauernhof"), phrase: "auf dem Bauernhof")
    static let jungle = Habitat(id: "jungle", picture: Picture(emoji: "🌴", name: "Dschungel"), phrase: "im Dschungel")
    static let savanna = Habitat(id: "savanna", picture: Picture(emoji: "🌾", name: "Savanne"), phrase: "in der Savanne")
    static let ice = Habitat(id: "ice", picture: Picture(emoji: "❄️", name: "Eis und Schnee"), phrase: "im Eis und Schnee")

    static let habitats = [forest, sea, farm, jungle, savanna, ice]

    /// Homes a child could reasonably mix up (some monkeys live in the savanna); never offered together.
    static func areRelated(_ first: Habitat, _ second: Habitat) -> Bool {
        Set([first.id, second.id]) == Set(["jungle", "savanna"])
    }

    static let animals: [Animal] = [
        Animal(picture: Picture(emoji: "🦊", name: "Fuchs"), subject: "der Fuchs", habitat: forest),
        Animal(picture: Picture(emoji: "🦌", name: "Hirsch"), subject: "der Hirsch", habitat: forest),
        Animal(picture: Picture(emoji: "🐿️", name: "Eichhörnchen"), subject: "das Eichhörnchen", habitat: forest),
        Animal(picture: Picture(emoji: "🦔", name: "Igel"), subject: "der Igel", habitat: forest),
        Animal(picture: Picture(emoji: "🦉", name: "Eule"), subject: "die Eule", habitat: forest),
        Animal(picture: Picture(emoji: "🐗", name: "Wildschwein"), subject: "das Wildschwein", habitat: forest),
        Animal(picture: Picture(emoji: "🦡", name: "Dachs"), subject: "der Dachs", habitat: forest),
        Animal(picture: Picture(emoji: "🐳", name: "Wal"), subject: "der Wal", habitat: sea),
        Animal(picture: Picture(emoji: "🐬", name: "Delfin"), subject: "der Delfin", habitat: sea),
        Animal(picture: Picture(emoji: "🐙", name: "Krake"), subject: "der Krake", habitat: sea),
        Animal(picture: Picture(emoji: "🦀", name: "Krabbe"), subject: "die Krabbe", habitat: sea),
        Animal(picture: Picture(emoji: "🦈", name: "Hai"), subject: "der Hai", habitat: sea),
        Animal(picture: Picture(emoji: "🐄", name: "Kuh"), subject: "die Kuh", habitat: farm),
        Animal(picture: Picture(emoji: "🐖", name: "Schwein"), subject: "das Schwein", habitat: farm),
        Animal(picture: Picture(emoji: "🐑", name: "Schaf"), subject: "das Schaf", habitat: farm),
        Animal(picture: Picture(emoji: "🐔", name: "Huhn"), subject: "das Huhn", habitat: farm),
        Animal(picture: Picture(emoji: "🐴", name: "Pferd"), subject: "das Pferd", habitat: farm),
        Animal(picture: Picture(emoji: "🐐", name: "Ziege"), subject: "die Ziege", habitat: farm),
        Animal(picture: Picture(emoji: "🐒", name: "Affe"), subject: "der Affe", habitat: jungle),
        Animal(picture: Picture(emoji: "🦜", name: "Papagei"), subject: "der Papagei", habitat: jungle),
        Animal(picture: Picture(emoji: "🦍", name: "Gorilla"), subject: "der Gorilla", habitat: jungle),
        Animal(picture: Picture(emoji: "🦥", name: "Faultier"), subject: "das Faultier", habitat: jungle),
        Animal(picture: Picture(emoji: "🦁", name: "Löwe"), subject: "der Löwe", habitat: savanna),
        Animal(picture: Picture(emoji: "🦒", name: "Giraffe"), subject: "die Giraffe", habitat: savanna),
        Animal(picture: Picture(emoji: "🦓", name: "Zebra"), subject: "das Zebra", habitat: savanna),
        Animal(picture: Picture(emoji: "🦏", name: "Nashorn"), subject: "das Nashorn", habitat: savanna),
        Animal(picture: Picture(emoji: "🐧", name: "Pinguin"), subject: "der Pinguin", habitat: ice),
        Animal(picture: Picture(emoji: "🐻‍❄️", name: "Eisbär"), subject: "der Eisbär", habitat: ice),
    ]

    static let foodPairs: [FoodPair] = [
        FoodPair(animal: Picture(emoji: "🐰", name: "Hase"), food: Picture(emoji: "🥕", name: "Möhre"),
                 fact: "Der Hase knabbert gern Möhren."),
        FoodPair(animal: Picture(emoji: "🐒", name: "Affe"), food: Picture(emoji: "🍌", name: "Banane"),
                 fact: "Der Affe isst gern Bananen."),
        FoodPair(animal: Picture(emoji: "🐿️", name: "Eichhörnchen"), food: Picture(emoji: "🌰", name: "Nuss"),
                 fact: "Das Eichhörnchen sammelt Nüsse für den Winter."),
        FoodPair(animal: Picture(emoji: "🐼", name: "Panda"), food: Picture(emoji: "🎋", name: "Bambus"),
                 fact: "Der Panda frisst fast nur Bambus."),
        FoodPair(animal: Picture(emoji: "🐝", name: "Biene"), food: Picture(emoji: "🌼", name: "Blüte"),
                 fact: "Die Biene holt süßen Nektar aus den Blüten."),
        FoodPair(animal: Picture(emoji: "🐄", name: "Kuh"), food: Picture(emoji: "🌿", name: "Gras"),
                 fact: "Die Kuh frisst Gras auf der Weide."),
        FoodPair(animal: Picture(emoji: "🐻", name: "Bär"), food: Picture(emoji: "🍯", name: "Honig"),
                 fact: "Der Bär nascht gern Honig."),
        FoodPair(animal: Picture(emoji: "🐧", name: "Pinguin"), food: Picture(emoji: "🐟", name: "Fisch"),
                 fact: "Der Pinguin fängt Fische im Meer."),
        FoodPair(animal: Picture(emoji: "🐸", name: "Frosch"), food: Picture(emoji: "🪰", name: "Fliege"),
                 fact: "Der Frosch fängt Fliegen mit seiner langen Zunge."),
        FoodPair(animal: Picture(emoji: "🐭", name: "Maus"), food: Picture(emoji: "🌾", name: "Körner"),
                 fact: "Die Maus knabbert gern Körner."),
        FoodPair(animal: Picture(emoji: "🦔", name: "Igel"), food: Picture(emoji: "🐌", name: "Schnecke"),
                 fact: "Der Igel frisst Schnecken und Käfer."),
        FoodPair(animal: Picture(emoji: "🐛", name: "Raupe"), food: Picture(emoji: "🍃", name: "Blatt"),
                 fact: "Die Raupe frisst viele Blätter."),
    ]

    static let babies: [AnimalBaby] = [
        AnimalBaby(parent: Picture(emoji: "🐄", name: "Kuh"), ofParent: "von der Kuh", baby: "Kalb"),
        AnimalBaby(parent: Picture(emoji: "🐴", name: "Pferd"), ofParent: "vom Pferd", baby: "Fohlen"),
        AnimalBaby(parent: Picture(emoji: "🐑", name: "Schaf"), ofParent: "vom Schaf", baby: "Lamm"),
        AnimalBaby(parent: Picture(emoji: "🐷", name: "Schwein"), ofParent: "vom Schwein", baby: "Ferkel"),
        AnimalBaby(parent: Picture(emoji: "🐶", name: "Hund"), ofParent: "vom Hund", baby: "Welpe"),
        AnimalBaby(parent: Picture(emoji: "🐱", name: "Katze"), ofParent: "von der Katze", baby: "Kätzchen"),
        AnimalBaby(parent: Picture(emoji: "🐔", name: "Huhn"), ofParent: "vom Huhn", baby: "Küken"),
        AnimalBaby(parent: Picture(emoji: "🐐", name: "Ziege"), ofParent: "von der Ziege", baby: "Zicklein"),
        AnimalBaby(parent: Picture(emoji: "🐸", name: "Frosch"), ofParent: "vom Frosch", baby: "Kaulquappe"),
        AnimalBaby(parent: Picture(emoji: "🦋", name: "Schmetterling"), ofParent: "vom Schmetterling", baby: "Raupe"),
    ]

    // MARK: - Natur

    static let seasons = [
        Season(id: 0, name: "Frühling", icon: "🌼", tint: .green),
        Season(id: 1, name: "Sommer", icon: "☀️", tint: .yellow),
        Season(id: 2, name: "Herbst", icon: "🍁", tint: .orange),
        Season(id: 3, name: "Winter", icon: "⛄️", tint: .blue),
    ]

    static let seasonItems: [SeasonItem] = [
        SeasonItem(picture: Picture(emoji: "🌷", name: "Tulpe"), subject: "die Tulpe", season: 0,
                   fact: "Im Frühling blühen die Tulpen."),
        SeasonItem(picture: Picture(emoji: "🐣", name: "Küken"), subject: "das Küken", season: 0,
                   fact: "Im Frühling schlüpfen viele Küken."),
        SeasonItem(picture: Picture(emoji: "🌸", name: "Kirschblüte"), subject: "die Kirschblüte", season: 0,
                   fact: "Im Frühling blühen die Kirschbäume."),
        SeasonItem(picture: Picture(emoji: "🌱", name: "Keimling"), subject: "der Keimling", season: 0,
                   fact: "Im Frühling wachsen überall neue Pflanzen."),
        SeasonItem(picture: Picture(emoji: "🍦", name: "Eis"), subject: "das Eis", season: 1,
                   fact: "Im Sommer ist es heiß. Ein Eis kühlt schön ab."),
        SeasonItem(picture: Picture(emoji: "🏖️", name: "Strand"), subject: "der Strand", season: 1,
                   fact: "Im Sommer kannst du am Strand spielen."),
        SeasonItem(picture: Picture(emoji: "🩱", name: "Badeanzug"), subject: "der Badeanzug", season: 1,
                   fact: "Im Sommer gehen wir schwimmen."),
        SeasonItem(picture: Picture(emoji: "🍉", name: "Wassermelone"), subject: "die Wassermelone", season: 1,
                   fact: "Im Sommer schmeckt eine kühle Wassermelone."),
        SeasonItem(picture: Picture(emoji: "🌻", name: "Sonnenblume"), subject: "die Sonnenblume", season: 1,
                   fact: "Im Sommer blühen die Sonnenblumen."),
        SeasonItem(picture: Picture(emoji: "🎃", name: "Kürbis"), subject: "der Kürbis", season: 2,
                   fact: "Im Herbst werden die Kürbisse geerntet."),
        SeasonItem(picture: Picture(emoji: "🌰", name: "Kastanie"), subject: "die Kastanie", season: 2,
                   fact: "Im Herbst fallen die Kastanien von den Bäumen."),
        SeasonItem(picture: Picture(emoji: "🍄", name: "Pilz"), subject: "der Pilz", season: 2,
                   fact: "Im Herbst wachsen im Wald viele Pilze."),
        SeasonItem(picture: Picture(emoji: "🪁", name: "Drachen"), subject: "der Drachen", season: 2,
                   fact: "Im Herbst ist es windig. Dann steigen die Drachen."),
        SeasonItem(picture: Picture(emoji: "🍂", name: "Laub"), subject: "das bunte Laub", season: 2,
                   fact: "Im Herbst werden die Blätter bunt und fallen herunter."),
        SeasonItem(picture: Picture(emoji: "🧤", name: "Handschuhe"), subject: "die Handschuhe", season: 3,
                   fact: "Im Winter halten Handschuhe die Hände warm."),
        SeasonItem(picture: Picture(emoji: "🧣", name: "Schal"), subject: "der Schal", season: 3,
                   fact: "Im Winter hält der Schal den Hals warm."),
        SeasonItem(picture: Picture(emoji: "🛷", name: "Schlitten"), subject: "der Schlitten", season: 3,
                   fact: "Im Winter fährst du mit dem Schlitten den Berg hinunter."),
        SeasonItem(picture: Picture(emoji: "❄️", name: "Schneeflocke"), subject: "die Schneeflocke", season: 3,
                   fact: "Im Winter fallen Schneeflocken vom Himmel."),
        SeasonItem(picture: Picture(emoji: "⛸️", name: "Schlittschuh"), subject: "der Schlittschuh", season: 3,
                   fact: "Im Winter kannst du auf dem Eis Schlittschuh laufen."),
    ]

    static let weathers: [Weather] = [
        Weather(picture: Picture(emoji: "🌧️", name: "Regen"), sentence: "Es regnet.", isSunny: false, items: [
            WeatherItem(picture: Picture(emoji: "☂️", name: "Regenschirm"),
                        fact: "Mit dem Regenschirm bleibst du trocken.", canBeWrongAnswer: true),
            WeatherItem(picture: Picture(emoji: "👢", name: "Gummistiefel"),
                        fact: "Mit Gummistiefeln kannst du in Pfützen springen.", canBeWrongAnswer: true),
        ]),
        Weather(picture: Picture(emoji: "☀️", name: "Sonne"), sentence: "Die Sonne scheint.", isSunny: true, items: [
            WeatherItem(picture: Picture(emoji: "🕶️", name: "Sonnenbrille"),
                        fact: "Die Sonnenbrille schützt deine Augen.", canBeWrongAnswer: true),
            WeatherItem(picture: Picture(emoji: "👒", name: "Sonnenhut"),
                        fact: "Der Sonnenhut schützt deinen Kopf vor der Sonne.", canBeWrongAnswer: true),
            WeatherItem(picture: Picture(emoji: "🧴", name: "Sonnencreme"),
                        fact: "Sonnencreme schützt deine Haut vor Sonnenbrand.", canBeWrongAnswer: true),
        ]),
        Weather(picture: Picture(emoji: "🌨️", name: "Schnee"), sentence: "Es schneit.", isSunny: false, items: [
            WeatherItem(picture: Picture(emoji: "🧤", name: "Handschuhe"),
                        fact: "Handschuhe halten deine Hände warm.", canBeWrongAnswer: true),
            WeatherItem(picture: Picture(emoji: "🧣", name: "Schal"),
                        fact: "Der Schal hält deinen Hals warm.", canBeWrongAnswer: true),
            WeatherItem(picture: Picture(emoji: "⛄️", name: "Schneemann"),
                        fact: "Aus Schnee kannst du einen Schneemann bauen.", canBeWrongAnswer: true),
        ]),
        Weather(picture: Picture(emoji: "⛈️", name: "Gewitter"), sentence: "Es blitzt und donnert.", isSunny: false, items: [
            WeatherItem(picture: Picture(emoji: "🏠", name: "Ins Haus"),
                        fact: "Bei Gewitter bist du im Haus sicher.", canBeWrongAnswer: false),
        ]),
    ]

    static let produce: [Produce] = [
        Produce(picture: Picture(emoji: "🍎", name: "Apfel"), subject: "der Apfel", isFruit: true, isCommon: true,
                fact: "Der Apfel ist Obst. Er wächst an einem Baum."),
        Produce(picture: Picture(emoji: "🍐", name: "Birne"), subject: "die Birne", isFruit: true, isCommon: true,
                fact: "Die Birne ist Obst. Sie wächst an einem Baum."),
        Produce(picture: Picture(emoji: "🍌", name: "Banane"), subject: "die Banane", isFruit: true, isCommon: true,
                fact: "Die Banane ist Obst. Sie wächst in warmen Ländern."),
        Produce(picture: Picture(emoji: "🍓", name: "Erdbeere"), subject: "die Erdbeere", isFruit: true, isCommon: true,
                fact: "Die Erdbeere ist Obst. Sie ist rot und süß."),
        Produce(picture: Picture(emoji: "🍒", name: "Kirschen"), subject: "die Kirschen", isFruit: true, isCommon: true,
                fact: "Kirschen sind Obst. Sie wachsen an einem Baum."),
        Produce(picture: Picture(emoji: "🍇", name: "Weintrauben"), subject: "die Weintrauben", isFruit: true, isCommon: false,
                fact: "Weintrauben sind Obst. Sie wachsen an langen Ranken."),
        Produce(picture: Picture(emoji: "🍋", name: "Zitrone"), subject: "die Zitrone", isFruit: true, isCommon: false,
                fact: "Die Zitrone ist Obst. Sie schmeckt sehr sauer."),
        Produce(picture: Picture(emoji: "🍍", name: "Ananas"), subject: "die Ananas", isFruit: true, isCommon: false,
                fact: "Die Ananas ist Obst. Sie wächst in warmen Ländern."),
        Produce(picture: Picture(emoji: "🥝", name: "Kiwi"), subject: "die Kiwi", isFruit: true, isCommon: false,
                fact: "Die Kiwi ist Obst. Innen ist sie grün."),
        Produce(picture: Picture(emoji: "🍊", name: "Mandarine"), subject: "die Mandarine", isFruit: true, isCommon: false,
                fact: "Die Mandarine ist Obst. Sie ist saftig und süß."),
        Produce(picture: Picture(emoji: "🥕", name: "Möhre"), subject: "die Möhre", isFruit: false, isCommon: true,
                fact: "Die Möhre ist Gemüse. Sie wächst in der Erde."),
        Produce(picture: Picture(emoji: "🥦", name: "Brokkoli"), subject: "der Brokkoli", isFruit: false, isCommon: true,
                fact: "Der Brokkoli ist Gemüse. Er sieht aus wie ein kleiner Baum."),
        Produce(picture: Picture(emoji: "🥔", name: "Kartoffel"), subject: "die Kartoffel", isFruit: false, isCommon: true,
                fact: "Die Kartoffel ist Gemüse. Sie wächst in der Erde."),
        Produce(picture: Picture(emoji: "🥒", name: "Gurke"), subject: "die Gurke", isFruit: false, isCommon: true,
                fact: "Die Gurke ist Gemüse. Sie ist knackig und frisch."),
        Produce(picture: Picture(emoji: "🥬", name: "Salat"), subject: "der Salat", isFruit: false, isCommon: true,
                fact: "Der Salat ist Gemüse. Er hat viele grüne Blätter."),
        Produce(picture: Picture(emoji: "🫑", name: "Paprika"), subject: "die Paprika", isFruit: false, isCommon: false,
                fact: "Die Paprika ist Gemüse. Es gibt sie in Rot, Gelb und Grün."),
        Produce(picture: Picture(emoji: "🧅", name: "Zwiebel"), subject: "die Zwiebel", isFruit: false, isCommon: false,
                fact: "Die Zwiebel ist Gemüse. Beim Schneiden kommen manchmal Tränen."),
        Produce(picture: Picture(emoji: "🧄", name: "Knoblauch"), subject: "der Knoblauch", isFruit: false, isCommon: false,
                fact: "Der Knoblauch ist Gemüse. Er riecht sehr stark."),
    ]

    private static let egg = Picture(emoji: "🥚", name: "Ei")
    private static let hen = Picture(emoji: "🐔", name: "Huhn")
    private static let tree = Picture(emoji: "🌳", name: "Baum")
    private static let moon = Picture(emoji: "🌙", name: "Nacht")
    private static let apple = Picture(emoji: "🍎", name: "roter Apfel")
    private static let snowman = Picture(emoji: "⛄️", name: "Schneemann")
    private static let rainbow = Picture(emoji: "🌈", name: "Regenbogen")
    private static let chick = Picture(emoji: "🐥", name: "Küken")
    private static let butterfly = Picture(emoji: "🦋", name: "Schmetterling")
    private static let fish = Picture(emoji: "🐟", name: "Fisch")
    private static let hedgehog = Picture(emoji: "🦔", name: "Igel")

    static let growth: [GrowthSequence] = [
        GrowthSequence(steps: [egg, Picture(emoji: "🐣", name: "Küken schlüpft"), chick, hen],
                       wrong: [tree, moon, apple, snowman, rainbow],
                       fact: "Aus dem Ei schlüpft ein Küken. Das Küken wird ein Huhn."),
        GrowthSequence(steps: [egg, Picture(emoji: "🐛", name: "Raupe"), butterfly],
                       wrong: [tree, snowman, moon, apple, Picture(emoji: "🌧️", name: "Regen")],
                       fact: "Aus dem Ei kommt eine Raupe. Die Raupe wird ein Schmetterling."),
        GrowthSequence(steps: [Picture(emoji: "🌰", name: "Kastanie"), Picture(emoji: "🌱", name: "Keimling"), tree],
                       wrong: [hen, moon, snowman, butterfly, rainbow],
                       fact: "Aus einer Kastanie kann ein großer Baum wachsen."),
        GrowthSequence(steps: [Picture(emoji: "🌸", name: "Blüte"), Picture(emoji: "🍏", name: "grüner Apfel"), apple],
                       wrong: [chick, moon, snowman, rainbow, fish],
                       fact: "Aus der Blüte wird ein Apfel. Er wird langsam rot und reif."),
        GrowthSequence(steps: [Picture(emoji: "🌅", name: "Morgen"), Picture(emoji: "☀️", name: "Mittag"),
                               Picture(emoji: "🌇", name: "Abend"), moon],
                       wrong: [Picture(emoji: "🐣", name: "Küken schlüpft"), apple, tree, butterfly, fish],
                       fact: "Morgen, Mittag, Abend und Nacht: So vergeht ein Tag."),
        GrowthSequence(steps: [Picture(emoji: "🌷", name: "Frühling"), Picture(emoji: "☀️", name: "Sommer"),
                               Picture(emoji: "🍂", name: "Herbst"), snowman],
                       wrong: [hen, moon, fish, rainbow],
                       fact: "Frühling, Sommer, Herbst und Winter: So vergeht ein Jahr."),
        GrowthSequence(steps: [Picture(emoji: "❄️", name: "Schnee"), snowman, Picture(emoji: "💧", name: "Wasser")],
                       wrong: [hen, apple, tree, butterfly],
                       fact: "Wenn die Sonne scheint, schmilzt der Schneemann zu Wasser."),
        GrowthSequence(steps: [Picture(emoji: "☁️", name: "Wolke"), Picture(emoji: "🌧️", name: "Regen"), rainbow],
                       wrong: [hen, apple, fish, hedgehog],
                       fact: "Nach dem Regen kommt die Sonne. Dann siehst du oft einen Regenbogen."),
    ]
}
