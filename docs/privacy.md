# Confidentialité

T2DECODE est conçu pour fonctionner **sans cloud**, avec une approche **offline-first** et **zéro tracking**.
L’application ne transfère pas vos données personnelles vers un serveur tiers.

## Garanties
- **Aucune télémétrie / analytics** : pas de tracking publicitaire, pas de profilage.
- **Aucune dépendance** Firebase / Sentry / Mixpanel.
- **Aucune API distante obligatoire** pour utiliser l’app.
- **Fonctionnement possible hors-ligne** (cours, outils, labs, préférences).
- **IA optionnelle** : l’IA locale via Ollama est un plus, jamais un prérequis.

## Données traitées et stockage

T2DECODE stocke principalement des données **fonctionnelles locales** :
- préférences (thème, options, configuration)
- progression et états de lecture
- configuration réseau locale (ex : URL Ollama si l’utilisateur l’active)

Ces données sont stockées localement sur l’appareil (ex : `SharedPreferences` selon la plateforme).

## Réseau : quand et pourquoi ?

T2DECODE peut effectuer des communications réseau **dans des cas limités** et **compréhensibles** :

1) **Ollama (IA locale)**  
- connexion à `localhost` ou à une adresse du réseau local (LAN) **configurée par l’utilisateur**
- but : générer des réponses IA **localement**, sans cloud

2) **Ghost Link (LAN)**  
- communication sur le réseau local (LAN) pour découverte/échange entre appareils

3) **Mises à jour de modules (optionnel)**  
- l’app peut vérifier/télécharger des modules depuis le dépôt officiel (HTTPS) si la fonctionnalité est activée et si le réseau n’est pas bloqué par les réglages

## Contrôle utilisateur

T2DECODE inclut des réglages pour limiter/désactiver le réseau (ex : “mode zéro réseau”).
Quand le réseau est désactivé, les fonctionnalités concernées doivent rester **non bloquantes**.

## Permissions système

Selon les fonctionnalités utilisées, l’application peut demander :
- réseau local (Ghost Link / connexion LAN)
- photothèque (si vous choisissez d’importer/exporter des images)

Les permissions sont utilisées uniquement pour la fonctionnalité demandée.

## Sécurité

L’application embarque des mécanismes locaux (sans cloud) de :
- vérification d’intégrité des assets
- protections anti‑altération et écrans de vérification

## Conservation / suppression

Les données restent sur votre appareil jusqu’à suppression manuelle :
- suppression via les réglages (si proposé)
- ou suppression de l’application (désinstallation)

## Contact

- Support : https://github.com/TUTODECODE-FR/T2DECODE/issues
- Politique App Store : `docs/appstore/privacy-policy-fr.md`
