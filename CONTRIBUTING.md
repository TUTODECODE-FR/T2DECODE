# Contribuer à TUTODECODE

## Prérequis
- Flutter SDK
- Dart SDK
- Make
- Git

## Gouvernance
- Les propriétaires de zones sont définis dans `.github/CODEOWNERS`.
- Toute contribution doit passer par une revue explicite avant merge.
- Les changements sécurité/CI doivent inclure une justification technique dans la PR.

## Installation
```bash
git clone https://github.com/TUTODECODE-FR/T2DECODE.git
cd TUTODECODE
make get
```

## Vérifications avant PR
```bash
flutter format .
flutter analyze
flutter test
```

## Checklist PR minimale
- Description claire du problème et de la solution.
- Impact sécurité/confidentialité documenté (si concerné).
- Tests exécutés localement (ou raison explicite si non exécutés).
- Mise à jour de la documentation (`README`/`docs`) si comportement modifié.

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
- `chore/*` : maintenance CI/docs/outillage

## Captures d’écran
- Nommez les fichiers clairement
- Stockez-les dans `docs/screenshots/` si ajoutées

## Modules pédagogiques
- Nommage stable et explicite
- Évitez les dépendances externes

## Builds multi-plateformes
- Testez localement si possible
- Décrivez les limites connues dans la PR
- Pour une release, vérifiez la présence de `SHA256SUMS.txt` dans les assets
