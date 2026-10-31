# Lernwiese – Lernspiele für Kinder (iPhone & iPad)

Zehn kleine, eigene Lernspiele für Kinder von 4 bis 8 Jahren rund um Zahlen, Tiere und Natur. Alle Aufgaben
werden mit der deutschen Systemstimme vorgelesen. Kein Zeitdruck, keine Strafen, Fortschritt mit Sternen.
Keine Werbung, keine Käufe, keine Anmeldung, keine Datenerfassung, keine Netzwerkverbindung.

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
| Demo-Modus für Screenshots | `Lernwiese/Demo/DemoContent.swift` |

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
