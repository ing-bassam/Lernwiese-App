# Lernwiese – Lernspiele für Kinder (iPhone & iPad)

Fünfzehn kleine, eigene Lernspiele für Kinder von 4 bis 8 Jahren mit dem Igel Pieks: Zahlen, Tiere, Natur und
Knobeln. Alle Aufgaben werden mit der deutschen Systemstimme vorgelesen. Kein Zeitdruck, keine Strafen,
Fortschritt mit Sternen, ruhige selbst komponierte Musik und eine Bildschirmzeit-Begrenzung für Eltern.
Kostenlos: keine Werbung, keine Käufe, keine Anmeldung, keine Datenerfassung, keine Netzwerkverbindung.

## Spiele

| Welt | Spiel | Genre |
| --- | --- | --- |
| Zahlen | Zählen (Antippen zählt laut mit) | Zählen |
| Zahlen | Mehr oder weniger | Mengen vergleichen |
| Zahlen | Plus und Minus mit Bildern bis 10 | Rechnen |
| Tiere | Wo wohnt das Tier? | Zuordnen |
| Tiere | Futter-Paare (Tier + Futter) | Paare finden |
| Tiere | Tierbabys | Benennen |
| Natur | Jahreszeiten | Sortieren |
| Natur | Wetter | Zuordnen |
| Natur | Obst oder Gemüse | Sortieren |
| Natur | Was kommt danach? | Reihenfolgen |
| Knobeln | Formen-Garten (Dinge in Umrisse ziehen) | Formen, Feinmotorik |
| Knobeln | Muster legen | Logik |
| Knobeln | Schatten-Rätsel | Visuelle Wahrnehmung |
| Knobeln | Was passt nicht? | Oberbegriffe |
| Knobeln | Klang-Echo (Töne nachspielen) | Hören, Merken |

Jedes beendete Spiel gibt einen Stern (höchstens drei pro Spiel); die Sterne bestimmen die Schwierigkeit
(Stufe 0 bis 2: mehr Antworten, größere Zahlen, mehr Paare).

## Aufbau

| Bereich | Datei |
| --- | --- |
| Lerninhalte (Tiere, Futter, Jahreszeiten …) | `Lernwiese/Models/Content.swift` |
| Aufgaben je Spiel und Stufe | `Lernwiese/Models/RoundFactory.swift` |
| Paare-Spiel | `Lernwiese/Models/MemoryDeck.swift` |
| Sterne, Einstellungen, Elternschranke | `Lernwiese/Models/` |
| Vorlesen, Vibration | `Lernwiese/Services/` |
| Oberfläche | `Lernwiese/Views/` |
| Knobeln-Inhalte und -Aufgaben | `Lernwiese/Models/ThinkingContent.swift`, `RoundFactory+Thinking.swift`, `ShapeRound.swift` |
| Musik (Noten) und Klangerzeugung | `Lernwiese/Models/Songs.swift`, `Synth.swift`, `Services/MusicPlayer.swift` |
| Bildschirmzeit (Empfehlung, Zählung, Pause) | `Lernwiese/Models/ScreenTime.swift`, `Views/RestViews.swift` |
| Igel Pieks | `Lernwiese/Views/Mascot.swift` |
| Demo-Modus für Screenshots | `Lernwiese/Demo/DemoContent.swift` |

## Musik

Alle Melodien sind für Lernwiese geschrieben und stehen als Noten im Code (`Songs.swift`). `Synth.swift` macht
daraus beim Start Klänge (Spieluhr, Marimba, weicher Bass) – keine Audiodateien, keine KI, keine Lizenzen
Dritter. Bewusst ruhig: höchstens 80 Schläge pro Minute, kleiner Tonumfang, keine Fanfaren; beim Vorlesen wird
die Musik leiser. Neue Melodie: eine `Track`-Zeile wie `"C5:1 E5:1 G5:2"` (Ton:Schläge, `r` = Pause) schreiben.

## Bildschirmzeit

Empfehlung nach der Leitlinie AWMF S2k 027-075 (2023): 3–6 Jahre höchstens 30 Minuten, 6–9 Jahre höchstens
30–45 Minuten, nicht täglich und am besten gemeinsam; WHO (2019): 2–4 Jahre höchstens eine Stunde. Die App
stellt das Tageslimit nach dem Alter ein (30 bzw. 45 Minuten, änderbar), warnt 5 Minuten vorher und zeigt dann
einen Pausen-Bildschirm mit einer Idee ohne Bildschirm. Mehr Zeit nur hinter der Elternschranke.

Alle Grafiken sind SwiftUI-Formen, SF Symbols oder Emoji; das App-Symbol zeichnet `scripts/make_icon.py`.
Das Xcode-Projekt wird aus `project.yml` mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) erzeugt.

## Kids-Kategorie (App Store Review Guidelines 1.3 und 5.1.4)

- Keine Werbung, keine Analyse- oder Tracking-Werkzeuge, keine Datenerfassung, keine Netzwerkzugriffe.
- Links aus der App (Datenschutz, Hilfe) und die Einstellungen liegen nur im Eltern-Bereich hinter einer
  Elternschranke (Multiplikation mit zweistelliger Zahl, `ParentalGate.swift`).
- Datenschutzerklärung: `docs/datenschutz.html`.

## Bauen und veröffentlichen (ohne eigenen Mac mit Xcode 26)

Alles läuft in GitHub Actions auf macOS 26:

- **Build & Test** (`.github/workflows/ci.yml`): bei jedem Push – Release-Build, Unit-Tests im Simulator,
  Screenshots auf iPhone und iPad.
- **TestFlight & App Store** (`.github/workflows/release.yml`): manuell starten – archiviert, signiert über
  Apple Cloud Signing, lädt zu TestFlight hoch, lädt Texte und Screenshots hoch und reicht optional zur Prüfung ein.

Einmalig nötig im GitHub-Repository:

| Name | Art | Inhalt |
| --- | --- | --- |
| `ASC_KEY_ID` | Secret | Schlüssel-ID des App-Store-Connect-API-Schlüssels (Rolle „Admin“) |
| `ASC_ISSUER_ID` | Secret | Issuer-ID von derselben Seite |
| `ASC_KEY_P8` | Secret | Inhalt der heruntergeladenen Datei `AuthKey_XXXX.p8` |
| `TEAM_ID` | Variable | Team-ID aus developer.apple.com › Account › Mitgliedschaft |

Die drei Secrets setzt `scripts/setup_apple_key.command` per Doppelklick.

Datenschutzerklärung, Hilfe und Impressum liegen in `docs/` (GitHub Pages).
