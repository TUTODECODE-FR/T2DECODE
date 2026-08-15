// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';

/// TUTODECODE Course Language (.tdc) Parser & Serializer.
/// Sovereign Domain-Specific Language (DSL) for TUTODECODE courses, labs, and quizzes.
class TDCParser {
  /// Parses a .tdc string containing one or more `course "id" { ... }` declarations.
  static List<Map<String, dynamic>> parseMultiCourse(String source) {
    final courses = <Map<String, dynamic>>[];
    final courseRegex = RegExp(r'course\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{', multiLine: true);
    final matches = courseRegex.allMatches(source).toList();

    if (matches.isEmpty) {
      // Fallback: If source is raw JSON, parse as JSON
      final trimmed = source.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map) {
          return [decoded.cast<String, dynamic>()];
        }
      }
      throw FormatException('No course "id" { ... } block found in TDC source.');
    }

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final courseId = match.group(1)!;
      final startIdx = match.end;
      final endIdx = (i + 1 < matches.length) ? matches[i + 1].start : source.length;
      final blockContent = source.substring(startIdx, endIdx);

      final courseMap = _parseCourseBody(courseId, blockContent);
      courses.add(courseMap);
    }

    return courses;
  }

  /// Parses a single course block into a Map compatible with Course.fromJson.
  static Map<String, dynamic> parseCourse(String source) {
    final courses = parseMultiCourse(source);
    if (courses.isEmpty) {
      throw FormatException("Failed to parse TDC course.");
    }
    return courses.first;
  }

  static Map<String, dynamic> _parseCourseBody(String id, String body) {
    final map = <String, dynamic>{
      'id': id,
      'title': id,
      'description': '',
      'icon': 'BookOpen',
      'level': 'beginner',
      'duration': '1h',
      'category': 'general',
      'keywords': <String>[],
      'content': <Map<String, dynamic>>[],
    };

    // Header fields
    map['title'] = _extractQuotedValue(body, 'title') ?? id;
    map['description'] = _extractQuotedValue(body, 'description') ?? '';
    map['category'] = _extractSimpleValue(body, 'category') ?? 'general';
    map['level'] = _extractSimpleValue(body, 'level') ?? 'beginner';
    map['duration'] = _extractSimpleValue(body, 'duration') ?? '1h';
    map['icon'] = _extractSimpleValue(body, 'icon') ?? 'BookOpen';

    // Keywords list: keywords: [linux, bash, terminal]
    final keywordsMatch = RegExp(r'keywords:\s*\[([^\]]+)\]').firstMatch(body);
    if (keywordsMatch != null) {
      final rawList = keywordsMatch.group(1)!;
      map['keywords'] = rawList
          .split(',')
          .map((e) => e.trim().replaceAll(RegExp(r'^["' "'" r']|["' "'" r']$'), ''))
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Extract modules
    final modules = <Map<String, dynamic>>[];
    final moduleRegex = RegExp(r'module\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{', multiLine: true);
    final moduleMatches = moduleRegex.allMatches(body).toList();

    for (int i = 0; i < moduleMatches.length; i++) {
      final mMatch = moduleMatches[i];
      final moduleId = mMatch.group(1)!;
      final mStart = mMatch.end;
      final mEnd = (i + 1 < moduleMatches.length) ? moduleMatches[i + 1].start : body.length;
      final mBody = body.substring(mStart, mEnd);

      modules.add(_parseModuleBody(moduleId, mBody));
    }

    map['content'] = modules;
    return map;
  }

  static Map<String, dynamic> _parseModuleBody(String id, String body) {
    final module = <String, dynamic>{
      'id': id,
      'title': _extractQuotedValue(body, 'title') ?? id,
      'duration': _extractSimpleValue(body, 'duration') ?? '15min',
      'content': '',
      'codeBlocks': <Map<String, String>>[],
      'quiz': <Map<String, dynamic>>[],
    };

    // Extract markdown block: content """ ... """
    final contentTripleMatch = RegExp(r'content\s+"""([\s\S]*?)"""').firstMatch(body);
    if (contentTripleMatch != null) {
      module['content'] = contentTripleMatch.group(1)!.trim();
    } else {
      module['content'] = _extractQuotedValue(body, 'content') ?? '';
    }

    // Extract codeblocks
    final codeblocks = <Map<String, String>>[];
    final cbRegex = RegExp(r'codeblock\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{', multiLine: true);
    final cbMatches = cbRegex.allMatches(body).toList();

    for (int i = 0; i < cbMatches.length; i++) {
      final cbMatch = cbMatches[i];
      final lang = cbMatch.group(1)!;
      final cbStart = cbMatch.end;
      final cbEnd = (i + 1 < cbMatches.length) ? cbMatches[i + 1].start : body.length;
      final cbBody = body.substring(cbStart, cbEnd);

      final title = _extractQuotedValue(cbBody, 'title') ?? 'Exemple $lang';
      final codeMatch = RegExp(r'code\s+"""([\s\S]*?)"""').firstMatch(cbBody);
      final code = codeMatch != null ? codeMatch.group(1)!.trim() : '';

      codeblocks.add({
        'language': lang,
        'title': title,
        'code': code,
      });
    }
    module['codeBlocks'] = codeblocks;

    // Extract Quizzes
    final quizList = <Map<String, dynamic>>[];
    final qRegex = RegExp(r'question\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{', multiLine: true);
    final qMatches = qRegex.allMatches(body).toList();

    for (int i = 0; i < qMatches.length; i++) {
      final qMatch = qMatches[i];
      final questionText = qMatch.group(1)!;
      final qStart = qMatch.end;
      final qEnd = (i + 1 < qMatches.length) ? qMatches[i + 1].start : body.length;
      final qBody = body.substring(qStart, qEnd);

      final choices = <String>[];
      int correctIdx = 0;

      final optRegex = RegExp(r'([\+\-])\s*["' "'" r']([^"' "'" r']+)["' "'" r']');
      final optMatches = optRegex.allMatches(qBody).toList();
      if (optMatches.isNotEmpty) {
        for (int idx = 0; idx < optMatches.length; idx++) {
          final opt = optMatches[idx];
          final isCorrect = opt.group(1) == '+';
          final text = opt.group(2)!;
          choices.add(text);
          if (isCorrect) {
            correctIdx = idx;
          }
        }
      }

      final explanation = _extractQuotedValue(qBody, 'explanation') ?? '';

      quizList.add({
        'question': questionText,
        'choices': choices,
        'correctIndex': correctIdx,
        'explanation': explanation,
      });
    }
    module['quiz'] = quizList;

    return module;
  }

  static String? _extractQuotedValue(String text, String key) {
    final match = RegExp('$key:?\\s*["' "'" r']([^"' "'" r']+)["' "'" r']', multiLine: true).firstMatch(text);
    return match?.group(1);
  }

  static String? _extractSimpleValue(String text, String key) {
    final match = RegExp('$key:\\s*([a-zA-Z0-9_-]+)', multiLine: true).firstMatch(text);
    return match?.group(1);
  }

  /// Converts a JSON course map into readable TDC DSL syntax.
  static String serializeToTdc(Map<String, dynamic> course) {
    final sb = StringBuffer();
    final id = course['id'] ?? 'course-id';
    final title = course['title'] ?? id;
    final desc = course['description'] ?? '';
    final cat = course['category'] ?? 'general';
    final level = course['level'] ?? 'beginner';
    final duration = course['duration'] ?? '1h';
    final icon = course['icon'] ?? 'BookOpen';
    final keywords = (course['keywords'] as List?)?.cast<String>() ?? [];

    sb.writeln('course "$id" {');
    sb.writeln('  title: "$title"');
    sb.writeln('  description: "$desc"');
    sb.writeln('  category: $cat');
    sb.writeln('  level: $level');
    sb.writeln('  duration: $duration');
    sb.writeln('  icon: $icon');
    if (keywords.isNotEmpty) {
      sb.writeln('  keywords: [${keywords.join(', ')}]');
    }
    sb.writeln();

    final modules = (course['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final m in modules) {
      final mId = m['id'] ?? 'mod-1';
      final mTitle = m['title'] ?? mId;
      final mDuration = m['duration'] ?? '15min';
      final content = m['content'] ?? '';

      sb.writeln('  module "$mId" {');
      sb.writeln('    title: "$mTitle"');
      sb.writeln('    duration: $mDuration');
      sb.writeln();
      sb.writeln('    content """');
      sb.writeln(content);
      sb.writeln('    """');

      final codeBlocks = (m['codeBlocks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final cb in codeBlocks) {
        final lang = cb['language'] ?? 'bash';
        final cbTitle = cb['title'] ?? 'Exemple';
        final code = cb['code'] ?? '';

        sb.writeln();
        sb.writeln('    codeblock "$lang" {');
        sb.writeln('      title: "$cbTitle"');
        sb.writeln('      code """');
        sb.writeln(code);
        sb.writeln('      """');
        sb.writeln('    }');
      }

      final quiz = (m['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (quiz.isNotEmpty) {
        sb.writeln();
        sb.writeln('    quiz {');
        for (final q in quiz) {
          final question = q['question'] ?? '';
          final choices = (q['choices'] as List?)?.cast<String>() ?? [];
          final correctIdx = q['correctIndex'] as int? ?? 0;
          final explanation = q['explanation'] ?? '';

          sb.writeln('      question "$question" {');
          for (int i = 0; i < choices.length; i++) {
            final prefix = (i == correctIdx) ? '+' : '-';
            sb.writeln('        $prefix "${choices[i]}"');
          }
          if (explanation.isNotEmpty) {
            sb.writeln('        explanation: "$explanation"');
          }
          sb.writeln('      }');
        }
        sb.writeln('    }');
      }

      sb.writeln('  }');
      sb.writeln();
    }

    sb.writeln('}');
    return sb.toString();
  }
}
