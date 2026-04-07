# 🚀 Release v1.0.3 — L'Automatisation au Service du Savoir

Cette version marque une étape historique pour **TUTODECODE**. Après une phase intense de refonte architecturale et de stabilisation, nous passons à un système de déploiement continu (CI/CD) automatisé et multi-plateforme.

### 🌟 Points Forts de la v1.0.3

*   **⚡ Ghost AI (IA Locale)** : Support optimisé pour **Ollama**. Interagissez avec vos modèles LLM favoris (Llama, Mistral, CodeGemma) sans aucune connexion Internet.
*   **📂 Modules Externes** : Vous pouvez désormais charger vos propres cours et tutoriels localement. La plateforme devient votre propre bibliothèque technique personnalisée.
*   **🛠️ NetKit & Labo** : Amélioration des outils de diagnostic réseau et des simulateurs de sécurité (SQL Injection, Handshake TCP).
*   **🎨 UI Premium & Cheat Sheets** : Refonte visuelle complète des fiches de mémos (Linux, Git, Docker, etc.) avec un design plus moderne et une meilleure lisibilité.
*   **⚙️ Paramètres Avancés** : Nouveau centre de configuration centralisé permettant une gestion fine de l'IA, de la vie privée et de l'interface.

### 🌍 Multi-Plateforme Native
Cette release propose pour la première fois des builds stables et automatisés pour :
*   📱 **Android** (APK)
*   💻 **Windows** (Executable ZIP)
*   🍎 **macOS** (App Bundle)
*   🐧 **Linux** (Tarball ready-to-use)
*   🍏 **iOS** (IPA de test)

---

### ❓ Pourquoi passer directement à la version 1.0.3 ?

Le saut de la version 1.0.1/1.0.2 directement à la **1.0.3** est une décision stratégique motivée par trois facteurs clés :

1.  **Réparation du Système de Build** : Les versions 1.0.1 et 1.0.2 ont servi de terrain d'expérimentation pour résoudre les erreurs de compilation complexes (notamment sur Android et macOS). La 1.0.3 est la première version à sortir d'un pipeline GitHub Actions **propre et 100% fonctionnel**.
2.  **Refonte de l'Architecture** : Plusieurs changements majeurs dans la structure des répertoires (déplacement des paramètres de configuration et service Ghost AI) justifiaient une nouvelle numérotation pour marquer une "rupture" positive avec les versions de développement précédentes.
3.  **Maturité Stable** : Plutôt que de sortir une 1.0.2 potentiellement incomplète, nous avons consolidé tous les travaux en cours (Modules Externes + UI + Build CI) dans un seul bloc stable et testé.

---
*Développé avec ❤️ par l'Association TUTODECODE.*
