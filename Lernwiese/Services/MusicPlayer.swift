import AVFoundation

/// Plays the background music and the short sounds. Everything is rendered on the device by `Synth`;
/// there are no audio files, no streaming and nothing leaves the device.
final class MusicPlayer {
    static let shared = MusicPlayer()

    enum Mood: Equatable {
        case meadow, play, rest, silent

        var song: Song? {
            switch self {
            case .meadow: return Songs.meadow
            case .play: return Songs.play
            case .rest: return Songs.lullaby
            case .silent: return nil
            }
        }
    }

    private let engine = AVAudioEngine()
    private let musicNode = AVAudioPlayerNode()
    private let soundNode = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 1)!
    private let renderQueue = DispatchQueue(label: "Lernwiese.Synth", qos: .userInitiated)

    private var loops: [String: AVAudioPCMBuffer] = [:]
    private var sounds: [String: AVAudioPCMBuffer] = [:]
    private var mood: Mood = .silent
    private var isDucked = false
    private var isSetUp = false

    private var settings: AppSettings { AppSettings.shared }
    private var isAllowed: Bool { !settings.isDemo }

    private init() {}

    /// Builds the audio graph and renders all songs in the background, so the first play has no delay.
    func prepare() {
        guard isAllowed, !isSetUp else { return }
        isSetUp = true
        engine.attach(musicNode)
        engine.attach(soundNode)
        engine.connect(musicNode, to: engine.mainMixerNode, format: format)
        engine.connect(soundNode, to: engine.mainMixerNode, format: format)
        applyVolume()
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil,
                                               queue: .main) { [weak self] note in
            self?.handleInterruption(note)
        }
        renderQueue.async { [weak self] in
            guard let self else { return }
            var rendered: [String: AVAudioPCMBuffer] = [:]
            for song in Songs.all {
                rendered[song.title] = self.buffer(Synth.render(song, looping: true))
            }
            var effects: [String: AVAudioPCMBuffer] = [:]
            for song in [Songs.correct, Songs.tryAgain, Songs.finish] + (0..<Songs.flowerPitches.count).map(Songs.flower) {
                effects[song.title] = self.buffer(Synth.render(song, looping: false))
            }
            DispatchQueue.main.async {
                self.loops = rendered
                self.sounds = effects
                self.startMood()
            }
        }
    }

    /// Switches to the music for the current screen. Songs fade over instead of cutting off.
    func setMood(_ newMood: Mood) {
        guard newMood != mood else { return }
        mood = newMood
        startMood()
    }

    /// Called by the settings when music is switched on or off or the volume changes.
    func settingsChanged() {
        applyVolume()
        startMood()
    }

    /// Back from the background: the system may have stopped the engine.
    func resume() {
        guard isSetUp, !musicNode.isPlaying || !engine.isRunning else { return }
        startMood()
    }

    /// Music gets quieter while a task is read aloud.
    func duck(_ ducked: Bool) {
        guard ducked != isDucked else { return }
        isDucked = ducked
        applyVolume()
    }

    // MARK: - Short sounds

    func playCorrect() { playSound(Songs.correct.title) }
    func playTryAgain() { playSound(Songs.tryAgain.title) }
    func playFinish() { playSound(Songs.finish.title) }

    /// Tones of the "Klang-Echo" game; they are part of the game and play even with the music switched off.
    func playFlower(_ index: Int) {
        playSound(Songs.flower(index).title, force: true)
    }

    private func playSound(_ title: String, force: Bool = false) {
        guard isAllowed, force || settings.soundsEnabled, let buffer = sounds[title] else { return }
        guard startEngine() else { return }
        soundNode.scheduleBuffer(buffer, at: nil, options: [.interrupts])
        if !soundNode.isPlaying { soundNode.play() }
    }

    // MARK: - Private

    private func startMood() {
        guard isAllowed, isSetUp else { return }
        guard settings.musicEnabled, let song = mood.song, let buffer = loops[song.title] else {
            musicNode.stop()
            return
        }
        guard startEngine() else { return }
        musicNode.stop()
        musicNode.scheduleBuffer(buffer, at: nil, options: [.loops])
        musicNode.volume = 0
        musicNode.play()
        fadeIn()
    }

    private func fadeIn() {
        let target = musicVolume
        let steps = 20
        for step in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06 * Double(step)) { [weak self] in
                guard let self else { return }
                self.musicNode.volume = min(self.musicVolume, target * Float(step) / Float(steps))
            }
        }
    }

    private var musicVolume: Float {
        let base = Float(settings.musicVolume) * 0.6
        return isDucked ? base * 0.35 : base
    }

    private func applyVolume() {
        musicNode.volume = musicVolume
        soundNode.volume = 0.55
    }

    @discardableResult
    private func startEngine() -> Bool {
        if engine.isRunning { return true }
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    private func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
        startMood()
    }

    private func buffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            channel.update(from: source.baseAddress!, count: samples.count)
        }
        return buffer
    }
}
