<p align="center">
  <img src="assets/TDC.png" width="96" height="96" alt="TUTODECODE Logo">
</p>

# TUTODECODE — Écosystème IT & Cybersécurité Souverain

[![CI](https://github.com/TUTODECODE-FR/TUTODECODE/actions/workflows/ci.yml/badge.svg)](https://github.com/TUTODECODE-FR/TUTODECODE/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/TUTODECODE-FR/TUTODECODE?style=for-the-badge)](https://github.com/TUTODECODE-FR/TUTODECODE/releases/latest)
[![License](https://img.shields.io/github/license/TUTODECODE-FR/TUTODECODE?style=for-the-badge)](https://github.com/TUTODECODE-FR/TUTODECODE/blob/main/LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-multi--platform-blue?style=for-the-badge)](https://flutter.dev)

> **"Le savoir technique ne devrait jamais dépendre d'une connexion."**

TUTODECODE est une plateforme d'apprentissage technique et une boîte à outils de cybersécurité conçue pour les étudiants et professionnels de l'IT. L'écosystème fonctionne de manière **100% isolée** (Air-Gapped ready) pour garantir une souveraineté numérique totale.

---

## ✅ État actuel du projet

Fonctionnalités actuellement disponibles :

- [x] Application Flutter multi-plateforme
- [x] Exécution locale sans cloud
- [x] Intégration Ollama locale
- [x] Modules de contenu Markdown/JSON
- [x] Outils offline intégrés
- [ ] Import/export avancé des modules
- [ ] Synchronisation de contenus signés
- [ ] Store communautaire offline-first

## 🧭 Plateformes (CI / tests / distribution)

| Plateforme | Build CI | Test manuel | Distribution |
| :--- | :---: | :---: | :---: |
| Android | ⚠️ | ⚠️ | ✅ |
| Windows | ⚠️ | ⚠️ | ✅ |
| macOS | ⚠️ | ⚠️ | ✅ |
| Linux | ⚠️ | ⚠️ | ✅ |
| Web | ⚠️ | ⚠️ | ⚠️ |
| iOS | ⚠️ | ⚠️ | ⚠️ |

> Les statuts sont mis à jour à chaque release. Si un artefact manque, il n'est pas marqué ✅.

---

## 📥 Téléchargements

Les binaires sont publiés sur la page des releases GitHub :

➡️ **[Télécharger la dernière version](https://github.com/TUTODECODE-FR/TUTODECODE/releases/latest)**

| Plateforme | Fichier recommandé | Alternatives | Notes |
| :--- | :--- | :--- | :--- |
| ![Android](https://img.shields.io/badge/Android-3DDC84?style=flat-square&logo=android&logoColor=white) | **APK** | AAB | Installation manuelle possible |
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat-square&logo=windows&logoColor=white) | **EXE** | ZIP | Installation classique |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=flat-square&logo=apple&logoColor=white) | **PKG** | DMG, ZIP | Signature selon release |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black) | **AppImage** | DEB, TAR.GZ | FUSE peut être requis |

### Vérification d'intégrité

Un fichier `SHA256SUMS.txt` est publié dans chaque release pour vérifier l'intégrité des binaires.

---

## ⚡ Pourquoi TUTODECODE ?

* **🛡️ Souveraineté Totale** : Aucune dépendance à des services tiers ou au Cloud. Tout est stocké et exécuté localement.
* **📂 Système de Modules** : Importez vos propres cours au format Markdown/JSON en les glissant dans le dossier `modules`.
* **🎨 Interface Moderne** : Une expérience fluide développée avec **Flutter**, optimisée pour la lisibilité du code.
* **📜 Mode Air-Gapped** : Idéal pour les interventions en zone sécurisée, datacenters ou zones blanches.

## 🤖 IA locale (Ollama)

Tout le traitement IA est local : aucune donnée n'est envoyée vers un service tiers.  
Guide : `docs/ollama.md`.

---

## 🏛️ Souveraineté Numérique & Engagement Associatif

TUTODECODE est le projet phare de l'**Association TUTODECODE**, organisme d'intérêt général relevant de l'Économie Sociale et Solidaire (ESS).

* **SIREN** : 102 763 133
* **Site Officiel** : [www.tutodecode.org](https://www.tutodecode.org)
* **Mission** : Diffusion gratuite et universelle du savoir technique.
* **Confidentialité** : Zéro Analytics, Zéro Tracking, Zéro Télémétrie.
* **Code Source** : Publié sous licence **GPLv3** pour garantir la pérennité du logiciel libre.

---

## ✨ Fonctionnalités

- [Laboratoires interactifs](docs/labs.md)
- [Outils offline](docs/tools.md)
- [Modules pédagogiques](docs/modules.md)
- [Architecture technique](docs/architecture.md)
- [Modèle de sécurité](docs/security-model.md)

---

## 🔒 Confidentialité

TUTODECODE n'envoie aucune télémétrie, aucun analytics et aucune donnée utilisateur vers un service tiers.  
Détails : `docs/privacy.md`.

---

## 👨‍💻 Développement

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

---

## 📚 Documentation

- `docs/build.md`
- `docs/release.md`
- `docs/ollama.md`
- `docs/security-model.md`

---

## 🤝 Contribuer

Voir `CONTRIBUTING.md`.

---

## 🗺️ Roadmap

### v1.0.x
- Stabilisation multi-plateforme
- Finalisation des packages de distribution
- Durcissement CI/CD
- Documentation technique

### v1.1
- Gestion avancée des modules pédagogiques
- UX améliorée des laboratoires
- Catalogue d’outils offline enrichi

### v1.2
- Signatures et vérifications renforcées
- Meilleure intégration locale Ollama
- Documentation utilisateur complète

---

## 📄 Licence

GPLv3
