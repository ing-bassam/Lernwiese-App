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
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false
    @State private var voices = Speaker.shared.germanVoices()

    var body: some View {
        NavigationStack {
            Form {
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
                    LabeledContent("Gesammelte Sterne", value: "\(progress.total) von \(progress.maximum)")
                    Button("Fortschritt zurücksetzen", role: .destructive) {
                        confirmingReset = true
                    }
                } header: {
                    Text("Fortschritt")
                } footer: {
                    Text("Für jedes beendete Spiel gibt es einen Stern, bis zu drei pro Spiel. Mit jedem Stern werden die Aufgaben etwas schwieriger.")
                }

                Section("Über Lernwiese") {
                    Text("Lernwiese ist ein Lernspiel für Kinder von 4 bis 8 Jahren: Zahlen, Tiere und Natur in zehn kleinen Spielen. Es gibt keinen Zeitdruck und keine Strafen.")
                    Text("Keine Werbung, keine In-App-Käufe, keine Anmeldung und keine Datenerfassung. Die App funktioniert vollständig offline.")
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
        }
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
