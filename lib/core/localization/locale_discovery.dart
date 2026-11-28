// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
import 'dart:io';

import 'package:flutter/material.dart';

/// Locales bundled with the app, in the order they are offered.
const List<Locale> kBuiltInLocales = [
  Locale('fr'),
  Locale('en'),
  Locale('es'),
  Locale('de'),
  Locale('ar'),
  Locale('zh'),
];

/// Returns the locale for a translation file [path], or null when [path]
/// does not end with `.json`.
///
/// The code is the last `/`-separated segment with every `.json` removed.
Locale? localeFromFileName(String path) {
  if (!path.endsWith('.json')) return null;
  final code = path.split('/').last.replaceAll('.json', '');
  return Locale(code);
}

/// Lists the built-in locales followed by one locale per `*.json` file found
/// in [translationsDir], without duplicates.
///
/// A missing directory yields only the built-in locales. Any error is logged
/// with [debugPrint] and the locales collected so far are returned.
Future<List<Locale>> discoverLocales(Directory translationsDir) async {
  final locales = kBuiltInLocales.toList();

  try {
    if (await translationsDir.exists()) {
      final files = await translationsDir.list().toList();
      for (var file in files) {
        if (file is File) {
          final loc = localeFromFileName(file.path);
          if (loc != null && !locales.contains(loc)) {
            locales.add(loc);
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Erreur scan traductions locales: $e');
  }
  return locales;
}
