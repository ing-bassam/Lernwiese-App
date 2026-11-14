import SwiftUI

enum Links {
    static let privacy = URL(string: "https://ing-bassam.github.io/Lernwiese-App/datenschutz.html")!
    static let support = URL(string: "https://ing-bassam.github.io/Lernwiese-App/")!
}

/// The parents' area always starts locked; it is the only place with settings and links out of the app.
struct ParentFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var unlocked = DemoContent.launchScreen == "parents"

    var body: some View {
        if unlocked {
            ParentAreaView()
        } else {
            ParentGateView(onSuccess: { unlocked = true }, onCancel: { dismiss() })
        }
    }
}

struct ParentGateView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var gate = ParentalGate.random()
    @State private var input = ""
    @State private var shake = 0
    @State private var showsError = false

    private let keys = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["delete", "0", "ok"]]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button("Zurück", action: onCancel)
                        .font(.headline)
                }
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Tint.blue.color)
                    .accessibilityHidden(true)
                Text("Nur für Eltern")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Bitte löse die Aufgabe, um zu den Einstellungen zu gelangen.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text("\(gate.question) = ?")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .accessibilityLabel("Wie viel ist \(gate.spokenQuestion)?")
                Text(input.isEmpty ? " " : input)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .frame(minWidth: 170, minHeight: 64)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                    .modifier(Shake(animatableData: CGFloat(shake)))
                    .accessibilityLabel(input.isEmpty ? "Noch keine Eingabe" : "Eingabe \(input)")
                if showsError {
                    Text("Das war leider falsch. Hier ist eine neue Aufgabe.")
                        .font(.callout)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                keypad
            }
            .padding(24)
            .frame(maxWidth: 440)
            .frame(maxWidth: .infinity)
        }
    }

    private var keypad: some View {
        VStack(spacing: 10) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            press(key)
                        } label: {
                            keyLabel(key)
                                .font(.system(size: 26, weight: .semibold, design: .rounded))
                                .frame(width: 86, height: 60)
                                .background(RoundedRectangle(cornerRadius: 14)
                                    .fill(key == "ok" ? Color.accentColor : Color(.secondarySystemBackground)))
                                .foregroundColor(key == "ok" ? .white : .primary)
                        }
                        .accessibilityLabel(key == "delete" ? "Löschen" : key == "ok" ? "Bestätigen" : key)
                    }
                }
            }
        }
    }

    @ViewBuilder private func keyLabel(_ key: String) -> some View {
        switch key {
        case "delete": Image(systemName: "delete.left")
        case "ok": Text("OK")
        default: Text(key)
        }
    }

    private func press(_ key: String) {
        switch key {
        case "delete":
            if !input.isEmpty { input.removeLast() }
        case "ok":
            check()
        default:
            showsError = false
            if input.count < 3 { input.append(key) }
        }
    }

    private func check() {
        if gate.accepts(input) {
            onSuccess()
            return
        }
        withAnimation(.linear(duration: 0.45)) { shake += 1 }
        showsError = true
        input = ""
        gate = ParentalGate.random()
    }
}

struct ParentAreaView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var progress: ProgressStore
    @ObservedObject private var playTime = PlayTimeStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false
    @State private var voices = Speaker.shared.germanVoices()

    var body: some View {
        NavigationStack {
            Form {
                screenTimeSection

                Section {
                    Toggle("Ruhige Musik", isOn: $settings.musicEnabled)
                    HStack {
                        Image(systemName: "speaker.fill").foregroundColor(.secondary)
                        Slider(value: $settings.musicVolume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill").foregroundColor(.secondary)
                    }
                    .disabled(!settings.musicEnabled)
                    .accessibilityLabel("Lautstärke der Musik")
                    Toggle("Sanfte Klänge bei Antworten", isOn: $settings.soundsEnabled)
                } header: {
                    Text("Musik und Klänge")
                } footer: {
                    Text("Alle Melodien wurden für Lernwiese geschrieben und werden direkt auf dem Gerät erzeugt: langsam, leise und ohne Fanfaren. Beim Vorlesen wird die Musik automatisch leiser.")
                }

                Section {
                    Toggle("Aufgaben vorlesen", isOn: $settings.speechEnabled)
                    Picker("Stimme", selection: $settings.voiceIdentifier) {
                        Text("Automatisch – die natürlichste").tag("")
                        ForEach(voices) { voice in
                            Text(voice.label).tag(voice.identifier)
                        }
                    }
                    .disabled(!settings.speechEnabled)
                    Toggle("Langsamer sprechen", isOn: $settings.slowSpeech)
                        .disabled(!settings.speechEnabled)
                    Button {
                        Speaker.shared.preview()
                    } label: {
                        Label("Stimme probehören", systemImage: "play.circle.fill")
                    }
                } header: {
                    Text("Vorlesen")
                } footer: {
                    Text(voiceFooter)
                }

                Section("Rückmeldung") {
                    Toggle("Vibration bei Antworten", isOn: $settings.hapticsEnabled)
                }

                Section {
                    ForEach(World.allCases) { world in
                        ForEach(world.games) { game in
                            Toggle(isOn: Binding(get: { settings.isVisible(game) },
                                                 set: { settings.setVisible($0, game) })) {
                                HStack(spacing: 12) {
                                    Text(game.emoji).font(.title2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(game.title)
                                        Text(game.skill).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    StarsView(count: progress.stars(for: game), size: 12)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Spiele und Fortschritt")
                } footer: {
                    Text("Ausgeschaltete Spiele erscheinen nicht auf der Wiese. Für jedes beendete Spiel gibt es einen Stern, bis zu drei pro Spiel. Mit jedem Stern werden die Aufgaben etwas schwieriger.")
                }

                Section {
                    LabeledContent("Gesammelte Sterne", value: "\(progress.total) von \(progress.maximum)")
                    Button("Fortschritt zurücksetzen", role: .destructive) {
                        confirmingReset = true
                    }
                }

                Section("Über Lernwiese") {
                    Text("Lernwiese ist ein kostenloses Lernspiel für Kinder von 4 bis 8 Jahren: Zahlen, Tiere, Natur und Knobeln in \(GameID.allCases.count) kleinen Spielen mit dem Igel Pieks. Es gibt keinen Zeitdruck und keine Strafen.")
                    Text("Keine Werbung, keine In-App-Käufe, keine Anmeldung, keine Cookies, keine Tracker und keine Datenerfassung. Die App funktioniert vollständig offline; Spielzeit und Sterne bleiben nur auf diesem Gerät.")
                }

                Section("Links") {
                    Link(destination: Links.privacy) {
                        Label("Datenschutzerklärung", systemImage: "hand.raised.fill")
                    }
                    Link(destination: Links.support) {
                        Label("Hilfe, Kontakt und Impressum", systemImage: "questionmark.circle.fill")
                    }
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Eltern-Bereich")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .confirmationDialog("Alle Sterne löschen?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Sterne löschen", role: .destructive) { progress.reset() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Alle Spiele beginnen dann wieder auf der leichtesten Stufe.")
            }
            .onChange(of: settings.musicEnabled) { _ in MusicPlayer.shared.settingsChanged() }
            .onChange(of: settings.musicVolume) { _ in MusicPlayer.shared.settingsChanged() }
        }
    }

    // MARK: - Screen time

    private var screenTimeSection: some View {
        Section {
            LabeledContent("Heute gespielt", value: minutesText(playTime.todaySeconds / 60))
            if let limit = settings.dailyLimitMinutes {
                LabeledContent("Heute erlaubt", value: minutesText(limit + playTime.todayExtraMinutes))
            }
            PlayTimeChart(history: playTime.history(days: 7), limit: settings.dailyLimitMinutes)
                .frame(height: 130)
                .padding(.vertical, 6)
            Picker("Alter des Kindes", selection: $settings.childAge) {
                ForEach(ScreenTime.ages, id: \.self) { age in
                    Text("\(age) Jahre").tag(age)
                }
            }
            Picker("Tägliche Spielzeit", selection: $settings.timeLimitMinutes) {
                Text("Empfohlen: \(ScreenTime.recommendedMinutes(age: settings.childAge)) Minuten").tag(ScreenTime.automatic)
                ForEach(ScreenTime.choices, id: \.self) { minutes in
                    Text("\(minutes) Minuten").tag(minutes)
                }
                Text("Kein Limit").tag(ScreenTime.off)
            }
            if settings.dailyLimitMinutes != nil {
                Button {
                    playTime.allowExtraTime()
                } label: {
                    Label("Heute \(ScreenTime.extraMinutes) Minuten mehr erlauben", systemImage: "plus.circle.fill")
                }
                Button {
                    playTime.resetToday()
                } label: {
                    Label("Spielzeit von heute zurücksetzen", systemImage: "arrow.counterclockwise")
                }
            }
        } header: {
            Text("Bildschirmzeit")
        } footer: {
            Text("""
            Kinderärztinnen und Kinderärzte empfehlen für 3- bis 6-Jährige höchstens 30 Minuten und für 6- bis 9-Jährige höchstens 30 bis 45 Minuten Bildschirmzeit, und das nicht jeden Tag – am besten gemeinsam mit Ihnen (Leitlinie AWMF 027-075, 2023). Die WHO rät für 2- bis 4-Jährige zu höchstens einer Stunde, weniger ist besser.

            5 Minuten vor Ende sagt Pieks freundlich Bescheid. Danach erscheint ein Pausen-Bildschirm mit einer Idee für Bewegung oder Spiel ohne Bildschirm. Mehr Zeit gibt es nur über die Rechenaufgabe für Erwachsene. Gezählt wird nur, solange Lernwiese geöffnet ist.
            """)
        }
    }

    private func minutesText(_ minutes: Int) -> String {
        minutes == 1 ? "1 Minute" : "\(minutes) Minuten"
    }

    private var voiceFooter: String {
        let onDevice = "Die Sprachausgabe ist in iOS eingebaut und läuft vollständig auf dem Gerät."
        guard VoiceChooser.onlyStandardVoices(in: voices) else { return onDevice }
        return "Tipp für eine besonders sanfte, natürliche Stimme: Lade kostenlos eine Premium-Stimme unter Einstellungen › Bedienungshilfen › Gesprochene Inhalte › Stimmen › Deutsch, z. B. „Anna (Premium)“. Lernwiese nutzt sie danach automatisch. " + onDevice
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

/// Bars for the minutes played on the last days; the dashed line is the daily limit.
struct PlayTimeChart: View {
    let history: [(day: Date, minutes: Int)]
    let limit: Int?

    private static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.setLocalizedDateFormatFromTemplate("EE")
        return formatter
    }()

    var body: some View {
        GeometryReader { geo in
            let top = max(Double(limit ?? 0), Double(history.map(\.minutes).max() ?? 0), 10) * 1.15
            let chartHeight = geo.size.height - 22
            ZStack(alignment: .bottomLeading) {
                if let limit {
                    let y = chartHeight * (1 - CGFloat(Double(limit) / top))
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                }
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(history.indices, id: \.self) { index in
                        let entry = history[index]
                        let over = limit.map { entry.minutes > $0 } ?? false
                        VStack(spacing: 4) {
                            Text("\(entry.minutes)")
                                .font(.caption2.monospacedDigit())
                                .foregroundColor(.secondary)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(over ? Tint.orange.color : Tint.green.color)
                                .frame(height: max(3, (chartHeight - 16) * CGFloat(Double(entry.minutes) / top)))
                            Text(Self.weekday.string(from: entry.day))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spielzeit der letzten sieben Tage: " +
                            history.map { "\(Self.weekday.string(from: $0.day)) \($0.minutes) Minuten" }.joined(separator: ", "))
    }
}
