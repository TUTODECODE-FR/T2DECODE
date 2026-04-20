# Build & Tests

## Prérequis
- Flutter SDK (stable)
- Dart SDK (inclus avec Flutter)
- Make

Recommandé :
- macOS/Linux : `git`, `bash/zsh`
- Windows : PowerShell + Git

## Philosophie
Le repo est pensé pour :
- des builds reproductibles,
- des tests rapides (`flutter test`),
- des sorties multi-plateformes via `make`.

## Installation
```bash
git clone https://github.com/TUTODECODE-FR/T2DECODE.git
cd T2DECODE
make get
```

## Tests
```bash
make test
```

## Vérification d’environnement
```bash
make setup
```

## Builds
```bash
make build-android
make build-android-fdroid
make build-macos
make build-linux
make build-dmg
```

## Exécution (dev)
```bash
flutter run
```

## Dépannage (rapide)

- **`flutter pub get` lent** : vérifier proxy/VPN, ou relancer `make get`.
- **Tests golden** : certains tests UI peuvent dépendre de l’environnement CI.
- **iOS App Store** : la publication App Store est en cours de vérification Apple ; côté dev, utilisez les builds iOS locaux (voir `docs/ios-build.md`).
