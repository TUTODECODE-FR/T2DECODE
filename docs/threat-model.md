# Modèle de Menace (Threat Model)

## Périmètre

T2DECODE est conçu pour un usage "local-first" dans des environnements hors ligne ou contraints.  
Le modèle de menace se concentre sur :

- L'intégrité des binaires distribués.
- L'intégrité des ressources pédagogiques embarquées (assets).
- La confidentialité des données locales de l'utilisateur.
- L'utilisation de l'IA locale via Ollama sans dépendance au cloud.

## Hypothèses de Sécurité

- Le système d'exploitation hôte n'est pas déjà entièrement compromis.
- Les utilisateurs installent les artefacts depuis les releases officielles sur GitHub.
- Les vérifications (`SHA256SUMS.txt`) sont effectuées avant l'installation dans les contextes sensibles.
- Ollama s'exécute sur un point de terminaison local de confiance configuré par l'utilisateur.

## Menaces Principales

| ID | Menace | Impact | Atténuations Actuelles |
| :-- | :-- | :-- | :-- |
| T1 | Artefact de release altéré | Élevé | Sommes de contrôle de release, signatures GPG optionnelles, workflow de release protégé |
| T2 | Modification d'assets après installation | Moyen | Vérification d'intégrité au démarrage (`AssetIntegrityService`) |
| T3 | Exfiltration de données via une dépendance cloud | Élevé | Architecture zéro-cloud, Ollama local uniquement, aucune télémétrie |
| T4 | Compromission de la chaîne d'approvisionnement CI/CD | Élevé | Actions épinglées, runners isolés, workflow limité au tag de release |
| T5 | Contenu de module malveillant ou dangereux | Moyen | Chargement local uniquement, feuille de route pour le contenu signé, processus de revue manuelle |
| T6 | Abus du LAN en mode Ghost Link | Moyen | Portée limitée au réseau local, messagerie chiffrée, activation contrôlée par l'utilisateur |

## Matrice de Contrôles

| Contrôle | Description | Statut | Preuve |
| :-- | :-- | :-- | :-- |
| C1 | Publication de sommes de contrôle SHA-256 pour chaque release | Implémenté | `SHA256SUMS.txt` dans les assets de release |
| C2 | Signatures détachées pour les artefacts Linux lorsque le secret GPG est configuré | Implémenté (conditionnel) | Assets `.sig` dans la release |
| C3 | Validation de l'intégrité des assets au démarrage | Implémenté | `lib/core/services/asset_integrity_service.dart` |
| C4 | Aucun SDK tiers d'analyse/télémétrie | Implémenté | `docs/privacy.md`, revue des dépendances |
| C5 | CODEOWNERS et politique de revue manuelle | Implémenté | `.github/CODEOWNERS`, `CONTRIBUTING.md` |
| C6 | Attestation de provenance du build dans le workflow de release | Implémenté | `.github/workflows/build_release.yml` |

## Risques Résiduels

- Le modèle à mainteneur unique augmente le risque opérationnel.
- Certains pipelines de signature de plateforme dépendent de la disponibilité de secrets.
- La couverture de validation manuelle peut varier d'une version à l'autre.

## Durcissement Prévu

- Ajouter un guide de vérification de signature de release par système d'exploitation.
- Ajouter des notes sur les builds reproductibles et des contrôles de builds déterministes.
- Publier des notes de révision de sécurité périodiques dans `docs/releases/`.
