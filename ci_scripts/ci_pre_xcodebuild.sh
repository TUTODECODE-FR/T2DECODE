#!/bin/bash
set -euo pipefail

set -x
trap 'code=$?; echo "[ci_pre_xcodebuild] ERROR: exit=$code line=$LINENO cmd=${BASH_COMMAND}" >&2; exit $code' ERR

# Optional Xcode Cloud hook before xcodebuild.
# Keep it idempotent: some workflows re-run steps.

ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
cd "$ROOT"

echo "[ci_pre_xcodebuild] Ensuring Flutter iOS config exists"
echo "[ci_pre_xcodebuild] repo: $ROOT"
echo "[ci_pre_xcodebuild] pwd: $(pwd)"

retry() {
  local max="${1:-3}"
  shift || true
  local n=1
  until "$@"; do
    if [ "$n" -ge "$max" ]; then
      return 1
    fi
    n=$((n + 1))
    sleep 3
  done
}

if ! command -v flutter >/dev/null 2>&1; then
  echo "[ci_pre_xcodebuild] flutter not found; installing Flutter SDK (stable)..." >&2
  FLUTTER_DIR="$ROOT/flutter"
  if [ ! -d "$FLUTTER_DIR/.git" ]; then
    retry 3 git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
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

if ! flutter build ios --config-only --no-codesign; then
  echo "[ci_pre_xcodebuild] WARNING: flutter config-only failed; continuing with generated fallback xcconfigs" >&2
fi

# ...and once after, because config-only may rewrite paths we don't want in CI.
write_flutter_ios_configs

echo "[ci_pre_xcodebuild] ios/Flutter files:"
ls -la ios/Flutter | sed -n '1,200p' || true

ensure_pod() {
  if command -v pod >/dev/null 2>&1; then
    return 0
  fi

  echo "[ci_pre_xcodebuild] CocoaPods (pod) not found; installing (user-install)..." >&2
  if ! command -v gem >/dev/null 2>&1; then
    echo "[ci_pre_xcodebuild] ERROR: RubyGems (gem) not available; cannot install CocoaPods" >&2
    return 1
  fi

  gem install --no-document --user-install cocoapods
  if command -v ruby >/dev/null 2>&1; then
    GEM_USER_DIR="$(ruby -e 'require \"rubygems\"; print Gem.user_dir' 2>/dev/null || true)"
    if [ -n "${GEM_USER_DIR:-}" ]; then
      export PATH="$GEM_USER_DIR/bin:$PATH"
    fi
  fi
  export PATH="$HOME/Library/Ruby/Gems/"*/bin:"$HOME/.gem/ruby/"*/bin:$PATH
  command -v pod >/dev/null 2>&1
}

if ! ensure_pod; then
  echo "[ci_pre_xcodebuild] ERROR: CocoaPods unavailable; iOS build cannot proceed" >&2
  exit 1
fi

pod --version || true
(cd ios && retry 3 pod install)
