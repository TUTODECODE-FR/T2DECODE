#!/bin/bash
# T2DECODE → Mac App Store (CI macOS).
#
#   appstore-upload.sh build/macos/Build/Products/Release/T2DECODE.app VERSION BUILD
#
# Signe l'app pour l'App Store (bac à sable, profil de distribution), fabrique le
# paquet d'installation signé, l'envoie dans App Store Connect (TestFlight) et,
# si APPSTORE_SUBMIT=1, la soumet à l'examen d'Apple.
#
# Secrets : MAS_APP_CERT_P12_BASE64, MAS_INSTALLER_CERT_P12_BASE64, MAS_CERT_PASSWORD,
#   MAS_PROVISION_PROFILE_BASE64, MAS_APP_IDENTITY, MAS_INSTALLER_IDENTITY,
#   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64.
# DRY_RUN=1 : tout sauf l'envoi à Apple.
set -euo pipefail

app=${1:?chemin du .app}; version=${2:?version X.Y.Z}; build=${3:?numéro de build}
bundle_id=${BUNDLE_ID:-org.t2decode.app}
for v in MAS_APP_CERT_P12_BASE64 MAS_INSTALLER_CERT_P12_BASE64 MAS_CERT_PASSWORD MAS_PROVISION_PROFILE_BASE64 \
	MAS_APP_IDENTITY MAS_INSTALLER_IDENTITY ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8_BASE64; do
	if [ -z "${!v:-}" ]; then echo "::warning::secret $v absent : pas d'envoi à l'App Store"; exit 0; fi
done

work=$(mktemp -d)
keychain="$work/appstore.keychain-db"
kpass=$(openssl rand -hex 24)
trap 'security delete-keychain "$keychain" >/dev/null 2>&1 || true; rm -rf "$work"' EXIT
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)

# trousseau temporaire avec les deux certificats
security create-keychain -p "$kpass" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$kpass" "$keychain"
for c in MAS_APP_CERT_P12_BASE64 MAS_INSTALLER_CERT_P12_BASE64; do
	printf '%s' "${!c}" | base64 --decode > "$work/c.p12"
	security import "$work/c.p12" -k "$keychain" -P "$MAS_CERT_PASSWORD" -T /usr/bin/codesign -T /usr/bin/productbuild
	rm -f "$work/c.p12"
done
security set-key-partition-list -S apple-tool:,apple:,codesign:,productbuild: -s -k "$kpass" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" $(security list-keychains -d user | tr -d '"')

# profil de distribution intégré à l'app ; ses identifiants complètent les droits
printf '%s' "$MAS_PROVISION_PROFILE_BASE64" | base64 --decode > "$work/profile.provisionprofile"
cp "$work/profile.provisionprofile" "$app/Contents/embedded.provisionprofile"
security cms -D -i "$work/profile.provisionprofile" > "$work/profile.plist"
pb=/usr/libexec/PlistBuddy
appid=$($pb -c "Print :Entitlements:com.apple.application-identifier" "$work/profile.plist")
team=$($pb -c "Print :Entitlements:com.apple.developer.team-identifier" "$work/profile.plist")
case "$appid" in *".$bundle_id") ;; *) echo "::error::le profil vise $appid, pas $bundle_id"; exit 1 ;; esac
cp "$root/macos/Runner/AppStore.entitlements" "$work/app.entitlements"
$pb -c "Add :com.apple.application-identifier string $appid" "$work/app.entitlements"
$pb -c "Add :com.apple.developer.team-identifier string $team" "$work/app.entitlements"

# version affichée et numéro de build, identiques au tag
$pb -c "Set :CFBundleShortVersionString $version" "$app/Contents/Info.plist"
$pb -c "Set :CFBundleVersion $build" "$app/Contents/Info.plist"

# signature : d'abord les bibliothèques et frameworks, puis l'app (bac à sable)
find "$app/Contents/Frameworks" -maxdepth 1 \( -name "*.framework" -o -name "*.dylib" \) -print0 2>/dev/null |
	while IFS= read -r -d '' f; do
		codesign --force --timestamp --keychain "$keychain" --sign "$MAS_APP_IDENTITY" "$f"
	done
codesign --force --timestamp --keychain "$keychain" --entitlements "$work/app.entitlements" \
	--sign "$MAS_APP_IDENTITY" "$app"
codesign --verify --strict --deep --verbose=2 "$app"

pkg="$work/T2DECODE-$version.pkg"
productbuild --component "$app" /Applications --sign "$MAS_INSTALLER_IDENTITY" --keychain "$keychain" "$pkg"
pkgutil --check-signature "$pkg"

if [ "${DRY_RUN:-0}" = 1 ]; then
	cp "$pkg" "$root/" && echo "essai à blanc : paquet prêt, rien envoyé à Apple"
	exit 0
fi

# clé API App Store Connect (jamais écrite dans le dépôt)
printf '%s' "$ASC_KEY_P8_BASE64" | base64 --decode > "$work/AuthKey.p8"
/usr/bin/python3 - "$work" <<'PY'
import json, os, sys
w = sys.argv[1]
json.dump({"key_id": os.environ["ASC_KEY_ID"], "issuer_id": os.environ["ASC_ISSUER_ID"],
           "key": open(f"{w}/AuthKey.p8").read(), "in_house": False}, open(f"{w}/asc.json", "w"))
PY

# envoi dans App Store Connect, puis attente du traitement par Apple (TestFlight)
fastlane run upload_to_testflight api_key_path:"$work/asc.json" pkg:"$pkg" app_platform:osx \
	skip_waiting_for_build_processing:false distribute_external:false

if [ "${APPSTORE_SUBMIT:-0}" = 1 ]; then
	release=false; [ "${APPSTORE_AUTO_RELEASE:-0}" = 1 ] && release=true
	fastlane run deliver api_key_path:"$work/asc.json" app_identifier:"$bundle_id" platform:osx \
		app_version:"$version" build_number:"$build" skip_binary_upload:true skip_metadata:true \
		skip_screenshots:true submit_for_review:true automatic_release:$release force:true \
		run_precheck_before_submit:false
	echo "version $version soumise à l'examen d'Apple"
else
	echo "version $version ($build) envoyée dans App Store Connect (TestFlight) ; soumission manuelle"
fi
