# T2DECODE - Résumé des Outils de Sécurité (Défense en Profondeur)

Ce document répertorie l'ensemble des outils, scanners et règles de sécurité de niveau "militaire" implémentés dans la chaîne d'intégration continue (CI/CD) et au sein du code de l'application T2DECODE. Il garantit l'absence de portes dérobées, de failles de sécurité, d'injections ou de code malveillant.

---

## 1. Analyse de Sécurité & SAST (Static Application Security Testing)

- **Semgrep** : Scanne le code source Dart, Python et Shell à la recherche de vulnérabilités, d'injections et de failles logiques.
- **Audit de Fonctions Dangereuses (C/C++)** : Script d'analyse ciblant le code natif (NDK / Linux) pour bannir les fonctions sujettes aux dépassements de mémoire tampon (ex: `strcpy`, `gets`, `sprintf`).

## 2. Détection de Secrets et Fuites de Données

- **Gitleaks / Secret Scanner** : Scanne l'historique et le code source pour repérer les fuites de clés API, tokens JWT, clés privées ou identifiants sensibles hardcodés.

## 3. Sécurité de la Chaîne d'Approvisionnement (SCA & Supply Chain)

- **OSV-Scanner (par Google)** : Analyse `pubspec.lock` et les dépendances du projet par rapport aux bases de vulnérabilités connues (CVE) pour bloquer les versions vulnérables.
- **Trivy (par Aqua Security)** : Scanne l'ensemble du système de fichiers et des images Docker pour détecter les failles de sécurité de l'OS et des dépendances.
- **Audit Pubspec (Protocole HTTP)** : Vérifie qu'aucune dépendance n'est téléchargée via un protocole HTTP non chiffré.
- **Détection des Attaques "Trojan Source" (Bidi)** : Détecte les caractères de contrôle Unicode directionnels invisibles (CVE-2021-42574) pouvant masquer du code malveillant.

## 4. Sécurité de l'Infrastructure & Conteneurs (IaC)

- **Hadolint** : Linter pour les fichiers `Dockerfile` afin d'assurer que l'image Docker de compilation respecte les meilleures pratiques de sécurité (non-root, paquets fixés, etc.).

## 5. Renforcement des Binaires & Hardening

- **R8 / ProGuard (Android)** : Réduction du code (`isMinifyEnabled = true`, `isShrinkResources = true`) et obfuscation active des symboles Java/Kotlin.
- **Obfuscation Dart / Flutter** : Utilisation des drapeaux `--obfuscate --split-debug-info=build/debug-info` lors de la compilation des binaires pour complexifier la rétro-ingénierie (reverse engineering).

## 6. Analyse Mobile DAST & SAST Android

- **MobSF (Mobile Security Framework)** : Outil d'audit d'APK recommandé et intégré dans notre processus de release pour valider les configurations réseau, les autorisations, et déceler toute fuite d'information dans les fichiers SQLite/Dex avant publication sur F-Droid.

## 7. Anti-Malware & Zero-Trust Tamper Defense

- **ClamAV** : Scanner antivirus automatisé analysant le code et les artefacts générés.
- **Asset Integrity Service / Checksums SHA-256** : Contrôle des sommes de contrôle des assets (`assets/asset_checksums.json`) au démarrage de l'application.

## 8. Intégrité des Commits Git

- **DCO & Signature de Commits** : Obligation de signer chaque commit (`Signed-off-by`) et recommandation d'utilisation de clés GPG/SSH signées pour valider l'identité de l'auteur sur GitLab/GitHub.

---

## Intégration dans le Pipeline CI/CD

Tous ces outils sont exécutés automatiquement dans le fichier `.gitlab-ci.yml` lors des Merge Requests. La CI adopte une politique de **tolérance zéro** (Fail-Fast) : tout échec annule le build pour garantir que seul du code totalement sain est produit.
