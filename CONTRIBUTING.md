# Contribuer à TUTODECODE

## Prérequis
- Flutter SDK
- Dart SDK
- Make
- Git

## Installation
```bash
git clone https://github.com/TUTODECODE-FR/TUTODECODE.git
cd TUTODECODE
make get
```

## Vérifications avant PR
```bash
flutter format .
flutter analyze
flutter test
```

## Convention de commits
- feat:
- fix:
- docs:
- chore:
- ci:
- refactor:
- test:

## Stratégie de branches
- `main` : stable
- `feature/*` : nouvelles fonctionnalités
- `fix/*` : corrections

## Captures d’écran
- Nommez les fichiers clairement
- Stockez-les dans `docs/screenshots/` si ajoutées

## Modules pédagogiques
- Nommage stable et explicite
- Évitez les dépendances externes

## Builds multi-plateformes
- Testez localement si possible
- Décrivez les limites connues dans la PR
