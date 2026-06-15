# T2DECODE — Résumé de l'application

T2DECODE est une suite pédagogique destinée aux étudiants, formateurs et
professionnels IT. Conçue pour fonctionner entièrement hors‑ligne, elle combine
cours interactifs, simulateurs techniques, outils métiers et un assistant IA
local (Ollama), tout en plaçant la confidentialité et l'intégrité des données au
centre de son architecture.

## Mission et philosophie

- Souveraineté numérique : aucune dépendance au cloud ; tout fonctionne en local.
- Confidentialité : pas de tracking, pas de comptes obligatoires, pas d'exfiltration.
- Accessibilité : utilisable en environnement déconnecté (zones blanches, datacenters).
- Open source : projet porté par l'Association TUTODECODE (licence GPLv3).

## Fonctionnalités principales

### 1) Ghost AI — Intelligence artificielle locale
- Intégration native avec Ollama pour exécuter des LLM en local.
- Assistant technique privé pour aide au code, diagnostics et tutoriels.

### 2) Académie — Cours et formations
Modules couvrant : systèmes (Linux, Bash), conteneurs (Docker, Kubernetes),
développement (Python, JavaScript, TypeScript), réseaux (OSI, TCP/IP, DNS),
sécurité pédagogique, et outils (Git, GitHub).

### 3) NetKit — Outils de diagnostic
- Vérification de ports, résolutions DNS, inventaire système (hostname, adresses IP),
  calculateur d'adressage et de sous‑réseaux.

### 4) Laboratoire de simulation
- Simulations interactives (Ping, handshake TCP, DNS) et environnements d'entraînement
  contrôlés pour l'apprentissage des vulnérabilités web (pédagogique).

### 5) Bibliothèque technique
- Cheat sheets, scripts réutilisables (Bash, PowerShell), et guides matériels.

## Spécifications techniques

- Framework : Flutter (multi‑plateforme : macOS, Windows, Linux, Android).
- Stockage : local uniquement (SharedPreferences / fichiers locaux).
- Modules externes : import possible via dossier local, avec contrôles d'intégrité.
- Sécurité : trafic cleartext désactivé, contrôle SHA‑256 des assets au démarrage.

---

© 2026 Association TUTODECODE — Le savoir ne devrait jamais dépendre d'une connexion.

