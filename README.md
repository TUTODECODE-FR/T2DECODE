<meta name="fediverse:creator" content="@TUTODECODE@mastodon.social">

> [!NOTE]
> 💙 **Bienvenue sur le miroir GitHub de T2DECODE !**  
> Ce dépôt est le miroir officiel de distribution et de téléchargement. Pour contribuer au code source, proposer des fonctionnalités ou échanger avec la communauté, découvrez notre [GitLab principal](https://gitlab.com/tutodecode-org/T2DECODE). N'hésitez pas à laisser une étoile ⭐ pour soutenir l'association !


<div align="center">
  <p>
    <strong>🇫🇷 Français</strong> | <a href="README_EN.md">🇬🇧 English</a>
  </p>
  <a href="https://gitlab.com/tutodecode-org/T2DECODE">
    <img src="https://gitlab.com/tutodecode-org/T2DECODE/-/raw/main/assets/TDC.png" width="160" height="160" alt="T2C Logo">
  </a>

  <h1>T2DECODE</h1>
  <p><strong>Plateforme pédagogique autonome et souveraine pour les réseaux, la cybersécurité et l'administration système.</strong></p>

  <p>
    <a href="#-téléchargement--installation-utilisateurs">Téléchargement</a> · 
    <a href="#-présentation--modules">Présentation</a> · 
    <a href="#-code-source--compilation-développeurs">Code & Compilation</a> · 
    <a href="docs/architecture.md">Architecture</a> · 
    <a href="RGPD.md">Confidentialité</a>
  </p>
</div>

<img src="assets/separator.svg" width="100%" height="4">

## 📦 Téléchargement & Installation (Utilisateurs)

Les binaires compilés et authentifiés sont distribués via les canaux officiels ci-dessous :

| Plateforme | Canal de Distribution | Format | Commande rapide |
| :--- | :--- | :--- | :--- |
| **Linux** | [Snap Store](https://snapcraft.io/t2decode) / [Releases GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | Snap / AppImage / DEB | `sudo snap install t2decode` |
| **macOS** | [App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12) / **Homebrew** / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | PKG / DMG / Cask | `brew install --cask t2decode` |
| **Android** | [F-Droid](https://f-droid.org/packages/org.t2decode.app/) / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | APK / AAB | *Via F-Droid Client* |
| **Windows** | [Releases GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | Installateur EXE / ZIP | *Téléchargement direct* |

---

### 🐧 Installation Linux (Snapcraft)

[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/t2decode)

```bash
# Installation depuis le Snap Store officiel
sudo snap install t2decode

# Mise à jour
sudo snap refresh t2decode
```

---

### 🍏 Installation macOS (Homebrew)

```bash
# Ajout du tap et installation du Cask
brew tap tutodecode-org/homebrew-tap
brew install --cask t2decode

# Mise à jour
brew upgrade --cask t2decode
```

<img src="assets/separator.svg" width="100%" height="4">

## 🛠️ Présentation & Modules

**T2DECODE** est un environnement d'apprentissage et d'expérimentation technique conçu pour fonctionner en mode strictement hors-ligne (air-gapped). La plateforme rassemble des modules interactifs, des simulateurs d'infrastructures et un assistant IA local, sans aucune dépendance envers des services cloud tiers.

- **Priorité au local (Local-first)** : Fonctionne de manière autonome sans serveur cloud. Zéro télémétrie, zéro tracking. Les fonctionnalités réseau facultatives (diagnostics NetKit, synchronisation de cours) respectent la vie privée et sont désactivables.
- **Intelligence Artificielle Locale (Ghost AI)** : Intégration du moteur LLM Ollama avec support RAG sur la base de connaissances.
- **Simulateurs Techniques Intégrés** : Modélisation dynamique de réseaux (NetKit), cryptographie et environnements système Linux.
- **Sécurité & Contrôle d'Intégrité** : Audit des assets au démarrage (SHA-256) et mécanismes anti-altération natifs.

### Interface

<p align="center">
  <img width="48%" src="docs/images/screenshots/app-home-full.png" style="border-radius: 8px;" alt="Accueil T2DECODE">
  <img width="48%" src="docs/images/screenshots/section-tools.png" style="border-radius: 8px;" alt="Outils Métier">
</p>
<p align="center">
  <img width="48%" src="docs/images/screenshots/section-chat-ia.png" style="border-radius: 8px;" alt="Ghost AI Local">
  <img width="48%" src="docs/images/screenshots/section-cheat-sheets.png" style="border-radius: 8px;" alt="Cheat Sheets">
</p>

### Modules & Rôle Technique

| Composant | Rôle Technique |
| :--- | :--- |
| **Ghost AI** | Assistant LLM local (Ollama) exploitant un pipeline RAG basé sur les cours intégrés. |
| **NetKit** | Simulation de topologies réseau (adressage, routage, analyse de paquets). |
| **CryptoLab** | Expérimentation d'algorithmes cryptographiques (chiffrement symétrique, asymétrique, hachage). |
| **LinuxLab** | Environnement d'entraînement aux commandes et à l'administration système POSIX. |
| **Outils Métier** | Calculateur CIDR IPv4/v6, convertisseur Chmod, générateur CRON, vérificateur de hash. |
| **T2C-Phantom** | Protocole de synchronisation décentralisé P2P pour les mises à jour hors-ligne (Prochainement). |

<img src="assets/separator.svg" width="100%" height="4">

## 💻 Code Source & Compilation (Développeurs)

### Architecture & Sécurité

1. **Sécurité Applicative (Runtime)**
   - **Vérification d'Intégrité** : Le service `AssetIntegrityService` valide la somme de contrôle SHA-256 de chaque ressource embarquée à partir du manifeste `assets/asset_checksums.json`.
   - **Isolation Réseau** : L'assistant Ghost AI communique exclusivement via `http://localhost:11434` sans transmission sortante.

2. **Audit Continu (CI/CD)**
   - **SAST & Analyse Statique** : Scan continu du code source via SonarQube et CodeQL.
   - **Analyse des Dépendances** : Audit des vulnérabilités connues par Google OSV-Scanner (`osv-scanner.yml`).
   - **Analyse de l'APK** : Contrôle de l'exécutable Android par MobSF.

---

### Compilation depuis les Sources

#### Prérequis Système
- **Linux (Debian/Ubuntu)** : `clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev`
- **macOS** : Command Line Tools (`xcode-select --install`)
- **Windows** : Git et Visual Studio 2022 (*Développement Desktop C++* et composant *ATL*)

#### Initialisation et Lancement

```bash
git clone https://gitlab.com/tutodecode-org/T2DECODE.git
cd T2DECODE

# Vérification de l'environnement et des dépendances
make setup
make get

# Exécution des tests unitaires
make test

# Lancement en mode développement
flutter run
```

#### Commandes du Makefile

```bash
make build-android  # Génération des APK Release (per-ABI)
make build-linux    # Compilation du binaire Linux
make build-macos    # Compilation du binaire macOS .app
make build-dmg      # Création de l'installateur DMG (macOS)
```

<img src="assets/separator.svg" width="100%" height="4">

## ⚖️ Mentions Légales & Licence

Le projet T2DECODE est édité par l'**Association TUTODECODE** (Loi 1901, SIREN 102 763 133).

- **Site officiel** : [tutodecode.org](https://tutodecode.org)
- **Parution JOAFE** : [Annonce légale n°202600110336](https://www.journal-officiel.gouv.fr/pages/associations-detail-annonce/?q.id=id:202600110336)
- **Licence** : [GNU General Public License v3.0 (GPLv3)](LICENSE)
