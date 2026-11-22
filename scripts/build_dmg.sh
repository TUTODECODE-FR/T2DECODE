#!/bin/bash
# Image DMG d'installation : fenêtre 660×400 au fond TUTODECODE, icône de l'app à gauche,
# raccourci Applications à droite, flèche entre les deux. Outil : create-dmg
# (brew install create-dmg). Images : installer-art/ (installer-art/generer.py).
set -euo pipefail

APP="${1:-build/macos/Build/Products/Release/T2DECODE.app}"
OUT="${2:-build/macos/Build/Products/Release/T2DECODE-macOS.dmg}"
CREATE_DMG="${CREATE_DMG:-create-dmg}"
here=$(cd "$(dirname "$0")/.." && pwd)

[ -d "$APP" ] || { echo "❌ application introuvable : $APP (flutter build macos --release)"; exit 1; }
command -v "$CREATE_DMG" >/dev/null || { echo "❌ create-dmg absent (brew install create-dmg)"; exit 1; }

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
ditto "$APP" "$staging/T2DECODE.app"
rm -f "$OUT"

"$CREATE_DMG" \
  --volname "T2DECODE" \
  --volicon "$APP/Contents/Resources/AppIcon.icns" \
  --background "$here/installer-art/dmg-fond.tiff" \
  --window-pos 200 140 \
  --window-size 660 422 \
  --icon-size 128 \
  --text-size 13 \
  --icon "T2DECODE.app" 170 215 \
  --hide-extension "T2DECODE.app" \
  --app-drop-link 490 215 \
  --no-internet-enable \
  "$OUT" "$staging"

echo "✅ DMG créé : $OUT"
