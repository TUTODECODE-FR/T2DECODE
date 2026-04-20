# Modèle de sécurité

## Principes
- Zéro cloud, zéro tracking
- Données locales uniquement
- Vérification d'intégrité des assets

## Mécanismes
- `AssetIntegrityService` : SHA-256 des assets
- Protections anti-altération au démarrage

## Chaîne de confiance release
- Les artefacts officiels sont publiés via GitHub Releases.
- `SHA256SUMS.txt` est généré automatiquement à chaque release.
- Des signatures GPG Linux (`.sig`) sont publiées si la clé release est configurée.
- La gouvernance des zones critiques est définie dans `.github/CODEOWNERS`.

## Confiance & vérifiabilité
T2DECODE vise une sécurité **vérifiable** (pas basée sur la confiance).

- État actuel et preuves : checksums, workflows, contrôles d’intégrité.
- Améliorations visées : audit indépendant, builds reproductibles, validation par les pairs,
  programme de recherche de vulnérabilités, transparence associative.

Détails : `docs/trust.md`.

## Menaces et contrôles
Le détail des menaces, hypothèses et contrôles est documenté dans `docs/threat-model.md`.
