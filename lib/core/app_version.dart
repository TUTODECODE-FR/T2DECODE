// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

/// Version de l'application, identique à `version:` de pubspec.yaml
/// (vérifié par test/unit/app_version_test.dart). À changer avec pubspec.yaml
/// à chaque version.
const String kAppVersion = '1.0.7+38';

/// Version affichée (sans le numéro de build).
String get kAppVersionName => kAppVersion.split('+').first;
