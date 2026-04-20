#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Force build/ onto a local, non-FileProvider path to avoid disallowed xattrs and build.db I/O issues.
TMP_BUILD_ROOT="/tmp/tutodecode-build"
mkdir -p "$TMP_BUILD_ROOT"
if [ -e "$ROOT_DIR/build" ] && [ ! -L "$ROOT_DIR/build" ]; then
  ts="$(date +%Y%m%d-%H%M%S)"
  mv "$ROOT_DIR/build" "$ROOT_DIR/build.backup-${ts}"
fi
ln -sfn "$TMP_BUILD_ROOT" "$ROOT_DIR/build"

if [ "${SKIP_PUB_GET:-0}" != "1" ]; then
  flutter pub get >/dev/null
fi
flutter build macos --config-only --no-pub >/dev/null || true

HOOK_BUILD_DIR="$ROOT_DIR/.dart_tool/hooks_runner/shared/objective_c/build"
NATIVE_DST_DIR="$ROOT_DIR/build/native_assets/macos/objective_c.framework"
mkdir -p "$NATIVE_DST_DIR" 2>/dev/null || true

# Prepare the native asset expected by Flutter's NativeAssetsManifest.json:
# build/native_assets/macos/objective_c.framework/objective_c
ARM_SRC=""
X64_SRC=""
if [ -d "$HOOK_BUILD_DIR" ]; then
  for f in "$HOOK_BUILD_DIR"/*/objective_c.dylib; do
    [ -f "$f" ] || continue
    info="$(lipo -info "$f" 2>/dev/null || true)"
    case "$info" in
      *"architecture: arm64"*|*"are: arm64"*) ARM_SRC="${ARM_SRC:-$f}" ;;
      *"architecture: x86_64"*|*"are: x86_64"*) X64_SRC="${X64_SRC:-$f}" ;;
    esac
  done
fi

rm -rf "$NATIVE_DST_DIR" 2>/dev/null || true
mkdir -p "$NATIVE_DST_DIR/Versions/A/Resources" 2>/dev/null || true

BIN_OUT="$NATIVE_DST_DIR/Versions/A/objective_c"
if [ -n "${ARM_SRC:-}" ] && [ -n "${X64_SRC:-}" ]; then
  lipo -create "$ARM_SRC" "$X64_SRC" -output "$BIN_OUT" 2>/dev/null || true
elif [ -n "${ARM_SRC:-}" ]; then
  cp -f "$ARM_SRC" "$BIN_OUT" 2>/dev/null || true
elif [ -n "${X64_SRC:-}" ]; then
  cp -f "$X64_SRC" "$BIN_OUT" 2>/dev/null || true
fi
chmod +x "$BIN_OUT" 2>/dev/null || true

ln -sfn A "$NATIVE_DST_DIR/Versions/Current" 2>/dev/null || true
ln -sfn Versions/Current/objective_c "$NATIVE_DST_DIR/objective_c" 2>/dev/null || true
ln -sfn Versions/Current/Resources "$NATIVE_DST_DIR/Resources" 2>/dev/null || true

cat > "$NATIVE_DST_DIR/Versions/A/Resources/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>package.objective_c</string>
  <key>CFBundleName</key>
  <string>objective_c</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleExecutable</key>
  <string>objective_c</string>
</dict>
</plist>
PLIST

set +e
flutter build macos --release --no-pub
rc=$?
set -e

APP_PATH="$ROOT_DIR/build/macos/Build/Products/Release/T2DECODE.app"
if [ ! -d "$APP_PATH" ]; then
  # Fallback: pick the first .app found in Release.
  APP_PATH_FOUND="$(find "$ROOT_DIR/build/macos/Build/Products/Release" -maxdepth 1 -name '*.app' -print -quit 2>/dev/null || true)"
  if [ -n "${APP_PATH_FOUND:-}" ]; then
    APP_PATH="$APP_PATH_FOUND"
  fi
fi

if [ "$rc" -eq 0 ]; then
  echo "macOS build OK: $APP_PATH"
  exit 0
fi

if [ ! -d "$APP_PATH" ]; then
  echo "macOS build failed and .app not found under build outputs." >&2
  exit "$rc"
fi

ENT_PATH="$(find "$ROOT_DIR/build/macos/Build/Intermediates.noindex/Runner.build" -path '*/Release/Runner.build/*.app.xcent' -print -quit 2>/dev/null || true)"
if [ -z "${ENT_PATH:-}" ]; then
  echo "macOS build failed; entitlements (.xcent) not found for re-sign." >&2
  exit "$rc"
fi

# Fix: remove FinderInfo/resource fork xattrs that make codesign fail, then re-run codesign.
xattr -cr "$APP_PATH" 2>/dev/null || true
xattr -cr "$APP_PATH/Contents/Frameworks" 2>/dev/null || true
xattr -r -d com.apple.FinderInfo "$APP_PATH" 2>/dev/null || true
xattr -r -d 'com.apple.fileprovider.fpfs#P' "$APP_PATH" 2>/dev/null || true

/usr/bin/codesign --force --sign - --entitlements "$ENT_PATH" --timestamp=none --generate-entitlement-der "$APP_PATH"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_PATH" >/dev/null

echo "macOS build repaired (xattr + codesign): $APP_PATH"
