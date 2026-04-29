# T2DECODE — Résumé (aligné sur `main`)

Dernière mise à jour : 21 avril 2026

## Objectif

T2DECODE est une application technique et pédagogique conçue pour apprendre et pratiquer **localement**, sans dépendre d’un cloud.

## Principes (message public)

- Offline-first : l’application reste utile sans Internet.
- Zéro tracking : pas d’analytics, pas de télémétrie.
- Données locales : préférences et progression stockées sur l’appareil.
- IA locale (optionnelle) : intégration avec Ollama, sans service tiers imposé.

## Capacités présentes (selon le code)

- Ghost AI : assistant technique via Ollama local (optionnel). Voir `docs/ollama.md`.
- NetKit : diagnostic réseau local (infos système, résolution DNS, test de connectivité TCP sur hôte fourni par l’utilisateur).
- Outils utilitaires : conversions, références, générateurs (hash / mots de passe), JSON, cron, etc. Voir `docs/tools.md`.
- Cours / modules : contenus Markdown/JSON + suivi local. Voir `docs/modules.md`.
- Labs / simulateurs : scénarios pédagogiques et simulations. Voir `docs/labs.md`.
- Lab isolé (offline) : guide pour préparer un environnement volontairement vulnérable en local. Voir `docs/ctf-prep.md`.

## Compatibilité OS (distribution)

| Plateforme | Distribution |
| :--- | :--- |
| Android | Releases GitHub |
| Windows | Releases GitHub |
| macOS | Releases GitHub |
| Linux | Releases GitHub |
| iOS | Builds locaux |

Ce document est volontairement sobre : il vise à décrire ce qui est visible dans le code et dans les releases, sans promesses au-delà de l’existant.
