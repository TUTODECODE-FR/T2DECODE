// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/services/tdc_dsl_parser.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';

const _source = '''
tdc-version: 2
type: course

course "essai" {
  title: "Essai"
  description: "Cours d'essai"
  category: network
  level: beginner
  duration: 10min

  module "m1" {
    title: "Module 1"
    duration: 5min
    content """
Texte du module.
    """
    quiz {
      pick: 2
      question "Q1 ?" { + "a" - "b" explanation: "e1" }
      question "Q2 ?" { + "a" - "b" }
      question "Q3 ?" { + "a" - "b" }
      question "Q4 ?" { - "b" + "a" }
    }
  }
}
''';

void main() {
  test('pick et banque de questions lus depuis le .tdc', () {
    final map = TdcDslParser.parse(_source);
    final course = Course.fromMap(map);
    final chapter = course.chapters.single;
    expect(chapter.quiz, hasLength(4));
    expect(chapter.quizPick, 2);
    expect(chapter.quiz![3].choices[chapter.quiz![3].correctIndex], 'a');
  });
}
