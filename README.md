<div align="center">
  <a href="https://github.com/TUTODECODE-FR/T2DECODE">
    <img src="https://raw.githubusercontent.com/TUTODECODE-FR/T2DECODE/main/assets/TDC.png" width="160" height="160" alt="T2C Logo">
  </a>

  <h1>T2DECODE</h1>
  
  <p>
    <b>« Le savoir ne devrait pas toujours dépendre d'une connexion. »</b><br>
    — <i>Maxime MARTIN CIVET</i>
  </p>

  <br>

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

  <!-- Security Scans Badges -->
  <p>
    <a href="https://sonarcloud.io/summary/new_code?id=TUTODECODE-FR_T2DECODE"><img src="https://sonarcloud.io/api/project_badges/measure?project=TUTODECODE-FR_T2DECODE&metric=alert_status" alt="SonarQube Quality Gate"></a>
    <a href="https://sonarcloud.io/summary/new_code?id=TUTODECODE-FR_T2DECODE"><img src="https://sonarcloud.io/api/project_badges/measure?project=TUTODECODE-FR_T2DECODE&metric=security_rating" alt="Security Rating"></a>
  </p>
  
  <br>
  <p>
    <b>Plateforme locale d’apprentissage technique (Réseau · Systèmes · Sécurité Défensive) avec boîte à outils et IA intégrée.</b><br>
    <i>100% Offline-first · Air-gapped ready · Zéro télémétrie · IA & RAG locaux (Ollama) · P2P LAN Mesh</i>
  </p>
  <br>

  <p>
    <a href="https://github.com/TUTODECODE-FR/T2DECODE/releases/latest">Releases</a> · 
    <a href="docs/build.md">Build & Compilation</a> · 
    <a href="docs/architecture.md">Architecture Souveraine</a> · 
    <a href="RGPD.md">Confidentialité & RGPD</a> · 
    <a href="CONTRIBUTING.md">Contribuer</a>
  </p>
</div>

<img src="assets/separator.svg" width="100%" height="4">

## 🛡️ Posture de Sécurité & Audits Continus

La sécurité est au cœur de l'architecture de T2DECODE. Nous appliquons des standards de développement rigoureux pour viser un très haut niveau de fiabilité, avec une configuration transparente et auditable.

### 1. Sécurité CI/CD (Pipelines Automatisés)
L'intégralité de nos chaînes de validation de sécurité est open source et configurée dans le dossier [`.github/workflows/`](.github/workflows/).
- **Analyse Statique (SAST)** : **SonarQube** et **CodeQL** s'exécutent à chaque Pull Request pour garantir un score AAA (Sécurité, Fiabilité, Maintenabilité). Configuration visible via `sonar-project.properties`.
- **Scan de Vulnérabilités** : **Google OSV-Scanner** audite continuellement les dépendances du projet contre les CVE mondiales connues (`osv-scanner.yml`).
- **Pentest Automatisé** : **MobSF (Mobile Security Framework)** effectue une analyse dynamique de l'APK Android généré pour bloquer toute faille d'exécution (`mobsf.yml`).
- **OpenSSF Scorecard** : Audit continu des bonnes pratiques de sécurité Open Source.

### 2. Sécurité au Runtime (In-App)
Notre architecture "Zero Trust" locale est implémentée en Dart natif directement dans [`lib/core/security/`](lib/core/security/).
- **Anti-Tampering Actif** : Au démarrage, le système recalcule les empreintes SHA-256 de tous les assets via `assets/asset_checksums.json`. Toute modification malveillante du binaire après compilation est immédiatement détectée.
- **Authenticité & Certificats** : Vérification stricte des signatures et métadonnées de l'Association TUTODECODE stockées de manière chiffrée (via `flutter_secure_storage`).
- **Conception Air-Gapped** : Aucune télémétrie, aucun SDK de pistage, aucun appel API cloud. Le fonctionnement est 100% hors-ligne.

### 3. Tableau de Bord en Temps Réel

| Métrique de Confiance | Implémentation | Preuve |
| :--- | :--- | :--- |
| **Score de Qualité (SAST)** | Analyse de code statique continue via **SonarQube** et **CodeQL**. | [![SonarQube Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=TUTODECODE-FR_T2DECODE&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=TUTODECODE-FR_T2DECODE) |
| **Audit des Dépendances** | Vérification anti-CVE automatisée par **Google OSV-Scanner**. | *Pipeline CI/CD (GitHub Actions)* |
| **Pentest Automatisé** | Analyse dynamique des binaires Android par **MobSF** à chaque publication. | *Pipeline CI/CD* |
| **Pratiques de Développement** | Respect des critères de l'Open Source Security Foundation (OpenSSF). | [![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/TUTODECODE-FR/T2DECODE/badge)](https://scorecard.dev/viewer/?uri=github.com/TUTODECODE-FR/T2DECODE) |
| **Anti-Tampering** | Vérification d'intégrité SHA-256 des assets au démarrage de l'application. | `IdentityVerificationService` |
| **Zéro Télémétrie** | Aucun appel API sortant (air-gapped par conception). RGPD strict. | [Politique Privacy](RGPD.md) |

<img src="assets/separator.svg" width="100%" height="4">

## 🎯 Raison d'Être de T2DECODE

T2DECODE est une **suite pédagogique et technique souveraine** conçue pour apprendre, expérimenter et diagnostiquer des infrastructures **sans aucune dépendance au cloud ni connexion Internet** :

- 📚 **Apprentissage Structuré** : Cours interactifs en Markdown/JSON avec QCM de validation des acquis et système de progression gamifié (XP & Badges).
- 🛠️ **Boîte à Outils Professionnelle** : Plus de 15 utilitaires de calcul, diagnostic et conversion fonctionnant entièrement en local.
- 🔬 **Laboratoires Virtuels (Simulateurs)** : Simulateurs interactifs de réseaux (NetKit), cryptographie, systèmes, cloud et algorithmique.
- 🛡️ **Souveraineté & Résilience** : Conçu spécifiquement pour opérer en environnements stricts (*air-gapped*, zones blanches, datacenters sécurisés).

<img src="assets/separator.svg" width="100%" height="4">

## 🛡️ Engagements & Architecture (Privacy by Design)

T2DECODE adopte un modèle de sécurité rigoureux, axé sur la souveraineté numérique et le respect absolu de l'utilisateur final.

```mermaid
flowchart TB
    subgraph Boot ["Phase d'Initialisation (Boot)"]
        Verify["Verificateur d'Integrite (AssetIntegrityService & SHA-256)"]
    end

    subgraph AppShell ["Conteneur Principal (App Shell & Navigation)"]
        direction TB
        UI["Interface Utilisateur (Flutter GUI)"]
        
        subgraph Features ["Modules Applicatifs"]
            direction LR
            Courses["Cours Interactifs (Progression & XP/Badges)"]
            Labs["Laboratoires (9 Simulateurs Réseau/Systèmes/Crypto)"]
            Tools["Boite a Outils (15+ Utilitaires Offline)"]
        end
    end

    subgraph LocalStorage ["Persistance Locale"]
        DB["Stockage et Preferences (StorageService)"]
    end

    subgraph localServices ["Services d'Arriere-plan Locaux"]
        subgraph AISubsystem ["Moteur d'IA (Ghost AI)"]
            Ollama["Connecteur Ollama (localhost:11434)"]
            LLM["Modeles LLM Locaux (Llama / Mistral / Phi)"]
        end
        
        subgraph NetworkSubsystem ["Reseau Decentralise (Ghost Link)"]
            P2P["Service P2P (Diffusion UDP LAN)"]
            Peers["Mesh de Pairs Chiffre (AES-GCM / ECDH)"]
        end
    end

    Verify -->|Validation de Securite OK| UI
    UI <-->|Interaction Utilisateur| Features
    
    UI <-->|Stockage Local Securise| DB
    Courses <-->|Sauvegarde Progression & Badges| DB
    
    UI <-->|Streaming HTTP Local| Ollama
    Ollama <-->|RAG sur le Contenu des Cours| LLM
    
    UI <-->|Echanges Directs| P2P
    P2P <-->|Decouverte & Chat P2P| Peers

    classDef default fill:#121212,stroke:#F5EBDA,stroke-width:1px,color:#F5EBDA;
    classDef primary fill:#000000,stroke:#F5EBDA,stroke-width:2px,color:#F5EBDA;
    classDef accent fill:#F5EBDA,stroke:#000000,stroke-width:1px,color:#000000;
    classDef container fill:#000000,stroke:#333333,stroke-width:1px,color:#FFFFFF;
    classDef security fill:#1b1510,stroke:#d4a373,stroke-width:1px,color:#d4a373;
    
    class UI primary;
    class Courses,Labs,Tools,DB,Ollama,P2P default;
    class LLM,Peers accent;
    class Verify security;
    class Boot,AppShell,LocalStorage,localServices container;
```

### Les 4 Piliers de l'Architecture Locale

1. ⚡ **100% Air-Gapped Ready** : Aucune connexion Internet requise après l'installation. L'application et tous ses modules sont autonomes.
2. 🧠 **IA & RAG Locaux (Ollama)** : Connecteur intégré de streaming HTTP vers votre instance locale Ollama. Accédez à un tuteur LLM privatif capable d'interroger directement vos cours (RAG).
3. 🌐 **Réseau LAN P2P (Ghost Link)** : *[En cours de développement]* Actuellement, l'interface visuelle est prête. À terme, ce module intégrera le réseau sous-jacent **T2C-Phantom** (développé en Go via libp2p) pour offrir une véritable messagerie instantanée décentralisée et chiffrée de bout en bout entre pairs d'un même sous-réseau, sans serveur central.
4. 🚫 **Zéro Télémétrie & Zéro Tracking** : Aucun appel réseau externe, aucun pistage (*analytics*), aucune collecte de données. L'intégrité de vos données est totale ([Politique RGPD](RGPD.md)).

### Modèle de Confiance
| Ce que nous faisons ✅ | Ce que nous ne faisons PAS ❌ |
| :--- | :--- |
| **Exécution 100% Locale** avec vérification d'intégrité SHA-256 des assets | **Pas d’API externe ni de cloud obligatoire** |
| **Isolation complète** et respect strict du [RGPD](RGPD.md) | **Pas d’analytics ni de cookies de pistage** |
| **Transparence totale** via des binaires open source et auditables | **Pas d’envoi de données de télémétrie vers des tiers** |

<img src="assets/separator.svg" width="100%" height="4">

## 👥 À Qui S'Adresse T2DECODE ?

- 🎓 **Étudiants & Autodidactes IT** : Acquisition de compétences solides en réseaux, administration Linux et sécurité défensive.
- 🧑‍💻 **Administrateurs Système & Réseau** : Utilitaires de diagnostic rapides (calculateurs IP, permissions chmod, générateurs CRON, tables de ports) utilisables sans accès réseau.
- 🕵️ **Auditeurs & Experts en Sécurité** : Interventions fiables et sécurisées dans des environnements isolés ou à diffusion restreinte (*datacenters*, salles blanches).
- 👨‍🏫 **Enseignants & Formateurs** : Plateforme pédagogique locale, reproductible et personnalisable grâce à l'importation de modules Markdown externes.

<img src="assets/separator.svg" width="100%" height="4">

## ⚡ Fonctionnalités Phares

| Fonctionnalité | Description | Documentation |
| :--- | :--- | :--- |
| 🧠 **Ghost AI (IA Locale)** | Tuteur conversationnel en streaming connecté à Ollama. Compatible Phi-3, Llama 3.2, Mistral, Qwen, CodeLlama. | [docs/ollama.md](docs/ollama.md) |
| 🔗 **Ghost Link (LAN P2P)** | **[WIP - En cours de développement]** Interface implémentée. À terme : Découverte automatique de pairs et chat chiffré via libp2p (T2C-Phantom) sans serveur central. | [docs/architecture.md](docs/architecture.md) |
| 🔬 **Laboratoires Intégrés** | 9 simulateurs interactifs : Réseau (NetKit), Système, Cloud, Cryptographie, Linux, Algorithmes et Préparation CTF. | [docs/labs.md](docs/labs.md) |
| 🛠️ **Multi-Outils Offline** | 15+ outils de productivité : Hash (SHA/MD5), CIDR IPv4/v6, Chmod, CRON, JSON Formatter, Base64, ASCII, Syslog, etc. | [docs/tools.md](docs/tools.md) |
| 🔒 **Sécurité au Démarrage** | Vérification automatique des sommes de contrôle SHA-256 (`assets/asset_checksums.json`) et protection anti-tampering. | [docs/security-model.md](docs/security-model.md) |

<img src="assets/separator.svg" width="100%" height="4">

## 📥 Téléchargements & Plateformes (v1.0.2)

➡️ [**Télécharger les binaires précompilés (Releases GitHub)**](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest)

| Plateforme | Format de Distribution | Statut CI | Accessibilité |
| :--- | :--- | :---: | :---: |
| ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) | **APK** / AAB (64-bit) | Actif | Disponible (v1.0.2) |
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white) | **ZIP** / Installateur EXE | Actif | Disponible (v1.0.2) |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white) | **[App Store](https://apps.apple.com/us/app/t2decode-plateforme/id6762523276?mt=12)** / PKG / ZIP Universel | Actif | Disponible (v1.0.2) |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) | **AppImage** / DEB (64-bit) | Actif | Disponible (v1.0.2) |

> 🔒 **Garantie d'intégrité** : Chaque version publiée s'accompagne d'un fichier de vérification `SHA256SUMS.txt` et de signatures cryptographiques pour authentifier la provenance des binaires.

<img src="assets/separator.svg" width="100%" height="4">

## 🖼️ Aperçu de l'Interface

L'interface de T2DECODE est conçue selon un design moderne (*Noir & Beige*, *Glassmorphism*, animations fluides) pour offrir une expérience de navigation d'excellence sur toutes les tailles d'écran.

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

## 👨‍💻 Environnement de Développement & Compilation

### 1. Dépendances Système Nécessaires

L'application reposant sur Flutter et des librairies natives (notamment pour le réseau et les fenêtres de bureau), assurez-vous d'installer les prérequis selon votre système d'exploitation :

- **Linux (Debian / Ubuntu)** :
  ```bash
  sudo apt-get update && sudo apt-get install -y clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
  ```
- **macOS** : `xcode-select --install`
- **Windows** : Git et Visual Studio 2022 avec la charge de travail *Développement Desktop en C++*.

> 📖 *Pour des instructions détaillées par distribution, consultez [OS_DEPENDENCIES.md](OS_DEPENDENCIES.md).*

### 2. Démarrage Rapide

```bash
# Clonage du dépôt officiel
git clone https://github.com/TUTODECODE-FR/T2DECODE.git
cd T2DECODE

# Vérification de l'environnement de build
make setup

# Installation des dépendances Flutter
make get

# Exécution de la suite de tests unitaires
make test

# Lancement de l'application en mode débogage
flutter run
```

### 🛠️ Automatisation des Tâches (Makefile)

Le projet intègre un `Makefile` complet pour faciliter la compilation sur l'ensemble des cibles :

```bash
make setup          # Diagnostic des dépendances (Flutter, Dart, Ollama)
make clean          # Nettoyage complet des répertoires de build
make test           # Lancement des tests automatisés
make build-android  # Construction de l'archive APK release
make build-macos    # Construction du binaire .app macOS
make build-dmg      # Création de l'image disque d'installation .dmg (macOS)
make build-linux    # Construction de l'exécutable natif Linux
```

<img src="assets/separator.svg" width="100%" height="4">

## 🏛️ L'Association TUTODECODE (Mentions Légales)

Le projet T2DECODE est développé et soutenu par l'**Association TUTODECODE**, structure relevant de l'Économie Sociale et Solidaire (ESS).  
Notre mission est de démocratiser la maîtrise des infrastructures informatiques et de la cybersécurité défensive en fournissant des outils souverains, auditable et respectueux de la vie privée.

Dans une démarche de transparence, l'association publie ses identifiants légaux officiels :

- **Éditeur** : Association Loi 1901 TUTO DECODE
- **Directeur de Publication** : Maxime MARTIN CIVET
- **SIREN** : 102 763 133
- **Site Web Officiel** : [https://tutodecode.org](https://tutodecode.org)
- **Preuve Légale** : [Annonce de création parue au Journal Officiel de la République Française (JOAFE)](https://www.journal-officiel.gouv.fr/pages/associations-detail-annonce/?q.id=id:202600110336)
- **Engagement de Confidentialité** : [Consulter notre Politique RGPD](RGPD.md)

> 💡 *L'intégralité de ces mentions légales et attestations est accessible directement depuis l'application via la section **Paramètres > Mentions Légales (JO)***.

<img src="assets/separator.svg" width="100%" height="4">

## 🤝 Contribuer & Normes Communautaires

T2DECODE est un bien commun open source construit par et pour sa communauté. Toutes les contributions sont chaleureusement accueillies !

### 📜 Standards et Santé du Projet (Community Health)
Dans une démarche de transparence professionnelle absolue, ce projet respecte les standards open source :
- 🛡️ **[Sécurité & Vulnérabilités (SECURITY.md)](SECURITY.md)** : Notre politique stricte de gestion des failles.
- ⚖️ **[Licence Libre (LICENSE)](LICENSE)** : Vos droits et obligations (GPLv3).
- 🤝 **[Code de Conduite (CODE_OF_CONDUCT.md)](CODE_OF_CONDUCT.md)** : Pour un environnement sain et inclusif.
- 📖 **[Guide de Contribution (CONTRIBUTING.md)](CONTRIBUTING.md)** : Comment ajouter des cours ou du code.
- 🏛️ **[Gouvernance (GOVERNANCE.md)](GOVERNANCE.md)** : Modèle de décision de l'association.
- 🆘 **[Support (SUPPORT.md)](SUPPORT.md)** : Où trouver de l'aide en cas de besoin.
- 🗺️ **[Roadmap & Profils (ROADMAP.md)](ROADMAP.md)** : Nos prochaines étapes et nos offres de missions ciblées.

### Comment nous aider ?
Consultez notre [CONTRIBUTING.md](CONTRIBUTING.md) pour découvrir comment :
- ⭐ **Soutenir le dépôt** en lui attribuant une étoile sur GitHub.
- 🐛 **Signaler des anomalies** ou suggérer des fonctionnalités via les *Issues*.
- 📝 **Créer ou enrichir des cours** (rédaction au format Markdown / QCM en JSON).
- 💻 **Développer de nouveaux outils** utilitaires en Dart/Flutter.

### 💖 Soutien Financier (Dons)
Si T2DECODE vous fait gagner du temps ou enrichit votre parcours professionnel, vous pouvez soutenir l'association TUTODECODE. Les dons servent exclusivement à pérenniser l'hébergement de nos services, le maintien des noms de domaine et la continuité de nos actions éducatives gratuites et sans publicité.
- ➡️ **[Faire un don sécurisé à l'association via HelloAsso](https://www.helloasso.com/associations/tutodecode)**

<img src="assets/separator.svg" width="100%" height="4">

## 🔐 Security

All commits in this repository are GPG-signed for authenticity.

<img src="assets/separator.svg" width="100%" height="4">

## 📄 Licence & Droits

Ce projet est distribué sous licence **[GNU General Public License v3.0 (GPLv3)](LICENSE)**.  

Un immense merci à tous les testeurs, développeurs, techniciens et passionnés qui participent à faire vivre ce projet ! 🌟
