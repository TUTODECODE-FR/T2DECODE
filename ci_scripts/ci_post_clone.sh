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

# Ensure iOS Flutter config files exist with CI-absolute paths (Xcode Cloud needs them at build time).
cat > ios/Flutter/Generated.xcconfig <<EOF
// Generated for Xcode Cloud. Local builds may overwrite via: flutter build ios --config-only
FLUTTER_ROOT=$ROOT/flutter
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
export "FLUTTER_ROOT=$ROOT/flutter"
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

echo "[ci_post_clone] ios/Flutter files:"
ls -la ios/Flutter | sed -n '1,200p' || true

# Generates ios/Flutter/Generated.xcconfig and ios/Flutter/flutter_export_environment.sh
flutter build ios --config-only

if command -v pod >/dev/null 2>&1; then
  (cd ios && pod install)
else
  echo "[ci_post_clone] WARN: CocoaPods (pod) not found; skipping pod install" >&2
fi
