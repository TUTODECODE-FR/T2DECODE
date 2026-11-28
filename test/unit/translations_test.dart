// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';
import 'dart:io';

// Localization/Translations are not exported publicly (see CODING_STANDARDS §4).
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

const _dir = 'assets/translations';
const _homeScreen = 'lib/features/home/screens/home_screen.dart';
const _pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};

/// Locales whose values are not maintained yet (T2D-004): missing keys are OK.
const _coreLocales = {'fr', 'en'};

List<File> _localeFiles() => Directory(_dir)
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.json'))
    .toList()
  ..sort((a, b) => a.path.compareTo(b.path));

String _lang(File f) => f.uri.pathSegments.last.replaceAll('.json', '');

Map<String, dynamic> _load(String lang) =>
    jsonDecode(File('$_dir/$lang.json').readAsStringSync())
        as Map<String, dynamic>;

/// True for a map whose keys are all CLDR plural forms (and non-empty).
bool _isPlural(Object? v) =>
    v is Map && v.isNotEmpty && v.keys.every(_pluralForms.contains);

/// Flattens a tree to dotted-path -> leaf value.
Map<String, Object?> _flatten(Object? node, [String prefix = '']) {
  final out = <String, Object?>{};
  if (node is Map) {
    node.forEach((k, v) =>
        out.addAll(_flatten(v, prefix.isEmpty ? '$k' : '$prefix.$k')));
  } else {
    out[prefix] = node;
  }
  return out;
}

/// Paths of all plural objects (path -> set of forms).
Map<String, Set<String>> _pluralObjects(Object? node, [String prefix = '']) {
  final out = <String, Set<String>>{};
  if (node is Map) {
    if (_isPlural(node)) {
      out[prefix] = node.keys.cast<String>().toSet();
    } else {
      node.forEach((k, v) =>
          out.addAll(_pluralObjects(v, prefix.isEmpty ? '$k' : '$prefix.$k')));
    }
  }
  return out;
}

final _placeholderRe = RegExp(r'\{(\w*)\}');

/// Placeholder tokens of a value, e.g. {'{n}', '{}'}.
Set<String> _placeholders(Object? v) => v is String
    ? _placeholderRe.allMatches(v).map((m) => m.group(0)!).toSet()
    : {};

/// Resolves a dotted path in the tree (null if absent).
Object? _resolve(Map<String, dynamic> tree, String path) {
  Object? cur = tree;
  for (final part in path.split('.')) {
    if (cur is Map && cur.containsKey(part)) {
      cur = cur[part];
    } else {
      return null;
    }
  }
  return cur;
}

List<String> _placeholderMismatches(
    Map<String, Object?> base, Map<String, Object?> other, String otherName) {
  final bad = <String>[];
  for (final k in other.keys) {
    if (!base.containsKey(k)) continue;
    final a = _placeholders(base[k]);
    final b = _placeholders(other[k]);
    if (a.length != b.length || !a.containsAll(b)) {
      bad.add(
          '$k: fr=${(a.toList()..sort())} $otherName=${(b.toList()..sort())}');
    }
  }
  return bad;
}

void main() {
  late Map<String, dynamic> fr;
  late Map<String, dynamic> en;

  setUpAll(() {
    fr = _load('fr');
    en = _load('en');
  });

  group('locale files are valid JSON objects', () {
    for (final f in _localeFiles()) {
      test('${f.path} parses to a JSON object', () {
        Object? decoded;
        try {
          decoded = jsonDecode(f.readAsStringSync());
        } catch (e) {
          fail('${f.path} is not valid JSON: $e');
        }
        expect(decoded, isA<Map>(), reason: '${f.path} must be a JSON object');
      });
    }
  });

  group('fr and en parity', () {
    test('fr and en have identical leaf key paths', () {
      final frKeys = _flatten(fr).keys.toSet();
      final enKeys = _flatten(en).keys.toSet();
      final missingInEn = (frKeys.difference(enKeys).toList()..sort());
      final extraInEn = (enKeys.difference(frKeys).toList()..sort());
      expect(missingInEn, isEmpty,
          reason: 'keys in fr but missing in en: $missingInEn');
      expect(extraInEn, isEmpty,
          reason: 'keys in en but missing in fr: $extraInEn');
    });

    test('shared leaves have identical placeholder sets in fr and en', () {
      final bad = _placeholderMismatches(_flatten(fr), _flatten(en), 'en');
      expect(bad, isEmpty,
          reason: 'placeholder mismatches:\n${bad.join('\n')}');
    });

    test('plural objects have zero/one/other and the same forms in fr and en',
        () {
      final frP = _pluralObjects(fr);
      final enP = _pluralObjects(en);
      final problems = <String>[];
      for (final entry in {'fr': frP, 'en': enP}.entries) {
        entry.value.forEach((path, forms) {
          final missing = {'zero', 'one', 'other'}.difference(forms);
          if (missing.isNotEmpty) {
            problems.add('${entry.key}:$path must contain at least '
                'zero, one and other; missing $missing (forms found: $forms)');
          }
        });
      }
      for (final path in {...frP.keys, ...enP.keys}) {
        final a = frP[path];
        final b = enP[path];
        if (a == null || b == null) {
          problems.add(
              '$path is a plural object only in ${a == null ? 'en' : 'fr'}');
        } else if (a.length != b.length || !a.containsAll(b)) {
          problems.add('$path forms differ: fr=$a en=$b');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });

  group('other locales (no orphans, placeholders match fr)', () {
    final others =
        _localeFiles().where((f) => !_coreLocales.contains(_lang(f)));
    for (final f in others) {
      final lang = _lang(f);
      test('$lang has no keys absent from fr and matching placeholders', () {
        final frFlat = _flatten(fr);
        final flat = _flatten(_load(lang));
        final orphans = flat.keys.where((k) => !frFlat.containsKey(k)).toList()
          ..sort();
        expect(orphans, isEmpty,
            reason: '$lang keys not present in fr: $orphans');
        final bad = _placeholderMismatches(frFlat, flat, lang);
        expect(bad, isEmpty,
            reason: '$lang placeholder mismatches:\n${bad.join('\n')}');
      });

      test('$lang plural objects have the same forms as fr', () {
        final frP = _pluralObjects(fr);
        final problems = <String>[];
        _pluralObjects(_load(lang)).forEach((path, forms) {
          final expected = frP[path];
          if (expected == null) {
            problems.add('$path is a plural object in $lang but not in fr');
          } else if (expected.length != forms.length ||
              !expected.containsAll(forms)) {
            problems.add('$path forms differ: fr=$expected $lang=$forms');
          }
        });
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });

  group('home_screen.dart key usage', () {
    // 'key'.tr( / "key".plural( ; whitespace/newlines allowed before the dot.
    final usage = RegExp(r'''(['"])([A-Za-z0-9_.]+)\1\s*\.(tr|plural)\(''');

    test('every literal .tr()/.plural() key resolves in fr and en', () {
      final src = File(_homeScreen).readAsStringSync();
      final calls = usage.allMatches(src).toList();
      expect(calls, isNotEmpty,
          reason: 'no literal .tr()/.plural() calls found in $_homeScreen');
      final problems = <String>{};
      for (final m in calls) {
        final key = m.group(2)!;
        final kind = m.group(3)!;
        for (final entry in {'fr': fr, 'en': en}.entries) {
          final v = _resolve(entry.value, key);
          final ok = v is String || (kind == 'plural' && _isPlural(v));
          if (!ok) {
            problems.add('${entry.key}: "$key" used with .$kind() -> '
                '${v == null ? 'missing' : v is Map ? 'object (not a valid target)' : 'unexpected ${v.runtimeType}'}');
          }
        }
      }
      expect(problems, isEmpty, reason: problems.toList().join('\n'));
    });
  });

  group('translation placeholders', () {
    test('no fr or en value contains the TODO(translator) marker', () {
      const marker = 'TODO(translator)';
      final offenders = <String>[];
      for (final entry in {'fr': fr, 'en': en}.entries) {
        _flatten(entry.value).forEach((k, v) {
          if (v is String && v.contains(marker)) {
            offenders.add('${entry.key}:$k');
          }
        });
      }
      offenders.sort();
      expect(offenders, isEmpty,
          reason: '${offenders.length} value(s) still contain $marker. '
              'First 20: ${offenders.take(20).toList()}');
    });
  });

  group('rendered home plurals', () {
    // Mirrors the call shapes in home_screen.dart. Runs with the app's
    // setting (ignorePluralRules: true) and with CLDR rules (false).
    for (final ignoreRules in [true, false]) {
      for (final lang in ['fr', 'en']) {
        final fr = lang == 'fr';

        String plural(
          String key,
          num n, {
          Map<String, String>? namedArgs,
          String? name,
          List<String>? args,
        }) =>
            Localization.instance
                .plural(key, n, namedArgs: namedArgs, name: name, args: args);

        group('$lang, ignorePluralRules=$ignoreRules', () {
          setUp(() {
            Localization.load(Locale(lang),
                translations: Translations(_load(lang)),
                ignorePluralRules: ignoreRules);
          });
          tearDown(() {
            Localization.load(const Locale('fr'),
                translations: Translations(_load('fr')));
          });

          test('home.chapters_done', () {
            final out = [0, 1, 2]
                .map((n) => plural('home.chapters_done', n, name: 'n'))
                .toList();
            expect(
                out,
                fr
                    ? [
                        '0 chapitre terminé',
                        '1 chapitre terminé',
                        '2 chapitres terminés'
                      ]
                    : [
                        '0 chapters completed',
                        '1 chapter completed',
                        '2 chapters completed'
                      ]);
          });

          for (final key in [
            'home.course_chapters_ratio',
            'home.progress.chapters_ratio'
          ]) {
            test('$key renders each count once', () {
              final arg =
                  key == 'home.progress.chapters_ratio' ? 'completed' : 'done';
              final out = [0, 1, 2]
                  .map((t) =>
                      plural(key, t, namedArgs: {arg: '0'}, name: 'total'))
                  .toList();
              expect(
                  out,
                  fr
                      ? [
                          '0 sur 0 chapitre',
                          '0 sur 1 chapitre',
                          '0 sur 2 chapitres'
                        ]
                      : [
                          '0 out of 0 chapters',
                          '0 out of 1 chapter',
                          '0 out of 2 chapters'
                        ]);
            });
          }

          test('home.sections.course_meta', () {
            final out = [0, 1, 2]
                .map((c) => plural('home.sections.course_meta', c,
                    namedArgs: {'category': 'LINUX'},
                    name: 'count',
                    args: const []))
                .toList();
            expect(
                out,
                fr
                    ? [
                        'LINUX · 0 chapitre',
                        'LINUX · 1 chapitre',
                        'LINUX · 2 chapitres'
                      ]
                    : [
                        'LINUX · 0 chapters',
                        'LINUX · 1 chapter',
                        'LINUX · 2 chapters'
                      ]);
          });

          test('home.sections.course_meta keeps a literal {} in the category',
              () {
            final out = plural('home.sections.course_meta', 5,
                namedArgs: {'category': 'WEB{}'},
                name: 'count',
                args: const []);
            expect(out, fr ? 'WEB{} · 5 chapitres' : 'WEB{} · 5 chapters');
          });
        });
      }
    }
  });
}
