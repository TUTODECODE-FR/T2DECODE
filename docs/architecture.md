# Architecture technique

## Vue d'ensemble
- Entrée principale : `lib/main.dart`
- Gestion d'état : `provider` (dossier `lib/core/providers/`)
- Navigation : routes nommées + `AppRouteObserver`
- Thème : `lib/core/theme/app_theme.dart`

## Couches principales
- **UI** : `lib/features/` et `lib/widgets/`
- **Services** : `lib/core/services/`
- **Sécurité** : `lib/core/security/`
- **Données** : assets JSON + stockage local (SharedPreferences)

## Sécurité et intégrité
- Vérification d'intégrité des assets au démarrage
- Protections anti-altération et vérifications d'identité
- Aucun service cloud requis
