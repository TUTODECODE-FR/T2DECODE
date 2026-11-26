// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// Feature: courses — Data layer
// Loads and owns the Course/Chapter data model.
import 'dart:convert';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../../../core/services/tdc_dsl_parser.dart';
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

  /// Nombre de questions tirées dans la banque `quiz` à chaque tentative.
  final int? quizPick;

  const CourseChapter({
    required this.id,
    required this.title,
    required this.content,
    required this.duration,
    this.codeBlocks,
    this.quiz,
    this.quizPick,
  });
}

class Course {
  final String id;
  final String title;
  final String description;
  final String level;
  final String duration;
  final String category;
  final String? author;
  final String? signedBy;
  final List<String> keywords;
  final List<CourseChapter> chapters;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.duration,
    required this.category,
    this.author,
    this.signedBy,
    required this.keywords,
    required this.chapters,
  });

  factory Course.fromMap(Map<String, dynamic> m) {
    final keywords = List<String>.from(m['keywords'] ?? []);
    final isExternal = keywords.contains('EXTERNAL');
    final author = m['author']?.toString() ??
        (isExternal ? 'Auteur tiers' : 'Association TUTODECODE');
    final signedBy = m['signedBy']?.toString() ??
        m['signed_by']?.toString() ??
        (isExternal ? null : 'Association TUTODECODE (RNA W134011896)');

    final course = Course(
      id: m['id'],
      title: m['title'],
      description: m['description'] ?? '',
      level: m['level'] ?? '',
      duration: m['duration'] ?? '',
      category: m['category'] ?? '',
      author: author,
      signedBy: signedBy,
      keywords: keywords,
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
        quizPick: c['quizPick'] is int ? c['quizPick'] as int : null,
      ));
    }
    return course;
  }

  /// Cours au format .tdc : assets/courses/<langue>/*.tdc (une version par langue,
  /// même nom de fichier). Un cours absent dans la langue demandée est pris en français.
  static Future<List<Course>> loadAll([String locale = 'fr']) async {
    final tdc = await _loadTdc(locale);
    if (tdc.isNotEmpty) return tdc;
    return _loadLegacyJson(locale); // anciens cours, le temps de la transition
  }

  static Future<List<Course>> _loadTdc(String locale) async {
    final List<String> tous;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      tous = manifest
          .listAssets()
          .where((a) => a.startsWith('assets/courses/') && a.endsWith('.tdc'))
          .toList();
    } catch (_) {
      return const [];
    }
    String nom(String a) => a.substring(a.lastIndexOf('/') + 1);
    final parLangue = <String, String>{
      for (final a in tous.where((a) => a.startsWith('assets/courses/fr/')))
        nom(a): a,
    };
    if (locale != 'fr') {
      for (final a in tous.where((a) => a.startsWith('assets/courses/$locale/'))) {
        parLangue[nom(a)] = a;
      }
    }
    final noms = parLangue.keys.toList()..sort();
    final cours = <Course>[];
    for (final n in noms) {
      try {
        final texte = await rootBundle.loadString(parLangue[n]!);
        cours.add(Course.fromMap(TdcDslParser.parse(texte)));
      } catch (_) {
        // un cours mal formé ne doit pas empêcher d'ouvrir les autres
      }
    }
    return cours;
  }

  static Future<List<Course>> _loadLegacyJson(String locale) async {
    String filename = 'assets/courses/courses_$locale.json';
    try {
      final data = await rootBundle.loadString(filename);
      final list = json.decode(data) as List<dynamic>;
      return list
          .map((m) => Course.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final fallback =
          await rootBundle.loadString('assets/courses/courses_en.json');
      final list = json.decode(fallback) as List<dynamic>;
      return list
          .map((m) => Course.fromMap(m as Map<String, dynamic>))
          .toList();
    }
  }
}
