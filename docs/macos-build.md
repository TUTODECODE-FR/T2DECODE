# macOS: creer et builder l'application

Ce guide explique comment **generer l'app macOS** (build local, packaging, signature/notarisation).

Pour la CI (GitHub Actions) et la liste des secrets, voir `docs/signing.md`.

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

## Signature + notarisation (distribution "propre")

Sans signature/notarisation, macOS peut afficher des alertes Gatekeeper.

### 1) Signer (Developer ID Application)

```bash
APP_PATH="build/macos/Build/Products/Release/T2DECODE.app"
codesign --force --deep --options runtime --timestamp --sign "Developer ID Application: ..." "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose "$APP_PATH"
```

### 2) Notariser (notarytool)

```bash
APP_PATH="build/macos/Build/Products/Release/T2DECODE.app"
rm -f T2DECODE-macOS.zip
ditto -c -k --keepParent "$APP_PATH" T2DECODE-macOS.zip

xcrun notarytool submit T2DECODE-macOS.zip \
  --apple-id "email@domain.tld" \
  --password "app-specific-password" \
  --team-id "TEAMID" \
  --wait
```

### 3) Staple

```bash
xcrun stapler staple "$APP_PATH"
```

---

## Depannage

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
