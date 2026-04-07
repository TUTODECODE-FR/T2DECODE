// Feature: courses — Data layer
// Loads and owns the Course/Chapter data model.
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../utils/course_expansion.dart';

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
      final quiz = quizData != null
          ? quizData.map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>)).toList()
          : null;

      final tempChapter = CourseChapter(
        id: c['id'],
        title: c['title'],
        content: c['content'] ?? '',
        duration: c['duration'] ?? '',
        codeBlocks: codeBlocks,
        quiz: quiz,
      );

      final expanded = CourseExpansion.expandChapterContent(course, tempChapter, i);

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

  static Future<List<Course>> loadAll() async {
    final data = await rootBundle.loadString('assets/courses.json');
    final list = json.decode(data) as List<dynamic>;
    return list.map((m) => Course.fromMap(m as Map<String, dynamic>)).toList();
  }
}
