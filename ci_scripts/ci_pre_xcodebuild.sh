#!/bin/bash
set -euo pipefail

# Optional Xcode Cloud hook before xcodebuild.
# Keep it idempotent: some workflows re-run steps.

ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
cd "$ROOT"

echo "[ci_pre_xcodebuild] Ensuring Flutter iOS config exists"

if ! command -v flutter >/dev/null 2>&1; then
  echo "[ci_pre_xcodebuild] flutter not found; installing Flutter SDK (stable)..." >&2
  FLUTTER_DIR="$ROOT/flutter"
  if [ ! -d "$FLUTTER_DIR/.git" ]; then
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

FLUTTER_BIN="$(command -v flutter)"
FLUTTER_ROOT="$(cd "$(dirname "$FLUTTER_BIN")/.." && pwd)"
export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter precache --ios
flutter pub get

write_flutter_ios_configs() {
  # Xcode reads these very early (Release.xcconfig includes Generated.xcconfig).
  cat > ios/Flutter/Generated.xcconfig <<EOF
// Generated for Xcode Cloud. Local builds may overwrite via: flutter build ios --config-only
FLUTTER_ROOT=$FLUTTER_ROOT
FLUTTER_APPLICATION_PATH=$ROOT
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=1.0.1
FLUTTER_BUILD_NUMBER=1
EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386
EXCLUDED_ARCHS[sdk=iphoneos*]=armv7
DART_OBFUSCATION=false
TRACK_WIDGET_CREATION=true
TREE_SHAKE_ICONS=false
PACKAGE_CONFIG=.dart_tool/package_config.json
EOF

  cat > ios/Flutter/flutter_export_environment.sh <<EOF
#!/bin/sh
set -e
# Generated for Xcode Cloud. Local builds may overwrite via: flutter build ios --config-only
export "FLUTTER_ROOT=$FLUTTER_ROOT"
export "FLUTTER_APPLICATION_PATH=$ROOT"
export "COCOAPODS_PARALLEL_CODE_SIGN=true"
export "FLUTTER_TARGET=lib/main.dart"
export "FLUTTER_BUILD_DIR=build"
export "FLUTTER_BUILD_NAME=1.0.1"
export "FLUTTER_BUILD_NUMBER=1"
export "DART_OBFUSCATION=false"
export "TRACK_WIDGET_CREATION=true"
export "TREE_SHAKE_ICONS=false"
export "PACKAGE_CONFIG=.dart_tool/package_config.json"
EOF
  chmod +x ios/Flutter/flutter_export_environment.sh
}

# Write once before config-only (in case it fails)...
write_flutter_ios_configs

flutter build ios --config-only

# ...and once after, because config-only may rewrite paths we don't want in CI.
write_flutter_ios_configs

echo "[ci_pre_xcodebuild] ios/Flutter files:"
ls -la ios/Flutter | sed -n '1,200p' || true

if command -v pod >/dev/null 2>&1; then
  (cd ios && pod install)
fi
