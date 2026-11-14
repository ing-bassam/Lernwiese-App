import Foundation

/// Settings from the parents' area, stored only on the device.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Key {
        static let speech = "speechEnabled"
        static let slowSpeech = "slowSpeech"
        static let haptics = "hapticsEnabled"
        static let voice = "voiceIdentifier"
        static let music = "musicEnabled"
        static let musicVolume = "musicVolume"
        static let sounds = "soundsEnabled"
        static let childAge = "childAge"
        static let timeLimit = "timeLimitMinutes"
        static let hiddenGames = "hiddenGames"
    }

    @Published var speechEnabled: Bool {
        didSet { defaults.set(speechEnabled, forKey: Key.speech) }
    }

    @Published var slowSpeech: Bool {
        didSet { defaults.set(slowSpeech, forKey: Key.slowSpeech) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.haptics) }
    }

    /// Chosen voice; empty means "pick the most natural one automatically".
    @Published var voiceIdentifier: String {
        didSet { defaults.set(voiceIdentifier, forKey: Key.voice) }
    }

    /// Calm background music.
    @Published var musicEnabled: Bool {
        didSet { defaults.set(musicEnabled, forKey: Key.music) }
    }

    /// 0 to 1.
    @Published var musicVolume: Double {
        didSet { defaults.set(musicVolume, forKey: Key.musicVolume) }
    }

    /// Short soft sounds for right and wrong answers.
    @Published var soundsEnabled: Bool {
        didSet { defaults.set(soundsEnabled, forKey: Key.sounds) }
    }

    /// Age of the child (4 to 8); sets the recommended daily screen time.
    @Published var childAge: Int {
        didSet { defaults.set(childAge, forKey: Key.childAge) }
    }

    /// `ScreenTime.automatic` (by age), `ScreenTime.off`, or a number of minutes per day.
    @Published var timeLimitMinutes: Int {
        didSet { defaults.set(timeLimitMinutes, forKey: Key.timeLimit) }
    }

    /// Games the parents switched off; they do not appear on the meadow.
    @Published var hiddenGames: Set<String> {
        didSet { defaults.set(Array(hiddenGames).sorted(), forKey: Key.hiddenGames) }
    }

    /// Screenshot mode: never speaks, vibrates or plays sounds.
    var isDemo = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.speech: true, Key.slowSpeech: false, Key.haptics: true,
            Key.music: true, Key.musicVolume: 0.5, Key.sounds: true,
            Key.childAge: 5, Key.timeLimit: ScreenTime.automatic,
        ])
        speechEnabled = defaults.bool(forKey: Key.speech)
        slowSpeech = defaults.bool(forKey: Key.slowSpeech)
        hapticsEnabled = defaults.bool(forKey: Key.haptics)
        voiceIdentifier = defaults.string(forKey: Key.voice) ?? ""
        musicEnabled = defaults.bool(forKey: Key.music)
        musicVolume = min(1, max(0, defaults.double(forKey: Key.musicVolume)))
        soundsEnabled = defaults.bool(forKey: Key.sounds)
        childAge = min(ScreenTime.ages.upperBound, max(ScreenTime.ages.lowerBound, defaults.integer(forKey: Key.childAge)))
        timeLimitMinutes = defaults.integer(forKey: Key.timeLimit)
        hiddenGames = Set(defaults.stringArray(forKey: Key.hiddenGames) ?? [])
    }

    /// Minutes allowed per day, or nil when the parents switched the limit off.
    var dailyLimitMinutes: Int? {
        ScreenTime.limit(choice: timeLimitMinutes, age: childAge)
    }

    func isVisible(_ game: GameID) -> Bool {
        !hiddenGames.contains(game.rawValue)
    }

    func setVisible(_ visible: Bool, _ game: GameID) {
        if visible {
            hiddenGames.remove(game.rawValue)
        } else {
            hiddenGames.insert(game.rawValue)
        }
    }
}
