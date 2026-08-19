// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// Feature: courses — Data layer
// Loads and owns the Course/Chapter data model.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../utils/course_expansion.dart';
import '../../../core/services/tdc_parser.dart';

class QuizQuestion {
  final String question;
  final List<String> choices;
  final int correctIndex;
  final String? explanation;

  const QuizQuestion({
    required this.question,
    required this.choices,
    required this.correctIndex,
    this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> m) {
    return QuizQuestion(
      question: m['question'] ?? '',
      choices: List<String>.from(m['choices'] ?? []),
      correctIndex: m['correctIndex'] ?? 0,
      explanation: m['explanation'],
    );
  }
}

class CourseChapter {
  final String id;
  final String title;
  final String content;
  final String duration;
  final List<Map<String, dynamic>>? codeBlocks;
  final List<QuizQuestion>? quiz;

  const CourseChapter({
    required this.id,
    required this.title,
    required this.content,
    required this.duration,
    this.codeBlocks,
    this.quiz,
  });
}

class Course {
  final String id;
  final String title;
  final String description;
  final String level;
  final String duration;
  final String category;
  final List<String> keywords;
  final List<CourseChapter> chapters;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.duration,
    required this.category,
    required this.keywords,
    required this.chapters,
  });

  factory Course.fromMap(Map<String, dynamic> m) {
    final course = Course(
      id: m['id'],
      title: m['title'],
      description: m['description'] ?? '',
      level: m['level'] ?? '',
      duration: m['duration'] ?? '',
      category: m['category'] ?? '',
      keywords: List<String>.from(m['keywords'] ?? []),
      chapters: [],
    );

    final rawChapters = (m['content'] ?? []) as List<dynamic>;
    for (int i = 0; i < rawChapters.length; i++) {
      final c = rawChapters[i];
      final codeBlocks = c['codeBlocks'] != null
          ? List<Map<String, dynamic>>.from(c['codeBlocks'])
          : null;

      final quizData = c['quiz'] as List<dynamic>?;
      final quiz = quizData
          ?.map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList();

      final tempChapter = CourseChapter(
        id: c['id'],
        title: c['title'],
        content: c['content'] ?? '',
        duration: c['duration'] ?? '',
        codeBlocks: codeBlocks,
        quiz: quiz,
      );

      final expanded =
          CourseExpansion.expandChapterContent(course, tempChapter, i);

      course.chapters.add(CourseChapter(
        id: c['id'],
        title: c['title'],
        content: expanded,
        duration: c['duration'] ?? '',
        codeBlocks: codeBlocks,
        quiz: quiz,
      ));
    }
    return course;
  }

  /// Builds a [Course] from a raw TDC map (output of [TdcParser]).
  static Course fromTdcMap(Map<String, dynamic> m) => Course.fromMap(m);

  /// Loads all courses. Reads [assets/courses.tdc] first (canonical DSL);
  /// falls back to localized JSON or default JSON if the TDC asset is absent or fails.
  static Future<List<Course>> loadAll([String locale = 'fr']) async {
    // Try .tdc first (canonical format)
    try {
      final src = await rootBundle.loadString('assets/courses.tdc');
      final maps = parseTdcSafe(src);
      if (maps.isNotEmpty) {
        return maps.map(Course.fromMap).toList();
      }
      if (kDebugMode) debugPrint('[CourseRepository] courses.tdc parsed 0 courses, falling back to JSON');
    } catch (_) {
      if (kDebugMode) debugPrint('[CourseRepository] courses.tdc not found, using JSON fallback');
    }

    // JSON fallback (localized or root)
    try {
      final data = await rootBundle.loadString('assets/courses/courses_$locale.json');
      final list = json.decode(data) as List<dynamic>;
      return list.map((m) => Course.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      try {
        final fallback = await rootBundle.loadString('assets/courses/courses_en.json');
        final list = json.decode(fallback) as List<dynamic>;
        return list.map((m) => Course.fromMap(m as Map<String, dynamic>)).toList();
      } catch (_) {
        final data = await rootBundle.loadString('assets/courses.json');
        final list = json.decode(data) as List<dynamic>;
        return list.map((m) => Course.fromMap(m as Map<String, dynamic>)).toList();
      }
    }
  }
}
