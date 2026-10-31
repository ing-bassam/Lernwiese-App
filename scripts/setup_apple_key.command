#!/bin/bash
# Hinterlegt den App-Store-Connect-API-Schlüssel als GitHub-Secrets für Lernwiese.
# Per Doppelklick starten, nachdem die Datei AuthKey_XXXXXXXXXX.p8 im Ordner "Downloads" liegt.
set -euo pipefail

REPO="ing-bassam/Lernwiese-App"
ISSUER_ID="433ca6b0-d40e-4e12-bf73-d8d37882b0e0"
PREFERRED_KEY="$HOME/Downloads/AuthKey_4Z8GCGWM5R.p8"
GH="$HOME/.local/bin/gh"
[ -x "$GH" ] || GH="$(command -v gh)"

echo "Lernwiese – Apple-Schlüssel bei GitHub hinterlegen"
echo

if [ -f "$PREFERRED_KEY" ]; then
  KEY_FILE="$PREFERRED_KEY"
else
  KEY_FILE=$(ls -t "$HOME"/Downloads/AuthKey_*.p8 2>/dev/null | head -1 || true)
fi
if [ -z "$KEY_FILE" ]; then
  echo "Keine Datei AuthKey_….p8 im Ordner Downloads gefunden."
  echo "Bitte in App Store Connect › Benutzer und Zugriff › Integrationen einen Schlüssel (Zugriff: Admin) erzeugen und herunterladen."
  read -r -p "Enter zum Schließen"
  exit 1
fi

KEY_ID=$(basename "$KEY_FILE" .p8)
KEY_ID=${KEY_ID#AuthKey_}
echo "Schlüssel:  $(basename "$KEY_FILE")  (Schlüssel-ID $KEY_ID)"
echo "Issuer-ID:  $ISSUER_ID"
echo "Repository: $REPO"
echo

"$GH" secret set ASC_KEY_P8 -R "$REPO" < "$KEY_FILE"
printf '%s' "$KEY_ID" | "$GH" secret set ASC_KEY_ID -R "$REPO"
printf '%s' "$ISSUER_ID" | "$GH" secret set ASC_ISSUER_ID -R "$REPO"

echo
echo "Fertig. Die drei Secrets sind bei GitHub hinterlegt:"
"$GH" secret list -R "$REPO"
echo
echo "Du kannst dieses Fenster jetzt schließen."
read -r -p "Enter zum Schließen"
