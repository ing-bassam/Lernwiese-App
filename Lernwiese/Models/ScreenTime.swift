import Foundation

/// Daily screen time as recommended for young children.
///
/// German guideline of the paediatric societies (AWMF S2k 027-075, "Prävention dysregulierten
/// Bildschirmmediengebrauchs", 2023): 3 to 6 years at most 30 minutes, 6 to 9 years at most 30 to 45 minutes,
/// not every day and preferably together with a parent. WHO (2019): 2 to 4 years no more than one hour,
/// less is better.
enum ScreenTime {
    static let automatic = 0
    static let off = -1
    static let ages = 4...8
    static let choices = [10, 15, 20, 30, 45, 60]
    /// The gentle "a few more minutes" notice comes this many minutes before the end.
    static let warningMinutes = 5
    /// Extra time parents can allow after the limit, behind the parental gate.
    static let extraMinutes = 15

    static func recommendedMinutes(age: Int) -> Int {
        age < 6 ? 30 : 45
    }

    static func limit(choice: Int, age: Int) -> Int? {
        switch choice {
        case off: return nil
        case automatic: return recommendedMinutes(age: age)
        default: return max(1, choice)
        }
    }

    enum Status: Equatable {
        case free
        case almost(minutesLeft: Int)
        case over
    }

    static func status(playedSeconds: Int, limitMinutes: Int?, extraMinutes: Int) -> Status {
        guard let limitMinutes else { return .free }
        let allowed = (limitMinutes + extraMinutes) * 60
        if playedSeconds >= allowed { return .over }
        let left = allowed - playedSeconds
        if left <= warningMinutes * 60 {
            return .almost(minutesLeft: max(1, Int((Double(left) / 60).rounded(.up))))
        }
        return .free
    }

    /// Ideas for the break, read aloud on the rest screen. Movement, fresh air and doing something together.
    static let breakIdeas: [(emoji: String, text: String)] = [
        ("🐸", "Hüpf zehnmal wie ein Frosch."),
        ("🌳", "Geh nach draußen und such drei verschiedene Blätter."),
        ("🦩", "Steh auf einem Bein wie ein Flamingo. Wie lange schaffst du es?"),
        ("🐻", "Krabbel wie ein Bär einmal durchs Zimmer."),
        ("🎨", "Mal ein Bild von deinem Lieblingstier."),
        ("🧱", "Bau einen hohen Turm aus Bausteinen."),
        ("💧", "Trink ein Glas Wasser."),
        ("📚", "Schau dir mit Mama oder Papa ein Bilderbuch an."),
        ("🙆", "Streck dich ganz groß wie ein Baum und mach dich dann ganz klein wie eine Maus."),
        ("🐞", "Such draußen einen Käfer, eine Blume und einen Stein."),
        ("👀", "Schau aus dem Fenster: Was siehst du ganz weit weg?"),
        ("🎵", "Sing ein Lied und klatsch dazu."),
    ]
}

/// Counts how long the app was open each day. Only on the device; the last 30 days are kept.
final class PlayTimeStore: ObservableObject {
    static let shared = PlayTimeStore()

    @Published private(set) var secondsByDay: [String: Int]
    @Published private(set) var extraMinutesByDay: [String: Int]

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date
    private var timer: Timer?
    private var unsavedSeconds = 0

    private enum Key {
        static let seconds = "playSeconds"
        static let extra = "extraMinutes"
    }

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        secondsByDay = defaults.dictionary(forKey: Key.seconds) as? [String: Int] ?? [:]
        extraMinutesByDay = defaults.dictionary(forKey: Key.extra) as? [String: Int] ?? [:]
    }

    func dayKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    var todaySeconds: Int { secondsByDay[dayKey(now())] ?? 0 }
    var todayExtraMinutes: Int { extraMinutesByDay[dayKey(now())] ?? 0 }

    func status(settings: AppSettings) -> ScreenTime.Status {
        ScreenTime.status(playedSeconds: todaySeconds, limitMinutes: settings.dailyLimitMinutes,
                          extraMinutes: todayExtraMinutes)
    }

    /// Minutes per day for the last `days` days, oldest first.
    func history(days: Int) -> [(day: Date, minutes: Int)] {
        let today = calendar.startOfDay(for: now())
        return (0..<days).reversed().compactMap { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            return (day, (secondsByDay[dayKey(day)] ?? 0) / 60)
        }
    }

    func add(seconds: Int) {
        guard seconds > 0 else { return }
        let key = dayKey(now())
        secondsByDay[key, default: 0] += seconds
        unsavedSeconds += seconds
        if unsavedSeconds >= 15 {
            save()
        }
    }

    /// Parents allow a bit more time today.
    func allowExtraTime() {
        extraMinutesByDay[dayKey(now()), default: 0] += ScreenTime.extraMinutes
        save()
    }

    /// Screenshot mode: a believable week, oldest day first. Nothing is saved.
    func fillForDemo(minutesPerDay: [Int]) {
        let today = calendar.startOfDay(for: now())
        for (offset, minutes) in minutesPerDay.reversed().enumerated() {
            if let day = calendar.date(byAdding: .day, value: -offset, to: today) {
                secondsByDay[dayKey(day)] = minutes * 60
            }
        }
    }

    func resetToday() {
        let key = dayKey(now())
        secondsByDay[key] = nil
        extraMinutesByDay[key] = nil
        save()
    }

    /// Counts while the app is in the foreground.
    func startCounting() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.add(seconds: 1)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stopCounting() {
        timer?.invalidate()
        timer = nil
        save()
    }

    func save() {
        unsavedSeconds = 0
        let oldest = dayKey(calendar.date(byAdding: .day, value: -30, to: now()) ?? now())
        secondsByDay = secondsByDay.filter { $0.key >= oldest }
        extraMinutesByDay = extraMinutesByDay.filter { $0.key >= oldest }
        defaults.set(secondsByDay, forKey: Key.seconds)
        defaults.set(extraMinutesByDay, forKey: Key.extra)
    }
}
