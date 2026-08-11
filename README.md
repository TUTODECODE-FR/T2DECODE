<meta name="fediverse:creator" content="@TUTODECODE@mastodon.social">

<div align="center">
  <p>
    <strong>🇫🇷 Français</strong> | <a href="README_EN.md">🇬🇧 English</a>
  </p>
  <a href="https://tutodecode.org">
    <img src="https://gitlab.com/tutodecode-org/T2DECODE/-/raw/main/assets/TDC.png" width="160" height="160" alt="Logo T2DECODE">
  </a>

  <h1>T2DECODE</h1>
  <p><strong>Plateforme pédagogique souveraine & laboratoire d'ingénierie réseaux & cybersécurité.</strong><br>
  <em>100% Hors-Ligne · Zéro Cloud · Zéro Tracking · Licence Libre GPLv3</em></p>

  <p>
    <a href="https://gitlab.com/tutodecode-org/T2DECODE/-/blob/main/LICENSE"><img src="https://img.shields.io/badge/Licence-GPLv3-blue.svg" alt="Licence GPLv3"></a>
    <a href="https://tutodecode.org"><img src="https://img.shields.io/badge/Hors--Ligne-100%25-success.svg" alt="100% Hors Ligne"></a>
    <a href="https://snapcraft.io/t2decode"><img src="https://img.shields.io/badge/Plateformes-Linux%20%7C%20macOS%20%7C%20Android%20%7C%20Windows-F5EBDA.svg" alt="Multiplateforme"></a>
    <a href="https://tutodecode.org"><img src="https://img.shields.io/badge/Z%C3%A9ro--Cloud-Souverain-black.svg" alt="Zéro Cloud"></a>
  </p>

  <p>
    <a href="#-1-présentation--fonctionnalités">Présentation</a> · 
    <a href="#-2-téléchargement--installation-prêt-à-lemploi">Télécharger</a> · 
    <a href="#-3-vérification-dintégrité--sécurité-zero-trust">Vérifier l'Intégrité</a> · 
    <a href="#-4-compilation-depuis-les-sources-développeurs">Compiler soi-même</a> · 
    <a href="docs/architecture.md">Architecture</a>
  </p>
</div>

<img src="assets/separator.svg" width="100%" height="4">

## ✨ 1. Présentation & Fonctionnalités

**T2DECODE** est un laboratoire technique d'apprentissage et une boîte d'outils d'intervention conçue pour fonctionner en **mode strictement autonome et hors-ligne (Air-gapped)**. Aucune donnée ne quitte votre ordinateur : ni télémétrie, ni compte obligatoire, ni dépendance à un serveur distants.

### 🧰 Les 6 Modules Clés Intégrés

| Module | Description & Usage Technique |
| :--- | :--- |
| **🧠 Ghost AI (Tuteur LLM)** | Assistant IA local (Ollama) exploitant un pipeline RAG directement connecté aux cours intégrés. |
| **🌐 NetKit (Réseaux)** | Modélisation et simulation dynamique de topologies réseau (adressage IPv4/v6, routage, analyse). |
| **💻 Linux VM Sandbox** | Terminal virtuel POSIX sécurisé pour s'entraîner aux commandes et au bash sans risquer de casser son système. |
| **🔐 CryptoLab** | Experimentation interactive des algorithmes cryptographiques (chiffrement RSA/AES, hachage SHA). |
| **🛠️ Outils Métier** | Calculateur CIDR, convertisseur Chmod, générateur CRON, vérificateur d'empreintes et de hashs. |
| **📚 Cours Masterclass** | Guides d'ingénierie rédigés avec cas d'incidents réels, réflexes de production et QCM de validation. |

---

### 📷 Aperçu de l'Interface

<p align="center">
  <img width="48%" src="docs/images/screenshots/app-home-full.png" style="border-radius: 8px;" alt="Accueil T2DECODE">
  <img width="48%" src="docs/images/screenshots/section-tools.png" style="border-radius: 8px;" alt="Outils Métier">
</p>
<p align="center">
  <img width="48%" src="docs/images/screenshots/section-chat-ia.png" style="border-radius: 8px;" alt="Ghost AI Local">
  <img width="48%" src="docs/images/screenshots/section-cheat-sheets.png" style="border-radius: 8px;" alt="Cheat Sheets">
</p>

<img src="assets/separator.svg" width="100%" height="4">

## 📦 2. Téléchargement & Installation (Prêt à l'Emploi)

Les exécutables pré-compilés et authentifiés sont distribués gratuitement sur les canaux officiels :

| Plateforme | Canal de Distribution | Format | Commande / Méthode |
| :--- | :--- | :--- | :--- |
| **Linux** | [Snap Store](https://snapcraft.io/t2decode) / [Releases GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | Snap / AppImage / DEB | `sudo snap install t2decode` |
| **macOS** | [App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12) / **Homebrew** / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | PKG / DMG / Cask | `brew install --cask t2decode` |
| **Android** | [F-Droid](https://f-droid.org/packages/org.t2decode.app/) / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | APK / AAB | *Via F-Droid Client* |
| **Windows** | [Releases GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) / [SourceForge](https://sourceforge.net/projects/t2decode/) | EXE / ZIP | *Téléchargement direct* |

> 🌐 **Miroir d'audit & distribution tiers** : Vous pouvez également télécharger l'ensemble des binaires et fichiers de checksums sur notre [Miroir officiel SourceForge](https://sourceforge.net/projects/t2decode/).

---

### 🐧 Installation Linux (Snap Store)
[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/t2decode)
```bash
sudo snap install t2decode
```

### 🍏 Installation macOS (Homebrew)
```bash
brew tap tutodecode-org/homebrew-tap
brew install --cask t2decode
```

<img src="assets/separator.svg" width="100%" height="4">

## 🛡️ 3. Vérification d'Intégrité & Sécurité (Zero Trust)

*On n'est jamais trop prudent : contrôlez toujours l'empreinte numérique SHA-256 de vos exécutables avant de les lancer.*

Comparez le résultat avec les sommes officielles publiées sur [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) ou sur [SourceForge](https://sourceforge.net/projects/t2decode/).

#### 🐧 Linux & 🍏 macOS (Terminal)
```bash
# Vérifier sous Linux
sha256sum T2DECODE-Linux.tar.gz

# Vérifier sous macOS
shasum -a 256 T2DECODE-macOS.dmg
```

#### 🪟 Windows (PowerShell)
```powershell
Get-FileHash .\T2DECODE-Windows.zip -Algorithm SHA256
```

<img src="assets/separator.svg" width="100%" height="4">

## 💻 4. Compilation depuis les Sources (Développeurs)

Si vous préférez **construire vous-même l'application à partir du code source**, suivez les instructions ci-dessous :

### 📋 Prérequis Système
- **Flutter SDK** : Version `stable` (3.x+)
- **Linux (Debian/Ubuntu)** : `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev`
- **macOS** : Xcode Command Line Tools (`xcode-select --install`)
- **Windows** : Visual Studio 2022 (*Desktop C++* et composant *ATL*)

### 🛠️ Instructions de Build

```bash
# 1. Cloner le dépôt
git clone https://gitlab.com/tutodecode-org/T2DECODE.git
cd T2DECODE

# 2. Vérifier l'environnement et récupérer les dépendances
make setup
make get

# 3. Exécuter la suite de tests (100% de réussite exigé)
make test

# 4. Lancer l'application en mode développement
flutter run
```

### 📦 Génération des Binaires Release via `Makefile`

```bash
make build-android  # Génère les APKs Release (per-ABI)
make build-linux    # Compile le binaire Linux natif
make build-macos    # Compile l'exécutable macOS .app
make build-dmg      # Génère le paquet d'installation DMG (macOS)
```

<img src="assets/separator.svg" width="100%" height="4">

## ⚖️ 5. Éditeur, Licence & Mentions Légales

Le logiciel **T2DECODE** est développé et édité par l'**Association TUTODECODE** (Association Loi 1901 à but non lucratif, SIREN 102 763 133, RNA W134011400).

- **Fondateur & Président** : Maxime MARTIN CIVET
- **Site Officiel** : [tutodecode.org](https://tutodecode.org)
- **Licence** : [GNU General Public License v3.0 (GPLv3)](LICENSE) — Logiciel Libre et Souverain.
