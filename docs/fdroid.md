# Publication F-Droid

## Objectif

Préparer une build Android reproductible et une base de métadonnées compatible F-Droid.

## Ce qui est déjà prêt dans ce dépôt

- Fichier upstream F-Droid : `.fdroid.yml` (utilisé comme référence)
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

## Procédure de soumission initiale

1. Ouvrir une Merge Request (MR) sur le dépôt F-DroidData (`https://gitlab.com/fdroid/fdroiddata`).
2. Fournir l’Application ID correct : `org.t2decode.app`.
3. Fournir l’URL du dépôt source : `https://gitlab.com/tutodecode-org/T2DECODE`.
4. Utiliser le template Flutter fourni par F-Droid (`templates/build-flutter.yml`) pour créer le fichier `metadata/org.t2decode.app.yml` sur votre fork de `fdroiddata`.
5. Ne **pas** inclure les champs `Summary` et `Description` dans le fichier YAML (ils sont récupérés automatiquement depuis `fastlane/`).

## Sortie d’une nouvelle version

1. Mettre à jour `pubspec.yaml` (`version: X.Y.Z+N`).
2. Assurez-vous que la version de Flutter est épinglée dans le fichier `.flutter-version`.
3. Mettre à jour `fastlane/metadata/android/en-US/changelogs/N.txt`.
4. Créer le tag Git `vX.Y.Z`.
5. Vérifier localement : `make build-android-fdroid`.

## En cas de demande de modification par F-Droid

Si l'équipe F-Droid demande des modifications sur la recette de build (ex: modifier l'étape de `prebuild`), vous **devez** modifier le fichier `metadata/org.t2decode.app.yml` qui se trouve dans votre propre fork du dépôt **`fdroiddata`** (et non pas seulement le fichier local `.fdroid.yml` de T2DECODE). 

**Étapes pour mettre à jour la MR F-Droid :**
```bash
# 1. Cloner votre fork de fdroiddata (si ce n'est pas déjà fait)
git clone git@gitlab.com:tutodecode-org/data.git fdroiddata-mr
cd fdroiddata-mr

# 2. Modifier le fichier de métadonnées
nano metadata/org.t2decode.app.yml

# 3. Commiter et pousser pour mettre à jour la MR
git add metadata/org.t2decode.app.yml
git commit -m "Update build recipe as requested"
git push origin master
```
