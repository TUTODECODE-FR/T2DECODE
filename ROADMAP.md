# 🗺️ Roadmap & Vision de T2DECODE

T2DECODE est en constante évolution pour devenir la plateforme de référence pour l'apprentissage hors ligne de la cybersécurité et des réseaux. Voici notre feuille de route pour l'année à venir.

## 🚀 Fonctionnalités à venir

### Phase 1 : Consolidation (En cours)
- [x] Refonte de l'interface graphique (Noir & Beige).
- [x] Intégration du LLM local interactif (Ghost AI).
- [x] Vérification de l'intégrité Air-Gapped (AssetChecksums).
- [ ] Optimisation des performances sur les architectures ARM natives (Linux/macOS).

### Phase 2 : T2C-Phantom & Réseau Décentralisé (Prochaine étape)
L'objectif majeur de cette phase est le développement du réseau sous-jacent pour la fonctionnalité Ghost Link.
- [ ] **T2C-Phantom** : Un réseau proxy décentralisé développé en **Go** utilisant **libp2p**.
- [ ] **Ghost Link (véritable P2P)** : Découverte de pairs dynamique et messagerie chiffrée de bout en bout sans serveur centralisé, s'appuyant sur T2C-Phantom.
- [ ] **Simulateur de Forensique** : Outils de base pour analyser des dumps réseau (.pcap) hors ligne.
- [ ] **Simulateur Cloud** : Apprendre la configuration IAM, les buckets AWS/GCP en environnement simulé local.
- [ ] **Nouvelle API pour modules** : Permettre à la communauté de créer des mini-outils (plugins) chargeables dynamiquement.

### Phase 3 : Interaction P2P Avancée
- [ ] Partage de progression et de cours via Ghost Link (LAN).
- [ ] Mode "CTF local" : Un utilisateur héberge des challenges, les autres s'y connectent via le réseau local P2P.

---

## 🎯 Profils Recherchés (Rejoignez l'association !)

Pour accélérer le développement de la plateforme et accomplir cette feuille de route, l'Association TUTODECODE a besoin d'expertises précises. Plutôt qu'un simple "Nous cherchons des contributeurs", voici des **missions très ciblées** pour lesquelles votre impact serait immédiat :

### 1. 🧑‍🏫 Créateurs de Contenu & Pédagogues (Markdown)
*Mission* : Nous avons besoin de personnes pour concevoir des modules d'apprentissage (Réseau, Cloud, Crypto, Linux). 
- **Compétence requise** : Bonne plume, pédagogie, maîtrise du Markdown.
- **Action immédiate** : Écrire un nouveau cours sur la Forensique ou Docker dans `assets/courses.json`.

### 2. 🛡️ Experts en Cybersécurité & Pentesters (CTF)
*Mission* : Concevoir des scénarios d'attaque/défense pour les simulateurs et créer des fiches réflexes professionnelles.
- **Compétence requise** : Expérience terrain (Blue/Red Team), OSINT, Web Sec.
- **Action immédiate** : Rédiger des "Cheat Sheets" techniques avancées pour le diagnostic sur le terrain.

### 3. 💻 Développeurs Dart / Flutter (Natif)
*Mission* : Améliorer les performances des modules et construire de nouveaux simulateurs interactifs.
- **Compétence requise** : Dart, Flutter, gestion d'état (Provider/Riverpod).
- **Action immédiate** : Contribuer à la création du futur **Simulateur Forensique** ou optimiser la gestion RAG de Ghost AI.

### 4. 🎨 Designers UI / UX & Accessibilité
*Mission* : Perfectionner l'interface "Dark Mode" pour la rendre ultra-intuitive sur Desktop et Mobile, et créer des animations micro-interactives.
- **Compétence requise** : Figma, Design System, sensibilité à l'accessibilité.
- **Action immédiate** : Proposer de nouvelles maquettes pour l'onglet "Outils" ou de nouveaux icônes SVG.

### 5. 🐧 Ingénieurs Systèmes & Réseaux (C++ / Rust / Scripts)
*Mission* : Maintenir les scripts de build pour l'intégration continue, packager l'application (Flatpak, AppImage, MSIX) et améliorer la détection réseau P2P UDP.
- **Compétence requise** : Bash, CMake, GitHub Actions, programmation bas niveau.
- **Action immédiate** : Améliorer la stabilité du script `build_linux_appimage.sh` ou optimiser la boucle réseau de *Ghost Link*.

**Vous vous reconnaissez dans un de ces profils ?** Lancez-vous en créant une *Issue* sur le dépôt ou contactez l'équipe principale.
