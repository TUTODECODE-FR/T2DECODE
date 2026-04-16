# Release

## Processus
- Un tag `vX.Y.Z` déclenche la build multi-plateforme
- Les artefacts sont publiés sur GitHub Releases
- Les checksums sont générés automatiquement pour tous les artefacts présents

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
