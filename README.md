<meta name="fediverse:creator" content="@TUTODECODE@mastodon.social">

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
    <a href="https://about.gitlab.com/solutions/open-source/"><img src="https://img.shields.io/badge/GitLab_Open_Source-Partner-554488?style=for-the-badge&logo=gitlab&logoColor=white&labelColor=1A1D2E&color=FC6D26" alt="GitLab Partner"></a>
    <a href="https://gitlab.com/tutodecode-org/T2DECODE/-/pipelines"><img src="https://gitlab.com/tutodecode-org/T2DECODE/badges/main/pipeline.svg" alt="Pipeline Status"></a>
    <a href="https://gitlab.com/tutodecode-org/T2DECODE/-/releases"><img src="https://gitlab.com/tutodecode-org/T2DECODE/-/badges/release.svg" alt="Latest Release"></a>
    <a href="https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12"><img src="https://img.shields.io/badge/Mac_App_Store-Available-000000?style=for-the-badge&logo=apple&logoColor=white&labelColor=1A1D2E&color=0078D6" alt="Mac App Store"></a>
    <a href="https://gitlab.com/tutodecode-org/homebrew-tap"><img src="https://img.shields.io/badge/Homebrew-Cask-F05032?style=for-the-badge&logo=homebrew&logoColor=white&labelColor=1A1D2E" alt="Homebrew"></a>
    <a href="https://f-droid.org/packages/org.t2decode.app/"><img src="https://img.shields.io/badge/F--Droid-v1.0.2-1976D2?style=for-the-badge&logo=f-droid&logoColor=white&labelColor=1A1D2E" alt="F-Droid"></a>
    <a href="https://gitlab.com/tutodecode-org/T2DECODE/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-FCC624?style=for-the-badge&labelColor=1A1D2E&color=FCC624" alt="License"></a>
  </p>

  <p>
    <a href="https://www.bestpractices.dev/projects/12999"><img src="https://www.bestpractices.dev/projects/12999/badge" alt="OpenSSF Best Practices"></a>
    <a href="https://scorecard.dev/viewer/?uri=gitlab.com/tutodecode-org/T2DECODE"><img src="https://api.scorecard.dev/projects/gitlab.com/tutodecode-org/T2DECODE/badge" alt="OpenSSF Scorecard"></a>
  </p>

  <p>
    <a href="https://gitlab.com/tutodecode-org/T2DECODE/-/releases">Releases</a> · 
    <a href="docs/build.md">Compilation</a> · 
    <a href="docs/architecture.md">Architecture</a> · 
    <a href="RGPD.md">Confidentialité</a> · 
    <a href="CONTRIBUTING.md">Contribuer</a>
  </p>
</div>

<img src="assets/separator.svg" width="100%" height="4">

## Présentation

**T2DECODE** est un environnement d'apprentissage et d'expérimentation technique conçu pour fonctionner en mode strictement hors-ligne (air-gapped). La plateforme rassemble des modules interactifs, des simulateurs d'infrastructures et un assistant IA local, sans aucune dépendance envers des services cloud tiers.

- **Conception Air-Gapped** : Aucun appel réseau externe, zéro télémétrie, respect strict du RGPD.
- **Intelligence Artificielle Locale (Ghost AI)** : Intégration du moteur LLM Ollama avec support RAG sur la base de connaissances.
- **Simulateurs Techniques Integrés** : Modélisation dynamique de réseaux (NetKit), cryptographie et environnements système Linux.
- **Sécurité et Contrôle d'Intégrité** : Audit des assets au démarrage (SHA-256) et mécanismes anti-altération natifs.

<img src="assets/separator.svg" width="100%" height="4">

## Interface

<p align="center">
  <img width="48%" src="docs/images/screenshots/app-home-full.png" style="border-radius: 8px;" alt="Accueil T2DECODE">
  <img width="48%" src="docs/images/screenshots/section-tools.png" style="border-radius: 8px;" alt="Outils Métier">
</p>
<p align="center">
  <img width="48%" src="docs/images/screenshots/section-chat-ia.png" style="border-radius: 8px;" alt="Ghost AI Local">
  <img width="48%" src="docs/images/screenshots/section-cheat-sheets.png" style="border-radius: 8px;" alt="Cheat Sheets">
</p>

<img src="assets/separator.svg" width="100%" height="4">

## Modules et Fonctionnalités

| Composant | Rôle Technique |
| :--- | :--- |
| **Ghost AI** | Assistant LLM local (Ollama) exploitant un pipeline RAG basé sur les cours intégrés. |
| **NetKit** | Simulation de topologies réseau (adressage, routage, analyse de paquets). |
| **CryptoLab** | Expérimentation d'algorithmes cryptographiques (chiffrement symétrique, asymétrique, hachage). |
| **LinuxLab** | Environnement d'entraînement aux commandes et à l'administration système POSIX. |
| **Outils Métier** | Calculateur CIDR IPv4/v6, convertisseur Chmod, générateur CRON, vérificateur de hash. |
| **T2C-Phantom** | Protocole de synchronisation décentralisé P2P pour les mises à jour hors-ligne (WIP). |

<img src="assets/separator.svg" width="100%" height="4">

## Téléchargements & Distribution

Les binaires compilés et authentifiés sont distribués via les canaux officiels ci-dessous :

| Plateforme | Canal de Distribution | Format |
| :--- | :--- | :--- |
| **macOS** | [App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12) / **Homebrew Cask** / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | PKG / DMG / Cask |
| **Android** | [F-Droid](https://f-droid.org/packages/org.t2decode.app/) / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | APK (per-ABI) / AAB |
| **Linux** | [Releases GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | AppImage / DEB / Snap |
| **Windows** | [Releases GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | Installateur EXE / ZIP |

### Installation via Homebrew (macOS)

```bash
# Ajout du tap et installation du Cask
brew tap tutodecode-org/homebrew-tap
brew install --cask t2decode
```

Mise à jour de l'application :
```bash
brew upgrade --cask t2decode
```

<img src="assets/separator.svg" width="100%" height="4">

## Architecture & Sécurité

### 1. Sécurité Applicative (Runtime)
- **Vérification d'Intégrité** : Le service `AssetIntegrityService` valide la somme de contrôle SHA-256 de chaque ressource embarquée à partir du manifeste `assets/asset_checksums.json`.
- **Isolation Réseau** : L'assistant Ghost AI communique exclusivement via `http://localhost:11434` sans transmission sortante.

### 2. Audit Continu (CI/CD)
- **SAST & Analyse Statique** : Scan continu du code source via SonarQube et CodeQL.
- **Analyse des Dépendances** : Audit des vulnérabilités connues par Google OSV-Scanner (`osv-scanner.yml`).
- **Analyse de l'APK** : Contrôle de l'exécutable Android par MobSF.

<img src="assets/separator.svg" width="100%" height="4">

## Compilation depuis les Sources

### Prérequis Système
- **Linux (Debian/Ubuntu)** : `clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev`
- **macOS** : Command Line Tools (`xcode-select --install`)
- **Windows** : Git et Visual Studio 2022 (*Développement Desktop C++* et composant *ATL*)

### Inscription et Build

```bash
git clone https://gitlab.com/tutodecode-org/T2DECODE.git
cd T2DECODE

# Vérification et installation des dépendances
make setup
make get

# Exécution des tests unitaires
make test

# Lancement en mode développement
flutter run
```

Commandes principales du `Makefile` :
```bash
make build-android  # Génération de l'APK Release
make build-macos    # Génération du binaire macOS .app
make build-dmg      # Création du paquet .dmg
make build-linux    # Compilation de l'exécutable Linux
```

<img src="assets/separator.svg" width="100%" height="4">

## Mentions Légales & Licence

Le projet T2DECODE est édité par l'**Association TUTODECODE** (Loi 1901, SIREN 102 763 133).

- **Site officiel** : [tutodecode.org](https://tutodecode.org)
- **Parution JOAFE** : [Annonce légale n°202600110336](https://www.journal-officiel.gouv.fr/pages/associations-detail-annonce/?q.id=id:202600110336)
- **Licence** : [GNU General Public License v3.0 (GPLv3)](LICENSE)
