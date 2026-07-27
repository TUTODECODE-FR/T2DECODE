# 🗺️ Roadmap & Vision de T2DECODE

T2DECODE est une plateforme d'apprentissage et d'expérimentation technique hors-ligne (air-gapped) conçue pour la cybersécurité et l'ingénierie réseau.

---

## 🟢 Ce que l'application contient DÉJÀ (Disponible)

### 🛠️ Simulateurs Interactifs (9 Simulateurs)
- **NetKit** : Simulation dynamique de topologies réseau (adressage IPv4/v6, routage, sous-réseaux, analyse de paquets).
- **CryptoLab** : Expérimentation cryptographique (chiffrement symétrique AES/DES, asymétrique RSA, hachage SHA/MD5).
- **LinuxLab** : Environnement d'entraînement aux commandes POSIX et à l'administration système Linux.
- **SecurityLab** : Modélisation des pare-feux, règles d'accès, failles web (XSS, SQLi) et principes de défense.
- **CloudLab** : Modélisation des permissions IAM et du stockage local simulé.
- **InternetLab** : Simulation du fonctionnement du Web (DNS, HTTP/S, sockets).
- **CryptoSimulator** : Visualisation interactive des blocs de chiffrement et clés.
- **AlgoLab** : Simulation visuelle d'algorithmes et de structures de données.
- **CTF Prep** : Entraînement interactif aux épreuves Capture The Flag.

### 🤖 Assistant IA Local & Souverain
- **Ghost AI** : Tuteur LLM local connecté au moteur Ollama (`http://localhost:11434`) exploitant un pipeline RAG basé sur les cours intégrés, sans aucun appel cloud.

### 🧰 Boîte à Outils Métier (15+ utilitaires)
- Calculateur CIDR IPv4/v6, convertisseur Chmod, générateur de tâches CRON, analyseur de hash, décodeur Base64/Hex, scanner de ports local, etc.

### 📡 Réseau & Souveraineté
- **Ghost Link (LAN)** : Chat et découverte de pairs décentralisés sur réseau local via diffusion UDP.
- **Sécurité Applicative** : Contrôle d'intégrité Air-Gapped au démarrage (`AssetIntegrityService` SHA-256) et mécanismes anti-altération natifs.

### 📦 Multi-plateformes & Distribution
- **macOS** (App Store / Homebrew Cask / DMG)
- **Linux** (Snap Store / AppImage / DEB)
- **Android** (APK signés / F-Droid)
- **Windows** (Installateur EXE / ZIP)

---

## 🔮 Prochainement (En cours de développement)

### ⚡ Phase 1 : Protocole T2C-Phantom (Prochainement)
- **T2C-Phantom** : Moteur et réseau proxy P2P décentralisé développé en **Go** / **libp2p** pour la synchronisation et la distribution autonome des cours et mises à jour sans serveur central.
- **Ghost Link P2P Avancé** : Messagerie chiffrée de bout en bout et échange de ressources entre pairs s'appuyant sur T2C-Phantom.

### 🧪 Phase 2 : Nouveaux Simulateurs & Mode CTF LAN
- **Simulateur Forensique** : Outil d'analyse de fichiers de captures réseau (`.pcap`) 100 % hors-ligne.
- **Mode CTF Multijoueur LAN** : Possibilité d'héberger une compétition CTF locale entre utilisateurs connectés en réseau local.
- **API & Plugins de Modules** : Permettre à la communauté de créer et d'importer dynamiquement des modules et mini-outils.

---

## 🎯 Profils Recherchés (Rejoignez l'association !)

Pour accélérer le développement de la plateforme et accomplir cette feuille de route, l'Association TUTODECODE recherche des expertises :

1. **🧑‍🏫 Pédagogues & Rédacteurs Markdown** : Concevoir de nouveaux cours et modules d'apprentissage.
2. **🛡️ Experts Cybersécurité & Pentesters** : Concevoir des scénarios CTF et des Cheat Sheets réflexes.
3. **💻 Développeurs Dart / Flutter** : Participer à la création du Simulateur Forensique.
4. **🐧 Ingénieurs Systèmes & Réseaux (Go / C++)** : Contribuer au développement du protocole **T2C-Phantom**.
