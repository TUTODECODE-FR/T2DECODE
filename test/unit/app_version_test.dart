// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/app_version.dart';

void main() {
  test('kAppVersion correspond à la version de pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(kAppVersion, match!.group(1),
        reason: 'Mettre à jour lib/core/app_version.dart avec pubspec.yaml');
  });
}
