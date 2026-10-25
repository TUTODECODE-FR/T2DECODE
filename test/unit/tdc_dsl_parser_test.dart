// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/services/tdc_dsl_parser.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';

void main() {
  group('TdcDslParser', () {
    test('isTdcDsl returns true for valid TDC DSL header', () {
      const dsl = '''
course "nouveau-cours" {
  title: "Nouveau Cours"
}
''';
      expect(TdcDslParser.isTdcDsl(dsl), isTrue);
      expect(TdcDslParser.isTdcDsl('{"id": "test"}'), isFalse);
    });

    test('parses full course DSL with module, multiline content, and quiz', () {
      const dsl = '''
course "nouveau-cours" {
  title: "Nouveau Cours"
  description: "Description du cours"
  category: linux
  level: beginner
  duration: 1h
  icon: BookOpen

  module "module-1" {
    title: "Introduction"
    duration: 15min
    content """
# Bienvenue dans ce cours

Rédigez votre contenu ici...
    """
    quiz {
      question "Nouvelle question ?" {
        options: ["Option A", "Option D"]
        correctAnswer: 0
        explanation: "Explication de la réponse correcte."
      }
    }
  }
}
''';

      final map = TdcDslParser.parse(dsl);
      expect(map['id'], equals('nouveau-cours'));
      expect(map['title'], equals('Nouveau Cours'));
      expect(map['description'], equals('Description du cours'));
      expect(map['category'], equals('linux'));
      expect(map['level'], equals('beginner'));
      expect(map['duration'], equals('1h'));
      expect(map['icon'], equals('BookOpen'));
      expect(map['keywords'], contains('EXTERNAL'));

      final content = map['content'] as List;
      expect(content.length, equals(1));

      final mod = content.first as Map<String, dynamic>;
      expect(mod['id'], equals('module-1'));
      expect(mod['title'], equals('Introduction'));
      expect(mod['duration'], equals('15min'));
      expect(mod['content'], contains('# Bienvenue dans ce cours'));

      final quiz = mod['quiz'] as List;
      expect(quiz.length, equals(1));
      final q = quiz.first as Map<String, dynamic>;
      expect(q['question'], equals('Nouvelle question ?'));
      expect(q['choices'], equals(['Option A', 'Option D']));
      expect(q['correctIndex'], equals(0));
      expect(q['explanation'], equals('Explication de la réponse correcte.'));

      // Also ensure Course.fromMap successfully constructs Course object
      final course = Course.fromMap(map);
      expect(course.id, equals('nouveau-cours'));
      expect(course.chapters.length, equals(1));
      expect(course.chapters.first.quiz?.first.question,
          equals('Nouvelle question ?'));
    });

    test('parses a TDC Studio course header and signed quiz choices', () {
      const dsl = '''
tdc-version: 2
type: course

course "Bash" {
  title: "Scripts Bash"
  description: "Écrire des scripts"
  category: linux
  level: intermediate
  duration: 5h05
  icon: Terminal

  module "intro" {
    title: "Chapitre 1 : premier script"
    duration: 20min
    content: """
Un script Bash est un fichier texte.
"""
    codeblock "bash" {
      title: "Vérifier la syntaxe"
      code: """
bash -n script.sh
"""
    }
    quiz {
      question "Que fait le shebang ?" {
        - "c'est un commentaire sans effet"
        + "elle indique quel programme doit lire le script"
        - "elle importe une bibliothèque"
        explanation: "Le système lit #! au lancement."
      }
    }
  }
}
''';

      final map = TdcDslParser.parse(dsl);
      expect(map['id'], equals('Bash'));
      expect(map['title'], equals('Scripts Bash'));
      expect(map['duration'], equals('5h05'));

      final mod = (map['content'] as List).first as Map<String, dynamic>;
      expect(mod['content'], contains('Un script Bash est un fichier texte.'));
      final blocks = mod['codeBlocks'] as List;
      expect(blocks.single['language'], equals('bash'));
      expect(blocks.single['code'], contains('bash -n script.sh'));
      final quiz = mod['quiz'] as List;
      final q = quiz.first as Map<String, dynamic>;
      expect(
          q['choices'],
          equals([
            "c'est un commentaire sans effet",
            'elle indique quel programme doit lire le script',
            'elle importe une bibliothèque',
          ]));
      expect(q['correctIndex'], equals(1));
      expect(q['explanation'], contains('#!'));

      final course = Course.fromMap(map);
      expect(course.chapters.first.quiz?.first.correctIndex, equals(1));
    });
  });
}
