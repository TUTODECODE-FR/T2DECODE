# Tableau des contributions bénévoles — T2DECODE

> **Source de vérité = [Issues GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/issues/?label_name[]=benevolat)**  
> Label : `benevolat` (+ `wishlist` / `bug` / `proposition` selon le cas).

Ce fichier est un **index** (pas un tableau à éditer à la main).  
Contributeurs : [CONTRIBUTORS.md](./CONTRIBUTORS.md).

## Flux bénévole (automatisé)

### 1. Proposer une idée / un bug

Créer une [issue GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/issues/new) avec les labels `benevolat` + `wishlist|bug|proposition`.

### 2. Prendre une tâche (`prendre #<iid>`)

Anti-collision : une seule personne peut être assignee. Le CI bloque une 2ᵉ claim.

1. Choisir une issue **ouverte sans assignee**.
2. Branche `volunteer/prendre-<iid>` (ex. `volunteer/prendre-42`).
3. Marqueur `volunteer/claims/<iid>.md` :

```markdown
username: ton-pseudo
```

4. MR titrée **exactement** `prendre #<iid>` + **DCO**.
5. Maxime (ou un reviewer) **valide / merge**.

### 3. Après le merge (automatique)

Job CI `volunteer_claim_apply` sur `main` :

1. détecte le claim (fichier et/ou titre) ;
2. assigne l’issue à l’auteur ;
3. pose `en-cours`, retire `libre` si présent.

Puis coder : branche feature + MR classique.

### 4. Garde anti-collision (MR)

`volunteer_claim_validate` **échoue** si l’issue a déjà un **autre** assignee.

### Labels recommandés

| Label | Usage |
| :--- | :--- |
| `benevolat` | **Obligatoire** |
| `wishlist` | Idée / amélioration |
| `proposition` | Proposition communauté |
| `bug` | Anomalie |
| `libre` | Optionnel — retiré au claim |
| `en-cours` | Posé automatiquement après merge du claim |
| `P1` / `P2` / `P3` | Priorité (optionnel) |

### Contact

Association TUTODECODE — [contact@tutodecode.org](mailto:contact@tutodecode.org) · [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## Idées de départ (à créer comme issues)

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
