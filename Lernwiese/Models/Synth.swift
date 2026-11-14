import Foundation

/// Turns songs into audio samples. Pure Swift, no sound files and no third-party code: every sound in
/// Lernwiese is computed on the device from the notes in `Songs`.
enum Synth {
    static let sampleRate = 44_100.0

    static func frequency(of pitch: Int) -> Double {
        440 * pow(2, Double(pitch - 69) / 12)
    }

    /// Renders a song into mono samples between -1 and 1.
    /// - Parameter looping: notes that ring past the end are wrapped to the start, so the loop has no gap or click.
    static func render(_ song: Song, looping: Bool) -> [Float] {
        let secondsPerBeat = 60 / song.tempo
        let tail = looping ? 0 : 2.0
        let count = max(1, Int((song.seconds + tail) * sampleRate))
        var samples = [Float](repeating: 0, count: count)
        for event in song.events {
            add(event, secondsPerBeat: secondsPerBeat, into: &samples, wraps: looping)
        }
        normalize(&samples, peak: 0.8)
        if !looping {
            fadeOutEnd(&samples, seconds: 0.05)
        }
        return samples
    }

    /// How a note sounds: overtones (multiple of the base frequency, loudness) and how quickly it fades.
    struct Voice {
        let partials: [(multiple: Double, level: Double, decay: Double)]
        let attack: Double
        let release: Double
        /// Bells ring on after the note ends; pads stop when the note ends.
        let ringsOut: Bool
    }

    static func voice(for instrument: Instrument) -> Voice {
        switch instrument {
        case .musicBox:
            return Voice(partials: [(1, 1.0, 2.2), (2, 0.28, 3.5), (3, 0.08, 6), (4.2, 0.05, 9)],
                         attack: 0.004, release: 0.25, ringsOut: true)
        case .marimba:
            return Voice(partials: [(1, 1.0, 3.2), (4, 0.18, 12), (10, 0.03, 30)],
                         attack: 0.006, release: 0.15, ringsOut: true)
        case .pad:
            return Voice(partials: [(1, 1.0, 0.15), (2, 0.18, 0.4), (3, 0.05, 0.6)],
                         attack: 0.09, release: 0.35, ringsOut: false)
        }
    }

    private static func add(_ event: NoteEvent, secondsPerBeat: Double, into samples: inout [Float], wraps: Bool) {
        let voice = voice(for: event.instrument)
        let start = event.start * secondsPerBeat
        let held = event.length * secondsPerBeat
        // Bells ring up to 2.5 s; pads stop after the note plus a short release.
        let duration = voice.ringsOut ? max(held, 2.5) : held + voice.release
        let base = frequency(of: event.pitch)
        // Higher notes are a bit quieter, so the melody never sounds shrill.
        let loudness = event.volume * min(1, 1.25 - Double(event.pitch - 48) / 96)
        let first = Int(start * sampleRate)
        let length = Int(duration * sampleRate)
        let total = samples.count
        for offset in 0..<length {
            var index = first + offset
            if index >= total {
                guard wraps else { break }
                index %= total
            }
            let time = Double(offset) / sampleRate
            var envelope = min(1, time / voice.attack)
            if !voice.ringsOut && time > held {
                envelope *= max(0, 1 - (time - held) / voice.release)
            }
            if voice.ringsOut && time > duration - voice.release {
                envelope *= max(0, (duration - time) / voice.release)
            }
            var value = 0.0
            for partial in voice.partials {
                value += partial.level * exp(-partial.decay * time) * sin(2 * .pi * base * partial.multiple * time)
            }
            samples[index] += Float(value * envelope * loudness)
        }
    }

    private static func normalize(_ samples: inout [Float], peak: Float) {
        let loudest = samples.reduce(0) { max($0, abs($1)) }
        guard loudest > 0 else { return }
        let factor = min(peak / loudest, 1.5)
        for index in samples.indices {
            samples[index] *= factor
        }
    }

    private static func fadeOutEnd(_ samples: inout [Float], seconds: Double) {
        let count = min(samples.count, Int(seconds * sampleRate))
        guard count > 0 else { return }
        for step in 0..<count {
            samples[samples.count - count + step] *= Float(count - step) / Float(count)
        }
    }
}
