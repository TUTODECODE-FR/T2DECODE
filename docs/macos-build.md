# macOS: creer et builder l'application

Ce guide explique comment **generer l'app macOS** (build local, packaging, signature/notarisation).

Pour la CI (GitHub Actions) et la liste des secrets, voir `docs/signing.md`.

---

## Flux release macOS (récap)

**Signer en local, puis envoyer l’artefact signé sur GitLab** (pas de signature dans la CI GitLab).

```bash
# 1) Build + Developer ID + notarize → dist/macos/
export APPLE_ID="…"
export APPLE_APP_SPECIFIC_PASSWORD="…"
export APPLE_TEAM_ID="TS97M57BJV"   # ou NOTARY_PROFILE=…
make sign-macos

# 2) Upload GitLab Release / Generic Package
export GITLAB_TOKEN="glpat-…"       # si glab auth expiré
make upload-macos-gitlab
# équivalent : TAG=v1.0.5 ./scripts/upload_macos_to_gitlab.sh

# 3) Mac App Store (distinct du DMG GitLab)
# Xcode → Archive → Organizer → Distribute → App Store Connect
```

| | **DMG GitLab** | **Mac App Store** |
|--|----------------|-------------------|
| Script / outil | `make sign-macos` puis `make upload-macos-gitlab` | Archive Xcode → ASC |
| Certificat | Developer ID Application | Apple Distribution + profil MAS |
| Sandbox | retiré par `build_macos_local.sh` | `app-sandbox = true` obligatoire |
| Destination | `tutodecode-org/T2DECODE` Releases / Packages | App Store Connect |

Détails auth / variables : [`docs/signing.md`](signing.md).

---

## Prerequis

- macOS + Xcode installe
- Flutter (stable)
- CocoaPods (souvent requis)

Verification:

```bash
flutter doctor -v
xcodebuild -version
pod --version
```

---

## Important: dossier `build/` (symlink)

Dans ce repo, `build/` peut etre un **symlink** vers `/tmp/tutodecode-build` (pour eviter des attributs etendus).

Si Flutter plante avec:
`PathNotFoundException ... path = '.../build'`

cree simplement la cible du symlink:

```bash
mkdir -p /tmp/tutodecode-build
```

Verifier:

```bash
ls -la build
```

---

## Build macOS (release, non signe)

```bash
flutter pub get
flutter build macos --release
```

Sortie:
- `build/macos/Build/Products/Release/T2DECODE.app`

---

## Packaging

### ZIP (recommande pour GitHub Releases)

```bash
APP_PATH="build/macos/Build/Products/Release/T2DECODE.app"
ditto -c -k --keepParent "$APP_PATH" T2DECODE-macOS.zip
```

### DMG / PKG

Si les scripts existent dans `scripts/`:

```bash
chmod +x scripts/build_dmg.sh scripts/build_pkg.sh
./scripts/build_dmg.sh
APP_VERSION="1.0.1" ./scripts/build_pkg.sh
```

---

## App Sandbox : Mac App Store vs Developer ID

Les entitlements Release (`macos/Runner/Release.entitlements`) activent
`com.apple.security.app-sandbox = true` — **obligatoire** pour le Mac App Store
(erreur ASC `90296` sinon).

| Canal | Sandbox | Fichier | Notes |
|-------|---------|---------|-------|
| **Mac App Store** (Archive → Distribute) | **Obligatoire `true`** | `Release.entitlements` | Signer avec *Apple Distribution* / profil Mac App Store. |
| **Developer ID** (DMG/ZIP hors store) | Souvent retiré | même source + post-traitement | `scripts/build_macos_local.sh` **supprime** `app-sandbox` après le build pour lancer depuis le Finder sans profil d’approvisionnement embarqué. |
| **Debug / Profile** | `true` + JIT | `DebugProfile.entitlements` | `allow-jit` uniquement hors Release MAS. |

Entitlements Release (minimaux T2DECODE) :
- `app-sandbox` — MAS
- `network.client` — Ollama (localhost/LAN) + clients GhostLink
- `network.server` — GhostLink (UDP 54321 + TCP 54322)
- `files.user-selected.read-write` — `file_picker` / import modules

Pas de `files.downloads.read-write`, pas de JIT/unsigned-memory en Release.

Vérifier avant upload MAS :

```bash
plutil -p macos/Runner/Release.entitlements
# "com.apple.security.app-sandbox" => 1 (true)

# Après Archive, sur le .app produit :
codesign -d --entitlements :- "…/T2DECODE.app" | grep -A1 app-sandbox
```

`project.pbxproj` : Release → `CODE_SIGN_ENTITLEMENTS = Runner/Release.entitlements` ;
Debug/Profile → `Runner/DebugProfile.entitlements`.

---

## Signature + notarisation (distribution "propre")

Sans signature/notarisation, macOS peut afficher des alertes Gatekeeper.

### Script recommandé (Developer ID → dist/macos/)

```bash
export APPLE_ID="email@domain.tld"
export APPLE_APP_SPECIFIC_PASSWORD="app-specific-password"
export APPLE_TEAM_ID="TEAMID"
# optionnel: MACOS_CERT_IDENTITY="Developer ID Application: …"
make sign-macos
# artefacts: dist/macos/T2DECODE.app, T2DECODE-macOS.dmg, T2DECODE-macOS.zip
```

Puis upload GitLab (pas le Mac App Store) :

```bash
export GITLAB_TOKEN="glpat-…"
make upload-macos-gitlab
```

### Étapes manuelles (équivalent)

#### 1) Signer (Developer ID Application)

```bash
APP_PATH="dist/macos/T2DECODE.app"
codesign --force --deep --options runtime --timestamp --sign "Developer ID Application: ..." "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose "$APP_PATH"
```

#### 2) Notariser (notarytool)

```bash
APP_PATH="dist/macos/T2DECODE.app"
rm -f dist/macos/T2DECODE-macOS.zip
ditto -c -k --keepParent "$APP_PATH" dist/macos/T2DECODE-macOS.zip

xcrun notarytool submit dist/macos/T2DECODE-macOS.zip \
  --apple-id "email@domain.tld" \
  --password "app-specific-password" \
  --team-id "TEAMID" \
  --wait
```

#### 3) Staple

```bash
xcrun stapler staple "$APP_PATH"
```

---

## Depannage

### Warnings: "Stale file ... is located outside of the allowed root paths"

Ce warning apparaît souvent quand vous avez **déplacé/cloné** le repo dans un
autre dossier, et que Xcode garde des références vers un ancien build.

Fix rapide :

```bash
make clean-macos
make get
make build-macos
```

Si le warning persiste, supprimez le cache Xcode (DerivedData) pour `Runner`
(option “nuke” côté machine), puis rebuild.

### Erreur codesign: "resource fork / Finder information ... not allowed"

Cause: attributs etendus (xattr).

```bash
APP_PATH="build/macos/Build/Products/Release/T2DECODE.app"
xattr -cr "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
```

### Erreur: `objective_c.framework did not contain an Info.plist`

Souvent lie aux native assets.

Actions:
- `flutter clean`
- `flutter pub get`
- rebuild `flutter build macos --release`
