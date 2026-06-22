<div align="center">
  <p>
    <a href="README.md">🇫🇷 Français</a> | <strong>🇬🇧 English</strong>
  </p>

  <a href="https://github.com/TUTODECODE-FR/T2DECODE">
    <img src="https://raw.githubusercontent.com/TUTODECODE-FR/T2DECODE/main/assets/TDC.png" width="160" height="160" alt="T2C Logo">
  </a>

  <h1>T2DECODE</h1>
  <p><strong>T2DECODE — Offline educational platform for networking, Linux, and cybersecurity.</strong></p>

  <p>T2DECODE is a standalone software suite for IT students, trainers, and professionals. It brings together interactive courses, technical simulators, specialized tools, and a local AI assistant (Ollama), all designed to work without an internet connection to guarantee data privacy and integrity.</p>

  <p><strong>Key Highlights:</strong></p>
  <ul>
    <li>100% offline functionality — no cloud dependencies.</li>
    <li>Interactive simulators: networking, Linux, cryptography.</li>
    <li>Integrated professional tools: CIDR, hashing, chmod, cron.</li>
    <li>Ghost AI: local LLM assistant via Ollama, with no external data transmission.</li>
    <li>Integrity and security: SHA-256 and anti-tampering checks at startup.</li>
  </ul>

  <p><strong>Multi-platform • Air-gapped ready • Open-source (GPLv3)</strong></p>

  <br>
  <img src="docs/images/t2decode_demo.gif" width="100%" style="border-radius: 12px; max-width: 800px; box-shadow: 0 4px 15px rgba(0,0,0,0.5);" alt="Video Demo - T2DECODE in action">
  <br><br>

  <!-- CI & Distribution Badges -->
  <p>
    <a href="https://github.com/TUTODECODE-FR/T2DECODE/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/TUTODECODE-FR/T2DECODE/ci.yml?style=for-the-badge&logo=githubactions&logoColor=white&labelColor=1A1D2E&color=3DDC84" alt="CI"></a>
    <a href="https://github.com/TUTODECODE-FR/T2DECODE/actions/workflows/mobsf.yml"><img src="https://img.shields.io/github/actions/workflow/status/TUTODECODE-FR/T2DECODE/mobsf.yml?label=MobSF%20Pentest&style=for-the-badge&logo=githubactions&logoColor=white&labelColor=1b1510" alt="MobSF Pentest"></a>
    <a href="https://github.com/TUTODECODE-FR/T2DECODE/actions/workflows/osv-scanner.yml"><img src="https://img.shields.io/github/actions/workflow/status/TUTODECODE-FR/T2DECODE/osv-scanner.yml?label=Google%20OSV&style=for-the-badge&logo=githubactions&logoColor=white&labelColor=1b1510" alt="OSV Scanner"></a>
    <a href="https://github.com/TUTODECODE-FR/T2DECODE/releases/latest"><img src="https://img.shields.io/github/v/release/TUTODECODE-FR/T2DECODE?style=for-the-badge&logo=github&color=F5EBDA&labelColor=1A1D2E&logoColor=F5EBDA" alt="Release"></a>
    <a href="https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12"><img src="https://img.shields.io/badge/Mac_App_Store-Available-000000?style=for-the-badge&logo=apple&logoColor=white&labelColor=1A1D2E&color=0078D6" alt="Mac App Store"></a>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-Multi--Platform-02569B?style=for-the-badge&logo=flutter&logoColor=white&labelColor=1A1D2E&color=02569B" alt="Flutter"></a>
    <a href="https://github.com/TUTODECODE-FR/T2DECODE/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-FCC624?style=for-the-badge&labelColor=1A1D2E&color=FCC624" alt="License"></a>
  </p>

  <!-- OpenSSF Badges -->
  <p>
    <a href="https://www.bestpractices.dev/projects/12999"><img src="https://www.bestpractices.dev/projects/12999/badge" alt="OpenSSF Best Practices"></a>
    <a href="https://www.bestpractices.dev/projects/12999"><img src="https://www.bestpractices.dev/projects/12999/baseline" alt="OpenSSF Baseline"></a>
    <a href="https://scorecard.dev/viewer/?uri=github.com/TUTODECODE-FR/T2DECODE"><img src="https://api.scorecard.dev/projects/github.com/TUTODECODE-FR/T2DECODE/badge" alt="OpenSSF Scorecard"></a>
  </p>

  <p>
    <a href="https://github.com/TUTODECODE-FR/T2DECODE/releases/latest">Releases</a> · 
    <a href="docs/resume.md">Summary</a> ·
    <a href="docs/build.md">Build & Compilation</a> · 
    <a href="docs/architecture.md">Architecture</a> · 
    <a href="RGPD.md">Privacy Policy</a> · 
    <a href="CONTRIBUTING.md">Contributing</a>
  </p>
</div>

<img src="assets/separator.svg" width="100%" height="4">

## 📊 By the Numbers

- 📚 **120+** educational sheets
- 🔬 **9** simulators
- 🛠️ **15+** integrated tools
- 💻 **Windows / Linux / macOS / Android**
- 🌐 **0** cloud dependencies
- 🔒 **100%** open source


<img src="assets/separator.svg" width="100%" height="4">

## ⚙️ Features

| Module | Description |
|----------|------------|
| **Ghost AI** | Local AI assistant (Ollama LLM) with RAG on courses |
| **NetKit** | Network simulator (Topology, Routing, Ping) |
| **CryptoLab** | Cryptography simulator (Symmetric/Asymmetric encryption) |
| **LinuxLab** | Linux terminal simulator |
| **CIDR** | IPv4/IPv6 subnet calculator |
| **Hash** | Hashing utilities (SHA256, MD5, etc.) |
| **Chmod** | Linux system permissions calculator |
| **Cron** | Scheduled tasks generator and validator |
| **T2C-Phantom** | Decentralized P2P network for course updates |

### 🔄 Autonomous P2P Updates with T2C-Phantom

The **T2C-Phantom** protocol (P2P synchronization engine via Go/libp2p proxy) is currently scheduled for the next development stages (Phase 2). 

To learn more about network security, course integrity validation (SHA-256), and technical details of this implementation, please see the dedicated documentation: [Security & Integrity FAQ](docs/prochaine_mise_a_jour.md).


<img src="assets/separator.svg" width="100%" height="4">

## 🖼️ T2DECODE in Action

<p align="center">
  <img width="48%" src="docs/images/screenshots/app-home-full.png" style="border-radius: 8px;" alt="Home">
  <img width="48%" src="docs/images/screenshots/section-tools.png" style="border-radius: 8px;" alt="Tools">
</p>
<p align="center">
  <img width="48%" src="docs/images/screenshots/section-chat-ia.png" style="border-radius: 8px;" alt="Ghost AI">
  <img width="48%" src="docs/images/screenshots/section-cheat-sheets.png" style="border-radius: 8px;" alt="Cheat Sheets">
</p>

<img src="assets/separator.svg" width="100%" height="4">

## 🎯 Why T2DECODE?

Unlike traditional training platforms:

| Cloud Platforms | T2DECODE |
|------------------|-----------|
| Internet required | Works **offline** |
| Data hosted by a third party | **Local** data |
| Remote AI (SaaS) | **Local** Ollama AI |
| Barely usable in secure environments | **Air-Gapped Ready** |
| Requires a subscription | **Standalone** software |

<img src="assets/separator.svg" width="100%" height="4">

## 👨‍💻 Use Cases

**🎓 For Students**
- Review networking concepts (OSI, TCP/IP) without an Internet connection.
- Perform practical exercises on simulators (NetKit, Linux).

**🛠️ For System Administrators**
- Quickly use IPv4/v6 CIDR calculators.
- Verify Linux permissions (chmod) or generate CRON requests from a clean interface.

**👨‍🏫 For Trainers**
- Distribute complete course materials on USB flash drives (Air-gapped).
- Build and provide standalone virtual pedagogical labs.

<img src="assets/separator.svg" width="100%" height="4">

## 🗺️ Visual Roadmap

We are building the future of sovereign education:

- [x] Interactive simulators
- [x] Local AI (Ollama)
- [x] Offline toolkit
- [ ] Synchronization engine (T2C-Phantom)
- [ ] Local P2P messaging (Ghost Link)
- [ ] Community educational modules marketplace

<img src="assets/separator.svg" width="100%" height="4">

## 🚀 Quick Start (Users)

If you don't want to compile the application yourself, here are the three steps to get started in a flash:

1. **📥 Download**: Grab the [latest release](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest) for your system (Windows, macOS, Linux, Android).
2. **⚡ Launch**: The application is standalone, install it or run the binary directly depending on your platform.
3. **🎓 Use**: You're done! You can instantly use the toolkit, play with simulators, and chat with the local AI (Ollama).

<img src="assets/separator.svg" width="100%" height="4">

## 🏗️ Visual Architecture

T2DECODE is structured in a modular way, separating the interface from the underlying local services.

```text
User
   │
   ▼
T2DECODE (Flutter Application)
 ├── 📚 Courses (Markdown, MCQs, Local progression)
 ├── 🔬 Simulators (Networking, Crypto, System)
 ├── 🛠️ Tools (Hash, CIDR, Chmod, CRON...)
 ├── 🧠 Ghost AI (HTTP client to local Ollama)
 └── 🔗 Ghost Link (LAN P2P Service - WIP)
```

<img src="assets/separator.svg" width="100%" height="4">

## 📥 Downloads & Platforms

➡️ [**Download pre-compiled binaries (GitHub Releases)**](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest)

| Platform | Distribution Format | CI Status | Accessibility |
| :--- | :--- | :---: | :---: |
| ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) | **APK** / AAB (64-bit) | Active | Available |
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white) | **ZIP** / EXE Installer | Active | Available |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white) | **[App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12)** / PKG / Universal ZIP | Active | Available |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) | **AppImage** / DEB (64-bit) | Active | Available |

> 🔒 **Integrity Guarantee**: Each version comes with a `SHA256SUMS.txt` file and cryptographic signatures to authenticate the origin of the binaries.

<img src="assets/separator.svg" width="100%" height="4">

## 🛡️ Security Posture & Continuous Audits

Security is at the heart of T2DECODE's architecture. We apply rigorous development standards to aim for a high level of reliability.

### 1. CI/CD Security (Automated Pipelines)
- **Static Analysis (SAST)**: SonarQube and CodeQL run on each Pull Request to guarantee code reliability.
- **Vulnerability Scanning**: Google OSV-Scanner continuously audits dependencies (`osv-scanner.yml`).
- **Automated Pentesting**: MobSF performs dynamic analysis of the generated Android APK (`mobsf.yml`).
- **OpenSSF Scorecard**: Continuous audit of Open Source security best practices.

### 2. Runtime Security (In-App)
Our architecture is implemented in native Dart directly in [`lib/core/security/`](lib/core/security/).
- **Active Anti-Tampering**: On startup, the system recalculates SHA-256 hashes of all assets via `assets/asset_checksums.json`. Any malicious modification is detected.
- **Authenticity & Certificates**: Strict verification of stored signatures in an encrypted manner.
- **Air-Gapped Design**: No telemetry, no tracking SDKs, no cloud API calls.

<img src="assets/separator.svg" width="100%" height="4">

## 👨‍💻 Development Environment & Compilation

### 1. Required System Dependencies

The application relies on Flutter and native libraries. Make sure to install the prerequisites according to your system:

- **Linux (Debian / Ubuntu)**:
  ```bash
  sudo apt-get update && sudo apt-get install -y clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
  ```
- **macOS**: `xcode-select --install`
- **Windows**: Git and Visual Studio 2022 with the *Desktop development with C++* workload.

> 📖 *For detailed instructions per distribution, check [OS_DEPENDENCIES.md](OS_DEPENDENCIES.md).*

### 2. Quick Start

```bash
# Clone the official repository
git clone https://github.com/TUTODECODE-FR/T2DECODE.git
cd T2DECODE

# Check build environment
make setup

# Install Flutter dependencies
make get

# Run the automated test suite
make test

# Launch the application in debug mode
flutter run
```

### 🛠️ Task Automation (Makefile)

The project includes a comprehensive `Makefile` to facilitate compilation across all targets:

```bash
make setup          # Dependency diagnostics (Flutter, Dart, Ollama)
make clean          # Complete cleanup of build directories
make test           # Run automated tests
make build-android  # Build release APK archive
make build-macos    # Build macOS .app binary
make build-dmg      # Create macOS installation disk image (.dmg)
make build-linux    # Build native Linux executable
```

<img src="assets/separator.svg" width="100%" height="4">

## 🏛️ TUTODECODE Association (Legal Notice)

The T2DECODE project is developed and supported by the **TUTODECODE Association**, an entity under the Social and Solidarity Economy (ESS).  
Our mission is to democratize the mastery of IT infrastructure and cybersecurity by providing sovereign and privacy-respecting tools.

- **Publisher**: Association Loi 1901 TUTODECODE
- **Publication Director**: Maxime MARTIN CIVET
- **SIREN**: 102 763 133
- **Official Website**: [https://tutodecode.org](https://tutodecode.org)
- **Legal Proof**: [Creation announcement published in JOAFE](https://www.journal-officiel.gouv.fr/pages/associations-detail-annonce/?q.id=id:202600110336)
- **Privacy Commitment**: [Read our GDPR Policy](RGPD.md)

<img src="assets/separator.svg" width="100%" height="4">

## 🤝 Contributing & Community Standards

T2DECODE is an open-source public good built by and for its community. All contributions are warmly welcomed!

### 📜 Standards and Project Health
- 🛡️ **[Security & Vulnerabilities](SECURITY.md)**: Our strict vulnerability management policy.
- ⚖️ **[Free License](LICENSE)**: Your rights and obligations (GPLv3).
- 🤝 **[Code of Conduct](CODE_OF_CONDUCT.md)**: For a healthy and inclusive environment.
- 📖 **[Contributing Guide](CONTRIBUTING.md)**: How to add courses or code.
- 🏛️ **[Governance](GOVERNANCE.md)**: The association's decision-making model.
- 🆘 **[Support](SUPPORT.md)**: Where to find help if needed.
- 🗺️ **[Roadmap](ROADMAP.md)**: Our next steps and targeted mission offers.

### 💖 Financial Support (Donations)
If T2DECODE saves you time or enriches your journey, you can support the TUTODECODE association. Donations are used exclusively to sustain the hosting of our services.
- ➡️ **[Make a secure donation via HelloAsso](https://www.helloasso.com/associations/tutodecode)**

<img src="assets/separator.svg" width="100%" height="4">

## 🔐 Security
All commits in this repository are GPG-signed to guarantee their authenticity.

<img src="assets/separator.svg" width="100%" height="4">

## 📄 License & Rights
This project is distributed under the **[GNU General Public License v3.0 (GPLv3)](LICENSE)**.
