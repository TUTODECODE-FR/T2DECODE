// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tutodecode/core/localization/locale_discovery.dart';

void main() {
  group('localeFromFileName', () {
    test('parses a POSIX path', () {
      expect(
        localeFromFileName('/home/me/Documents/T2DECODE/translations/it.json'),
        const Locale('it'),
      );
    });

    test('parses a Windows path with backslashes', () {
      expect(
        localeFromFileName(
          r'C:\Users\me\Documents\T2DECODE\translations\it.json',
          pathContext: p.windows,
        ),
        const Locale('it'),
      );
    });

    test('parses a Windows path with mixed separators', () {
      // What Directory.list() returns on Windows for a directory built as
      // '${docDir.path}/T2DECODE/translations'.
      expect(
        localeFromFileName(
          r'C:\Users\me\Documents/T2DECODE/translations\it.json',
          pathContext: p.windows,
        ),
        const Locale('it'),
      );
    });

    test('accepts three-letter language codes', () {
      expect(localeFromFileName('/t/fil.json'), const Locale('fil'));
    });

    test('returns null for files that are not .json', () {
      expect(localeFromFileName('/t/it.txt'), isNull);
      expect(localeFromFileName('/t/it'), isNull);
    });

    for (final name in [
      'pt_BR.json',
      'pt-BR.json',
      'IT.json',
      'notes.json',
      '.json',
      'fr.backup.json',
      'abcd.json',
      'a.json',
      // Deprecated codes: Locale maps them (iw -> he, in -> id, mo -> ro),
      // so the loader would look for a different file name.
      'iw.json',
      'in.json',
      'mo.json',
    ]) {
      test('returns null for unusable name "$name"', () {
        expect(localeFromFileName('/t/$name'), isNull);
      });
    }

    test('accepts the canonical code of a deprecated one', () {
      expect(localeFromFileName('/t/he.json'), const Locale('he'));
    });
  });

  group('discoverLocales', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tdc_locale_discovery');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> touch(String name) =>
        File(p.join(tempDir.path, name)).writeAsString('{}');

    test('returns exactly the built-in locales for a missing directory',
        () async {
      final result = await discoverLocales(
        Directory(p.join(tempDir.path, 'does_not_exist')),
      );

      expect(result, kBuiltInLocales);
    });

    test('built-ins come first in the documented order', () async {
      await touch('it.json');

      final result = await discoverLocales(tempDir);

      expect(
        result.take(6).map((l) => l.languageCode).toList(),
        ['fr', 'en', 'es', 'de', 'ar', 'zh'],
      );
    });

    test('adds a valid user locale after the built-ins', () async {
      await touch('it.json');

      final result = await discoverLocales(tempDir);

      expect(result, [...kBuiltInLocales, const Locale('it')]);
    });

    test('does not duplicate a built-in locale', () async {
      await touch('fr.json');

      final result = await discoverLocales(tempDir);

      expect(result, kBuiltInLocales);
    });

    test('ignores unusable file names', () async {
      for (final name in [
        'pt_BR.json',
        'IT.json',
        'notes.json',
        '.json',
        'readme.txt',
      ]) {
        await touch(name);
      }

      final result = await discoverLocales(tempDir);

      expect(result, kBuiltInLocales);
    });

    test('an unusable file does not stop the scan of the others', () async {
      // A file named exactly ".json" used to throw (empty language code) and
      // abort the whole scan, hiding every valid user translation.
      await touch('.json');
      await touch('it.json');

      final result = await discoverLocales(tempDir);

      expect(result, [...kBuiltInLocales, const Locale('it')]);
    });

    test('ignores a directory whose name looks like a locale file', () async {
      await Directory(p.join(tempDir.path, 'ru.json')).create();

      final result = await discoverLocales(tempDir);

      expect(result, kBuiltInLocales);
    });
  });
}
