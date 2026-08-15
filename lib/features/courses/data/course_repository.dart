// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// Feature: courses — Data layer
// Loads and owns the Course/Chapter data model.
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../core/parser/tdc_parser.dart';
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

enum CourseOrigin { official, signed, community }

enum KeyTrustStatus { trusted, recognized, conflict, untrusted }

class Course {
  final String id;
  final String title;
  final String description;
  final String level;
  final String duration;
  final String category;
  final List<String> keywords;
  final List<CourseChapter> chapters;

  final CourseOrigin origin;
  final String author;
  final String? authorKeyFingerprint;
  final KeyTrustStatus trustStatus;
  final String? sourcePath;
  final bool isCustomCategory;
  final String? rawSource;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.duration,
    required this.category,
    required this.keywords,
    required this.chapters,
    this.origin = CourseOrigin.official,
    this.author = 'TUTODECODE',
    this.authorKeyFingerprint,
    this.trustStatus = KeyTrustStatus.trusted,
    this.sourcePath,
    this.isCustomCategory = false,
    this.rawSource,
  });

  static const List<String> standardCategories = [
    'linux',
    'network',
    'security',
    'cloud',
    'crypto',
    'development',
    'réseau',
    'sécurité',
    'développement',
  ];

  factory Course.fromMap(Map<String, dynamic> m, {String? sourcePath, String? rawSource}) {
    final keywords = List<String>.from(m['keywords'] ?? []);
    final category = (m['category'] ?? '').toString().trim();
    final isCustomCat = category.isNotEmpty &&
        !standardCategories.contains(category.toLowerCase());

    final bool isExternal = keywords.contains('EXTERNAL') ||
        m['isExternal'] == true ||
        sourcePath != null;

    CourseOrigin origin = CourseOrigin.official;
    String author = 'TUTODECODE';
    String? fingerprint = m['authorKeyFingerprint'] ?? m['authorKey'];
    KeyTrustStatus trustStatus = KeyTrustStatus.trusted;

    if (isExternal) {
      final sigMatch = m['signature'] != null ||
          (rawSource != null && rawSource.contains('signature:'));
      final authorMatch = m['author'] ??
          (rawSource != null
              ? RegExp(r'author:\s*["' "'" r']([^"' "'" r']+)["' "'" r']')
                  .firstMatch(rawSource)
                  ?.group(1)
              : null);

      if (sigMatch || authorMatch != null) {
        origin = CourseOrigin.signed;
        author = authorMatch?.toString() ?? 'Auteur Tiers';
        if (fingerprint == null && rawSource != null) {
          final fpMatch = RegExp(
                  r'author-key:\s*["' "'" r']([^"' "'" r']+)["' "'" r']')
              .firstMatch(rawSource);
          fingerprint = fpMatch?.group(1);
        }
        final statusStr = m['trustStatus']?.toString() ?? '';
        if (statusStr == 'conflict') {
          trustStatus = KeyTrustStatus.conflict;
        } else if (statusStr == 'recognized') {
          trustStatus = KeyTrustStatus.recognized;
        } else if (statusStr == 'untrusted') {
          trustStatus = KeyTrustStatus.untrusted;
        } else {
          trustStatus = KeyTrustStatus.recognized;
        }
      } else {
        origin = CourseOrigin.community;
        author = m['author']?.toString() ?? 'Communauté';
        trustStatus = KeyTrustStatus.untrusted;
      }
    }

    final course = Course(
      id: m['id'] ?? 'cours-inconnu',
      title: m['title'] ?? 'Sans titre',
      description: m['description'] ?? '',
      level: m['level'] ?? '',
      duration: m['duration'] ?? '',
      category: category,
      keywords: keywords,
      chapters: [],
      origin: origin,
      author: author,
      authorKeyFingerprint: fingerprint,
      trustStatus: trustStatus,
      sourcePath: sourcePath,
      isCustomCategory: isCustomCat,
      rawSource: rawSource,
    );

    final rawChapters = (m['content'] is List) ? (m['content'] as List<dynamic>) : [];
    for (int i = 0; i < rawChapters.length; i++) {
      final c = rawChapters[i];
      if (c is! Map) continue;
      final mapC = Map<String, dynamic>.from(c);

      final rawBlocks = mapC['codeBlocks'];
      final List<Map<String, dynamic>>? codeBlocks = rawBlocks is List
          ? rawBlocks
              .map((b) => Map<String, dynamic>.from(b as Map))
              .toList()
          : null;

      final quizData = mapC['quiz'] as List<dynamic>?;
      final quiz = quizData
          ?.map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
          .toList();

      final tempChapter = CourseChapter(
        id: mapC['id']?.toString() ?? 'module-$i',
        title: mapC['title']?.toString() ?? 'Chapitre $i',
        content: mapC['content']?.toString() ?? '',
        duration: mapC['duration']?.toString() ?? '',
        codeBlocks: codeBlocks,
        quiz: quiz,
      );

      final expanded =
          CourseExpansion.expandChapterContent(course, tempChapter, i);

      course.chapters.add(CourseChapter(
        id: tempChapter.id,
        title: tempChapter.title,
        content: expanded,
        duration: tempChapter.duration,
        codeBlocks: codeBlocks,
        quiz: quiz,
      ));
    }
    return course;
  }

  static Future<List<Course>> loadAll([String locale = 'fr']) async {
    String filename = 'assets/courses/courses_$locale.json';
    try {
      final data = await rootBundle.loadString(filename);
      final list = TDCParser.parseMultiCourse(data);
      return list
          .map((m) => Course.fromMap(m))
          .toList();
    } catch (e) {
      // Fallback
      final fallback =
          await rootBundle.loadString('assets/courses/courses_en.json');
      final list = TDCParser.parseMultiCourse(fallback);
      return list
          .map((m) => Course.fromMap(m))
          .toList();
    }
  }
}
