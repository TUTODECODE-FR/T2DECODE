# Notes de vérification (Apple App Review) — T2DECODE

Ces notes sont destinées à accompagner une soumission App Store et à clarifier l’intention, le périmètre et les usages réseau de l’application.

## Intention / usage

T2DECODE est une application **éducative** (apprentissage technique) et **défensive** (diagnostic, hygiène, durcissement), conçue pour fonctionner **en local** (offline-first).

## Compte / données

- Aucun compte requis.
- Aucune collecte de données, aucun tracking, aucune télémétrie.
- Les données (préférences, progression) restent stockées localement.

## Réseau (déclenché par l’utilisateur)

Le réseau n’est pas requis pour utiliser les contenus et une partie des outils. Quand il est utilisé, il l’est **à l’initiative de l’utilisateur** :

- IA locale (optionnelle) : connexion à une instance Ollama **locale** (sur la machine ou sur le LAN) selon l’URL configurée par l’utilisateur.
- GhostLink (optionnel) : messagerie **LAN** (découverte + communication locale).
- NetKit : outils de diagnostic (ex. résolution DNS via le système, test de connectivité TCP vers un hôte/port saisi).

## Sécurité

Le projet documente sa posture de sécurité et ses protections d’intégrité : `docs/security-model.md` et `docs/trust.md`.

