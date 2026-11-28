// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Locales bundled with the app, in the order they are offered.
const List<Locale> kBuiltInLocales = [
  Locale('fr'),
  Locale('en'),
  Locale('es'),
  Locale('de'),
  Locale('ar'),
  Locale('zh'),
];

/// Language codes the loader can actually serve: lowercase ISO 639, 2-3 letters.
final RegExp _languageCodePattern = RegExp(r'^[a-z]{2,3}$');

/// Returns the locale for a translation file [path], or null when the file
/// cannot be used.
///
/// `HybridAssetLoader` loads exactly `<languageCode>.json` and the app runs
/// with `useOnlyLangCode: true`, so only files named after a lowercase ISO 639
/// code (`^[a-z]{2,3}$`, e.g. `it.json`) are accepted. Other names such as
/// `pt_BR.json`, `IT.json`, `notes.json` or `fr.backup.json` could never be
/// loaded, and neither could deprecated codes such as `iw.json`, which
/// [Locale] maps to `he`. They are skipped with a [debugPrint] message and null
/// is returned. Paths without a `.json` extension (including a file named just
/// `.json`) return null silently.
///
/// [pathContext] selects the path syntax (defaults to the current platform),
/// so Windows paths can be parsed correctly and tested on any host.
Locale? localeFromFileName(String path, {p.Context? pathContext}) {
  final ctx = pathContext ?? p.context;
  if (ctx.extension(path) != '.json') return null;
  final code = ctx.basenameWithoutExtension(path);
  if (!_languageCodePattern.hasMatch(code)) {
    _logIgnored(
        ctx.basename(path), 'expected a lowercase language code, e.g. it.json');
    return null;
  }
  final locale = Locale(code);
  // Locale canonicalizes deprecated codes (iw -> he, in -> id, ...), and the
  // loader then looks for the canonical file name, so a deprecated name
  // could never be loaded.
  if (locale.languageCode != code) {
    _logIgnored(ctx.basename(path),
        'deprecated language code, rename it to ${locale.languageCode}.json');
    return null;
  }
  return locale;
}

/// The file name comes from a user-writable folder: [jsonEncode] escapes
/// control characters so a crafted name cannot forge or garble log lines.
void _logIgnored(String fileName, String reason) {
  debugPrint('Ignoring translation file ${jsonEncode(fileName)}: $reason');
}

/// Lists the built-in locales followed by one locale per usable `*.json` file
/// found directly in [translationsDir], without duplicates.
///
/// File names are interpreted by [localeFromFileName]; unusable files and
/// non-file entries are skipped and never stop the scan of the others. A
/// missing directory yields only the built-in locales. A listing error is
/// logged with [debugPrint] and the locales collected so far are returned.
Future<List<Locale>> discoverLocales(Directory translationsDir) async {
  final locales = kBuiltInLocales.toList();

  try {
    if (await translationsDir.exists()) {
      final files = await translationsDir.list().toList();
      for (final file in files) {
        if (file is File) {
          final loc = localeFromFileName(file.path);
          if (loc != null && !locales.contains(loc)) {
            locales.add(loc);
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Failed to scan local translations: $e');
  }
  return locales;
}
