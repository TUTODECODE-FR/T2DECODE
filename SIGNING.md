# Signature multi-plateforme (CI)

Ce projet signe les releases dans `/.github/workflows/build_release.yml`.
Les jobs release echouent si les secrets de signature ne sont pas fournis.

## Artefacts publies
- Android: `TUTODECODE-Android.apk`, `TUTODECODE-Android.aab`
- Windows: `TUTODECODE-Setup.exe` (installeur), `TUTODECODE-Windows.zip`
- macOS: `TUTODECODE-macOS.dmg` (installeur), `TUTODECODE-macOS.zip`
- Linux: `TUTODECODE-Linux.deb`, `TUTODECODE-Linux.tar.gz` + signatures `.sig`
- iOS: `TUTODECODE-iOS.ipa`

## Secrets GitHub obligatoires

### Android
- `ANDROID_KEYSTORE_BASE64` : contenu base64 du `.jks`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

### Windows
- `WINDOWS_PFX_BASE64` : certificat code-signing `.pfx` en base64
- `WINDOWS_PFX_PASSWORD`

### macOS (signature + notarization Apple)
- `MACOS_CERT_P12_BASE64` : certificat Developer ID Application `.p12` en base64
- `MACOS_CERT_PASSWORD`
- `MACOS_CERT_IDENTITY` : ex: `Developer ID Application: Your Company (TEAMID)`
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`

### iOS
- `IOS_CERT_P12_BASE64`
- `IOS_CERT_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `IOS_EXPORT_OPTIONS_PLIST_BASE64`

### Linux (signature du tarball)
- `LINUX_GPG_PRIVATE_KEY_BASE64`
- `LINUX_GPG_PASSPHRASE`
- `LINUX_GPG_KEY_ID`

## Exemple: convertir un fichier binaire en base64

```bash
base64 -i certificate.p12 | pbcopy
```

Sur Linux:

```bash
base64 -w 0 certificate.p12
```

## Note macOS Gatekeeper

Pour eviter l'erreur "Apple n'a pas pu confirmer...", il faut:
1. Signer l'app avec un certificat `Developer ID Application`
2. Soumettre a Apple Notary (`notarytool`)
3. `staple` le ticket de notarization

Le workflow fait ces 3 etapes automatiquement quand les secrets macOS sont presentes.
