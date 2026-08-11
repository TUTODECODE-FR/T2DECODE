# Cartographie de Sécurité OWASP MASVS — T2DECODE

Ce document établit la correspondance formelle entre l'architecture de sécurité de **T2DECODE** et le standard international **OWASP MASVS (Mobile Application Security Verification Standard)**.

Éditeur : **Association TUTODECODE** (Loi 1901, SIREN 102 763 133).  
Licence : **GNU General Public License v3.0 (GPLv3)**.

---

## 🛡️ Modèle de Menace & Threat Actors (Rappel du Périmètre)

T2DECODE est un laboratoire pédagogique d'ingénierie et un environnement d'apprentissage autonome 100% hors-ligne. Les risques principaux identifiés sont :

1. **Repackaging / Altération Malveillante** : Modification non autorisée des binaires APK/DMG/Deb par des tiers malveillants ré-utilisant la marque de l'association.
2. **Attaques de la Chaîne d'Approvisionnement (Supply Chain)** : Infiltration de paquets malveillants ou typosquatting sur les registres de dépendances.
3. **Plagiat et Falsification des Attestations** : Altération du manifeste d'intégrité des cours et des ressources pédagogiques.

---

## 📊 Matrice de Conformité OWASP MASVS

| Exigence MASVS | Domaines & Contrôles MASVS | Implémentation T2DECODE | Statut |
| :--- | :--- | :--- | :---: |
| **MASVS-STORAGE** | Stockage sécurisé des données locales & zéro fuite mémoire | `StorageService` (SharedPreferences isolées), zéro stockage en clair de clés secrètes, aucune donnée transmise au cloud. | ✅ **Conforme** |
| **MASVS-CRYPTO** | Cryptographie forte & pas d'algorithmes obsolètes | Seuls SHA-256 et chiffrement fort sont exploités pour la validation des signatures d'assets et les transactions LAN GhostLink. | ✅ **Conforme** |
| **MASVS-AUTH** | Authentification & Contrôle d'Accès local | Mode local souverain sans identifiants externes. Verrouillage pédagogique des modules par validation QCM. | ✅ **Conforme** |
| **MASVS-NETWORK** | Sécurité des communications & isolation réseau | Architecture Air-gapped (100% Hors-ligne). Interdiction stricte des requêtes HTTP distantes en prod. Binding localhost pour Ghost AI. | ✅ **Conforme** |
| **MASVS-PLATFORM** | Interaction sécurisée avec la plateforme OS | Utilisation minimale des permissions Android/Linux/macOS. Protection contre les composants exportés non sécurisés. | ✅ **Conforme** |
| **MASVS-CODE** | Qualité du code, dépendances & Build CI/CD | `Gitleaks`, `Semgrep SAST`, `Google OSV-Scanner`, `Trivy`, `Yamllint`, `ShellCheck`, `flutter analyze`, `verify_checksums.py`. | ✅ **Conforme** |
| **MASVS-RESILIENCE**| Anti-Tampering, Anti-Reversing & Intégrité | `AssetIntegrityService`, `BuildVerification`, `AntiTampering`, `IdentityVerification`, `SourceAuthentication`, `PlagiarismProtection`. | ✅ **Conforme** |

---

## 🔍 Outils d'Audit d'Intégrité Associés

* **Analyse Statique & SAST** : `Semgrep`, `Trivy`, `Gitleaks`.
* **Vérification Runtime** : `AssetIntegrityService` à l'initialisation dans `lib/main.dart`.
* **Audit des Dépendances** : `osv-scanner` et `pubspec.lock` HTTPS enforcement.
