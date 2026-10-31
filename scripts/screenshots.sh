#!/bin/bash
# Takes the App Store screenshots in the Simulator using the built-in demo mode.
# Usage: scripts/screenshots.sh <simulator-udid> <path/to/Lernwiese.app> <output-folder> <prefix>
set -euo pipefail

UDID="$1"
APP="$2"
OUT="$3"
PREFIX="${4:-iphone}"
BUNDLE_ID="${BUNDLE_ID:-de.lernwiese.app}"

mkdir -p "$OUT"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl ui "$UDID" appearance light
xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl install "$UDID" "$APP"

shoot() {
  local name="$1"
  shift
  local file="$OUT/${PREFIX}_$name.png"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" -demo YES -AppleLanguages "(de)" -AppleLocale de_DE "$@"
  sleep 12
  xcrun simctl io "$UDID" screenshot "$file"
  # The 13" iPad slot in App Store Connect takes 2048x2732; the iPad Pro 13" Simulator renders 2064x2752.
  if [ "$(sips -g pixelWidth "$file" | awk '/pixelWidth/ {print $2}')" = "2064" ]; then
    sips -z 2732 2048 "$file" >/dev/null
  fi
  echo "Screenshot $(basename "$file") gespeichert"
}

shoot 01_wiese -screen home
shoot 02_zaehlen -screen counting
shoot 03_tiere -screen habitat -solved YES
shoot 04_paare -screen foodPairs
shoot 05_rechnen -screen arithmetic
shoot 06_jahreszeiten -screen seasons

xcrun simctl shutdown "$UDID" 2>/dev/null || true
