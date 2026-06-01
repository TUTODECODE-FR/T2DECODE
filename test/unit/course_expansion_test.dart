import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tutodecode/utils/course_expansion.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';

void main() {
  group('CourseExpansion Full Coverage', () {
    test('generateExpandedContent coverage', () {
      final course = Course(
        id: 'test_course',
        title: 'Test Course',
        description: 'Desc',
        category: 'network',
        level: 'Débutant',
        duration: '1h',
        keywords: ['test'],
        chapters: [
          CourseChapter(
            id: 'c1',
            title: 'Intro',
            content: 'import something\nprint("hello")\nclass Test {}',
            duration: '10m',
          )
        ]
      );

      final expanded = CourseExpansion.expandChapterContent(course, course.chapters[0], 0);
      expect(expanded, isNotEmpty);
      expect(expanded.contains('Intro'), isTrue);
    });
  });
}
