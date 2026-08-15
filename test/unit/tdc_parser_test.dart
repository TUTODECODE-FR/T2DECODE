import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/parser/tdc_parser.dart';

void main() {
  group('TUTODECODE Course Language (.tdc) Parser', () {
    final sampleTdc = '''
course "linux-basics" {
  title: "Linux : Le Pouvoir du Terminal"
  description: "Maîtrisez le système qui fait tourner 96% des serveurs."
  category: linux
  level: beginner
  duration: 6h
  icon: Terminal
  keywords: [linux, bash, terminal]

  module "intro" {
    title: "Architecture et Commandes Essentielles"
    duration: 15min

    content """
    # Introduction au Terminal Linux
    Linux administre le monde des serveurs.
    """

    codeblock "bash" {
      title: "Premier contact"
      code """
      whoami
      pwd
      """
    }

    quiz {
      question "Quelle est la racine sous Linux ?" {
        - "C:\\"
        + "/"
        - "/home"
        explanation "Sous Linux tout commence à la racine /."
      }
    }
  }
}
''';

    test('Parses .tdc metadata correctly', () {
      final course = TDCParser.parseCourse(sampleTdc);
      expect(course['id'], equals('linux-basics'));
      expect(course['title'], equals('Linux : Le Pouvoir du Terminal'));
      expect(course['category'], equals('linux'));
      expect(course['level'], equals('beginner'));
      expect(course['keywords'], contains('bash'));
    });

    test('Parses module content and codeblock correctly', () {
      final course = TDCParser.parseCourse(sampleTdc);
      final modules = course['content'] as List;
      expect(modules.length, equals(1));

      final mod = modules.first as Map<String, dynamic>;
      expect(mod['id'], equals('intro'));
      expect(mod['title'], equals('Architecture et Commandes Essentielles'));
      expect(mod['content'], contains('Introduction au Terminal Linux'));

      final codeBlocks = mod['codeBlocks'] as List;
      expect(codeBlocks.length, equals(1));
      expect(codeBlocks.first['language'], equals('bash'));
      expect(codeBlocks.first['code'], contains('whoami'));
    });

    test('Parses quiz questions and choices correctly', () {
      final course = TDCParser.parseCourse(sampleTdc);
      final mod = (course['content'] as List).first as Map<String, dynamic>;
      final quiz = mod['quiz'] as List;
      expect(quiz.length, equals(1));

      final q = quiz.first as Map<String, dynamic>;
      expect(q['question'], contains('racine'));
      expect(q['choices'], contains('/'));
      expect(q['correctIndex'], equals(0));
      expect(q['explanation'], contains('racine /'));
    });

    test('Serializes course back to valid .tdc string', () {
      final course = TDCParser.parseCourse(sampleTdc);
      final serialized = TDCParser.serializeToTdc(course);
      expect(serialized, contains('course "linux-basics"'));
      expect(serialized, contains('category: linux'));
      expect(serialized, contains('codeblock "bash"'));
    });
  });
}
