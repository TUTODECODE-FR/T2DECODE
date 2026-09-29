#!/bin/sh
# Build a Homebrew cask from a published T2DECODE macOS DMG.
# Refuses HTML error bodies (SourceForge 404 pages are non-empty and were
# previously hashed as if they were the disk image).
set -eu

VERSION="${1:?version required (without the leading v)}"
OUT="${2:?output cask path required}"

WORKDIR="$(mktemp -d)"
DMG="$WORKDIR/T2DECODE-macOS.dmg"
trap 'rm -rf "$WORKDIR"' EXIT

is_dmg() {
  f="$1"
  [ -f "$f" ] || return 1
  size=$(wc -c < "$f" | tr -d '[:space:]')
  # Real disk images are many megabytes; the SourceForge 404 body is ~154 bytes.
  [ "$size" -gt 1000000 ] || return 1
  # UDIF trailer magic ("koly") lives in the last 512 bytes.
  tail -c 512 "$f" | tr -d '\000' | grep -q "koly"
}

try_download() {
  url="$1"
  rm -f "$DMG"
  if curl -fL --retry 3 --retry-delay 2 -o "$DMG" "$url" && is_dmg "$DMG"; then
    return 0
  fi
  rm -f "$DMG"
  return 1
}

# First URL that serves a real DMG wins. The cask template must keep working
# for that same host when Homebrew substitutes #{version}.
GITLAB_URL="https://gitlab.com/api/v4/projects/84128177/packages/generic/t2decode-macos/${VERSION}/T2DECODE-macOS.dmg"
GITHUB_URL="https://github.com/TUTODECODE-FR/T2DECODE/releases/download/v${VERSION}/T2DECODE-macOS.dmg"
SF_URL="https://downloads.sourceforge.net/project/t2decode/v${VERSION}/T2DECODE-macOS.dmg"

CASK_URL=""
if try_download "$GITLAB_URL"; then
  CASK_URL="https://gitlab.com/api/v4/projects/84128177/packages/generic/t2decode-macos/#{version}/T2DECODE-macOS.dmg"
elif try_download "$GITHUB_URL"; then
  CASK_URL="https://github.com/TUTODECODE-FR/T2DECODE/releases/download/v#{version}/T2DECODE-macOS.dmg"
elif try_download "$SF_URL"; then
  CASK_URL="https://downloads.sourceforge.net/project/t2decode/v#{version}/T2DECODE-macOS.dmg"
else
  echo "No valid T2DECODE-macOS.dmg published for v${VERSION}." >&2
  exit 1
fi

SHA256_HASH=$(sha256sum "$DMG" | awk '{print $1}')
echo "Resolved v${VERSION} sha256 ${SHA256_HASH}"
echo "Cask URL template: ${CASK_URL}"

cat > "$OUT" <<EOF
cask "t2decode" do
  version "${VERSION}"
  sha256 "${SHA256_HASH}"

  url "${CASK_URL}"
  name "T2DECODE"
  desc "Offline simulator and toolkit for networking and cybersecurity"
  homepage "https://tutodecode.org/"

  app "T2DECODE.app"

  zap trash: [
    "~/Library/Application Support/org.t2decode.app",
    "~/Library/Preferences/org.t2decode.app.plist",
    "~/Library/Saved Application State/org.t2decode.app.savedState",
  ]
end
EOF
