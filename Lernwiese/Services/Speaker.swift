import AVFoundation

/// Reads tasks and answers aloud with the most natural German voice on the device. Runs entirely on the device.
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()
    private var automaticVoice: AVSpeechSynthesisVoice?

    override init() {
        super.init()
        synthesizer.delegate = self
        refreshVoices()
    }

    // The background music gets quieter while something is read aloud.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { MusicPlayer.shared.duck(true) }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        unduckWhenQuiet()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        unduckWhenQuiet()
    }

    private func unduckWhenQuiet() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, !self.synthesizer.isSpeaking else { return }
            MusicPlayer.shared.duck(false)
        }
    }

    /// Spoken instructions are part of the game, so they also play with the silent switch on; music from other
    /// apps is ducked. Lernwiese's own music can be switched off in the parents' area.
    func prepareAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
    }

    /// Looks for the best voice again – parents may have downloaded a premium voice in the meantime.
    func refreshVoices() {
        let best = VoiceChooser.best(from: germanVoices())
        automaticVoice = best.flatMap { AVSpeechSynthesisVoice(identifier: $0.identifier) }
            ?? AVSpeechSynthesisVoice(language: "de-DE")
    }

    /// Installed German voices that sound natural, best first.
    func germanVoices() -> [VoiceCandidate] {
        VoiceChooser.ranked(AVSpeechSynthesisVoice.speechVoices().map(Self.candidate))
    }

    var automaticVoiceName: String? {
        automaticVoice.map { Self.candidate($0).label }
    }

    /// - Parameter interrupt: stop what is being said; otherwise the text is queued behind it.
    func say(_ text: String, interrupt: Bool = true) {
        let settings = AppSettings.shared
        guard settings.speechEnabled, !settings.isDemo, !text.isEmpty else { return }
        speak(text, interrupt: interrupt)
    }

    /// Sample for the parents' area; plays even when reading aloud is switched off.
    func preview() {
        guard !AppSettings.shared.isDemo else { return }
        speak(SpeechStyle.sample, interrupt: true)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func speak(_ text: String, interrupt: Bool) {
        if interrupt && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let settings = AppSettings.shared
        let voice = selectedVoice(settings.voiceIdentifier)
        let rate = AVSpeechUtteranceDefaultSpeechRate * (settings.slowSpeech ? SpeechStyle.slowRate : SpeechStyle.normalRate)
        // One utterance per sentence gives short, natural pauses instead of reading everything in one breath.
        for sentence in SpeechStyle.sentences(text) {
            let utterance = AVSpeechUtterance(string: sentence)
            utterance.voice = voice
            utterance.rate = rate
            utterance.pitchMultiplier = SpeechStyle.pitch
            utterance.postUtteranceDelay = SpeechStyle.pauseBetweenSentences
            synthesizer.speak(utterance)
        }
    }

    private func selectedVoice(_ identifier: String) -> AVSpeechSynthesisVoice? {
        if !identifier.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        return automaticVoice
    }

    private static func candidate(_ voice: AVSpeechSynthesisVoice) -> VoiceCandidate {
        let quality: Int
        switch voice.quality {
        case .premium: quality = 3
        case .enhanced: quality = 2
        default: quality = 1
        }
        var excluded = voice.identifier.contains("eloquence") || voice.identifier.contains("speech.synthesis.voice")
        if #available(iOS 17.0, *) {
            excluded = excluded || voice.voiceTraits.contains(.isNoveltyVoice) || voice.voiceTraits.contains(.isPersonalVoice)
        }
        return VoiceCandidate(identifier: voice.identifier, name: voice.name, language: voice.language,
                              quality: quality, isFemale: voice.gender == .female, isExcluded: excluded)
    }
}

enum Phrases {
    static let praise = ["Richtig!", "Super!", "Toll gemacht!", "Prima!", "Sehr schön!", "Genau!", "Gut gemacht!"]
    static let tryAgain = [
        "Fast. Probier es noch einmal.",
        "Hmm, schau noch einmal genau hin.",
        "Versuch es noch einmal.",
        "Das ist es nicht. Du schaffst das.",
    ]

    static func randomPraise() -> String { praise.randomElement() ?? "Richtig!" }
    static func randomTryAgain() -> String { tryAgain.randomElement() ?? "Versuch es noch einmal." }
}
