#!/usr/bin/env bash
# scripts/upload_macos_to_gitlab.sh
#
# Upload already-signed macOS artefacts from dist/macos/ to GitLab:
#   - Generic Package Registry (t2decode-macos / <version>)
#   - GitLab Release asset links for tag vX.Y.Z
#
# Auth (priority):
#   1. GITLAB_TOKEN / PRIVATE_TOKEN / GL_TOKEN env (PRIVATE-TOKEN header)
#   2. glab CLI (if authenticated)
#
# No certificates or tokens are stored in the repository.
#
# Optional env:
#   GITLAB_HOST        default: gitlab.com
#   GITLAB_PROJECT      default: tutodecode-org/T2DECODE
#   TAG / VERSION      default: v + pubspec version (before +build)
#   UPLOAD_MODE        release | package | both (default: both)
#   RELEASE_NAME       default: Release $TAG
#   RELEASE_NOTES      optional description body
#   DRY_RUN=1          print actions only

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist/macos}"
GITLAB_HOST="${GITLAB_HOST:-gitlab.com}"
GITLAB_PROJECT="${GITLAB_PROJECT:-tutodecode-org/T2DECODE}"
UPLOAD_MODE="${UPLOAD_MODE:-both}"
API="https://${GITLAB_HOST}/api/v4"

# Parallel lists (bash 3 compatible): basename|url
PACKAGE_LINK_LINES=""

log() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

urlencode() {
  python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

read_pubspec_version() {
  local raw
  raw="$(sed -n 's/^version:[[:space:]]*//p' "$ROOT_DIR/pubspec.yaml" | head -n1 | tr -d '[:space:]')"
  [[ -n "$raw" ]] || die "Impossible de lire version dans pubspec.yaml"
  printf '%s\n' "${raw%%+*}"
}

resolve_tag() {
  if [[ -n "${TAG:-}" ]]; then
    printf '%s\n' "$TAG"
    return
  fi
  if [[ -n "${VERSION:-}" ]]; then
    case "$VERSION" in
      v*) printf '%s\n' "$VERSION" ;;
      *)  printf 'v%s\n' "$VERSION" ;;
    esac
    return
  fi
  printf 'v%s\n' "$(read_pubspec_version)"
}

resolve_token() {
  if [[ -n "${GITLAB_TOKEN:-}" ]]; then
    printf '%s\n' "$GITLAB_TOKEN"
    return
  fi
  if [[ -n "${PRIVATE_TOKEN:-}" ]]; then
    printf '%s\n' "$PRIVATE_TOKEN"
    return
  fi
  if [[ -n "${GL_TOKEN:-}" ]]; then
    printf '%s\n' "$GL_TOKEN"
    return
  fi
  printf '\n'
}

have_glab_auth() {
  command -v glab >/dev/null 2>&1 || return 1
  # auth status can exit 0 while API token is expired (git SSH still OK).
  local out
  out="$(glab auth status -h "$GITLAB_HOST" 2>&1 || true)"
  printf '%s\n' "$out" | grep -qi 'could not authenticate\|invalid_grant\|HTTP 401\|unauthorized' && return 1
  printf '%s\n' "$out" | grep -qi 'Logged in to\|✓.*Token found\|api token' >/dev/null || return 1
  # Probe API with a cheap call.
  glab api user -h "$GITLAB_HOST" >/dev/null 2>&1
}

api_curl() {
  local method="$1"
  local path="$2"
  shift 2
  curl --silent --show-error --fail-with-body \
    --request "$method" \
    --header "PRIVATE-TOKEN: ${TOKEN}" \
    --header "Accept: application/json" \
    "$@" \
    "${API}${path}"
}

json_escape_pair() {
  # json_escape_pair name url description(optional unused) — emit JSON object fields via python
  NAME_JSON="$1" URL_JSON="$2" python3 - <<'PY'
import json, os
print(json.dumps({"name": os.environ["NAME_JSON"], "url": os.environ["URL_JSON"], "link_type": "package"}))
PY
}

collect_files() {
  FILES=()
  local f
  for f in \
    "$DIST_DIR/T2DECODE-macOS.dmg" \
    "$DIST_DIR/T2DECODE-macOS.zip" \
    "$DIST_DIR/SHA256SUMS-macos.txt"
  do
    [[ -f "$f" ]] && FILES+=("$f")
  done
  if [[ ${#FILES[@]} -eq 0 ]]; then
    die "Aucun artefact dans $DIST_DIR (attendu: T2DECODE-macOS.dmg / .zip). Lancez make sign-macos d'abord."
  fi
}

upload_generic_package() {
  local file="$1"
  local base
  base="$(basename "$file")"
  local package_name="t2decode-macos"
  local package_version="${TAG#v}"
  local encoded_project
  encoded_project="$(urlencode "$GITLAB_PROJECT")"
  local path="/projects/${encoded_project}/packages/generic/${package_name}/${package_version}/${base}"
  local public_url="https://${GITLAB_HOST}/api/v4/projects/${encoded_project}/packages/generic/${package_name}/${package_version}/${base}"

  log "→ Generic Package: $package_name/$package_version/$base"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "   DRY_RUN PUT ${API}${path}"
    PACKAGE_LINK_LINES="${PACKAGE_LINK_LINES}${base}|${public_url}"$'\n'
    return
  fi
  curl --silent --show-error --fail-with-body \
    --request PUT \
    --header "PRIVATE-TOKEN: ${TOKEN}" \
    --upload-file "$file" \
    "${API}${path}" >/dev/null
  PACKAGE_LINK_LINES="${PACKAGE_LINK_LINES}${base}|${public_url}"$'\n'
}

ensure_release() {
  local encoded_project
  encoded_project="$(urlencode "$GITLAB_PROJECT")"
  local name="${RELEASE_NAME:-Release ${TAG}}"
  local description="${RELEASE_NOTES:-Artefacts macOS signés localement (Developer ID + notarisation). Mac App Store: canal ASC distinct.}"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "→ DRY_RUN ensure release $TAG"
    return
  fi

  local status
  status="$(curl --silent --output /dev/null --write-out '%{http_code}' \
    --header "PRIVATE-TOKEN: ${TOKEN}" \
    "${API}/projects/${encoded_project}/releases/$(urlencode "$TAG")" || true)"

  if [[ "$status" == "200" ]]; then
    log "→ Release $TAG déjà présente."
    return
  fi

  log "→ Création release $TAG"
  local payload
  payload="$(
    TAG_JSON="$TAG" NAME_JSON="$name" DESC_JSON="$description" python3 - <<'PY'
import json, os
print(json.dumps({
  "name": os.environ["NAME_JSON"],
  "tag_name": os.environ["TAG_JSON"],
  "description": os.environ["DESC_JSON"],
  "ref": "main",
}))
PY
  )"
  if ! api_curl POST "/projects/${encoded_project}/releases" \
      --header "Content-Type: application/json" \
      --data "$payload" >/dev/null 2>&1; then
    payload="$(
      TAG_JSON="$TAG" NAME_JSON="$name" DESC_JSON="$description" python3 - <<'PY'
import json, os
print(json.dumps({
  "name": os.environ["NAME_JSON"],
  "tag_name": os.environ["TAG_JSON"],
  "description": os.environ["DESC_JSON"],
}))
PY
    )"
    api_curl POST "/projects/${encoded_project}/releases" \
      --header "Content-Type: application/json" \
      --data "$payload" >/dev/null
  fi
}

link_release_asset() {
  local base="$1"
  local url="$2"
  local encoded_project
  encoded_project="$(urlencode "$GITLAB_PROJECT")"
  local encoded_tag
  encoded_tag="$(urlencode "$TAG")"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "→ DRY_RUN link $base → $url"
    return
  fi

  local links
  links="$(api_curl GET "/projects/${encoded_project}/releases/${encoded_tag}/assets/links" 2>/dev/null || echo '[]')"
  local link_id
  link_id="$(
    NAME_JSON="$base" LINKS_JSON="$links" python3 - <<'PY'
import json, os
name = os.environ["NAME_JSON"]
try:
    data = json.loads(os.environ["LINKS_JSON"])
except Exception:
    data = []
for item in data if isinstance(data, list) else []:
    if item.get("name") == name:
        print(item.get("id", ""))
        break
PY
  )"
  if [[ -n "$link_id" ]]; then
    api_curl DELETE "/projects/${encoded_project}/releases/${encoded_tag}/assets/links/${link_id}" >/dev/null || true
  fi

  local payload
  payload="$(json_escape_pair "$base" "$url")"
  log "→ Release link: $base"
  api_curl POST "/projects/${encoded_project}/releases/${encoded_tag}/assets/links" \
    --header "Content-Type: application/json" \
    --data "$payload" >/dev/null
}

upload_via_glab() {
  log "→ Upload via glab release…"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "   DRY_RUN glab release create/upload $TAG ${FILES[*]}"
    return
  fi

  if ! glab release view "$TAG" -R "$GITLAB_PROJECT" >/dev/null 2>&1; then
    glab release create "$TAG" \
      -R "$GITLAB_PROJECT" \
      --name "${RELEASE_NAME:-Release ${TAG}}" \
      --notes "${RELEASE_NOTES:-Artefacts macOS signés localement (Developer ID).}" \
      "${FILES[@]}"
  else
    glab release upload "$TAG" -R "$GITLAB_PROJECT" "${FILES[@]}"
  fi
}

print_auth_help() {
  cat >&2 <<'EOF'
Aucun jeton GitLab utilisable.

Option A — variable d'environnement (recommandé si glab est expiré) :
  export GITLAB_TOKEN="glpat-xxxxxxxx"
  # scopes: api
  ./scripts/upload_macos_to_gitlab.sh

Option B — ré-authentifier glab :
  glab auth login --hostname gitlab.com
  # ou: glab auth login --hostname gitlab.com --token "$GITLAB_TOKEN"
  ./scripts/upload_macos_to_gitlab.sh

Projet cible: tutodecode-org/T2DECODE
EOF
}

# --- main ---

TAG="$(resolve_tag)"
collect_files

TOKEN="$(resolve_token)"
USE_GLAB=0
if [[ -z "$TOKEN" ]]; then
  if have_glab_auth; then
    USE_GLAB=1
    log "→ Auth: glab (session valide)"
  else
    print_auth_help
    exit 1
  fi
else
  log "→ Auth: GITLAB_TOKEN / PRIVATE-TOKEN"
fi

log "→ Projet: $GITLAB_PROJECT"
log "→ Tag:    $TAG"
log "→ Mode:   $UPLOAD_MODE"
log "→ Fichiers:"
for f in "${FILES[@]}"; do
  log "   - $f"
done

if [[ "$USE_GLAB" == "1" && ( "$UPLOAD_MODE" == "release" || "$UPLOAD_MODE" == "both" ) ]]; then
  upload_via_glab
  if [[ "$UPLOAD_MODE" == "release" ]]; then
    log ""
    log "✅ Upload GitLab terminé (glab release)."
    log "   https://${GITLAB_HOST}/${GITLAB_PROJECT}/-/releases/${TAG}"
    exit 0
  fi
  if [[ -z "$TOKEN" ]]; then
    log "⚠ Generic Package ignoré (pas de GITLAB_TOKEN). Release glab OK."
    log "   https://${GITLAB_HOST}/${GITLAB_PROJECT}/-/releases/${TAG}"
    exit 0
  fi
fi

[[ -n "$TOKEN" ]] || die "GITLAB_TOKEN requis pour l'API curl / Generic Packages."

if [[ "$UPLOAD_MODE" == "package" || "$UPLOAD_MODE" == "both" ]]; then
  for f in "${FILES[@]}"; do
    upload_generic_package "$f"
  done
fi

if [[ "$UPLOAD_MODE" == "release" || "$UPLOAD_MODE" == "both" ]]; then
  if [[ "$USE_GLAB" != "1" ]]; then
    ensure_release
  fi
  if [[ -z "$PACKAGE_LINK_LINES" && "$UPLOAD_MODE" == "release" ]]; then
    die "Mode release via curl nécessite UPLOAD_MODE=both (Generic Packages → liens Release)."
  fi
  while IFS='|' read -r base url; do
    [[ -n "${base:-}" && -n "${url:-}" ]] || continue
    link_release_asset "$base" "$url"
  done <<EOF
$PACKAGE_LINK_LINES
EOF
fi

log ""
log "✅ Upload GitLab terminé."
log "   Release : https://${GITLAB_HOST}/${GITLAB_PROJECT}/-/releases/${TAG}"
log "   Packages: https://${GITLAB_HOST}/${GITLAB_PROJECT}/-/packages"
log ""
log "Rappel: le Mac App Store (Archive → ASC) n'est pas couvert par cet upload DMG."
