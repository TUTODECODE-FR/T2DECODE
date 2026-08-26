#!/usr/bin/env bash
# scripts/sign_notarize_macos.sh
#
# Build (optional) + Developer ID sign + Apple notarize + staple.
# Produces signed artefacts in dist/macos/ for GitLab upload.
#
# This path is for direct / Homebrew / GitLab DMG distribution.
# Mac App Store is separate: Xcode Archive → Organizer → App Store Connect.
#
# Required (unless SKIP_NOTARIZE=1 or NOTARY_PROFILE is set):
#   APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD (or APPLE_PASSWORD), APPLE_TEAM_ID
# Optional:
#   MACOS_CERT_IDENTITY   Developer ID Application identity
#   NOTARY_PROFILE        notarytool keychain profile (skips APPLE_* password)
#   SKIP_BUILD=1          reuse dist/macos/T2DECODE.app (or build Products)
#   SKIP_NOTARIZE=1       sign only (no notarytool / staple)
#   SKIP_DMG=1            skip DMG packaging
#
# No certificates are written to the repo; Keychain only.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DIST_DIR="$ROOT_DIR/dist/macos"
APP_NAME="T2DECODE.app"
DMG_NAME="T2DECODE-macOS.dmg"
ZIP_NAME="T2DECODE-macOS.zip"

log() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

detect_identity() {
  if [[ -n "${MACOS_CERT_IDENTITY:-}" ]]; then
    printf '%s\n' "$MACOS_CERT_IDENTITY"
    return
  fi
  local found
  found="$(security find-identity -v -p codesigning 2>/dev/null \
    | sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' \
    | head -n1 || true)"
  [[ -n "$found" ]] || die "Aucun certificat Developer ID Application trouvé. Exportez MACOS_CERT_IDENTITY."
  printf '%s\n' "$found"
}

resolve_app_path() {
  if [[ -d "$DIST_DIR/$APP_NAME" ]]; then
    printf '%s\n' "$DIST_DIR/$APP_NAME"
    return
  fi
  local release_app="$ROOT_DIR/build/macos/Build/Products/Release/$APP_NAME"
  if [[ -d "$release_app" ]]; then
    mkdir -p "$DIST_DIR"
    rm -rf "$DIST_DIR/$APP_NAME"
    cp -R "$release_app" "$DIST_DIR/"
    xattr -cr "$DIST_DIR/$APP_NAME" 2>/dev/null || true
    printf '%s\n' "$DIST_DIR/$APP_NAME"
    return
  fi
  die "Aucun $APP_NAME trouvé. Lancez make build-macos ou omettez SKIP_BUILD."
}

sign_app() {
  local app="$1"
  local identity="$2"
  log "→ Signature Developer ID : $identity"
  xattr -cr "$app" 2>/dev/null || true
  /usr/bin/codesign --force --deep --options runtime --timestamp \
    --sign "$identity" "$app"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$app"
}

notarize_zip() {
  local zip_path="$1"
  if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    log "→ Notarisation (keychain profile: $NOTARY_PROFILE)"
    xcrun notarytool submit "$zip_path" \
      --keychain-profile "$NOTARY_PROFILE" \
      --wait
    return
  fi

  local apple_id="${APPLE_ID:-}"
  local password="${APPLE_APP_SPECIFIC_PASSWORD:-${APPLE_PASSWORD:-}}"
  local team_id="${APPLE_TEAM_ID:-}"

  [[ -n "$apple_id" ]] || die "APPLE_ID manquant (ou définissez NOTARY_PROFILE)."
  [[ -n "$password" ]] || die "APPLE_APP_SPECIFIC_PASSWORD manquant (ou NOTARY_PROFILE)."
  [[ -n "$team_id" ]] || die "APPLE_TEAM_ID manquant (ou NOTARY_PROFILE)."

  log "→ Notarisation (Apple ID: $apple_id, team: $team_id)"
  xcrun notarytool submit "$zip_path" \
    --apple-id "$apple_id" \
    --password "$password" \
    --team-id "$team_id" \
    --wait
}

build_dmg() {
  local app="$1"
  local dmg_out="$DIST_DIR/$DMG_NAME"
  local stage
  stage="$(mktemp -d "${TMPDIR:-/tmp}/t2decode-dmg.XXXXXX")"

  cp -R "$app" "$stage/"
  ln -s /Applications "$stage/Applications"
  sync
  hdiutil create -volname "T2DECODE" -srcfolder "$stage" -ov -format UDZO "$dmg_out"
  rm -rf "$stage"
  log "→ DMG: $dmg_out"
}

# --- main ---

mkdir -p "$DIST_DIR"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  log "→ Build macOS local…"
  chmod +x "$ROOT_DIR/scripts/build_macos_local.sh"
  SKIP_PUB_GET="${SKIP_PUB_GET:-0}" "$ROOT_DIR/scripts/build_macos_local.sh"
fi

APP_PATH="$(resolve_app_path)"
IDENTITY="$(detect_identity)"
sign_app "$APP_PATH" "$IDENTITY"

rm -f "$DIST_DIR/$ZIP_NAME"
ditto -c -k --keepParent "$APP_PATH" "$DIST_DIR/$ZIP_NAME"
log "→ ZIP: $DIST_DIR/$ZIP_NAME"

if [[ "${SKIP_NOTARIZE:-0}" != "1" ]]; then
  notarize_zip "$DIST_DIR/$ZIP_NAME"
  log "→ Staple ticket…"
  xcrun stapler staple "$APP_PATH"
  # Refresh ZIP after staple so GitLab artefact includes the ticket.
  rm -f "$DIST_DIR/$ZIP_NAME"
  ditto -c -k --keepParent "$APP_PATH" "$DIST_DIR/$ZIP_NAME"
else
  log "→ SKIP_NOTARIZE=1 : signature seule (Gatekeeper peut encore avertir)."
fi

if [[ "${SKIP_DMG:-0}" != "1" ]]; then
  build_dmg "$APP_PATH"
  # Optional DMG codesign (same Developer ID).
  /usr/bin/codesign --force --sign "$IDENTITY" --timestamp "$DIST_DIR/$DMG_NAME" 2>/dev/null || true
fi

(
  cd "$DIST_DIR"
  rm -f SHA256SUMS-macos.txt
  for f in "$DMG_NAME" "$ZIP_NAME"; do
    [[ -f "$f" ]] || continue
    shasum -a 256 "$f" >> SHA256SUMS-macos.txt
  done
)

log ""
log "✅ Signature locale terminée."
log "   App : $APP_PATH"
[[ -f "$DIST_DIR/$DMG_NAME" ]] && log "   DMG : $DIST_DIR/$DMG_NAME"
[[ -f "$DIST_DIR/$ZIP_NAME" ]] && log "   ZIP : $DIST_DIR/$ZIP_NAME"
log ""
log "Prochaine étape (GitLab, pas le Mac App Store) :"
log "  make upload-macos-gitlab"
log "  # ou: ./scripts/upload_macos_to_gitlab.sh"
log ""
log "Mac App Store : Archive Xcode → Organizer → App Store Connect (canal distinct)."
