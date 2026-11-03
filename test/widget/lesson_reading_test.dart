// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/features/courses/screens/chapter_screen.dart';
import 'package:tutodecode/features/courses/widgets/lesson_reading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const apiTitle = "Une API c'est Quoi ? La Métaphore du Serveur de Restaurant";

  group('prepareLessonOpening', () {
    test('lifts the kicker and chapô of the restaurant lesson', () {
      const raw = '''
# L'API, c'est le Serveur au Restaurant

Tu es client dans un restaurant (ton application). Tu appelles le **serveur**.

```
Client (app mobile) → API REST → Base de données
```

## Les 4 Verbes HTTP : CRUD
''';
      final opening = prepareLessonOpening(raw, apiTitle);

      expect(opening.kicker, "L'API, c'est le Serveur au Restaurant");
      expect(opening.chapoMarkdown, contains('**serveur**'));
      expect(opening.bodyMarkdown, isNot(contains('Tu es client')));
      expect(opening.bodyMarkdown, contains('## Les 4 Verbes HTTP'));
      expect(opening.bodyMarkdown, isNot(contains('# L\'API')));
    });

    test('drops a level-1 heading that repeats the chapter title', () {
      const raw = '''
# Intro

Premier paragraphe du chapitre.

## Suite
''';
      final opening = prepareLessonOpening(raw, 'Intro');

      expect(opening.kicker, isNull);
      expect(opening.chapoMarkdown, 'Premier paragraphe du chapitre.');
      expect(opening.bodyMarkdown, startsWith('## Suite'));
    });

    test('keeps a blockquote and a code fence in the body', () {
      const raw = '''
# Situation

> Mise en situation réelle : le téléphone sonne.

```bash
ls -la
```
''';
      final opening = prepareLessonOpening(raw, 'Autre');

      expect(opening.kicker, 'Situation');
      expect(opening.chapoMarkdown, isEmpty);
      expect(opening.bodyMarkdown, startsWith('> Mise en situation'));
    });
  });

  group('lessonFenceIsCallout', () {
    test('treats arrow diagrams as callouts and real code as code', () {
      expect(lessonFenceIsCallout('Client → API REST → Base', null), isTrue);
      expect(lessonFenceIsCallout('{"status": "success"}', null), isFalse);
      expect(
        lessonFenceIsCallout('def run():\n    return 1', 'python'),
        isFalse,
      );
      expect(lessonFenceIsCallout('def run():\n    return 1', null), isFalse);
    });
  });

  group('ChapterScreen official lesson', () {
    late Course apiCourse;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async => null,
      );
      await _loadScreenshotFonts();
      final raw = await rootBundle.loadString('assets/courses/courses_fr.json');
      final list = json.decode(raw) as List<dynamic>;
      final map = list
          .cast<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .firstWhere((item) => item['id'] == 'api-rest');
      apiCourse = Course.fromMap(map);
    });

    testWidgets('renders the restaurant lesson without repeating the title', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      HttpOverrides.global = _RefusedHttpOverrides();
      addTearDown(() => HttpOverrides.global = null);

      final chapter = apiCourse.chapters.first;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => CoursesProvider.seeded(
                [apiCourse],
                courseId: apiCourse.id,
                chapterId: chapter.id,
              ),
            ),
            ChangeNotifierProvider(create: (_) => ShellProvider()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(
              backgroundColor: TdcColors.bg,
              body: RepaintBoundary(
                key: Key('lesson-capture'),
                child: ChapterScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(apiTitle), findsOneWidget);
      expect(find.text('Quiz obligatoire'), findsOneWidget);
      expect(find.text('Chapitre 1 sur 1'), findsOneWidget);
      expect(find.textContaining('Chapitre 1 / 0'), findsNothing);
      expect(find.textContaining('Chapitre 1 /'), findsNothing);
      expect(
        find.text("L'API, c'est le Serveur au Restaurant"),
        findsOneWidget,
      );
      expect(
        find.textContaining('Tu es client dans un restaurant'),
        findsOneWidget,
      );
      expect(find.text('REPÈRE'), findsWidgets);
      expect(find.textContaining('Client (app mobile)'), findsOneWidget);
      expect(find.text('Les 4 Verbes HTTP : CRUD'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.text('WEB'), findsOneWidget);
      expect(find.byKey(const Key('lesson-scroll-progress')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _saveCapture(tester, '/tmp/lesson_api_top.png');

      await tester.scrollUntilVisible(
        find.text('API REST complète avec FastAPI'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('API REST complète avec FastAPI'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _saveCapture(tester, '/tmp/lesson_api_scrolled.png');
    });

    testWidgets('counts chapters from the loaded course', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final course = Course(
        id: 'deux',
        title: 'Module deux chapitres',
        description: '',
        level: 'beginner',
        duration: '1h',
        category: 'linux',
        keywords: const ['linux'],
        chapters: const [
          CourseChapter(
            id: 'a',
            title: 'Premier',
            content: 'Texte du premier chapitre, assez court pour le chapô.',
            duration: '10min',
          ),
          CourseChapter(
            id: 'b',
            title: 'Second',
            content: '# Un autre angle\n\nLa suite tient en une phrase.',
            duration: '12min',
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => CoursesProvider.seeded(
                [course],
                courseId: course.id,
                chapterId: 'b',
              ),
            ),
            ChangeNotifierProvider(create: (_) => ShellProvider()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(
              backgroundColor: TdcColors.bg,
              body: ChapterScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Chapitre 2 sur 2'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Un autre angle'), findsOneWidget);
      expect(find.textContaining('La suite tient'), findsOneWidget);
      expect(find.textContaining('/ 0'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('frames the quiz without borrowing the lesson body', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final chapter = apiCourse.chapters.first;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            backgroundColor: TdcColors.bg,
            body: RepaintBoundary(
              key: const Key('lesson-quiz-capture'),
              child: OfficialLessonBody(
                course: apiCourse,
                chapter: chapter,
                quiz: const Text('Question fixture du quiz'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('QUIZ OBLIGATOIRE'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('QUIZ OBLIGATOIRE'), findsOneWidget);
      expect(find.text('Question fixture du quiz'), findsOneWidget);
      expect(find.textContaining('fonctionne hors ligne'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _saveCapture(
        tester,
        '/tmp/lesson_api_quiz.png',
        finder: find.byKey(const Key('lesson-quiz-capture')),
      );
    });
  });
}

Future<void> _loadScreenshotFonts() async {
  final aileron = FontLoader('Aileron')
    ..addFont(rootBundle.load('assets/fonts/Aileron-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/Aileron-Italic.otf'))
    ..addFont(rootBundle.load('assets/fonts/Aileron-SemiBold.otf'))
    ..addFont(rootBundle.load('assets/fonts/Aileron-Bold.otf'));
  await aileron.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(
      _fileFont(
        '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
  await icons.load();

  final mono = FontLoader('monospace')
    ..addFont(_fileFont('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'))
    ..addFont(
      _fileFont('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'),
    );
  await mono.load();
}

Future<ByteData> _fileFont(String path) async {
  final bytes = await File(path).readAsBytes();
  return ByteData.view(Uint8List.fromList(bytes).buffer);
}

class _RefusedHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _RefusedHttpClient();
}

class _RefusedHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return Future<HttpClientRequest>.error(const SocketException('refused'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      final name = invocation.memberName.toString();
      if (name.contains('Url') || name.contains('close')) {
        return Future<Object>.error(const SocketException('refused'));
      }
    }
    return null;
  }
}

Future<void> _saveCapture(
  WidgetTester tester,
  String path, {
  Finder? finder,
}) async {
  final target = finder ?? find.byKey(const Key('lesson-capture'));
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(target);
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
  });
  expect(File(path).lengthSync(), greaterThan(1000));
}
