#!/bin/bash
set -euo pipefail

# Xcode Cloud runs this script right after cloning the repo.
# Goal: generate Flutter iOS xcconfig files ignored by git (Generated.xcconfig, flutter_export_environment.sh),
# and ensure CocoaPods is installed for the iOS workspace build.

ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
cd "$ROOT"

echo "[ci_post_clone] repo: $ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "[ci_post_clone] flutter not found; installing Flutter SDK (stable) into repo/flutter ..." >&2
  FLUTTER_DIR="$ROOT/flutter"
  if [ ! -d "$FLUTTER_DIR/.git" ]; then
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

flutter --version | head -n 1 || true

flutter precache --ios
flutter pub get

# Generates ios/Flutter/Generated.xcconfig and ios/Flutter/flutter_export_environment.sh
flutter build ios --config-only

if command -v pod >/dev/null 2>&1; then
  (cd ios && pod install)
else
  echo "[ci_post_clone] WARN: CocoaPods (pod) not found; skipping pod install" >&2
fi
