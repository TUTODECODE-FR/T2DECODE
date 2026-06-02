// SPDX-License-Identifier: GPL-3.0-or-later

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
    test('generateExpandedContent coverage - empty fields', () {
      final course = Course(
        id: 'test_course_2',
        title: 'Test Course 2',
        description: 'Desc',
        category: 'network',
        level: 'Débutant',
        duration: '1h',
        keywords: [], // Empty keywords
        chapters: [
          CourseChapter(
            id: 'c2',
            title: 'Intro 2',
            content: 'Just text',
            duration: ' ', // Empty duration
            codeBlocks: [], // Empty code blocks
          )
        ]
      );

      final expanded = CourseExpansion.expandChapterContent(course, course.chapters[0], 0);
      expect(expanded, isNotEmpty);
    });
  });
}
