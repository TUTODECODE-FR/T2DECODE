# Tableau des contributions bénévoles — T2DECODE

> **Source de vérité = [Issues GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/issues/?label_name[]=benevolat)**  
> Label : `benevolat` (+ `wishlist` / `bug` / `proposition` selon le cas).

Ce fichier est un **index** (pas un tableau à éditer à la main).  
Pas de colonne « Pris par » — on se coordonne via les **issues** et les **Merge Requests**.

## Comment contribuer (sans édition manuelle)

1. **Consulter** les [issues `benevolat`](https://gitlab.com/tutodecode-org/T2DECODE/-/issues/?label_name[]=benevolat).
2. **Proposer** une idée / **signaler** un bug : créer une issue avec le label `benevolat` (et `wishlist` ou `bug`).
3. **Coder** : branche + **Merge Request** avec DCO (`Signed-off-by`).

Assignees GitLab = travail en cours (optionnel). Fermer l’issue au merge.

### Labels recommandés

| Label | Usage |
| :--- | :--- |
| `benevolat` | **Obligatoire** — apparaît sur ce board |
| `wishlist` | Idée / amélioration |
| `proposition` | Proposition communauté |
| `bug` | Anomalie |
| `P1` / `P2` / `P3` | Priorité (optionnel) |

### Contact

Association TUTODECODE — [contact@tutodecode.org](mailto:contact@tutodecode.org) · [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## Idées de départ (à créer comme issues)

Si le label `benevolat` n’a pas encore d’issues, voici des pistes (créez une issue chacune) :

| ID | Priorité | Titre | Compétences |
| :--- | :--- | :--- | :--- |
| T2D-001 | P1 | Aligner CONTRIBUTING sur GitLab (`make get`) | Markdown, Git |
| T2D-002 | P1 | HybridAssetLoader : JSON bundlés (i18n) | Flutter/Dart, i18n |
| T2D-003 | P1 | i18n écran Accueil (clés `.tr()`) | Flutter, FR/EN |
| T2D-004 | P2 | Compléter traductions ES/DE/AR/ZH | Traduction, JSON |
| T2D-005 | P2 | Accessibilité shell & navigation | Flutter, a11y |
| T2D-006 | P2 | Docs contribution modules `.tdc` | Rédaction |
| T2D-007 | P2 | Empty states cours / progression | Flutter, UX |
| T2D-008 | P2 | Polish Android (outils & dense UI) | Flutter, Android |
| T2D-009 | P3 | Polish desktop Windows/Linux | Flutter, desktop |
| T2D-010 | P2 | Indicateur mode hors-ligne | Flutter, UX |

*T2DECODE est multi-OS (dont Android) — les builds release restent sur GitHub Actions / F-Droid selon le flux du dépôt.*
