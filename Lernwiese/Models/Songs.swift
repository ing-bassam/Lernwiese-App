import Foundation

/// Sound colours of the built-in synthesizer. All of them are soft and have no sharp attack.
enum Instrument: Equatable {
    /// Bright, quickly fading bell like a music box.
    case musicBox
    /// Warm wooden tone like a marimba.
    case marimba
    /// Soft, round tone for the bass and long chord notes.
    case pad
}

/// One note of a song. Times are in beats.
struct NoteEvent: Equatable {
    let start: Double
    let length: Double
    /// MIDI note number, 60 = middle C.
    let pitch: Int
    let volume: Double
    let instrument: Instrument
}

/// A melody line written in a tiny text notation, e.g. `"C5:1 E5:0.5 r:0.5 G5:2"`.
/// Each token is a note name (C, C#, D, … B with octave) or `r` for a rest, followed by `:` and the length
/// in beats. `|` separates bars and is only there for readability.
struct Track {
    let notes: String
    let instrument: Instrument
    let volume: Double

    /// The notes as events; unknown tokens are skipped.
    var events: [NoteEvent] {
        var events: [NoteEvent] = []
        var time = 0.0
        for token in notes.split(whereSeparator: { $0 == " " || $0 == "\n" }) where token != "|" {
            let parts = token.split(separator: ":")
            guard parts.count == 2, let length = Double(parts[1]), length > 0 else { continue }
            let name = String(parts[0])
            if let pitch = Track.midi(name) {
                events.append(NoteEvent(start: time, length: length, pitch: pitch, volume: volume, instrument: instrument))
            }
            time += length
        }
        return events
    }

    /// Length of the line in beats.
    var beats: Double {
        notes.split(whereSeparator: { $0 == " " || $0 == "\n" }).reduce(0) { sum, token in
            let parts = token.split(separator: ":")
            return sum + (parts.count == 2 ? Double(parts[1]) ?? 0 : 0)
        }
    }

    /// "C4" -> 60, "F#3" -> 54, "Bb4" -> 70, "r" -> nil
    static func midi(_ name: String) -> Int? {
        let steps: [Character: Int] = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]
        guard let letter = name.first, let step = steps[letter] else { return nil }
        var rest = name.dropFirst()
        var accidental = 0
        if rest.first == "#" { accidental = 1; rest = rest.dropFirst() }
        else if rest.first == "b" { accidental = -1; rest = rest.dropFirst() }
        guard let octave = Int(rest) else { return nil }
        return (octave + 1) * 12 + step + accidental
    }
}

/// A short piece that loops seamlessly.
struct Song {
    let title: String
    /// Beats per minute – all songs are slow and calm.
    let tempo: Double
    let events: [NoteEvent]
    let beats: Double

    init(title: String, tempo: Double, tracks: [Track]) {
        self.title = title
        self.tempo = tempo
        events = tracks.flatMap(\.events)
        beats = tracks.map(\.beats).max() ?? 0
    }

    init(title: String, tempo: Double, events: [NoteEvent]) {
        self.title = title
        self.tempo = tempo
        self.events = events
        beats = events.map { $0.start + $0.length }.max() ?? 0
    }

    var seconds: Double { beats * 60 / tempo }
}

/// Original music, composed for Lernwiese. Deliberately calm: slow tempo, soft sounds, a small range of notes,
/// no build-ups and no fanfares, so the music accompanies the game without pushing the child.
enum Songs {
    /// On the meadow (home screen). C major, 76 BPM, 16 bars.
    static let meadow = Song(title: "Wiesenlied", tempo: 76, tracks: [
        Track(notes: """
        E5:1 G5:1 A5:1 G5:1 | E5:2 D5:1 C5:1 | D5:1 E5:1 G5:1 E5:1 | D5:3 r:1 |
        C5:1 D5:1 E5:1 G5:1 | A5:2 G5:1 E5:1 | G5:1 E5:1 D5:1 E5:1 | C5:3 r:1 |
        A4:1 C5:1 D5:1 C5:1 | E5:2 D5:1 C5:1 | D5:1 C5:1 A4:1 G4:1 | A4:3 r:1 |
        C5:1 E5:1 G5:1 A5:1 | G5:2 E5:1 D5:1 | E5:1 D5:1 C5:1 D5:1 | C5:4 |
        """, instrument: .musicBox, volume: 0.55),
        Track(notes: """
        C3:2 G3:2 | A2:2 E3:2 | F2:2 C3:2 | G2:2 D3:2 |
        C3:2 G3:2 | F2:2 C3:2 | G2:2 D3:2 | C3:2 G3:2 |
        A2:2 E3:2 | C3:2 G3:2 | F2:2 C3:2 | E2:2 A2:2 |
        F2:2 C3:2 | C3:2 G3:2 | G2:2 D3:2 | C3:4 |
        """, instrument: .pad, volume: 0.5),
        Track(notes: """
        r:1 E4:1 r:1 G4:1 | r:1 C4:1 r:1 E4:1 | r:1 A3:1 r:1 C4:1 | r:1 B3:1 r:1 D4:1 |
        r:1 E4:1 r:1 G4:1 | r:1 A3:1 r:1 C4:1 | r:1 B3:1 r:1 D4:1 | r:1 E4:1 r:1 G4:1 |
        r:1 C4:1 r:1 E4:1 | r:1 E4:1 r:1 G4:1 | r:1 A3:1 r:1 C4:1 | r:1 C4:1 r:1 E4:1 |
        r:1 A3:1 r:1 C4:1 | r:1 E4:1 r:1 G4:1 | r:1 B3:1 r:1 D4:1 | r:1 E4:1 r:1 G4:1 |
        """, instrument: .marimba, volume: 0.25),
    ])

    /// While playing a game: quieter and simpler, so the spoken tasks stay in front. F major, 70 BPM, 8 bars.
    static let play = Song(title: "Spiellied", tempo: 70, tracks: [
        Track(notes: """
        F4:1 A4:1 C5:2 | D5:1 C5:1 A4:2 | G4:1 A4:1 C5:1 A4:1 | G4:4 |
        F4:1 A4:1 C5:2 | D5:1 F5:1 D5:2 | C5:1 A4:1 G4:1 A4:1 | F4:4 |
        """, instrument: .marimba, volume: 0.42),
        Track(notes: """
        F2:4 | Bb2:4 | C3:4 | C3:4 |
        F2:4 | Bb2:4 | C3:4 | F2:4 |
        """, instrument: .pad, volume: 0.45),
    ])

    /// Lullaby for the break screen. 3/4 time, 60 BPM, 8 bars.
    static let lullaby = Song(title: "Pausenlied", tempo: 60, tracks: [
        Track(notes: """
        G4:2 E4:1 | G4:2 E4:1 | A4:1 G4:1 E4:1 | D4:3 |
        F4:2 D4:1 | F4:2 D4:1 | E4:1 D4:1 B3:1 | C4:3 |
        """, instrument: .musicBox, volume: 0.45),
        Track(notes: """
        C3:3 | C3:3 | F2:3 | G2:3 |
        G2:3 | G2:3 | G2:3 | C3:3 |
        """, instrument: .pad, volume: 0.45),
    ])

    static let all = [meadow, play, lullaby]

    // MARK: - Short sounds

    /// Three soft rising notes after a right answer.
    static let correct = Song(title: "Richtig", tempo: 240, tracks: [
        Track(notes: "C6:1 E6:1 G6:3", instrument: .musicBox, volume: 0.5),
    ])

    /// One quiet, low note for a wrong answer – never a buzzer.
    static let tryAgain = Song(title: "Nochmal", tempo: 120, tracks: [
        Track(notes: "E4:1.5", instrument: .marimba, volume: 0.35),
    ])

    /// Gentle arpeggio at the end of a game.
    static let finish = Song(title: "Fertig", tempo: 200, tracks: [
        Track(notes: "C5:1 E5:1 G5:1 C6:4", instrument: .musicBox, volume: 0.5),
        Track(notes: "r:3 C4:4", instrument: .pad, volume: 0.35),
    ])

    /// The four flowers of the "Klang-Echo" game: C, E, G and A form a pentatonic set that always sounds nice.
    static let flowerPitches = [72, 76, 79, 81]

    static func flower(_ index: Int) -> Song {
        let pitch = flowerPitches[max(0, min(index, flowerPitches.count - 1))]
        return Song(title: "Blume \(index + 1)", tempo: 120, events: [
            NoteEvent(start: 0, length: 1.6, pitch: pitch, volume: 0.6, instrument: .marimba),
        ])
    }
}
