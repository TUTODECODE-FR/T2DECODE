<meta name="fediverse:creator" content="@TUTODECODE@mastodon.social">

> [!NOTE]
> 💙 **Welcome to the T2DECODE GitHub mirror!**  
> This repository is the official mirror for distribution and automated releases. To contribute code, report issues, or connect with the community, visit our main [GitLab repository](https://gitlab.com/tutodecode-org/T2DECODE). Feel free to drop a star ⭐ to support the project!


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
    <a href="#-downloads--installation-users">Downloads</a> · 
    <a href="#-overview--modules">Overview</a> · 
    <a href="#-source-code--compilation-developers">Code & Build</a> · 
    <a href="docs/architecture.md">Architecture</a> · 
    <a href="RGPD.md">Privacy</a>
  </p>
</div>

<img src="assets/separator.svg" width="100%" height="4">

## 📦 Downloads & Installation (Users)

Pre-compiled and signed binaries are distributed through official channels:

| Platform | Channel | Format | Quick Command |
| :--- | :--- | :--- | :--- |
| **Linux** | [Snap Store](https://snapcraft.io/t2decode) / [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | Snap / AppImage / DEB | `sudo snap install t2decode` |
| **macOS** | [App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12) / **Homebrew** / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | PKG / DMG / Cask | `brew install --cask t2decode` |
| **Android** | [F-Droid](https://f-droid.org/packages/org.t2decode.app/) / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | APK / AAB | *Via F-Droid Client* |
| **Windows** | [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | EXE Installer / ZIP | *Direct Download* |

---

### 🐧 Linux Installation (Snapcraft)

[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/t2decode)

```bash
# Install from official Snap Store
sudo snap install t2decode

# Update application
sudo snap refresh t2decode
```

---

### 🍏 macOS Installation (Homebrew)

```bash
# Add official tap and install Cask
brew tap tutodecode-org/homebrew-tap
brew install --cask t2decode

# Update application
brew upgrade --cask t2decode
```

<img src="assets/separator.svg" width="100%" height="4">

## 🛠️ Overview & Modules

**T2DECODE** is an offline-first learning and technical experimentation platform designed for air-gapped environments. The platform features interactive simulators, infrastructure modeling, and a local AI assistant without external cloud dependencies.

- **Local-First Architecture**: Runs autonomously without cloud servers. Zero telemetry, zero tracking. Optional network utility features (NetKit diagnostics, course sync) respect user privacy and can be fully disabled.
- **Local AI Engine (Ghost AI)**: Integrated Ollama LLM client with local RAG capabilities over course materials.
- **Technical Simulators**: Dynamic modeling for networks (NetKit), cryptography, and Linux POSIX environments.
- **Security & Integrity Controls**: Built-in runtime asset verification (SHA-256) and anti-tampering enforcement.

### Interface

<p align="center">
  <img width="48%" src="docs/images/screenshots/app-home-full.png" style="border-radius: 8px;" alt="T2DECODE Home">
  <img width="48%" src="docs/images/screenshots/section-tools.png" style="border-radius: 8px;" alt="Tools Section">
</p>
<p align="center">
  <img width="48%" src="docs/images/screenshots/section-chat-ia.png" style="border-radius: 8px;" alt="Local Ghost AI">
  <img width="48%" src="docs/images/screenshots/section-cheat-sheets.png" style="border-radius: 8px;" alt="Cheat Sheets">
</p>

### Modules & Technical Capabilities

| Component | Technical Role |
| :--- | :--- |
| **Ghost AI** | Local LLM assistant (Ollama) with RAG pipeline over built-in courses. |
| **NetKit** | Network topology simulation (addressing, routing, packet analysis). |
| **CryptoLab** | Cryptographic algorithm lab (symmetric/asymmetric encryption, hashing). |
| **LinuxLab** | Command-line training environment for POSIX system administration. |
| **Utilitarian Tools** | IPv4/v6 CIDR calculator, Chmod converter, CRON generator, Hash verifier. |
| **T2C-Phantom** | Decentralized P2P course update protocol (Coming Soon). |

<img src="assets/separator.svg" width="100%" height="4">

## 💻 Source Code & Compilation (Developers)

### Architecture & Security

1. **Runtime Security**
   - **Asset Integrity Verification**: `AssetIntegrityService` checks SHA-256 hashes of bundled resources against `assets/asset_checksums.json` at startup.
   - **Network Isolation**: Ghost AI operates strictly on `http://localhost:11434` with zero outbound connectivity.

2. **Continuous CI/CD Auditing**
   - **SAST Analysis**: Code analysis powered by SonarQube and CodeQL.
   - **Dependency Auditing**: Vulnerability scans performed by Google OSV-Scanner (`osv-scanner.yml`).
   - **Mobile Analysis**: Android APK dynamic scanning via MobSF.

---

### Building from Source

#### System Prerequisites
- **Linux (Debian/Ubuntu)**: `clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev`
- **macOS**: Command Line Tools (`xcode-select --install`)
- **Windows**: Git and Visual Studio 2022 (*Desktop development with C++* and *ATL* component)

#### Quick Start

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

#### Makefile Targets

```bash
make build-android  # Build release APK (per-ABI)
make build-linux    # Build Linux native binary
make build-macos    # Build macOS .app bundle
make build-dmg      # Generate .dmg installer
```

<img src="assets/separator.svg" width="100%" height="4">

## ⚖️ Legal & Licensing

T2DECODE is published by **Association TUTODECODE** (French Non-Profit Association, SIREN 102 763 133).

- **Official Website**: [tutodecode.org](https://tutodecode.org)
- **License**: [GNU General Public License v3.0 (GPLv3)](LICENSE)
