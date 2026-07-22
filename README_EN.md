<meta name="fediverse:creator" content="@TUTODECODE@mastodon.social">

<div align="center">
  <p>
    <a href="README.md">🇫🇷 Français</a> | <strong>🇬🇧 English</strong>
  </p>
  <a href="https://gitlab.com/tutodecode-org/T2DECODE">
    <img src="https://gitlab.com/tutodecode-org/T2DECODE/-/raw/main/assets/TDC.png" width="160" height="160" alt="T2C Logo">
  </a>

  <h1>T2DECODE</h1>
  <p><strong>Autonomous and sovereign educational platform for networking, cybersecurity, and system administration.</strong></p>

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
    <a href="docs/build.md">Build</a> · 
    <a href="docs/architecture.md">Architecture</a> · 
    <a href="RGPD.md">Privacy</a> · 
    <a href="CONTRIBUTING.md">Contributing</a>
  </p>
</div>

<img src="assets/separator.svg" width="100%" height="4">

## Overview

**T2DECODE** is an offline-first learning and technical experimentation platform designed for air-gapped environments. The platform features interactive simulators, infrastructure modeling, and a local AI assistant without external cloud dependencies.

- **Air-Gapped Architecture**: Zero telemetry, no external API calls, full privacy compliance.
- **Local AI Engine (Ghost AI)**: Integrated Ollama LLM client with local RAG capabilities over course materials.
- **Technical Simulators**: Dynamic modeling for networks (NetKit), cryptography, and Linux POSIX environments.
- **Security & Integrity Controls**: Built-in runtime asset verification (SHA-256) and anti-tampering enforcement.

<img src="assets/separator.svg" width="100%" height="4">

## Interface

<p align="center">
  <img width="48%" src="docs/images/screenshots/app-home-full.png" style="border-radius: 8px;" alt="T2DECODE Home">
  <img width="48%" src="docs/images/screenshots/section-tools.png" style="border-radius: 8px;" alt="Tools Section">
</p>
<p align="center">
  <img width="48%" src="docs/images/screenshots/section-chat-ia.png" style="border-radius: 8px;" alt="Local Ghost AI">
  <img width="48%" src="docs/images/screenshots/section-cheat-sheets.png" style="border-radius: 8px;" alt="Cheat Sheets">
</p>

<img src="assets/separator.svg" width="100%" height="4">

## Modules & Technical Capabilities

| Component | Technical Role |
| :--- | :--- |
| **Ghost AI** | Local LLM assistant (Ollama) with RAG pipeline over built-in courses. |
| **NetKit** | Network topology simulation (addressing, routing, packet analysis). |
| **CryptoLab** | Cryptographic algorithm lab (symmetric/asymmetric encryption, hashing). |
| **LinuxLab** | Command-line training environment for POSIX system administration. |
| **Utilitarian Tools** | IPv4/v6 CIDR calculator, Chmod converter, CRON generator, Hash verifier. |
| **T2C-Phantom** | Decentralized P2P course update protocol (WIP). |

<img src="assets/separator.svg" width="100%" height="4">

## Distribution & Downloads

Pre-compiled and signed binaries are distributed through official channels:

| Platform | Channel | Format |
| :--- | :--- | :--- |
| **macOS** | [App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12) / **Homebrew Cask** / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | PKG / DMG / Cask |
| **Android** | [F-Droid](https://f-droid.org/packages/org.t2decode.app/) / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | APK (per-ABI) / AAB |
| **Linux** | [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | AppImage / DEB / Snap |
| **Windows** | [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | EXE Installer / ZIP |

### Homebrew Installation (macOS)

```bash
# Add official tap and install Cask
brew tap tutodecode-org/homebrew-tap
brew install --cask t2decode
```

Updating the application:
```bash
brew upgrade --cask t2decode
```

<img src="assets/separator.svg" width="100%" height="4">

## Architecture & Security

### 1. Runtime Security
- **Asset Integrity Verification**: `AssetIntegrityService` checks SHA-256 hashes of bundled resources against `assets/asset_checksums.json` at startup.
- **Network Isolation**: Ghost AI operates strictly on `http://localhost:11434` with zero outbound connectivity.

### 2. Continuous CI/CD Auditing
- **SAST Analysis**: Code analysis powered by SonarQube and CodeQL.
- **Dependency Auditing**: Vulnerability scans performed by Google OSV-Scanner (`osv-scanner.yml`).
- **Mobile Analysis**: Android APK dynamic scanning via MobSF.

<img src="assets/separator.svg" width="100%" height="4">

## Building from Source

### System Prerequisites
- **Linux (Debian/Ubuntu)**: `clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev`
- **macOS**: Command Line Tools (`xcode-select --install`)
- **Windows**: Git and Visual Studio 2022 (*Desktop development with C++* and *ATL* component)

### Quick Start

```bash
git clone https://gitlab.com/tutodecode-org/T2DECODE.git
cd T2DECODE

# Setup and dependencies
make setup
make get

# Run test suite
make test

# Development launch
flutter run
```

Makefile build targets:
```bash
make build-android  # Build release APK
make build-macos    # Build macOS .app bundle
make build-dmg      # Generate .dmg installer
make build-linux    # Build Linux native binary
```

<img src="assets/separator.svg" width="100%" height="4">

## Legal & Licensing

T2DECODE is published by **Association TUTODECODE** (French Non-Profit Association, SIREN 102 763 133).

- **Official Website**: [tutodecode.org](https://tutodecode.org)
- **License**: [GNU General Public License v3.0 (GPLv3)](LICENSE)
