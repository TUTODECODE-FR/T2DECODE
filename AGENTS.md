# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Commands

```bash
make get             # Install dependencies (flutter pub get)
make test            # Run all tests (flutter test)
make setup           # Check environment (Flutter, Dart, Ollama)
make clean           # Clean build artifacts

flutter run          # Run in debug mode
flutter test test/unit/search_provider_test.dart  # Run a single test

make build-android   # Build APK release
make build-macos     # Build macOS app
make build-linux     # Build Linux binary
make build-dmg       # Create DMG installer (macOS)
```

## Architecture

**Entry point**: `lib/main.dart` — initializes providers, routes, and `IdentityVerificationService` (asset integrity check on startup).

**State management**: `provider` package. Core providers:
- `SettingsProvider` (`lib/core/providers/`) — offline mode, Ollama URL/model, theme, security flags
- `CoursesProvider` (`lib/features/courses/providers/`) — course data, progress tracking, module updates
- `ShellProvider` (`lib/core/providers/`) — active route, title, breadcrumbs (updated by `AppRouteObserver`)
- `SearchProvider` (`lib/core/providers/`) — global search state

**Navigation**: Named routes defined in `main.dart` `onGenerateRoute`. `AppNavigator` holds a `GlobalKey<NavigatorState>`. `AppRouteObserver` hooks into route changes to update `ShellProvider`. Page transitions use `FadeThroughTransition`.

**Responsive shell** (`lib/widgets/app_shell.dart`): Desktop = fixed left sidebar + content + right panel; Tablet = collapsible drawer; Mobile = bottom nav + drawer. Sidebar has 9 items: Home, Tools, Cheat Sheets, NetKit, Chat IA, Settings, Roadmap, Lab, Ghost Link.

**Features** (`lib/features/`):
- `ghost_ai/` — Local LLM tutor via Ollama HTTP API (streaming). Default URL `http://localhost:11434`. Supports Phi-3, Llama 3.2, Qwen, Mistral, CodeLlama.
- `ghost_link/` — P2P LAN chat (UDP broadcast for peer discovery, encrypted messaging).
- `lab/` — 9 interactive simulators (Network, Security, System, Cloud, Cryptography, Internet, Linux, Algorithms, CTF Prep). Each simulator is a self-contained widget in `lib/features/lab/simulators/`.
- `tools/` — 15+ offline utility tools (hash, CIDR, ports, chmod, CRON, JSON formatter, etc.).
- `courses/` — Markdown-rendered courses with QCM, XP/badge gamification, RAG service, custom module import.
- `legal/` — Build verification and identity verification screens (SHA-256 asset checksums).

**Core services**:
- `StorageService` (`lib/core/services/`) — wraps `shared_preferences`
- `OllamaService` (`lib/features/ghost_ai/service/`) — HTTP streaming client for local LLM
- `ModuleService` / `GithubService` (`lib/core/services/`) — custom course module loading and update checks
- `AssetIntegrityService` (`lib/core/services/`) — verifies `assets/asset_checksums.json` on startup

**Security** (`lib/core/security/`): `IdentityVerification`, `BuildVerification`, `AntiTampering`, `SourceAuthentication`, `PlagiarismProtection`. These run at startup and protect asset/code integrity — do not remove or bypass them.

**Theme** (`lib/core/theme/app_theme.dart`): "Noir & Beige" (TutoDeCode.org). Primary background `#000000`, surface `#000000`, accent beige `#F5EBDA`. Category colors are neutral/muted (Network=tan, Security=gray, System=beige, Cloud=silver, Crypto=sand).

## Key Design Constraints

- **Fully offline / air-gapped**: No external APIs. All features must work without internet. Ollama runs locally. GhostLink operates on LAN only.
- **No analytics, no tracking**: Do not add any external telemetry or network calls to third-party services.
- **Assets**: `assets/courses.json`, `assets/cheat_sheets.json`, `assets/netkit_cheat_sheets.json`, `assets/manifest.json`, `assets/asset_checksums.json`, `assets/logo.png` must remain consistent with checksums.
- **Cross-platform**: Targets Android, iOS, macOS, Windows, Linux. Avoid platform-specific code without proper guards.
## Behavioral Rules (Quota Optimization)

- **Language**: Always respond in **French**, but keep code comments and variable names in English (Standard Flutter/Dart).
- **Concision**: Never rewrite an entire file. Provide only the modified code blocks (diffs) unless explicitly asked for the full file.
- **Tone**: Professional, direct, and solution-oriented. Skip polite fillers (e.g., "I hope this helps").
- **Efficiency**: If a request requires scanning more than 10 files, warn the user about potential token usage and suggest a targeted alternative.
- **Sovereignty**: If the user asks for a feature that requires an external API (Cloud), remind them of the "Zero Cloud" policy and suggest an offline/Ollama-based alternative.
- **No Red Dots**: When suggesting UI changes for Ghost AI availability, use neutral states (Grey/Blue) instead of error states (Red) to keep the UX inclusive for low-end devices.