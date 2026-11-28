// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
//
// Home screen category chips (HOME-001): each chip must list the courses
// whose data `category` it stands for.

import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutodecode/core/providers/search_provider.dart';
import 'package:tutodecode/core/providers/settings_provider.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/features/ghost_link/service/ghost_link_service.dart';
import 'package:tutodecode/features/home/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Course> bundled;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'security_updates': false});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall call) async => null,
    );
    final fr = jsonDecode(
      File('assets/translations/fr.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    Localization.load(const Locale('fr'), translations: Translations(fr));
    bundled = await Course.loadAll('fr');
  });

  Future<void> pumpHome(WidgetTester tester, List<Course> courses) async {
    await tester.binding.setSurfaceSize(const Size(1280, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => CoursesProvider.seeded(courses),
          ),
          ChangeNotifierProvider(create: (_) => ShellProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          // Process-wide singleton: provide it without disposing it.
          ChangeNotifierProvider.value(value: GhostLinkService()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> selectChip(WidgetTester tester, String chipId) async {
    final chip = find.widgetWithText(ChoiceChip, chipId);
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump(const Duration(seconds: 2));
  }

  // The course grid: the only builder-based GridView on the home screen (the
  // tools grid uses GridView.count). Absent when the category shows its
  // "no course" message instead.
  final courseGrid = find.byWidgetPredicate(
    (w) => w is GridView && w.childrenDelegate is SliverChildBuilderDelegate,
  );

  // Text shown inside the course grid.
  Set<String> listedTitles(WidgetTester tester) {
    return tester
        .widgetList<Text>(
          find.descendant(of: courseGrid, matching: find.byType(Text)),
        )
        .map((t) => t.data)
        .whereType<String>()
        .toSet();
  }

  Set<String> titlesOf(List<Course> courses, String category) =>
      courses.where((c) => c.category == category).map((c) => c.title).toSet();

  group('bundled catalog', () {
    const chips = {
      'LINUX': 'linux',
      'RÉSEAU': 'network',
      'SÉCURITÉ': 'security',
    };
    chips.forEach((chipId, category) {
      testWidgets('$chipId lists every "$category" course and nothing else',
          (tester) async {
        final expected = titlesOf(bundled, category);
        expect(expected, isNotEmpty,
            reason: 'the bundled catalog has "$category" courses');

        await pumpHome(tester, bundled);
        await selectChip(tester, chipId);

        expect(find.textContaining('Aucun parcours dans la catégorie'),
            findsNothing);
        expect(courseGrid, findsOneWidget);
        final allTitles = bundled.map((c) => c.title).toSet();
        expect(listedTitles(tester).intersection(allTitles), expected);
      });
    });
  });

  // Seeded through CoursesProvider.seeded with the category values an import
  // could give; the .tdc import path itself is not exercised here.
  group('courses with custom categories (as an import would give)', () {
    Course course(String id, String category) => Course(
          id: id,
          title: 'Course $id',
          description: '',
          level: 'beginner',
          duration: '1h',
          category: category,
          keywords: const [],
          chapters: const [],
        );

    // Matching ignores case. A category equal to the chip id once upper-cased
    // (e.g. `cloud`, `crypto` from TDC_SPEC) keeps matching as before; the
    // English data ids `network` and `security` match their French chips.
    const cases = [
      ['LINUX', 'Linux'],
      ['CLOUD', 'cloud'],
      ['CRYPTO', 'crypto'],
      ['RÉSEAU', 'réseau'],
      ['RÉSEAU', 'Network'],
      ['SÉCURITÉ', 'SECURITY'],
    ];
    for (final c in cases) {
      final chipId = c[0];
      final category = c[1];
      testWidgets('$chipId lists a course with category "$category"',
          (tester) async {
        await pumpHome(tester, [course('a', category), course('b', 'other')]);
        await selectChip(tester, chipId);

        expect(courseGrid, findsOneWidget);
        expect(listedTitles(tester), contains('Course a'));
        expect(listedTitles(tester), isNot(contains('Course b')));
      });
    }
  });
}
