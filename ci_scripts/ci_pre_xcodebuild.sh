#!/bin/bash
set -euo pipefail

# Optional Xcode Cloud hook before xcodebuild.
# Keep it idempotent: some workflows re-run steps.

ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
cd "$ROOT"

echo "[ci_pre_xcodebuild] Ensuring Flutter iOS config exists"

if ! command -v flutter >/dev/null 2>&1; then
  echo "[ci_pre_xcodebuild] flutter not found; installing Flutter SDK (stable)..." >&2
  FLUTTER_DIR="$HOME/flutter"
  if [ ! -d "$FLUTTER_DIR/.git" ]; then
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

flutter precache --ios
flutter pub get
flutter build ios --config-only

if command -v pod >/dev/null 2>&1; then
  (cd ios && pod install)
fi
