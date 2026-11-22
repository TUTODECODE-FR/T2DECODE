// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/app_version.dart';

void main() {
  test('kAppVersion cohérent avec pubspec.yaml (X.Y.Z et build)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final p = RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$', multiLine: true)
        .firstMatch(pubspec);
    expect(p, isNotNull, reason: 'pubspec.yaml : version X.Y.Z+B attendue');
    final a =
        RegExp(r'^(\d+\.\d+\.\d+)(\.\d+)?\+(\d+)$').firstMatch(kAppVersion);
    expect(a, isNotNull, reason: 'kAppVersion : X.Y.Z+B ou X.Y.Z.K+B attendu');
    expect(a!.group(1), p!.group(1),
        reason: 'Même X.Y.Z dans lib/core/app_version.dart et pubspec.yaml');
    expect(a.group(3), p.group(2),
        reason:
            'Même numéro de build dans lib/core/app_version.dart et pubspec.yaml');
  });
}
