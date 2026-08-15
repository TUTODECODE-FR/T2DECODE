// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/parser/tdc_parser.dart';

void main() {
  group('TDCParser — Strict Syntax Validator Tests', () {
    test('Valide un cours vierge minimal', () {
      const source = '''course "cours-minimal" {
  title: "Cours Minimal"
  description: "Description du cours"
  category: linux
  level: beginner
  duration: 1h
  icon: BookOpen
}''';
      final errors = TDCParser.validateSyntax(source);
      expect(errors, isEmpty);

      final parsed = TDCParser.parseCourse(source);
      expect(parsed['id'], equals('cours-minimal'));
      expect(parsed['title'], equals('Cours Minimal'));
      expect(parsed['category'], equals('linux'));
      expect(parsed['content'], isEmpty);
    });

    test('Détecte un mot-clé mal orthographié (corse au lieu de course)', () {
      const source = '''corse "cours-invalide" {
  title: "Test"
}''';
      final errors = TDCParser.validateSyntax(source);
      expect(errors, isNotEmpty);
      expect(errors.first.line, equals(1));
    });

    test('Détecte du texte corrompu / orphelin', () {
      const source = '''course "cours-test" {
  title: "Test"
  nvbjksf;,nhi...
}''';
      final errors = TDCParser.validateSyntax(source);
      expect(errors, isNotEmpty);
      expect(errors.first.line, equals(3));
    });

    test('Détecte des accolades non fermées', () {
      const source = '''course "cours-incomplet" {
  title: "Test"
  module "mod-1" {
    title: "Chapitre 1"
''';
      final errors = TDCParser.validateSyntax(source);
      expect(errors, isNotEmpty);
    });
  });

  group('TDCParser — Round-Trip Tests (Serialize -> Parse -> Serialize)', () {
    test('Round-trip sur un cours complet avec modules et quiz', () {
      final original = {
        'id': 'linux-essentials',
        'title': 'Les Bases de Linux',
        'description': 'Maîtrisez la ligne de commande Linux.',
        'category': 'linux',
        'level': 'beginner',
        'duration': '2h',
        'icon': 'Terminal',
        'keywords': ['bash', 'cli', 'linux'],
        'content': [
          {
            'id': 'chap-1-intro',
            'title': 'Introduction au Shell',
            'duration': '30min',
            'markdown': '# Bienvenue\nVoici une commande : `ls -la`',
            'quiz': [
              {
                'question': 'Quelle commande liste les fichiers ?',
                'options': ['ls', 'cd', 'mkdir', 'rm'],
                'correctAnswer': 0,
                'explanation': 'ls signifie list directory contents.',
              }
            ],
          }
        ],
      };

      final tdcCode = TDCParser.serializeToTdc(original);
      final syntaxErrors = TDCParser.validateSyntax(tdcCode);
      expect(syntaxErrors, isEmpty, reason: 'Le code généré doit être 100% syntaxiquement valide');

      final parsed = TDCParser.parseCourse(tdcCode);
      expect(parsed['id'], equals(original['id']));
      expect(parsed['title'], equals(original['title']));
      expect(parsed['category'], equals(original['category']));
      expect((parsed['content'] as List).length, equals(1));
      
      final mod = (parsed['content'] as List).first as Map;
      expect(mod['id'], equals('chap-1-intro'));
      expect(mod['title'], equals('Introduction au Shell'));
      expect((mod['quiz'] as List).length, equals(1));

      final q = (mod['quiz'] as List).first as Map;
      expect(q['question'], equals('Quelle commande liste les fichiers ?'));
      expect(q['correctAnswer'], equals(0));
      expect(q['explanation'], equals('ls signifie list directory contents.'));

      // Deuxième round-trip
      final secondTdc = TDCParser.serializeToTdc(parsed);
      expect(TDCParser.validateSyntax(secondTdc), isEmpty);
    });
  });
}
