import Foundation

/// A speech voice installed on the device, reduced to what is needed to pick the softest one.
struct VoiceCandidate: Equatable, Identifiable {
    let identifier: String
    let name: String
    let language: String
    /// 1 = standard (compact), 2 = enhanced, 3 = premium.
    let quality: Int
    let isFemale: Bool
    /// Eloquence, novelty or personal voices – they never sound soft and natural.
    let isExcluded: Bool

    var id: String { identifier }

    var qualityLabel: String {
        switch quality {
        case 3: return "Premium"
        case 2: return "Erweitert"
        default: return "Standard"
        }
    }

    /// "Anna – Premium", "Leni (Österreich) – Erweitert"
    var label: String {
        let region: String
        switch language {
        case "de-AT": region = " (Österreich)"
        case "de-CH": region = " (Schweiz)"
        default: region = ""
        }
        return "\(name)\(region) – \(qualityLabel)"
    }
}

/// Picks the most natural German voice: premium before enhanced before standard; then German from Germany,
/// then a female voice (perceived as softer by most children), then a few voices known to sound friendly.
enum VoiceChooser {
    static let friendlyNames = ["Anna", "Petra", "Helena", "Marlene", "Katja"]

    static func isUsable(_ voice: VoiceCandidate) -> Bool {
        voice.language.hasPrefix("de") && !voice.isExcluded
    }

    static func score(_ voice: VoiceCandidate) -> Int {
        var score = voice.quality * 1000
        if voice.language == "de-DE" { score += 100 }
        if voice.isFemale { score += 50 }
        if let index = friendlyNames.firstIndex(where: { voice.name.hasPrefix($0) }) {
            score += friendlyNames.count - index
        }
        return score
    }

    /// Usable voices, best first.
    static func ranked(_ voices: [VoiceCandidate]) -> [VoiceCandidate] {
        voices.filter(isUsable).sorted { first, second in
            let a = score(first)
            let b = score(second)
            return a != b ? a > b : first.name < second.name
        }
    }

    static func best(from voices: [VoiceCandidate]) -> VoiceCandidate? {
        ranked(voices).first
    }

    /// True when only standard voices are installed – then parents get a tip to download a better one.
    static func onlyStandardVoices(in voices: [VoiceCandidate]) -> Bool {
        (best(from: voices)?.quality ?? 1) < 2
    }
}

/// How the text is spoken: calm, at natural pitch, with short pauses between sentences.
enum SpeechStyle {
    /// Factors of `AVSpeechUtteranceDefaultSpeechRate`.
    static let normalRate: Float = 0.86
    static let slowRate: Float = 0.74
    /// A raised pitch makes the system voices sound artificial, so they keep their natural pitch.
    static let pitch: Float = 1.0
    static let pauseBetweenSentences: TimeInterval = 0.28

    static let sample = "Hallo! Schön, dass du da bist. Wollen wir zusammen spielen?"

    /// "Super! Das sind 3 Enten." -> ["Super!", "Das sind 3 Enten."]
    static func sentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        let characters = Array(text)
        for (index, character) in characters.enumerated() {
            current.append(character)
            let isEnd = ".!?".contains(character)
            let nextIsSpace = index + 1 < characters.count && characters[index + 1] == " "
            if isEnd && (nextIsSpace || index + 1 == characters.count) {
                sentences.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            }
        }
        let rest = current.trimmingCharacters(in: .whitespaces)
        if !rest.isEmpty {
            sentences.append(rest)
        }
        return sentences
    }
}
