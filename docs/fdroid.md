# Publication F-Droid

## Objectif

Préparer une build Android reproductible et une base de métadonnées compatible F-Droid.

## Ce qui est déjà prêt dans ce dépôt

- Fichier upstream F-Droid : `.fdroid.yml`
- Mode build dédié F-Droid : variable `FDROID_BUILD=true`
- Commande locale dédiée : `make build-android-fdroid`
- Métadonnées store listing : `fastlane/metadata/android/en-US/`

## Build locale “comme F-Droid”

```bash
make get
make test
make build-android-fdroid
```

APK attendu :

`build/app/outputs/flutter-apk/app-release.apk`

## Règles projet à maintenir pour F-Droid

- Pas de télémétrie ni analytics tiers
- Pas de dépendance cloud obligatoire
- Réseau limité à localhost (Ollama local) et LAN (GhostLink)
- Version Android synchronisée via `pubspec.yaml` (`version: X.Y.Z+N`)

## Procédure de soumission

1. Ouvrir une demande de packaging sur le tracker F-Droid (RFP).
2. Fournir l’Application ID : `com.tutodecode.app`.
3. Fournir l’URL du dépôt source : `https://github.com/TUTODECODE-FR/TUTODECODE`.
4. Mentionner que le dépôt contient déjà `.fdroid.yml` et les métadonnées Fastlane.
5. Répondre aux retours de l’équipe F-Droid (ajustements éventuels sur build/reproductibilité).

## Sortie d’une nouvelle version

1. Mettre à jour `pubspec.yaml` (`version: X.Y.Z+N`).
2. Mettre à jour `fastlane/metadata/android/en-US/changelogs/N.txt`.
3. Créer le tag Git `vX.Y.Z`.
4. Vérifier localement : `make build-android-fdroid`.

