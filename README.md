<div align="center">
  <img src="https://raw.githubusercontent.com/TUTODECODE-FR/T2DECODE/main/assets/TDC.png" width="160" height="160" alt="T2C Logo">

  # T2DECODE
  
  **« Le savoir ne devrait pas toujours dépendre d'une connexion. »**<br>
  — *Maxime MARTIN CIVET*

  <br>

  <!-- CI & Distribution Badges -->
  [![CI](https://img.shields.io/github/actions/workflow/status/TUTODECODE-FR/T2DECODE/ci.yml?style=for-the-badge&logo=githubactions&logoColor=white&labelColor=1A1D2E&color=3DDC84)](https://github.com/TUTODECODE-FR/T2DECODE/actions/workflows/ci.yml)
  [![Release](https://img.shields.io/github/v/release/TUTODECODE-FR/T2DECODE?style=for-the-badge&logo=github&color=F5EBDA&labelColor=1A1D2E&logoColor=F5EBDA)](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest)
  [![Mac App Store](https://img.shields.io/badge/Mac_App_Store-Available-000000?style=for-the-badge&logo=apple&logoColor=white&labelColor=1A1D2E&color=0078D6)](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12)
  [![Flutter](https://img.shields.io/badge/Flutter-Multi--Platform-02569B?style=for-the-badge&logo=flutter&logoColor=white&labelColor=1A1D2E&color=02569B)](https://flutter.dev)
  [![License](https://img.shields.io/badge/License-GPLv3-FCC624?style=for-the-badge&labelColor=1A1D2E&color=FCC624)](https://github.com/TUTODECODE-FR/T2DECODE/blob/main/LICENSE)
  
  <br>

  <!-- Security & Trust Badges -->
  [![OpenSSF Best Practices](https://www.bestpractices.dev/projects/12999/badge)](https://www.bestpractices.dev/projects/12999)
  [![OpenSSF Baseline](https://www.bestpractices.dev/projects/12999/baseline)](https://www.bestpractices.dev/projects/12999)
  [![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/TUTODECODE-FR/T2DECODE/badge)](https://scorecard.dev/viewer/?uri=github.com/TUTODECODE-FR/T2DECODE)
  [![Snyk Security](https://snyk.io/test/github/TUTODECODE-FR/T2DECODE/badge.svg)](https://snyk.io/test/github/TUTODECODE-FR/T2DECODE)
  [![SonarQube Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=TUTODECODE-FR_T2DECODE&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=TUTODECODE-FR_T2DECODE)
  [![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=TUTODECODE-FR_T2DECODE&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=TUTODECODE-FR_T2DECODE)

  <br>
  <p>
    <b>Plateforme locale d’apprentissage technique (Réseau · Systèmes · Sécurité Défensive) avec boîte à outils et IA intégrée.</b><br>
    <i>100% Offline-first · Air-gapped ready · Zéro télémétrie · IA & RAG locaux (Ollama) · P2P LAN Mesh</i>
  </p>
  <br>

  [Releases](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest) · [Build & Compilation](docs/build.md) · [Architecture Souveraine](docs/architecture.md) · [Confidentialité & RGPD](RGPD.md) · [Contribuer](CONTRIBUTING.md)
</div>

<img src="assets/separator.svg" width="100%" height="4">

## 🎯 La Vision T2DECODE

T2DECODE est une **suite pédagogique et technique de classe entreprise** conçue pour apprendre, expérimenter et diagnostiquer des infrastructures **sans aucune dépendance au cloud ni connexion Internet**.

Que vous soyez dans un *datacenter* sécurisé, dans un train sans réseau, ou dans un environnement *air-gapped* strict, T2DECODE vous offre vos outils, vos cours et votre IA.

- 📚 **Apprentissage Structuré** : Cours interactifs en Markdown avec QCM de validation et système de progression gamifié (XP & Badges).
- 🛠️ **Boîte à Outils Professionnelle** : Plus de 15 utilitaires de calcul, diagnostic et conversion (Syslog, CIDR, Chmod, Base64).
- 🔬 **Laboratoires Virtuels (Simulateurs)** : Entraînez-vous sur des simulateurs de réseaux (NetKit), cryptographie, systèmes et algorithmique.
- 🛡️ **Souveraineté & Résilience** : Conçu spécifiquement pour opérer en environnements stricts (Air-gapped, Zéro Confiance).

<img src="assets/separator.svg" width="100%" height="4">

## 🛡️ Posture de Sécurité & Audits Continus

La sécurité n'est pas une option, c'est le cœur de T2DECODE. Nous appliquons les standards de développement les plus stricts du marché pour garantir une fiabilité absolue.

| Métrique de Confiance | Implémentation | Preuve |
| :--- | :--- | :--- |
| **Analyse Statique (SAST)** | Vérification en continu par **SonarQube** et **CodeQL** à chaque modification. | [![SonarQube Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=TUTODECODE-FR_T2DECODE&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=TUTODECODE-FR_T2DECODE) |
| **Sécurité des Dépendances** | Audit automatisé de la chaîne logistique logicielle par **Snyk**. | [![Snyk Security](https://snyk.io/test/github/TUTODECODE-FR/T2DECODE/badge.svg)](https://snyk.io/test/github/TUTODECODE-FR/T2DECODE) |
| **Pratiques de Développement** | Respect des critères de l'Open Source Security Foundation (OpenSSF). | [![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/TUTODECODE-FR/T2DECODE/badge)](https://scorecard.dev/viewer/?uri=github.com/TUTODECODE-FR/T2DECODE) |
| **Anti-Tampering** | Vérification d'intégrité SHA-256 des assets au démarrage de l'application. | `IdentityVerificationService` |
| **Zéro Télémétrie** | Aucun appel API sortant (air-gapped par conception). RGPD strict. | [Politique Privacy](RGPD.md) |

<img src="assets/separator.svg" width="100%" height="4">

## ⚡ Fonctionnalités Phares

| Module | Description | Guide |
| :--- | :--- | :--- |
| 🧠 **Ghost AI (IA Locale)** | Tuteur conversationnel en streaming connecté à Ollama (127.0.0.1). Interrogez vos cours localement. | [docs/ollama.md](docs/ollama.md) |
| 🔗 **Ghost Link (LAN P2P)** | Découverte automatique de pairs via UDP et chat chiffré en réseau local (sans serveur central). | [docs/architecture.md](docs/architecture.md) |
| 🔬 **Laboratoires Intégrés** | 9 simulateurs interactifs : Réseau (NetKit), Système, Cloud, Cryptographie, Linux, et CTF. | [docs/labs.md](docs/labs.md) |
| 🛠️ **Multi-Outils Offline** | Calculateur CIDR, Permissions Chmod, Générateur CRON, JSON Formatter, Encodeurs Hash/Base64. | [docs/tools.md](docs/tools.md) |

<img src="assets/separator.svg" width="100%" height="4">

## 📥 Téléchargements & Plateformes (v1.0.2)

➡️ [**Télécharger les binaires précompilés (Releases GitHub)**](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest)

| Plateforme | Format de Distribution | Statut CI | Accessibilité |
| :--- | :--- | :---: | :---: |
| ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) | **APK** / AAB (64-bit) | ✅ Actif | Disponible |
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white) | **ZIP** / Installateur EXE | ✅ Actif | Disponible |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white) | **[App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12)** / PKG / ZIP | ✅ Actif | Disponible |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) | **AppImage** / DEB (64-bit) | ✅ Actif | Disponible |

> 🔒 **Garantie d'intégrité** : Chaque version publiée s'accompagne d'un fichier de vérification `SHA256SUMS.txt` et de signatures GPG pour authentifier la provenance des binaires.

<img src="assets/separator.svg" width="100%" height="4">

## 🖼️ Interface Premium (Noir & Beige)

L'interface de T2DECODE est conçue selon un design moderne (*Glassmorphism*, animations fluides) pour offrir une expérience utilisateur d'excellence sur toutes les tailles d'écran.

<div align="center">
  <img src="docs/images/t2decode_demo.gif" width="100%" style="border-radius: 12px; max-width: 800px; box-shadow: 0 4px 15px rgba(0,0,0,0.5);" alt="Démo vidéo - T2DECODE en action">
  <br><br>
</div>

<table width="100%" style="border: none; border-collapse: collapse;">
  <tr>
    <td colspan="2" align="center"><b>Vue Bureau — Accueil & Tableau de Bord</b><br><img src="docs/images/screenshots/app-home-full.png" width="100%" style="border-radius: 8px;" alt="Vue d'ensemble de l'application"></td>
  </tr>
  <tr>
    <td width="50%" align="center"><b>Navigation Parcours</b><br><img src="docs/images/screenshots/section-home.png" width="100%" style="border-radius: 8px;" alt="Accueil et Parcours"></td>
    <td width="50%" align="center"><b>Boîte à Outils Utilitaires</b><br><img src="docs/images/screenshots/section-tools.png" width="100%" style="border-radius: 8px;" alt="Outils Utilitaires"></td>
  </tr>
  <tr>
    <td width="50%" align="center"><b>Fiches Réflexes (Cheat Sheets)</b><br><img src="docs/images/screenshots/section-cheat-sheets.png" width="100%" style="border-radius: 8px;" alt="Fiches Réflexes"></td>
    <td width="50%" align="center"><b>Ghost AI (Tuteur IA Local)</b><br><img src="docs/images/screenshots/section-chat-ia.png" width="100%" style="border-radius: 8px;" alt="Chat IA Local"></td>
  </tr>
  <tr>
    <td width="50%" align="center"><b>Ghost Link (LAN P2P Chat)</b><br><img src="docs/images/screenshots/section-ghost-link.png" width="100%" style="border-radius: 8px;" alt="Ghost Link P2P"></td>
    <td width="50%" align="center"><b>Paramètres & Souveraineté</b><br><img src="docs/images/screenshots/section-settings.png" width="100%" style="border-radius: 8px;" alt="Paramètres de l'application"></td>
  </tr>
</table>

<img src="assets/separator.svg" width="100%" height="4">

## ⚙️ Architecture Interne

T2DECODE suit le principe de l'isolation des processus et des données privatives.

```mermaid
flowchart TB
    subgraph Boot ["Phase d'Initialisation (Sécurisée)"]
        Verify["IdentityVerificationService (Anti-Tampering SHA-256)"]
    end

    subgraph AppShell ["Conteneur Principal"]
        direction TB
        UI["Interface Flutter Multiplateforme"]
        
        subgraph Features ["Modules Applicatifs (Offline)"]
            direction LR
            Courses["Cours & Progression"]
            Labs["9 Simulateurs (Labs)"]
            Tools["15+ Utilitaires"]
        end
    end

    subgraph Backend ["Services Locaux Sous-jacents"]
        Ollama["Ghost AI (Ollama Local API)"]
        P2P["Ghost Link (UDP / AES-GCM Mesh)"]
        Storage["Stockage Sécurisé (SharedPreferences)"]
    end

    Verify -->|Validation OK| UI
    UI <--> Features
    UI <--> Backend

    classDef default fill:#121212,stroke:#F5EBDA,stroke-width:1px,color:#F5EBDA;
    classDef primary fill:#000000,stroke:#F5EBDA,stroke-width:2px,color:#F5EBDA;
    classDef security fill:#1b1510,stroke:#d4a373,stroke-width:1px,color:#d4a373;
    
    class UI primary;
    class Verify security;
    class Boot,AppShell,Backend,Features default;
```

<img src="assets/separator.svg" width="100%" height="4">

## 👨‍💻 Compilation & Développement

### 1. Prérequis Système
- **Linux** : `sudo apt-get install clang cmake git ninja-build pkg-config libgtk-3-dev`
- **macOS** : `xcode-select --install`
- **Windows** : Git et Visual Studio 2022 (C++ Desktop).

### 2. Lancement Rapide
```bash
git clone https://github.com/TUTODECODE-FR/T2DECODE.git
cd T2DECODE

# Validation de l'environnement (Flutter, Dart, Ollama)
make setup

# Téléchargement des packages
make get

# Exécution des tests unitaires
make test

# Lancement en mode debug
flutter run
```

<img src="assets/separator.svg" width="100%" height="4">

## 🏛️ Mentions Légales & Association

Le projet T2DECODE est soutenu par l'**Association TUTODECODE** (Loi 1901, ESS).
Notre mission : démocratiser les infrastructures et la cybersécurité avec des outils souverains, sans tracking.

- **Éditeur** : Association TUTO DECODE (SIREN : 102 763 133)
- **Directeur de Publication** : Maxime MARTIN CIVET
- **Preuve Légale** : [Annonce de création au JOAFE](https://www.journal-officiel.gouv.fr/pages/associations-detail-annonce/?q.id=id:202600110336)
- **Confidentialité** : [Politique RGPD Zéro-Data](RGPD.md)

<img src="assets/separator.svg" width="100%" height="4">

## 🤝 Contribuer

T2DECODE est un bien commun open source. Rejoignez-nous !
- ⭐ **Étoilez** ce dépôt pour nous soutenir.
- 🐛 **Signalez des bugs** via les *Issues*.
- 📝 **Ajoutez des cours** en Markdown.
- 👨‍💻 **Codez de nouveaux outils** en suivant le [Guide de Contribution (CONTRIBUTING.md)](CONTRIBUTING.md).

> 💖 **Soutenir le projet** : [Faire un don sécurisé via HelloAsso](https://www.helloasso.com/associations/tutodecode) pour nous aider à payer nos serveurs vitrines.

<br>
<div align="center">
  <i>Distribué sous licence <b>GNU General Public License v3.0 (GPLv3)</b>.</i>
</div>
