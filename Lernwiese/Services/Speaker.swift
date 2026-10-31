import AVFoundation

/// Reads tasks and answers aloud with the German system voice. Runs entirely on the device.
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "de-DE")

    /// Spoken instructions are part of the game, so they also play with the silent switch on; music is ducked.
    func prepareAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    /// - Parameter interrupt: stop what is being said; otherwise the text is queued behind it.
    func say(_ text: String, interrupt: Bool = true) {
        let settings = AppSettings.shared
        guard settings.speechEnabled, !settings.isDemo, !text.isEmpty else { return }
        if interrupt && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (settings.slowSpeech ? 0.78 : 0.92)
        utterance.pitchMultiplier = 1.1
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

enum Phrases {
    static let praise = ["Richtig!", "Super!", "Toll!", "Prima!", "Klasse!", "Genau!", "Sehr gut!"]
    static let tryAgain = [
        "Fast! Probier es noch einmal.",
        "Hmm, schau noch einmal genau hin.",
        "Versuch es noch einmal.",
        "Das ist es nicht. Du schaffst das!",
    ]

    static func randomPraise() -> String { praise.randomElement() ?? "Richtig!" }
    static func randomTryAgain() -> String { tryAgain.randomElement() ?? "Versuch es noch einmal." }
}
