# Tableau des contributions bénévoles — T2DECODE

> **Source de vérité = [Issues GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/issues/?label_name[]=benevolat)**  
> Label : `benevolat` (+ `wishlist` / `bug` / `proposition` selon le cas).

Ce fichier est un **index** (pas un tableau à éditer à la main).  
Contributeurs : [CONTRIBUTORS.md](./CONTRIBUTORS.md).

## Flux bénévole (100 % automatisé)

### 1. Proposer une idée / un bug

[Nouvelle issue](https://gitlab.com/tutodecode-org/T2DECODE/-/issues/new) → modèle **Proposition** ou **Bug_benevolat**  
(labels `benevolat` + `wishlist|bug|proposition`). Le dropdown Type (Incident / Issue / Task) **n’accepte pas** de types custom sur GitLab.com : on s’appuie sur **modèles + labels**.

### 2. Prendre une tâche (`prendre #<iid>`) — effet immédiat

**Le ticket est verrouillé pour vous dès l’ouverture de la MR** — pas besoin d’attendre
qui que ce soit. **Ne pas** ouvrir une issue « Prendre » pour claimer — le modèle
*Prendre_une_tache* renvoie ici.

1. Choisir une issue **ouverte sans assignee** (idéalement label `libre`).
2. Branche `volunteer/prendre-<iid>` (ex. `volunteer/prendre-42`).
3. Marqueur `volunteer/claims/<iid>.md` :

```markdown
username: ton-pseudo-gitlab
```

4. MR titrée **exactement** `prendre #<iid>` + **DCO** (`Signed-off-by`) — modèle MR **Prendre** recommandé.
5. La pipeline de la MR se déclenche aussitôt :
   - ✅ **verte** → le ticket est **à vous, immédiatement** (même si la MR reste ouverte).
     Le bot bénévole (pipeline planifiée sur `main`) assigne l’issue (`en-cours`)
     et **merge la MR tout seul** peu après.
   - ❌ **rouge** → ticket déjà pris (« déjà pris par @xxx (MR !NNN) »), format
     invalide, ou fichier hors zone bénévole : le message de la CI dit quoi corriger.

### 3. Règles anti-collision

- **Une seule claim active par personne** (MR de claim ouverte *ou* ticket `en-cours` assigné).
- Si deux MR visent le même ticket, **la plus ancienne gagne** ; l’autre échoue en CI.
- **Abandon** : fermez votre MR de claim → le bot libère le ticket automatiquement.
- **Inactivité** : une MR de claim sans activité pendant **14 jours** est fermée par le bot → le ticket redevient `libre`.

### 4. Après le claim : coder

Branche feature dédiée + MR classique (relecture mainteneur, comme tout le code).  
La MR de code **ferme l’issue** une fois mergée (livraison).

| Merge de… | Effet |
| :--- | :--- |
| Issue / discussion « Proposition » | ❌ ne réserve pas la tâche |
| MR `prendre #N` **ouverte** | ✅ verrouille le ticket (immédiat) |
| MR `prendre #N` mergée (par le bot) | ✅ assigne + `en-cours` + archive le claim |
| MR de **code** | ✅ ferme l’issue (livraison) |

### Labels recommandés

| Label | Usage |
| :--- | :--- |
| `benevolat` | **Obligatoire** |
| `wishlist` | Idée / amélioration |
| `proposition` | Proposition communauté |
| `bug` | Anomalie |
| `libre` | Optionnel — retiré au claim |
| `en-cours` | Posé automatiquement dès le claim validé |
| `P1` / `P2` / `P3` | Priorité (optionnel) |

### Contact

Association TUTODECODE — [contact@tutodecode.org](mailto:contact@tutodecode.org) · [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## Idées de départ (à créer comme issues)

| ID | Priorité | Titre | Description courte | Compétences |
| :--- | :--- | :--- | :--- | :--- |
| T2D-001 | P1 | Aligner CONTRIBUTING sur GitLab | Remplacer le `git clone` GitHub obsolète par l’URL GitLab canonique et documenter `make get` / vérifs Flutter. | Markdown, Git |
| T2D-002 | P1 | HybridAssetLoader : JSON bundlés | Charger aussi `assets/translations/{en,es,…}.json` depuis le bundle (aujourd’hui seul `fr.json` + override Documents). | Flutter/Dart, i18n |
| T2D-003 | P1 | i18n écran Accueil | Remplacer les chaînes FR en dur de `home_screen.dart` (`Mes parcours`, `Tuteur IA`, etc.) par des clés `.tr()`. | Flutter, FR/EN |
| T2D-004 | P2 | Compléter traductions ES/DE/AR/ZH | Aligner les ~21 clés manquantes (`home.*`) sur `fr.json` / `en.json` dans `assets/translations/`. | Traduction, JSON |
| T2D-005 | P2 | Accessibilité shell & navigation | Ajouter `Semantics` / labels sur la barre latérale, nav mobile et actions principales (`app_shell`, home). | Flutter, a11y |
| T2D-006 | P2 | Docs contribution modules `.tdc` | Mettre à jour `docs/module-contribution.md` pour le format `courses.tdc` (pas seulement Markdown/JSON legacy). | Rédaction, `.tdc` |
| T2D-007 | P2 | Empty states cours / progression | Empty states clairs quand aucun parcours démarré ou QCM absent (CTA vers catalogue), cohérents offline-first. | Flutter, UX |
| T2D-008 | P2 | Polish Android (outils & dense UI) | Passer en revue toolbox / calculateurs sur petit écran : overflow, padding, scroll, touches. | Flutter, Android |
| T2D-009 | P3 | Polish desktop Windows/Linux | Fenêtrage, focus clavier et densités pour runners desktop (pas de nouvelle feature). | Flutter, desktop |
| T2D-010 | P2 | Indicateur mode hors-ligne | Rendre le mode offline / zero-network plus visible (badge ou bannière settings/home) sans alarme rouge. | Flutter, UX |
| T2D-011 | P3 | Guide contributeur first-run | Court tutoriel dans CONTRIBUTING : clone → `make get` → `flutter run` → claim board → MR + DCO `-s`. | Markdown |
| T2D-012 | P3 | Cohérence cheat sheets assets | Vérifier alignement `cheat_sheets.json` / NetKit vs contenus affichés ; documenter le workflow d’édition. | JSON, docs |

*T2DECODE est multi-OS (dont Android) — les builds release restent sur GitHub Actions / F-Droid selon le flux du dépôt.*
