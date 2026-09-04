# Tableau des contributions bénévoles — T2DECODE

Cahier des charges vivant des améliorations ouvertes sur **T2DECODE**, l’application Flutter d’apprentissage offline (cours, labs, outils, Ghost AI, i18n, accessibilité, docs).

Ce fichier est la **source de vérité** pour savoir qui travaille sur quoi. Les issues GitLab/GitHub restent optionnelles ; le suivi des claims bénévoles se fait ici.

## Comment ça marche

1. **Choisir** une tâche dont le statut est `Libre`.
2. **Réclamer** : ouvrir une MR qui **ne fait que** remplir **Pris par** avec `@username` et passer le statut à `En cours`.
3. **Travailler** sur une branche dédiée (commits avec **DCO** : `Signed-off-by: Prénom NOM <email>`).
4. **Livrer** : au merge, passer le statut à `Fait` et mettre le lien de la MR dans **MR / Lien**.

### Anti-collision (personne ne se marche dessus)

- Si **Pris par** est rempli → **ne pas prendre** : ouvre une discussion ou choisis une autre tâche.
- Soft lock : sans MR / activité pendant **14 jours**, la tâche revient à `Libre` (toi ou un mainteneur).
- Recommandé : **une personne = une seule tâche** `En cours` à la fois.
- Abandonner : retirer ton pseudo, remettre `Libre`, laisser un mot si besoin.

### Statuts

| Valeur | Signification |
| :--- | :--- |
| `Libre` | À prendre |
| `En cours` | Quelqu’un travaille dessus |
| `Fait` | Mergé / terminé |
| `Bloqué` | En attente d’une décision ou d’une dépendance |

### Priorités

`P1` (urgent / fort impact) · `P2` (utile bientôt) · `P3` (nice-to-have)

### Contact

Association TUTODECODE — [contact@tutodecode.org](mailto:contact@tutodecode.org) · GitLab : [tutodecode-org/T2DECODE](https://gitlab.com/tutodecode-org/T2DECODE)

Guide détaillé : [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## Backlog

| ID | Statut | Priorité | Titre | Description courte | Compétences | Pris par | MR / Lien |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| T2D-001 | Libre | P1 | Aligner CONTRIBUTING sur GitLab | Remplacer le `git clone` GitHub obsolète par l’URL GitLab canonique et documenter `make get` / vérifs Flutter. | Markdown, Git | — | — |
| T2D-002 | Libre | P1 | HybridAssetLoader : JSON bundlés | Charger aussi `assets/translations/{en,es,…}.json` depuis le bundle (aujourd’hui seul `fr.json` + override Documents). | Flutter/Dart, i18n | — | — |
| T2D-003 | Libre | P1 | i18n écran Accueil | Remplacer les chaînes FR en dur de `home_screen.dart` (`Mes parcours`, `Tuteur IA`, etc.) par des clés `.tr()`. | Flutter, FR/EN | — | — |
| T2D-004 | Libre | P2 | Compléter traductions ES/DE/AR/ZH | Aligner les ~21 clés manquantes (`home.*`) sur `fr.json` / `en.json` dans `assets/translations/`. | Traduction, JSON | — | — |
| T2D-005 | Libre | P2 | Accessibilité shell & navigation | Ajouter `Semantics` / labels sur la barre latérale, nav mobile et actions principales (`app_shell`, home). | Flutter, a11y | — | — |
| T2D-006 | Libre | P2 | Docs contribution modules `.tdc` | Mettre à jour `docs/module-contribution.md` pour le format `courses.tdc` (pas seulement Markdown/JSON legacy). | Rédaction, `.tdc` | — | — |
| T2D-007 | Libre | P2 | Empty states cours / progression | Empty states clairs quand aucun parcours démarré ou QCM absent (CTA vers catalogue), cohérents offline-first. | Flutter, UX | — | — |
| T2D-008 | Libre | P2 | Polish Android (outils & dense UI) | Passer en revue toolbox / calculateurs sur petit écran : overflow, padding, scroll, touches. | Flutter, Android | — | — |
| T2D-009 | Libre | P3 | Polish desktop Windows/Linux | Fenêtrage, focus clavier et densités pour runners desktop (pas de nouvelle feature). | Flutter, desktop | — | — |
| T2D-010 | Libre | P2 | Indicateur mode hors-ligne | Rendre le mode offline / zero-network plus visible (badge ou bannière settings/home) sans alarme rouge. | Flutter, UX | — | — |
| T2D-011 | Libre | P3 | Guide contributeur first-run | Court tutoriel dans CONTRIBUTING : clone → `make get` → `flutter run` → claim board → MR + DCO `-s`. | Markdown | — | — |
| T2D-012 | Libre | P3 | Cohérence cheat sheets assets | Vérifier alignement `cheat_sheets.json` / NetKit vs contenus affichés ; documenter le workflow d’édition. | JSON, docs | — | — |

---

## Proposer une nouvelle tâche

Ajoute une ligne en bas du tableau (ID suivant : `T2D-013`, …) via une MR, ou écris à [contact@tutodecode.org](mailto:contact@tutodecode.org).

Garde la description **courte** (une phrase) ; le détail technique va dans la MR.
