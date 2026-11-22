#!/bin/bash
# Signature Developer ID + notarisation Apple (CI macOS).
#
#   macos-sign.sh app    "chemin/T2DECODE.app"     signe, notarise, agrafe le ticket
#   macos-sign.sh binary fichier [fichier…]           signe, notarise (outils en ligne de commande)
#
# Secrets attendus (GitHub → Settings → Secrets) :
#   MACOS_CERT_P12_BASE64  certificat « Developer ID Application » exporté en .p12, en base64
#   MACOS_CERT_PASSWORD    mot de passe du .p12
#   MACOS_CERT_IDENTITY    « Developer ID Application: TUTODECODE (TS97M57BJV) »
#   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64   clé API App Store Connect (notarisation)
#
# Sans ces secrets : avertissement et rien n'est signé (version non signée,
# comme avant). Avec SIGN_REQUIRED=1 : échec.
set -euo pipefail

kind=${1:?app|binary}; shift
need="MACOS_CERT_P12_BASE64 MACOS_CERT_PASSWORD MACOS_CERT_IDENTITY ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8_BASE64"
for v in $need; do
	if [ -z "${!v:-}" ]; then
		msg="secret $v absent : version NON signée (macOS affichera un avertissement)"
		if [ "${SIGN_REQUIRED:-0}" = 1 ]; then echo "::error::$msg"; exit 1; fi
		echo "::warning::$msg"
		exit 0
	fi
done

work=$(mktemp -d)
keychain="$work/signature.keychain-db"
kpass=$(openssl rand -hex 24)
cleanup() {
	security delete-keychain "$keychain" >/dev/null 2>&1 || true
	rm -rf "$work"
}
trap cleanup EXIT

# trousseau temporaire, détruit à la fin du travail
printf '%s' "$MACOS_CERT_P12_BASE64" | base64 --decode > "$work/cert.p12"
security create-keychain -p "$kpass" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$kpass" "$keychain"
security import "$work/cert.p12" -k "$keychain" -P "$MACOS_CERT_PASSWORD" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$kpass" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" $(security list-keychains -d user | tr -d '"')
rm -f "$work/cert.p12"

printf '%s' "$ASC_KEY_P8_BASE64" | base64 --decode > "$work/AuthKey.p8"
here=$(cd "$(dirname "$0")" && pwd)

sign() { # durcissement (« hardened runtime ») + horodatage Apple : exigés pour la notarisation
	codesign --force --options runtime --timestamp --keychain "$keychain" \
		--entitlements "${ENTITLEMENTS:-$here/developer-id-entitlements.plist}" --sign "$MACOS_CERT_IDENTITY" "$@"
}

notarize() { # envoie à Apple et attend le verdict
	out=$(xcrun notarytool submit "$1" --key "$work/AuthKey.p8" --key-id "$ASC_KEY_ID" \
		--issuer "$ASC_ISSUER_ID" --wait --timeout 30m --output-format json)
	echo "$out"
	id=$(printf '%s' "$out" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')
	status=$(printf '%s' "$out" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)["status"])')
	if [ "$status" != "Accepted" ]; then
		xcrun notarytool log "$id" --key "$work/AuthKey.p8" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" || true
		echo "::error::notarisation refusée par Apple ($status)"
		exit 1
	fi
}

case "$kind" in
app)
	app=${1:?chemin du .app}
	# d'abord le contenu, puis l'application elle-même
	find "$app/Contents" -type f -perm -u+x -not -path "*/Contents/MacOS/*" -print0 2>/dev/null |
		while IFS= read -r -d '' f; do sign "$f"; done
	sign "$app"
	codesign --verify --strict --deep --verbose=2 "$app"
	ditto -c -k --keepParent "$app" "$work/app.zip"
	notarize "$work/app.zip"
	xcrun stapler staple "$app"           # ticket attaché : vérifiable même hors ligne
	xcrun stapler validate "$app"
	spctl --assess --type execute --verbose=2 "$app"   # ce que dira Gatekeeper chez l'utilisateur
	;;
binary)
	for f in "$@"; do sign "$f"; codesign --verify --strict --verbose=2 "$f"; done
	ditto -c -k "$@" "$work/outils.zip" 2>/dev/null || zip -qj "$work/outils.zip" "$@"
	notarize "$work/outils.zip"   # un binaire seul ne peut pas porter de ticket : Gatekeeper le vérifie en ligne
	;;
*)
	echo "usage: $0 app|binary …"; exit 2 ;;
esac
echo "signé et notarisé par Apple : $*"
