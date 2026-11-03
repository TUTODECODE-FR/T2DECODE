// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tutodecode/core/services/module_service.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  late ModuleService moduleService;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('tdc_module_import');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    moduleService = ModuleService();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  String fixture(String name) =>
      File('test/fixtures/tdc/$name').readAsStringSync();

  group('TDC Studio course import', () {
    test(
        'imports python-scripting.tdc and bash-scripting.tdc into the course list',
        () async {
      final python = await moduleService.importModuleContent(
        fixture('python-scripting.tdc'),
      );
      final bash = await moduleService.importModuleContent(
        fixture('bash-scripting.tdc'),
      );

      expect(python.id, 'Python');
      expect(python.title, 'Scripts Python');
      expect(python.description.length, greaterThan(500));
      expect(python.description, contains('administration système'));
      expect(python.chapters, hasLength(10));
      expect(
        python.chapters.first.content,
        contains('#!/usr/bin/env python3'),
      );
      expect(python.chapters.first.codeBlocks, isNotNull);
      expect(python.chapters.first.codeBlocks!.single['language'], 'python');
      expect(
        python.chapters.first.codeBlocks!.single['code'],
        contains('platform.system'),
      );
      expect(python.chapters.first.quiz, isNotNull);
      expect(python.chapters.first.quiz!, hasLength(3));
      expect(python.chapters.first.quiz!.first.correctIndex, 2);
      expect(
        python.chapters.last.content,
        contains('Pour publier un dossier sur un dépôt distant'),
      );

      expect(bash.id, 'Bash');
      expect(bash.title, 'Scripts Bash');
      expect(bash.duration, '5h05');
      expect(bash.description.length, greaterThan(500));
      expect(bash.chapters, hasLength(10));
      expect(bash.chapters.first.quiz!.first.correctIndex, 1);
      final processes =
          bash.chapters.firstWhere((chapter) => chapter.id == 'processes');
      expect(processes.codeBlocks, isNotNull);
      expect(processes.codeBlocks!.single['language'], 'bash');
      expect(processes.codeBlocks!.single['code'], contains('grep -c'));
      expect(
        bash.chapters.last.title,
        'Chapitre 10 : automatiser git sans laisser fuiter le token',
      );
      expect(
        bash.chapters.last.content,
        contains('Pour publier un dossier sur un dépôt distant'),
      );

      final listed = await moduleService.loadExternalModules();
      expect(
          listed.map((course) => course.id), containsAll(['Python', 'Bash']));
      expect(ModuleService.courseAppearsInList(listed, python), isTrue);
      expect(ModuleService.courseAppearsInList(listed, bash), isTrue);
      expect(
        ModuleService.courseAppearsInList(const [], python),
        isFalse,
      );

      final pythonListed = listed.firstWhere((course) => course.id == 'Python');
      final bashListed = listed.firstWhere((course) => course.id == 'Bash');
      expect(pythonListed.title, 'Scripts Python');
      expect(bashListed.title, 'Scripts Bash');
      expect(pythonListed.chapters.first.content, contains('script Python'));
      expect(bashListed.chapters.first.content, contains('script Bash'));
      expect(pythonListed.keywords, contains('EXTERNAL'));
      expect(bashListed.keywords, contains('EXTERNAL'));
    });

    test('rejects a malformed module and leaves the course list empty',
        () async {
      expect(await moduleService.loadExternalModules(), isEmpty);

      expect(
        () => moduleService.importModuleContent('course "broken" { title: }'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => moduleService.importModuleContent('   \n'),
        throwsA(
          predicate<Exception>(
            (error) => error.toString().contains('Format de module invalide'),
          ),
        ),
      );
      expect(
        () => moduleService.importModuleContent('''
course "empty-course" {
  title: "Vide"
  description: "Rien à importer"
  category: linux
}
'''),
        throwsA(
          predicate<Exception>(
            (error) => error.toString().contains('Contenu vide'),
          ),
        ),
      );

      const blankChapter = '''
course "blank-chapter" {
  title: "Chapitre blanc"
  description: "Le chapitre n'a pas de texte"
  category: linux
  module "vide" {
    title: "Chapitre vide"
    content: """
    """
  }
}
''';
      expect(
        () => moduleService.importModuleContent(blankChapter),
        throwsA(
          predicate<Exception>(
            (error) => error.toString().contains('contenu vide'),
          ),
        ),
      );

      final oversized = 'A' * (ModuleService.maxDescriptionChars + 1);
      expect(
        () => moduleService.importModuleContent('''
course "too-long" {
  title: "Trop long"
  description: "$oversized"
  category: linux
  module "intro" {
    title: "Chapitre"
    content: """
Texte présent, mais la description dépasse la limite.
"""
  }
}
'''),
        throwsA(
          predicate<Exception>(
            (error) => error.toString().contains('Description trop longue'),
          ),
        ),
      );

      expect(await moduleService.loadExternalModules(), isEmpty);
    });
  });
}
