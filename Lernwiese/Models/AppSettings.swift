import Foundation

/// Settings from the parents' area, stored only on the device.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Key {
        static let speech = "speechEnabled"
        static let slowSpeech = "slowSpeech"
        static let haptics = "hapticsEnabled"
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

    /// Screenshot mode: never speaks or vibrates.
    var isDemo = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Key.speech: true, Key.slowSpeech: false, Key.haptics: true])
        speechEnabled = defaults.bool(forKey: Key.speech)
        slowSpeech = defaults.bool(forKey: Key.slowSpeech)
        hapticsEnabled = defaults.bool(forKey: Key.haptics)
    }
}
