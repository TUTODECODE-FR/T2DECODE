<meta name="fediverse:creator" content="@TUTODECODE@mastodon.social">

<div align="center">
  <p>
    <a href="README.md">🇫🇷 Français</a> | <strong>🇬🇧 English</strong>
  </p>
  <a href="https://tutodecode.org">
    <img src="https://gitlab.com/tutodecode-org/T2DECODE/-/raw/main/assets/TDC.png" width="160" height="160" alt="T2DECODE Logo">
  </a>

  <h1>T2DECODE</h1>
  <p><strong>Autonomous & Sovereign Educational Platform for Computer Networks, Cybersecurity, and System Administration.</strong><br>
  <em>100% Offline · Zero Cloud · Zero Tracking · Open Source GPLv3 License</em></p>

  <p align="center">
    <img src="https://img.shields.io/badge/pipeline-passed-brightgreen?style=flat-square" alt="Pipeline Passed">
    <img src="https://img.shields.io/badge/Latest_Release-v1.0.3-blue?style=flat-square" alt="Release v1.0.3">
    <img src="https://img.shields.io/badge/License-GPLv3-gold?style=flat-square" alt="License GPLv3">
    <img src="https://img.shields.io/badge/Homebrew-Cask-orange?style=flat-square" alt="Homebrew Cask">
    <img src="https://img.shields.io/badge/F--Droid-Available-0070e0?style=flat-square" alt="F-Droid">
    <img src="https://img.shields.io/badge/OpenSSF_Best_Practices-Gold-yellow?style=flat-square" alt="OpenSSF Gold">
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/100%25_AIR--GAPPED-OFFLINE_FIRST-success?style=flat-square" alt="Offline First">
    <img src="https://img.shields.io/badge/ZERO_CLOUD-NO_TRACKING-00bcd4?style=flat-square" alt="Zero Cloud">
    <img src="https://img.shields.io/badge/GHOST_AI-OLLAMA_LOCAL_LLM-8e24aa?style=flat-square" alt="Ghost AI Local LLM">
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/COMMITS-VERIFIED_SSH-00e676?style=flat-square" alt="Verified Commits">
    <img src="https://img.shields.io/badge/SOVEREIGN_CODE-GPLV3-orange?style=flat-square" alt="Sovereign Code">
    <img src="https://img.shields.io/badge/FLUTTER_CORE-MULTI--PLATFORM-0288d1?style=flat-square" alt="Multi-platform">
    <img src="https://img.shields.io/badge/TUTODECODE-VERIFIED_REPOSITORY-039be5?style=flat-square" alt="Verified Repository">
  </p>

  <p>
    <a href="#-download--ready-to-use-installation">Download</a> · 
    <a href="#-overview--core-modules">Overview</a> · 
    <a href="#-quality-assurance--transparency">Quality & Security</a> · 
    <a href="#-join-the-team--contribute">Contribute</a> · 
    <a href="#-build-from-source">Build</a> · 
    <a href="docs/architecture.md">Architecture</a>
  </p>
</div>

<img src="assets/separator.svg" width="100%" height="4">

## 📑 Table of Contents

<details>
<summary><strong>Click here to expand the full table of contents</strong></summary>

- [📦 Download & Ready-To-Use Installation](#-download--ready-to-use-installation)
  - [Linux (Snap Store)](#-linux-installation-snap-store)
  - [macOS (Homebrew)](#-macos-installation-homebrew)
  - [Windows](#-windows-first-launch-smartscreen)
  - [Android (F-Droid)](#-android-installation-f-droid)
- [🛠️ Overview & Core Modules](#️-overview--core-modules)
- [🛡️ Quality Assurance & Transparency](#-quality-assurance--transparency)
- [🤝 Join the Team & Contribute](#-join-the-team--contribute)
- [🗺️ Roadmap & Future Enhancements](#️-roadmap--future-enhancements)
- [🛡️ Binary Integrity Verification (Zero Trust)](#️-binary-integrity-verification-zero-trust)
- [💻 Build From Source](#-build-from-source)
- [❓ Frequently Asked Questions (FAQ)](#-frequently-asked-questions-faq)
- [📚 Full Documentation](#-full-documentation)
- [⚖️ Legal Notice & License](#️-legal-notice--license)

</details>

---

## 📦 Download & Ready-To-Use Installation

Pre-compiled and verified binaries are distributed free of charge across our official channels:

| Platform | Distribution Channel | Format | Command / Method |
| :--- | :--- | :--- | :--- |
| **Linux** | [Snap Store](https://snapcraft.io/t2decode) / [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | Snap / AppImage / DEB | `sudo snap install t2decode` |
| **macOS** | [App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12) / **Homebrew** / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | PKG / DMG / Cask | `brew install --cask t2decode` |
| **Android** | [F-Droid](https://f-droid.org/packages/org.t2decode.app/) / [Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) | APK / AAB | *Via F-Droid Client* |
| **Windows** | [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) / [SourceForge](https://sourceforge.net/projects/t2decode/) | EXE / ZIP | *Direct Download* |

> 🌐 **Audit Mirror & Third-Party Distribution**: You can also download all binaries and checksum files from our official [SourceForge Mirror](https://sourceforge.net/projects/t2decode/).

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

## 🛠️ Overview & Core Modules

**T2DECODE** is an educational and technical experimentation environment designed to operate in **strictly autonomous, air-gapped mode**. No data leaves your machine: zero telemetry, zero tracking, zero third-party cloud.

### 🧰 The 6 Built-In Core Modules

| Module | Description & Technical Scope |
| :--- | :--- |
| **🧠 Ghost AI (Local LLM)** | Local AI assistant (Ollama) running an RAG pipeline connected directly to built-in courses. |
| **🌐 NetKit (Networking)** | Dynamic network topology modeling and simulation (IPv4/v6 addressing, routing). |
| **💻 Linux VM Sandbox** | Secure POSIX virtual terminal for practicing system administration and shell scripting. |
| **🔐 CryptoLab** | Interactive experimentation with cryptographic algorithms (RSA, AES, SHA-256). |
| **🛠️ Utility Tools** | IPv4/v6 CIDR calculator, Chmod converter, CRON generator, hash verifier. |
| **📚 Masterclass Courses** | Engineering guides featuring real incident case studies and production best practices. |

### User Interface

<p align="center">
  <img width="48%" src="docs/images/screenshots/app-home-full.png" style="border-radius: 8px;" alt="T2DECODE Home">
  <img width="48%" src="docs/images/screenshots/section-tools.png" style="border-radius: 8px;" alt="Utility Tools">
</p>
<p align="center">
  <img width="48%" src="docs/images/screenshots/section-chat-ia.png" style="border-radius: 8px;" alt="Ghost AI Local">
  <img width="48%" src="docs/images/screenshots/section-cheat-sheets.png" style="border-radius: 8px;" alt="Cheat Sheets">
</p>

<img src="assets/separator.svg" width="100%" height="4">

## 🛡️ Quality Assurance & Transparency

T2DECODE relies on a rigorous, automated DevSecOps engineering process:

- **163 Automated Tests**: 100% pass rate across unit and widget tests on every commit.
- **Coverage Audit (`verify_coverage.py`)**: Continuous test coverage enforcement.
- **16 CI/CD DevSecOps Scanners**:
  - `Gitleaks`: Deep Git commit history secret leak scanner.
  - `Semgrep SAST`: Source code static security audit.
  - `Google OSV-Scanner` & `Trivy`: Dependency supply chain vulnerability auditing.
  - `ClamAV`: Antivirus and anti-malware scanner.
  - `flutter analyze`, `yamllint`, `shellcheck`: Strict code quality linters.
- **OWASP MASVS Compliance**: Full security mapping documented in [`docs/masvs-mapping.md`](docs/masvs-mapping.md).

<img src="assets/separator.svg" width="100%" height="4">

## 🤝 Join the Team & Contribute

The **TUTODECODE Association** welcomes contributors and developers passionate about networking and cybersecurity!

- 📖 **Contribution Guide**: Read [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.
- 👥 **Maintainer Recruitment**: Check opportunities in [`MAINTAINER_WANTED.md`](MAINTAINER_WANTED.md).
- 💬 **Support & Inquiries**: Reach out at `contact@tutodecode.org`.

<img src="assets/separator.svg" width="100%" height="4">

## 🗺️ Roadmap & Future Enhancements

- [x] Cross-platform releases (Snap Store, Homebrew, F-Droid, App Store)
- [x] Full DevSecOps pipeline (16 automated scanners)
- [x] Binary integrity and OWASP MASVS audit
- [ ] T2C-Phantom: Decentralized P2P LAN sync module
- [ ] Extended Network Simulators & Packet Analysis

<img src="assets/separator.svg" width="100%" height="4">

## 🛡️ Binary Integrity Verification (Zero Trust)

*Always verify the SHA-256 digital fingerprint of binary files before execution.*

Compare the output with official checksums published on [GitLab Releases](https://gitlab.com/tutodecode-org/T2DECODE/-/releases) or [SourceForge](https://sourceforge.net/projects/t2decode/).

#### 🐧 Linux & 🍏 macOS (Terminal)
```bash
sha256sum T2DECODE-Linux.tar.gz
shasum -a 256 T2DECODE-macOS.dmg
```

#### 🪟 Windows (PowerShell)
```powershell
Get-FileHash .\T2DECODE-Windows.zip -Algorithm SHA256
```

<img src="assets/separator.svg" width="100%" height="4">

## 💻 Build From Source

#### System Prerequisites
- **Flutter SDK**: `stable` channel (3.x+)
- **Linux (Debian/Ubuntu)**: `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`
- **macOS**: Xcode Command Line Tools (`xcode-select --install`)
- **Windows**: Visual Studio 2022 (*Desktop C++* and *ATL* component)

#### Setup & Build

```bash
git clone https://gitlab.com/tutodecode-org/T2DECODE.git
cd T2DECODE

make setup
make get
make test
flutter run
```

#### Generating Release Packages via `Makefile`
```bash
make build-android  # Generates Release APKs (per-ABI)
make build-linux    # Compiles native Linux binary
make build-macos    # Compiles macOS .app executable
make build-dmg      # Generates DMG installer package (macOS)
```

<img src="assets/separator.svg" width="100%" height="4">

## ❓ Frequently Asked Questions (FAQ)

### 1. Does the app truly run 100% offline?
Yes, the application is engineered air-gapped: zero telemetry, zero remote cloud servers. Ollama (Ghost AI) runs locally on your machine.

### 2. How to report a security vulnerability confidentially?
Do not open a public issue. Send a report directly to `contact@tutodecode.org`. Read our full policy in [`SECURITY.md`](SECURITY.md).

### 3. What is the licensing status of the codebase?
T2DECODE is distributed under the free software **GNU General Public License v3.0 (GPLv3)**.

<img src="assets/separator.svg" width="100%" height="4">

## 📚 Full Documentation

- [🏗️ Technical Architecture](docs/architecture.md)
- [🔒 Security Policy](SECURITY.md)
- [🛡️ OWASP MASVS Mapping](docs/masvs-mapping.md)
- [🤝 Contributing Guide](CONTRIBUTING.md)
- [👥 Maintainer Recruitment](MAINTAINER_WANTED.md)
- [📄 GPLv3 License](LICENSE)

<img src="assets/separator.svg" width="100%" height="4">

## ⚖️ Legal Notice & License

The T2DECODE project is maintained and published by **TUTODECODE Association** (French Non-Profit Association Law 1901, SIREN 102 763 133, RNA W134011400).

- **Founder & President**: Maxime MARTIN CIVET
- **Official Website**: [tutodecode.org](https://tutodecode.org)
- **License**: [GNU General Public License v3.0 (GPLv3)](LICENSE) — Free & Sovereign Software.

---

<div align="center">

**T2DECODE** — Autonomous & Sovereign Educational Platform for Computer Networks and Cybersecurity

Published by TUTODECODE Association (Law 1901, SIREN 102 763 133)

[Website](https://tutodecode.org) · [GitLab](https://gitlab.com/tutodecode-org/T2DECODE) · [SourceForge](https://sourceforge.net/projects/t2decode/) · [Contact](mailto:contact@tutodecode.org)

<sub>© 2024-2026 TUTODECODE Association. All rights reserved.</sub>

</div>
