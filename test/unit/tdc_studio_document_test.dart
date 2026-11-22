// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/services/tdc_dsl_parser.dart';
import 'package:tutodecode/core/services/tdc_studio_document.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';

void main() {
  const minimalStudioCourse = '''
tdc-version: 2
type: course

course "mini" {
  title: "Mini"
  description: "Document TDC Studio minimal"
  category: linux
  level: beginner
  duration: 15min

  module "intro" {
    title: "Introduction"
    duration: 5min
    content """
    Bonjour
    """
  }
}
''';

  const fakeTdc = 'Notes personnelles renommees en .tdc\n';

  group('TDC Studio hierarchy', () {
    test('accepts a minimal TDC Studio document', () {
      final decision = TdcOpenDecision.decide(
        minimalStudioCourse,
        namedTdc: true,
        allowLegacyPayloads: false,
      );

      expect(decision.rejected, isFalse);
      expect(decision.importCourse, isTrue);
      expect(decision.document, isNotNull);
      expect(decision.document!.version, '2');
      expect(decision.document!.type, 'course');
      expect(decision.document!.id, 'mini');
      expect(decision.document!.title, 'Mini');

      final map = TdcDslParser.parse(minimalStudioCourse);
      expect(map['id'], 'mini');
      expect(map['title'], 'Mini');
      expect(map['description'], 'Document TDC Studio minimal');
      expect(map['category'], 'linux');

      final course = Course.fromMap(map);
      expect(course.id, 'mini');
      expect(course.title, 'Mini');
      expect(course.chapters, hasLength(1));
      expect(course.chapters.single.id, 'intro');
      expect(course.chapters.single.title, 'Introduction');
      expect(course.chapters.single.content, contains('Bonjour'));
    });

    test('rejects a file whose only TDC trait is the .tdc extension', () {
      final inspection = TdcStudioDocument.inspect(fakeTdc);
      final decision = TdcOpenDecision.decide(
        fakeTdc,
        namedTdc: true,
        allowLegacyPayloads: false,
      );

      expect(inspection.accepted, isFalse);
      expect(inspection.document, isNull);
      expect(inspection.rejection, TdcStudioDocument.notStudioMessage);
      expect(decision.rejected, isTrue);
      expect(decision.importCourse, isFalse);
      expect(decision.document, isNull);
      expect(decision.message, contains(".tdc"));
      expect(decision.message, contains("n'est pas un document TDC Studio"));
    });

    test('rejects a root block that does not match the declared type', () {
      const mismatch = '''
tdc-version: 2
type: course

cheat_sheet "hydra" {
  title: "Hydra"
  category: red_team

  entry "ssh" {
    command: "hydra"
    description: "Test"
  }
}
''';
      const illegalChild = '''
tdc-version: 2
type: course

course "mini" {
  title: "Mini"
  description: "Court"
  category: linux

  entry "nope" {
    command: "ls"
    description: "pas un module"
  }
}
''';

      final mismatchDecision = TdcOpenDecision.decide(
        mismatch,
        namedTdc: true,
        allowLegacyPayloads: false,
      );
      final illegalDecision = TdcOpenDecision.decide(
        illegalChild,
        namedTdc: true,
        allowLegacyPayloads: false,
      );

      expect(mismatchDecision.importCourse, isFalse);
      expect(mismatchDecision.rejected, isTrue);
      expect(mismatchDecision.message, contains('hiérarchie'));
      expect(mismatchDecision.message, contains('course'));
      expect(illegalDecision.importCourse, isFalse);
      expect(illegalDecision.rejected, isTrue);
      expect(illegalDecision.message, contains('entry'));
    });

    test('loads a studio course with codeblock and signed quiz choices', () {
      const source = '''
// TUTODECODE Course — format .tdc v2
tdc-version: 2
type: course

course "intro-linux" {
  title: "Linux"
  description: "Commandes de base"
  category: linux
  level: beginner
  duration: 2h
  icon: Terminal

  module "diag" {
    title: "Diagnostic"
    duration: 15min

    content """
    # Incident
    Connexion SSH.
    """

    codeblock "bash" {
      title: "Audit mémoire"
      code """
      free -h
      """
    }

    quiz {
      question "Quelle commande affiche la mémoire ?" {
        - "whoami"
        + "free -h"
        explanation: "free -h affiche la RAM."
      }
    }
  }
}
''';

      final decision = TdcOpenDecision.decide(
        source,
        namedTdc: true,
        allowLegacyPayloads: false,
      );
      expect(decision.importCourse, isTrue);

      final map = TdcDslParser.parse(source);
      final course = Course.fromMap(map);
      expect(course.id, 'intro-linux');
      expect(course.chapters.single.content, contains('Incident'));
      expect(course.chapters.single.codeBlocks, isNotNull);
      expect(course.chapters.single.codeBlocks!.single['language'], 'bash');
      expect(course.chapters.single.codeBlocks!.single['code'],
          contains('free -h'));
      final question = course.chapters.single.quiz!.single;
      expect(question.choices, ['whoami', 'free -h']);
      expect(question.correctIndex, 1);
      expect(question.explanation, 'free -h affiche la RAM.');
    });

    test('accepts a cheat sheet without importing it as a course', () {
      const sheet = '''
tdc-version: 2
type: cheat_sheet

cheat_sheet "hydra-bruteforce" {
  title: "Brute-force"
  category: red_team
  danger_level: 3

  entry "hydra-ssh" {
    command: "hydra -l [user] -P [wordlist] [target] ssh"
    description: "Brute-force SSH"
  }
}
''';

      final decision = TdcOpenDecision.decide(
        sheet,
        namedTdc: true,
        allowLegacyPayloads: false,
      );
      expect(decision.rejected, isFalse);
      expect(decision.importCourse, isFalse);
      expect(decision.document!.type, 'cheat_sheet');
      expect(decision.document!.id, 'hydra-bruteforce');
      expect(decision.message, contains('cheat_sheet'));
    });
  });
}
