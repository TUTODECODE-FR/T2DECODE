# Confiance & vérifiabilité (T2DECODE)

Cette page décrit comment T2DECODE **prouve** sa fiabilité, et quelles pratiques
peuvent être mises en place pour renforcer la confiance dans le temps.

Le principe : **ne pas demander la confiance — la rendre vérifiable**.

---

## ✅ Ce que vous pouvez vérifier aujourd’hui

### 1) Chaîne de release vérifiable

- Les artefacts officiels sont publiés sur GitHub Releases.
- Un fichier `SHA256SUMS.txt` est inclus pour vérifier l’intégrité des binaires.
- Les workflows CI/release sont versionnés dans `.github/workflows/`.

### 2) Sécurité “offline-first”

- Zéro cloud requis pour utiliser l’application.
- L’IA locale (Ollama) est **optionnelle**.
- Les fonctionnalités LAN (ex : Ghost Link) restent **locales**.

### 3) Contrôles d’intégrité au démarrage

L’application exécute des vérifications d’intégrité des assets au démarrage
et des protections anti-altération (locales, sans réseau).

---

## 🚀 Ce que nous voulons renforcer (roadmap “fiabilité”)

### 1) Audit de sécurité indépendant (pentest / audit code)

Objectif : faire réaliser un audit par un tiers spécialisé (pentest et/ou audit
du code source), puis publier un rapport de synthèse.

Pourquoi : c’est l’un des signaux les plus forts pour prouver l’absence de
comportements cachés (trackers, exfiltration, etc.) et réduire les risques
de failles critiques.

### 2) Builds reproductibles (transparence totale)

Objectif : permettre à un tiers de recompiler le projet et d’obtenir un binaire
identique (ou strictement vérifiable) par rapport à l’artefact distribué.

Pourquoi : cela réduit le risque “code public propre” vs “binaire officiel modifié”.

Note : atteindre la reproductibilité “bit‑pour‑bit” sur toutes plateformes
demande une chaîne de build strictement déterministe (toolchains, timestamps,
notarization/signature, etc.). Dans certains écosystèmes (ex : App Store),
le binaire final peut être re-signé côté Apple, ce qui peut limiter l’égalité
bit‑pour‑bit mais on peut conserver une vérifiabilité forte (hash du binaire
pré‑signature, provenance CI, attestations, etc.).

### 3) Validation par les pairs (open source “sous inspection”)

Objectif : augmenter la revue externe (Issues, PRs, forks), favoriser les
contributions et la relecture.

Pourquoi : plus il y a d’yeux, plus les erreurs et comportements suspects sont
difficiles à cacher.

### 4) Bug bounty / programme de recherche de vulnérabilités

Objectif : inviter explicitement les chercheurs en sécurité à tester T2DECODE,
avec un cadre clair (scope, règles, canaux de signalement, et éventuellement
récompenses).

Pourquoi : cela prouve la maturité et la réactivité, et améliore la sécurité
réelle du produit.

### 5) Transparence associative

Objectif : publier des informations publiques et régulières (ex : rapport annuel)
sur la gouvernance et le financement du projet, et réaffirmer l’absence de
monétisation de données.

Pourquoi : le modèle associatif (ESS) est un atout, mais la transparence est ce
qui le rend crédible dans la durée.

---

## Liens utiles

- Politique de sécurité : `SECURITY.md`
- Confidentialité : `docs/privacy.md`
- Modèle de sécurité : `docs/security-model.md`
- Threat model : `docs/threat-model.md`

