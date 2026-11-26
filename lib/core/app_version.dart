// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

/// Version complète de l'application : `X.Y.Z` (grande version) ou
/// `X.Y.Z.K` (petite version), suivie du numéro de build `+B`.
/// pubspec.yaml n'accepte que `X.Y.Z+B` : même X.Y.Z et même B
/// (vérifié par test/unit/app_version_test.dart).
/// Mise à jour par scripts/nouvelle-version.sh.
const String kAppVersion = '1.0.8.2+41';

/// Version affichée (sans le numéro de build), ex. 1.0.7.1.
String get kAppVersionName => kAppVersion.split('+').first;
