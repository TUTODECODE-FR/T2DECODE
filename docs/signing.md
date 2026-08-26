# Signature multi-plateforme

## Flux recommandé macOS (local → GitLab)

**On ne signe pas dans la CI GitLab.** Signature + notarisation sur le Mac local,
puis upload de l’artefact déjà signé.

```
1. Signer en local
   make sign-macos
   # ou: ./scripts/sign_notarize_macos.sh

2. Upload GitLab (Release + Generic Package)
   export GITLAB_TOKEN="glpat-…"   # si glab auth est expiré
   make upload-macos-gitlab
   # ou: ./scripts/upload_macos_to_gitlab.sh

3. Mac App Store (canal distinct)
   Xcode → Product → Archive → Organizer → Distribute App → App Store Connect
   (pas d’upload DMG GitLab pour le MAS)
```

| Canal | Certificat | Artefact | Destination |
|-------|------------|----------|-------------|
| **GitLab / Homebrew / direct** | Developer ID Application | `dist/macos/T2DECODE-macOS.dmg` (+ zip) | GitLab Release / Generic Package |
| **Mac App Store** | Apple Distribution + profil MAS | Archive `.xcarchive` / IPA-like | App Store Connect (ASC) |

Sandbox : MAS exige `com.apple.security.app-sandbox = true` dans
`macos/Runner/Release.entitlements`. Le build local Developer ID
(`scripts/build_macos_local.sh`) retire le sandbox pour un lancement Finder
sans profil d’approvisionnement. Détails : [`docs/macos-build.md`](macos-build.md).

### Variables signature locale (Keychain / env — jamais dans Git)

| Variable | Rôle |
|----------|------|
| `MACOS_CERT_IDENTITY` | optionnel ; sinon auto-détecte `Developer ID Application: …` |
| `APPLE_ID` | compte Apple pour `notarytool` |
| `APPLE_APP_SPECIFIC_PASSWORD` | mot de passe app-spécifique |
| `APPLE_TEAM_ID` | Team ID (ex. `TS97M57BJV`) |
| `NOTARY_PROFILE` | profil keychain `notarytool` (alternative aux 3 vars Apple) |
| `SKIP_BUILD=1` | réutilise `dist/macos/T2DECODE.app` |
| `SKIP_NOTARIZE=1` | signature seule (Gatekeeper peut encore avertir) |

Exemple :

```bash
export APPLE_ID="contact@tutodecode.org"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export APPLE_TEAM_ID="TS97M57BJV"
make sign-macos
```

### Auth upload GitLab

Priorité : `GITLAB_TOKEN` / `PRIVATE_TOKEN` / `GL_TOKEN`, sinon `glab` authentifié.

```bash
# Token expiré côté glab :
export GITLAB_TOKEN="glpat-xxxxxxxx"   # scope api
make upload-macos-gitlab

# Ou ré-auth glab :
glab auth login --hostname gitlab.com
# glab auth login --hostname gitlab.com --token "$GITLAB_TOKEN"
```

Options upload :

```bash
TAG=v1.0.5 UPLOAD_MODE=both ./scripts/upload_macos_to_gitlab.sh
# UPLOAD_MODE=package  → Generic Package seulement
# UPLOAD_MODE=release  → Release (glab) ou liens Release (curl+packages)
DRY_RUN=1 ./scripts/upload_macos_to_gitlab.sh
```

Projet par défaut : `tutodecode-org/T2DECODE` (`GITLAB_PROJECT` / `GITLAB_HOST` surchargeables).
Tag par défaut : `v` + version `pubspec.yaml` (ex. `1.0.5+37` → `v1.0.5`).

---

## CI GitHub (historique / miroir)

Le workflow `/.github/workflows/build_release.yml` (ou miroir) peut encore signer
si les secrets sont fournis. Les jobs release échouent sans secrets.

### Artefacts publiés (CI)
- Android: `T2DECODE-Android.apk`, `T2DECODE-Android.aab`
- Windows: `T2DECODE-Setup.exe`, `T2DECODE-Windows.zip`
- macOS: `T2DECODE-macOS.dmg`, `T2DECODE-macOS.zip`
- Linux: `T2DECODE-Linux.deb`, `T2DECODE-Linux.tar.gz` + `.sig`
- iOS: `T2DECODE-iOS.ipa`

### Secrets GitHub (si signature CI)

#### Android
- `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`

#### Windows
- `WINDOWS_PFX_BASE64`, `WINDOWS_PFX_PASSWORD`

#### macOS (signature + notarization Apple)
- `MACOS_CERT_P12_BASE64`, `MACOS_CERT_PASSWORD`
- `MACOS_CERT_IDENTITY` : ex. `Developer ID Application: Your Company (TEAMID)`
- `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`

#### iOS
- `IOS_CERT_P12_BASE64`, `IOS_CERT_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_EXPORT_OPTIONS_PLIST_BASE64`

#### Linux
- `LINUX_GPG_PRIVATE_KEY_BASE64`, `LINUX_GPG_PASSPHRASE`, `LINUX_GPG_KEY_ID`

### Convertir un binaire en base64

```bash
base64 -i certificate.p12 | pbcopy
```

Linux :

```bash
base64 -w 0 certificate.p12
```

## Note Gatekeeper

Pour éviter « Apple n'a pas pu confirmer… » :

1. Signer avec `Developer ID Application`
2. Soumettre à Apple Notary (`notarytool`)
3. `stapler staple` le ticket

Le script local `scripts/sign_notarize_macos.sh` enchaîne ces étapes.
**Aucun certificat n’est stocké dans le dépôt** — Keychain / variables d’environnement uniquement.
