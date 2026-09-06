# Contribuer à TUTODECODE

## Wishlist / bénévolat (Issues GitLab)

**Source de vérité** : [issues label `benevolat`](https://gitlab.com/tutodecode-org/T2DECODE/-/issues/?label_name[]=benevolat)  
Index : [VOLUNTEER_BOARD.md](./VOLUNTEER_BOARD.md) · Contributeurs : [CONTRIBUTORS.md](./CONTRIBUTORS.md)

1. **Proposer** : modèle d’issue **Proposition** ou **Bug_benevolat** (labels `benevolat` + `proposition`/`wishlist` ou `bug`). Le menu Type (Incident / Issue / Task) n’est **pas** personnalisable sur GitLab.com — on utilise modèles + labels. Type **Task** optionnel pour le suivi.
2. **Prendre** : **pas** une issue « Prendre » — branche `volunteer/prendre-<iid>` + `volunteer/claims/<iid>.md` + MR titrée **exactement** `prendre #<iid>` (modèle MR **Prendre**) → après merge de **cette** MR, la CI assigne (`en-cours`). Collision = pipeline rouge. Merger une Proposition **n’assigne pas** ; la MR de code ferme l’issue.
3. **Coder** : branche dédiée + **Merge Request** avec **DCO** (`Signed-off-by`).

Contact : [contact@tutodecode.org](mailto:contact@tutodecode.org)

## Prérequis
- Flutter SDK
- Dart SDK
- Make
- Git

## Gouvernance
- Les propriétaires de zones sont définis dans `.github/CODEOWNERS`.
- Toute contribution doit passer par une revue explicite avant merge.
- Les changements sécurité/CI doivent inclure une justification technique dans la PR.

## Developer Certificate of Origin (DCO)
Pour des raisons légales, toute contribution doit respecter le DCO (Developer Certificate of Origin). En contribuant à ce dépôt, vous certifiez avoir le droit de soumettre ce code sous la licence GPLv3 du projet.
**Tous vos commits doivent être signés** avec la ligne `Signed-off-by: Votre Nom <votre.email@example.com>`.
Pour ce faire automatiquement, utilisez l'option `-s` lors de vos commits :
`git commit -s -m "feat: ajout d'une fonctionnalité"`

Consultez le fichier [DCO.md](DCO.md) pour lire le certificat complet.

## Installation
```bash
git clone https://gitlab.com/tutodecode-org/T2DECODE.git
cd T2DECODE
make get
```

## Vérifications avant PR
```bash
flutter format .
flutter analyze
flutter test
```

## Checklist PR minimale
- **DCO** : Tous les commits sont signés (`Signed-off-by`).
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
