# Politique de Sécurité

## Périmètre

Cette politique couvre :

- Le code source hébergé dans ce dépôt.
- Les artefacts officiels des versions publiées sur GitHub Releases.
- Le comportement d'exécution local (conception offline-first, aucune télémétrie cloud par conception).

Voir aussi :

- `docs/security-model.md`
- `docs/threat-model.md`
- `docs/privacy.md`

## Versions Supportées

Seule la dernière version stable est considérée comme supportée pour les correctifs de sécurité.

| Version | Supportée |
| :-- | :--: |
| Dernière version stable | ✅ |
| Anciennes versions | ❌ |

**Portée du support :** Chaque version stable reçoit des correctifs de sécurité jusqu'à la publication de la version stable suivante. Les versions majeures (ex: v1.x) sont supportées pendant au moins 6 mois après la sortie de la version majeure suivante.

## Fin de Support (End of Life)

Une version atteint sa fin de support dans les cas suivants :

- Une nouvelle version stable est publiée : l'ancienne version cesse de recevoir des correctifs de sécurité immédiatement.
- La version a plus de 12 mois d'ancienneté sans mise à jour majeure.

Les utilisateurs sont **fortement encouragés** à mettre à jour vers la dernière version stable dès sa disponibilité. Les annonces de fin de support sont publiées dans les [notes de version](https://github.com/TUTODECODE-FR/T2DECODE/releases) et dans le fichier `CHANGELOG.md`.

## Nomenclature Logicielle (SBOM)

La liste complète des dépendances logicielles (Software Bill of Materials) est disponible sous forme machine-readable dans :

- [`pubspec.yaml`](https://github.com/TUTODECODE-FR/T2DECODE/blob/main/pubspec.yaml) — dépendances déclarées avec contraintes de version
- [`pubspec.lock`](https://github.com/TUTODECODE-FR/T2DECODE/blob/main/pubspec.lock) — versions exactes résolues et hashes d'intégrité
- [Graphe de dépendances GitHub](https://github.com/TUTODECODE-FR/T2DECODE/network/dependencies) — vue interactive de toutes les dépendances transitives

## Contrôles de Sécurité (Actuels)

- Les sommes de contrôle SHA-256 (`SHA256SUMS.txt`) sont publiées pour les assets de la release.
- Les signatures détachées Linux (`.sig`) sont générées lorsque les secrets GPG de release sont configurés.
- Les contrôles d'intégrité des assets sont exécutés au démarrage de l'application.
- Les pipelines d'intégration continue (CI) et de release sont versionnés dans `.github/workflows/`.
- La politique de propriété est déclarée dans `.github/CODEOWNERS`.

## Divulgation Responsable

N'ouvrez pas d'issues GitHub publiques pour signaler des vulnérabilités.

Utilisez l'un de ces canaux privés :

- Avis de sécurité privé GitHub.
- Email : `contact@tutodecode.org`.

Lors de votre signalement, veuillez inclure :

- La version/le tag affecté(e).
- Les étapes pour reproduire.
- Un résumé de l'impact.
- Une suggestion de remédiation (si disponible).

## Objectifs de Réponse

- Délai d'accusé de réception : dans les 72 heures.
- Délai de tri : dans les 7 jours ouvrables.
- Délai de correction : dépend de la sévérité et de l'impact sur la plateforme.

Après un correctif :

- Une version corrigée est publiée.
- Le journal des modifications (changelog) / les notes de version mentionnent la portée de la correction.

## Confiance et Vérification

Avant d'installer des binaires, vérifiez les sommes de contrôle :

```bash
sha256sum -c SHA256SUMS.txt
```

Si des fichiers `.sig` sont présents, vérifiez les signatures avec la clé publique distribuée par les mainteneurs.

## Feuille de Route de Confiance

Pour une vue structurée sur la manière dont le projet peut renforcer sa vérifiabilité au fil du temps (audit indépendant, builds reproductibles, validation communautaire, programme de recherche de vulnérabilités, transparence associative), consultez `docs/trust.md`.

## Limitations Connues

- Le projet est encore à un stade précoce et est maintenu par une petite équipe.
- Certains chemins de signature/notarisation dépendent de la disponibilité des secrets dans la CI.
