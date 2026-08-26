# Release

## Processus

### macOS (recommandé) : signer localement, puis GitLab
1. `make sign-macos` — Developer ID + notarisation → `dist/macos/`
2. `make upload-macos-gitlab` — Release / Generic Package (`GITLAB_TOKEN` ou `glab`)
3. Mac App Store reste **Archive → App Store Connect** (canal distinct du DMG)

Voir [`docs/signing.md`](signing.md) et [`docs/macos-build.md`](macos-build.md).

### Autres plateformes / miroir GitHub
- Un tag `vX.Y.Z` peut déclencher la build multi-plateforme (GitHub Actions)
- Les artefacts sont publiés sur GitHub Releases (miroir) et/ou liés depuis GitLab
- Les checksums sont générés pour les artefacts présents

## Checksums
- Un fichier `SHA256SUMS.txt` est publié avec la release
- Vérification locale : `sha256sum -c SHA256SUMS.txt`

## Signatures (quand secrets configurés)
- Linux : signatures détachées `.sig` pour `tar.gz` et `deb`
- Manifest release : signature GPG de `SHA256SUMS.txt` (si clé disponible)

## Provenance CI/CD
- La release est produite par `.github/workflows/build_release.yml`
- Les workflows sont versionnés dans le repo pour audit

## Préparation F-Droid
- Le dépôt inclut `.fdroid.yml` à la racine
- Les métadonnées Android sont disponibles dans `fastlane/metadata/android/en-US/`
- Build locale dédiée : `make build-android-fdroid`
