<p align="center">
  <img src="assets/TDC.png" width="96" height="96" alt="TUTODECODE Logo">
</p>

# TUTODECODE — Écosystème IT & Cybersécurité Souverain

[![Offline First](https://img.shields.io/badge/Offline-100%25-0f1218?style=for-the-badge&label=MODE)](https://github.com/TUTODECODE-FR/TUTODECODE)
[![Zero Cloud](https://img.shields.io/badge/Z%C3%A9ro-Cloud-0f1218?style=for-the-badge&label=SOUVERAINET%C3%89)](https://github.com/TUTODECODE-FR/TUTODECODE)
[![Local AI](https://img.shields.io/badge/IA-Locale-00D9C0?style=for-the-badge&label=GHOST%20AI)](https://github.com/TUTODECODE-FR/TUTODECODE)
[![Cross Platform](https://img.shields.io/badge/Cross--Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-0f1218?style=for-the-badge)](https://github.com/TUTODECODE-FR/TUTODECODE)

> **"Le savoir technique ne devrait jamais dépendre d'une connexion."**

TUTODECODE est une plateforme d'apprentissage technique et une boîte à outils de cybersécurité conçue pour les étudiants et professionnels de l'IT. L'écosystème fonctionne de manière **100% isolée** (Air-Gapped ready) pour garantir une souveraineté numérique totale.

---

### 📥 Téléchargements (dernière version)

| Plateforme | Binaire | Statut |
| :--- | :--- | :--- |
| ![Android](https://img.shields.io/badge/Android-3DDC84?style=flat-square&logo=android&logoColor=white) | [**Fichier APK**](https://github.com/TUTODECODE-FR/TUTODECODE/releases/latest) | `Stable` |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=flat-square&logo=apple&logoColor=white) | [**Installer PKG**](https://github.com/TUTODECODE-FR/TUTODECODE/releases/latest) | `Signé` |
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat-square&logo=windows&logoColor=white) | [**Installeur EXE**](https://github.com/TUTODECODE-FR/TUTODECODE/releases/latest) | `Disponible` |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black) | [**AppImage**](https://github.com/TUTODECODE-FR/TUTODECODE/releases/latest) | `FOSS` |

---

## ⚡ Pourquoi choisir TUTODECODE ?

* **🛡️ Souveraineté Totale** : Aucune dépendance à des services tiers ou au Cloud. Tout est stocké et exécuté localement.
* **📂 Système de Modules** : Importez vos propres cours au format Markdown/JSON en les glissant dans le dossier `modules`.
* **🎨 Interface Moderne** : Une expérience fluide développée avec **Flutter**, optimisée pour la lisibilité du code.
* **📜 Mode Air-Gapped** : Idéal pour les interventions en zone sécurisée, datacenters ou zones blanches.

## 🤖 Ghost AI (Intelligence 100% Locale)

L'atout majeur de TUTODECODE est son intégration native avec **Ollama**. 
Vous pouvez interroger un tuteur IA (Llama 3, Mistral, Phi-3) directement dans l'application. **Aucun octet ne quitte votre machine**, l'intelligence est traitée par votre processeur/GPU local.

---

## 🏛️ Souveraineté Numérique & Engagement Associatif

TUTODECODE est le projet phare de l'**Association TUTODECODE**, organisme d'intérêt général relevant de l'Économie Sociale et Solidaire (ESS).

* **SIREN** : 102 763 133
* **Site Officiel** : [www.tutodecode.org](https://www.tutodecode.org)
* **Mission** : Diffusion gratuite et universelle du savoir technique.
* **Confidentialité** : Zéro Analytics, Zéro Tracking, Zéro Télémétrie.
* **Code Source** : Publié sous licence **GPLv3** pour garantir la pérennité du logiciel libre.

---

## 🧪 Laboratoires de Simulation Interactifs

8 simulateurs pédagogiques pour comprendre la tech par l'expérimentation :

| Lab | Scénarios inclus |
|---|---|
| 🌐 **Réseau** | Scan de ports, Ping, Traceroute, Capture de paquets (Sniffing) |
| 🛡️ **Sécurité** | Vulnérabilités OWASP, Pentest, simulations IDS/IPS |
| ⚙️ **Système** | Gestion des processus, Services systemd, Monitoring I/O |
| ☁️ **Cloud** | Conteneurs Docker, Orchestration Kubernetes, CI/CD |
| 🔐 **Crypto** | Chiffrement AES/RSA, Hachage SHA-256, Signatures numériques |
| 🌍 **Internet** | Protocoles DNS, Handshake TCP, TLS 1.3, Routage BGP/NAT |
| 🐧 **Linux** | Boot BIOS/UEFI, Filesystem (inodes), Bash Scripting |
| 🧮 **Algorithmes** | Complexité Big-O, Graphes, Systèmes distribués |

---

## 🛠️ Boîte à Outils (15+ outils offline)

* **Réseau** : Calculateur CIDR, Référence de ports, Scanner local.
* **Sécurité** : Générateur de clés, Hasher (MD5, SHA), Encodeur Base64.
* **Système** : Calculateur Chmod, CRON Builder, RAID Simulator.
* **Dev** : JSON Formatter, Table ASCII, Générateur de scripts Bash.

---

## 👨‍💻 Pour les Développeurs (Quick Start)

Pour compiler le projet localement :

1. **Prérequis** : Flutter SDK installé (et `make` disponible).
2. **Installation** :
   ```bash
   git clone https://github.com/TUTODECODE-FR/TUTODECODE.git
   cd TUTODECODE
   make get
   ```
3. **Tests** :
   ```bash
   make test
   ```
4. **Lancer l’app** :
   ```bash
   flutter run
   ```

### 🔧 Commandes utiles

```bash
make setup          # Vérifie l’environnement (Flutter, Dart, Ollama)
make clean          # Nettoie les artefacts
make build-android  # Build APK release
make build-macos    # Build macOS app
make build-linux    # Build Linux binary
make build-dmg      # Création DMG (macOS)
```

### 🔒 Règles de souveraineté

TUTODECODE est conçu pour fonctionner **sans Internet** : aucune API externe, aucune télémétrie, aucun tracking. Toutes les fonctions IA s’appuient sur **Ollama en local**.
