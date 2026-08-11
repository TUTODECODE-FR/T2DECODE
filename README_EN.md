<meta name="fediverse:creator" content="@TUTODECODE@mastodon.social">

<div align="center">
  <p>
    <a href="README.md">🇫🇷 Français</a> | <strong>🇬🇧 English</strong>
  </p>
  <a href="https://tutodecode.org">
    <img src="https://gitlab.com/tutodecode-org/T2DECODE/-/raw/main/assets/TDC.png" width="160" height="160" alt="T2DECODE Logo">
  </a>

  <h1>T2DECODE</h1>
  <p><strong>Sovereign educational platform & cybersecurity & networking engineering workbench.</strong><br>
  <em>100% Offline · Zero Cloud · Zero Tracking · Open Source GPLv3 License</em></p>

  <p>
    <a href="https://gitlab.com/tutodecode-org/T2DECODE/-/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="GPLv3 License"></a>
    <a href="https://tutodecode.org"><img src="https://img.shields.io/badge/Offline-100%25-success.svg" alt="100% Offline"></a>
    <a href="https://snapcraft.io/t2decode"><img src="https://img.shields.io/badge/Platforms-Linux%20%7C%20macOS%20%7C%20Android%20%7C%20Windows-F5EBDA.svg" alt="Multiplatform"></a>
    <a href="https://tutodecode.org"><img src="https://img.shields.io/badge/Zero--Cloud-Sovereign-black.svg" alt="Zero Cloud"></a>
  </p>

  <p>
    <a href="#-1-overview--features">Overview</a> · 
    <a href="#-2-downloads--installation-ready-to-use">Download</a> · 
    <a href="#-3-binary-integrity--zero-trust-security">Verify Integrity</a> · 
    <a href="#-4-building-from-source-developers">Build From Source</a> · 
    <a href="docs/architecture.md">Architecture</a>
  </p>
</div>

<img src="assets/separator.svg" width="100%" height="4">

## ✨ 1. Overview & Features

**T2DECODE** is an offline-first learning laboratory and field engineering toolkit built to run **100% locally and air-gapped**. No data ever leaves your computer: no telemetry, no mandatory account, and no third-party cloud dependency.

### 🧰 Key Integrated Modules

| Module | Description & Technical Usage |
| :--- | :--- |
| **🧠 Ghost AI (LLM Tutor)** | Local AI assistant (Ollama) with RAG pipeline directly connected to built-in course modules. |
| **🌐 NetKit (Networking)** | Dynamic network topology simulator (IPv4/v6 addressing, routing, packet inspection). |
| **💻 Linux Sandbox VM** | Secure POSIX virtual terminal to practice shell commands without breaking your system. |
| **🔐 CryptoLab** | Interactive experimentation with cryptography algorithms (RSA/AES encryption, SHA hashing). |
| **🛠️ Field Tools** | CIDR calculator, Chmod converter, CRON generator, hash and checksum verifier. |
| **📚 Masterclass Courses** | In-depth engineering guides written with real incident scenarios and validation quizzes. |

---

### 📷 Application Interface

<p align="center">
  <img width="48%" src="docs/images/screenshots/app-home-full.png" style="border-radius: 8px;" alt="T2DECODE Home">
  <img width="48%" src="docs/images/screenshots/section-tools.png" style="border-radius: 8px;" alt="Field Tools">
</p>
<p align="center">
  <img width="48%" src="docs/images/screenshots/section-chat-ia.png" style="border-radius: 8px;" alt="Local Ghost AI">
  <img width="48%" src="docs/images/screenshots/section-cheat-sheets.png" style="border-radius: 8px;" alt="Cheat Sheets">
</p>

<img src="assets/separator.svg" width="100%" height="4">

## 📦 2. Downloads & Installation (Ready to Use)

Pre-compiled and verified binaries are distributed free of charge on official channels:

| Platform | Channel | Format | Quick Command |
| :--- | :--- | :--- | :--- |
| **Linux** | [Snap Store](https://snapcraft.io/t2decode) / [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | Snap / AppImage / DEB | `sudo snap install t2decode` |
| **macOS** | [App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12) / **Homebrew** / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | PKG / DMG / Cask | `brew install --cask t2decode` |
| **Android** | [F-Droid](https://f-droid.org/packages/org.t2decode.app/) / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | APK / AAB | *Via F-Droid Client* |
| **Windows** | [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) / [SourceForge](https://sourceforge.net/projects/t2decode/) | EXE / ZIP | *Direct Download* |

> 🌐 **Independent Audit & Mirror**: All release binaries, archives, and checksum files are mirrored on our [official SourceForge repository](https://sourceforge.net/projects/t2decode/).

---

### 🐧 Linux Installation (Snap Store)
[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/t2decode)
```bash
sudo snap install t2decode
```

### 🍏 macOS Installation (Homebrew)
```bash
brew tap tutodecode-org/homebrew-tap
brew install --cask t2decode
```

> 💡 **First Launch on macOS (Gatekeeper)**: If an "Unverified Developer" warning appears on first `.dmg` launch: perform a **Right-Click on T2DECODE.app → Open**, or execute `xattr -cr /Applications/T2DECODE.app` in your Terminal.

### 🪟 Windows First Launch (SmartScreen)
> 💡 **First Launch on Windows (SmartScreen)**: If the blue Windows protection dialog pops up on first `.exe` launch: click **"More info"** and then press **"Run anyway"**. Windows will remember `Association TUTODECODE` for subsequent launches.


<img src="assets/separator.svg" width="100%" height="4">

## 🛡️ 3. Binary Integrity & Zero Trust Security

*You can never be too safe: always verify the SHA-256 digital fingerprint of your downloaded executables before running them.*

Compare the result with the official checksums published on [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) or [SourceForge](https://sourceforge.net/projects/t2decode/).

#### 🐧 Linux & 🍏 macOS (Terminal)
```bash
# Verify hash on Linux
sha256sum T2DECODE-Linux.tar.gz

# Verify hash on macOS
shasum -a 256 T2DECODE-macOS.dmg
```

#### 🪟 Windows (PowerShell)
```powershell
Get-FileHash .\T2DECODE-Windows.zip -Algorithm SHA256
```

<img src="assets/separator.svg" width="100%" height="4">

## 💻 4. Building From Source (Developers)

If you prefer **building the application yourself from the source code**, follow the steps below:

### 📋 System Prerequisites
- **Flutter SDK**: `stable` branch (3.x+)
- **Linux (Debian/Ubuntu)**: `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev`
- **macOS**: Xcode Command Line Tools (`xcode-select --install`)
- **Windows**: Visual Studio 2022 (*Desktop C++* and *ATL* component)

### 🛠️ Build Commands

```bash
# 1. Clone the repository
git clone https://gitlab.com/tutodecode-org/T2DECODE.git
cd T2DECODE

# 2. Check environment & fetch dependencies
make setup
make get

# 3. Run unit & widget test suite
make test

# 4. Launch in development mode
flutter run
```

### 📦 Release Building via `Makefile`

```bash
make build-android  # Build Release APKs (per-ABI)
make build-linux    # Compile native Linux binary
make build-macos    # Compile macOS .app executable
make build-dmg      # Create macOS DMG installer package
```

<img src="assets/separator.svg" width="100%" height="4">

## ⚖️ 5. Publisher, License & Legal Information

The **T2DECODE** software is published and maintained by **TUTODECODE Association** (Non-profit organisation, SIREN 102 763 133, RNA W134011400).

- **Founder & President**: Maxime MARTIN CIVET
- **Official Website**: [tutodecode.org](https://tutodecode.org)
- **License**: [GNU General Public License v3.0 (GPLv3)](LICENSE) — Sovereign Open Source Software.
