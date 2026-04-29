# AGENTS.md

Ce fichier fournit des instructions à Codex (Codex.ai/code) lors de la manipulation du code dans ce dépôt.

## Commandes

```bash
make get             # Installer les dépendances (flutter pub get)
make test            # Exécuter tous les tests (flutter test)
make setup           # Vérifier l'environnement (Flutter, Dart, Ollama)
make clean           # Nettoyer les artefacts de build

flutter run          # Exécuter en mode débogage
flutter test test/unit/search_provider_test.dart  # Exécuter un seul test

make build-android   # Construire la release APK
make build-macos     # Construire l'application macOS
make build-linux     # Construire le binaire Linux
make build-dmg       # Créer l'installateur DMG (macOS)
```

## Architecture

**Point d'entrée** : `lib/main.dart` — initialise les providers, les routes, et le `IdentityVerificationService` (vérification de l'intégrité des assets au démarrage).

**Gestion d'état** : package `provider`. Providers principaux :
- `SettingsProvider` (`lib/core/providers/`) — mode hors ligne, URL/modèle Ollama, thème, drapeaux de sécurité
- `CoursesProvider` (`lib/features/courses/providers/`) — données des cours, suivi de progression, mises à jour des modules
- `ShellProvider` (`lib/core/providers/`) — route active, titre, fil d'Ariane (mis à jour par `AppRouteObserver`)
- `SearchProvider` (`lib/core/providers/`) — état de la recherche globale

**Navigation** : Routes nommées définies dans `main.dart` `onGenerateRoute`. `AppNavigator` contient une `GlobalKey<NavigatorState>`. `AppRouteObserver` intercepte les changements de route pour mettre à jour `ShellProvider`. Les transitions de page utilisent `FadeThroughTransition`.

**Shell responsive** (`lib/widgets/app_shell.dart`) : Bureau = barre latérale gauche fixe + contenu + panneau droit ; Tablette = tiroir rétractable ; Mobile = navigation inférieure + tiroir. La barre latérale comporte 9 éléments : Accueil, Outils, Cheat Sheets, NetKit, Chat IA, Paramètres, Roadmap, Lab, Ghost Link.

**Fonctionnalités** (`lib/features/`) :
- `ghost_ai/` — Tuteur LLM local via l'API HTTP Ollama (streaming). URL par défaut `http://localhost:11434`. Supporte Phi-3, Llama 3.2, Qwen, Mistral, CodeLlama.
- `ghost_link/` — Chat P2P LAN (diffusion UDP pour la découverte de pairs, messagerie chiffrée).
- `lab/` — 9 simulateurs interactifs (Réseau, Sécurité, Système, Cloud, Cryptographie, Internet, Linux, Algorithmes, Préparation CTF). Chaque simulateur est un widget autonome dans `lib/features/lab/simulators/`.
- `tools/` — 15+ outils utilitaires hors ligne (hash, CIDR, ports, chmod, CRON, formateur JSON, etc.).
- `courses/` — Cours rendus en Markdown avec QCM, gamification par XP/badges, service RAG, importation de modules personnalisés.
- `legal/` — Écrans de vérification du build et de vérification d'identité (sommes de contrôle des assets SHA-256).

**Services principaux** :
- `StorageService` (`lib/core/services/`) — enveloppe `shared_preferences`
- `OllamaService` (`lib/features/ghost_ai/service/`) — client de streaming HTTP pour le LLM local
- `ModuleService` / `GithubService` (`lib/core/services/`) — chargement de modules de cours personnalisés et vérifications de mise à jour
- `AssetIntegrityService` (`lib/core/services/`) — vérifie `assets/asset_checksums.json` au démarrage

**Sécurité** (`lib/core/security/`) : `IdentityVerification`, `BuildVerification`, `AntiTampering`, `SourceAuthentication`, `PlagiarismProtection`. Ceux-ci s'exécutent au démarrage et protègent l'intégrité des assets et du code — ne les supprimez ni ne les contournez pas.

**Thème** (`lib/core/theme/app_theme.dart`) : "Noir & Beige" (TutoDeCode.org). Fond principal `#000000`, surface `#000000`, accent beige `#F5EBDA`. Les couleurs de catégories sont neutres/atténuées (Réseau=tan, Sécurité=gris, Système=beige, Cloud=argent, Crypto=sable).

## Contraintes de Conception Clés

- **Entièrement hors ligne / air-gapped** : Aucune API externe. Toutes les fonctionnalités doivent fonctionner sans Internet. Ollama s'exécute localement. GhostLink fonctionne uniquement sur LAN.
- **Aucune analyse (analytics), aucun tracking** : N'ajoutez aucune télémétrie externe ni d'appels réseau à des services tiers.
- **Assets** : `assets/courses.json`, `assets/cheat_sheets.json`, `assets/netkit_cheat_sheets.json`, `assets/manifest.json`, `assets/asset_checksums.json`, `assets/logo.png` doivent rester cohérents avec les sommes de contrôle.
- **Multi-plateforme** : Cible Android, iOS, macOS, Windows, Linux. Évitez le code spécifique à une plateforme sans les vérifications (guards) appropriées.

## Règles de Comportement (Optimisation des Quotas)

- **Langue** : Répondez toujours en **Français**, mais gardez les commentaires de code et les noms de variables en Anglais (Standard Flutter/Dart).
- **Concision** : Ne réécrivez jamais un fichier entier. Fournissez uniquement les blocs de code modifiés (diffs) sauf demande explicite du fichier complet.
- **Ton** : Professionnel, direct et orienté solution. Sautez les formules de politesse (ex: "J'espère que cela vous aide").
- **Efficacité** : Si une demande nécessite de scanner plus de 10 fichiers, avertissez l'utilisateur de l'utilisation potentielle des tokens et suggérez une alternative ciblée.
- **Souveraineté** : Si l'utilisateur demande une fonctionnalité qui nécessite une API externe (Cloud), rappelez-lui la politique "Zéro Cloud" et suggérez une alternative hors ligne/basée sur Ollama.
- **Pas de Points Rouges** : Lors de la suggestion de modifications d'UI pour la disponibilité de Ghost AI, utilisez des états neutres (Gris/Bleu) au lieu d'états d'erreur (Rouge) pour garder l'UX inclusive pour les appareils bas de gamme.