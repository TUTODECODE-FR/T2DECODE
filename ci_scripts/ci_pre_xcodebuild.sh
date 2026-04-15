#!/bin/bash
set -euo pipefail

# Optional Xcode Cloud hook before xcodebuild.
# Keep it idempotent: some workflows re-run steps.

ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
cd "$ROOT"

echo "[ci_pre_xcodebuild] Ensuring Flutter iOS config exists"

if command -v flutter >/dev/null 2>&1; then
  flutter pub get
  flutter build ios --config-only
fi

if command -v pod >/dev/null 2>&1; then
  (cd ios && pod install)
fi

