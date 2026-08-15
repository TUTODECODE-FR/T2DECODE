// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';
import 'package:tutodecode/core/services/tdc_category_registry.dart';
import 'package:tutodecode/core/services/tdc_icon_registry.dart';

/// Représente une erreur de validation syntaxique avec numéro de ligne.
class TDCValidationError {
  final int line;
  final String message;
  final bool isWarning;

  const TDCValidationError(this.line, this.message, {this.isWarning = false});

  @override
  String toString() => '${isWarning ? "Avertissement" : "Ligne"} $line : $message';
}

class _BlockScope {
  final String type; // 'course', 'metadata', 'category_custom', 'module', 'quiz', 'question', 'codeblock'
  final int startLine;
  _BlockScope(this.type, this.startLine);
}

/// TUTODECODE Course Language (.tdc) Parser & Serializer v2.
/// Sovereign Domain-Specific Language (DSL) for TUTODECODE courses, labs, and quizzes.
class TDCParser {
  /// Valide ligne par ligne la syntaxe d'un fichier source .TDC.
  static List<TDCValidationError> validateSyntax(String source) {
    final errors = <TDCValidationError>[];
    final lines = source.split('\n');
    final braceStack = <_BlockScope>[];
    bool inTripleQuote = false;
    int tripleQuoteStartLine = 0;
    bool foundCourseBlock = false;
    final declaredCustomCategories = <String>{};

    for (int i = 0; i < lines.length; i++) {
      final lineNum = i + 1;
      final rawLine = lines[i];
      final line = rawLine.trim();

      // Gestion des blocs multiline """ ... """
      if (inTripleQuote) {
        if (line.contains('"""')) {
          inTripleQuote = false;
        }
        continue;
      }

      final tqCount = RegExp(r'"""').allMatches(line).length;
      if (tqCount % 2 != 0) {
        inTripleQuote = true;
        tripleQuoteStartLine = lineNum;
        continue;
      }

      // Lignes vides ou commentaires // ou #
      if (line.isEmpty || line.startsWith('//') || line.startsWith('#')) {
        continue;
      }

      // Fermeture d'accolade '}'
      if (line == '}') {
        if (braceStack.isEmpty) {
          errors.add(TDCValidationError(lineNum, 'Accolade fermante \'}\' en trop sans bloc ouvert.'));
        } else {
          braceStack.removeLast();
        }
        continue;
      }

      // Déclaration top-level category custom "id" {
      final customCatMatch = RegExp(r'^category\s+custom\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{$').firstMatch(line);
      if (customCatMatch != null) {
        final catId = customCatMatch.group(1)!;
        if (TDCCategoryRegistry.isBuiltin(catId)) {
          errors.add(TDCValidationError(lineNum, 'L\'identifiant de catégorie custom \'$catId\' entre en collision avec une catégorie intégrée.'));
        }
        declaredCustomCategories.add(catId.toLowerCase());
        braceStack.add(_BlockScope('category_custom', lineNum));
        continue;
      }

      // Déclaration course "id" {
      final courseMatch = RegExp(r'^course\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{$').firstMatch(line);
      if (courseMatch != null) {
        if (braceStack.isNotEmpty) {
          errors.add(TDCValidationError(lineNum, 'Le bloc course ne peut pas être imbriqué.'));
        }
        braceStack.add(_BlockScope('course', lineNum));
        foundCourseBlock = true;
        continue;
      }

      if (!foundCourseBlock && braceStack.isEmpty) {
        errors.add(TDCValidationError(
          lineNum,
          'Déclaration \'course "identifiant" {\' attendue en début de fichier (trouvé : \'$line\').',
        ));
        continue;
      }

      final currentScope = braceStack.isNotEmpty ? braceStack.last.type : 'root';

      if (currentScope == 'category_custom') {
        if (RegExp(r'^label:\s*["' "'" r']').hasMatch(line)) {
          continue;
        }
        final colorMatch = RegExp(r'^color:\s*([a-zA-Z0-9_\-\.\+]+)').firstMatch(line);
        if (colorMatch != null) {
          final colorToken = colorMatch.group(1)!;
          if (!TDCColorTokens.isValidToken(colorToken)) {
            errors.add(TDCValidationError(lineNum, 'Token de couleur \'$colorToken\' inconnu. Tokens valides : ${TDCColorTokens.availableTokens.join(", ")}'));
          }
          continue;
        }
        final iconMatch = RegExp(r'^icon:\s*([a-zA-Z0-9_\-\.\+]+)').firstMatch(line);
        if (iconMatch != null) {
          final iconToken = iconMatch.group(1)!;
          if (!TDCIconRegistry.isValidToken(iconToken)) {
            errors.add(TDCValidationError(lineNum, 'Icône \'$iconToken\' inconnue (repli automatique sur BookOpen).', isWarning: true));
          }
          continue;
        }
        errors.add(TDCValidationError(lineNum, 'Propriété de catégorie custom invalide : \'$line\''));
      } else if (currentScope == 'course') {
        final moduleMatch = RegExp(r'^module\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{$').firstMatch(line);
        if (moduleMatch != null) {
          braceStack.add(_BlockScope('module', lineNum));
          continue;
        }

        final metadataBlock = RegExp(r'^metadata\s*\{$').firstMatch(line);
        if (metadataBlock != null) {
          braceStack.add(_BlockScope('metadata', lineNum));
          continue;
        }

        // Vérification de la catégorie
        final catMatch = RegExp(r'^category:\s*([a-zA-Z0-9_\-\.\+]+)').firstMatch(line);
        if (catMatch != null) {
          final catVal = catMatch.group(1)!.toLowerCase();
          final isBuiltin = TDCCategoryRegistry.isBuiltin(catVal);
          final isCustomDeclared = declaredCustomCategories.contains(catVal);
          final isLocalCustom = TDCCategoryRegistry.findById(catVal) != null;
          if (!isBuiltin && !isCustomDeclared && !isLocalCustom) {
            errors.add(TDCValidationError(lineNum, 'Catégorie \'$catVal\' non déclarée (attendu : intégrée ou déclarée via category custom).'));
          }
          continue;
        }

        // Vérification de l'icône
        final iconMatch = RegExp(r'^icon:\s*([a-zA-Z0-9_\-\.\+]+)').firstMatch(line);
        if (iconMatch != null) {
          final iconToken = iconMatch.group(1)!;
          if (!TDCIconRegistry.isValidToken(iconToken)) {
            errors.add(TDCValidationError(lineNum, 'Icône \'$iconToken\' inconnue (repli automatique).', isWarning: true));
          }
          continue;
        }

        // Vérification de l'accent couleur
        final accentMatch = RegExp(r'^accent:\s*([a-zA-Z0-9_\-\.\+]+)').firstMatch(line);
        if (accentMatch != null) {
          final token = accentMatch.group(1)!;
          if (!TDCColorTokens.isValidToken(token)) {
            errors.add(TDCValidationError(lineNum, 'Token d\'accent \'$token\' inconnu. Tokens valides : ${TDCColorTokens.availableTokens.join(", ")}', isWarning: true));
          }
          continue;
        }

        if (RegExp(r'^(title|description|author|author-key|signature|tdc-version):\s*["' "'" r']').hasMatch(line) ||
            RegExp(r'^(level|duration):\s*[a-zA-Z0-9_\-\.\+]+').hasMatch(line) ||
            RegExp(r'^keywords:\s*\[.*\]').hasMatch(line)) {
          continue;
        }

        errors.add(TDCValidationError(lineNum, 'Instruction inconnue ou syntaxe invalide dans le bloc course : \'$line\''));
      } else if (currentScope == 'metadata') {
        if (RegExp(r'^(title|description|author|author-key|signature):\s*["' "'" r']').hasMatch(line) ||
            RegExp(r'^(category|level|duration|icon|accent):\s*[a-zA-Z0-9_\-\.\+]+').hasMatch(line) ||
            RegExp(r'^keywords:\s*\[.*\]').hasMatch(line)) {
          continue;
        }
        errors.add(TDCValidationError(lineNum, 'Propriété metadata invalide : \'$line\''));
      } else if (currentScope == 'module') {
        if (RegExp(r'^(title|description|markdown|content):\s*["' "'" r']').hasMatch(line) ||
            RegExp(r'^duration:\s*[a-zA-Z0-9_\-\.]+').hasMatch(line) ||
            RegExp(r'^(content|markdown)\s+"""').hasMatch(line)) {
          continue;
        }

        final quizBlock = RegExp(r'^quiz\s*\{$').firstMatch(line);
        if (quizBlock != null) {
          braceStack.add(_BlockScope('quiz', lineNum));
          continue;
        }

        final cbBlock = RegExp(r'^codeblock\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{$').firstMatch(line);
        if (cbBlock != null) {
          braceStack.add(_BlockScope('codeblock', lineNum));
          continue;
        }

        errors.add(TDCValidationError(lineNum, 'Instruction inconnue ou syntaxe invalide dans le module : \'$line\''));
      } else if (currentScope == 'quiz') {
        final qMatch = RegExp(r'^question\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{$').firstMatch(line);
        if (qMatch != null) {
          braceStack.add(_BlockScope('question', lineNum));
          continue;
        }
        errors.add(TDCValidationError(lineNum, 'Seules les déclarations \'question "texte" {\' sont autorisées dans un bloc quiz (trouvé : \'$line\').'));
      } else if (currentScope == 'question') {
        if (RegExp(r'^options:\s*\[').hasMatch(line) ||
            RegExp(r'^correctAnswer:\s*\d+').hasMatch(line) ||
            RegExp(r'^explanation:\s*["' "'" r']').hasMatch(line) ||
            RegExp(r'^\s*["' "'" r'].*["' "'" r'],?\s*$').hasMatch(line) ||
            line == ']') {
          continue;
        }
        errors.add(TDCValidationError(lineNum, 'Propriété de question invalide : \'$line\''));
      } else if (currentScope == 'codeblock') {
        if (RegExp(r'^(content|initialCode)\s+"""').hasMatch(line) ||
            RegExp(r'^(language|executable):\s*[a-zA-Z0-9_\-\.]+').hasMatch(line) ||
            RegExp(r'^expectedOutput:\s*["' "'" r']').hasMatch(line)) {
          continue;
        }
        errors.add(TDCValidationError(lineNum, 'Propriété de codeblock invalide : \'$line\''));
      }
    }

    if (inTripleQuote) {
      errors.add(TDCValidationError(tripleQuoteStartLine, 'Bloc de texte multiligne """ non fermé.'));
    }

    while (braceStack.isNotEmpty) {
      final unclosed = braceStack.removeLast();
      errors.add(TDCValidationError(unclosed.startLine, 'Bloc \'${unclosed.type}\' non fermé (accolade \'}\' manquante).'));
    }

    // Filtrer les vraies erreurs bloquantes
    return errors.where((e) => !e.isWarning).toList();
  }

  /// Extrait les définitions de catégories personnalisées déclarées dans un fichier .TDC
  static List<TDCCategory> extractCustomCategories(String source) {
    final list = <TDCCategory>[];
    final regex = RegExp(r'category\s+custom\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{([\s\S]*?)\}', multiLine: true);
    final matches = regex.allMatches(source);

    for (final m in matches) {
      final id = m.group(1)!;
      final body = m.group(2)!;
      final label = _extractQuotedValue(body, 'label') ?? id;
      final color = _extractSimpleValue(body, 'color') ?? 'mint';
      final icon = _extractSimpleValue(body, 'icon') ?? 'BookOpen';
      list.add(TDCCategory(id: id, label: label, colorToken: color, iconToken: icon, isCustom: true));
    }
    return list;
  }

  /// Parses a .tdc string containing one or more `course "id" { ... }` declarations.
  static List<Map<String, dynamic>> parseMultiCourse(String source) {
    final courses = <Map<String, dynamic>>[];
    final customCategories = extractCustomCategories(source);

    final courseRegex = RegExp(r'course\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{', multiLine: true);
    final matches = courseRegex.allMatches(source).toList();

    if (matches.isEmpty) {
      final trimmed = source.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map) {
          return [decoded.cast<String, dynamic>()];
        }
      }
      throw FormatException('Aucun bloc \'course "id" { ... }\' trouvé dans le code TDC.');
    }

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final courseId = match.group(1)!;
      final startIdx = match.end;
      final endIdx = (i + 1 < matches.length) ? matches[i + 1].start : source.lastIndexOf('}');
      final blockContent = source.substring(startIdx, endIdx >= startIdx ? endIdx : source.length);

      final courseMap = _parseCourseBody(courseId, blockContent, customCategories);
      courses.add(courseMap);
    }

    return courses;
  }

  /// Parses a single course block into a Map compatible with Course.fromJson.
  static Map<String, dynamic> parseCourse(String source) {
    final courses = parseMultiCourse(source);
    if (courses.isEmpty) {
      throw FormatException("Impossible de parser le cours TDC.");
    }
    return courses.first;
  }

  static Map<String, dynamic> _parseCourseBody(String id, String body, List<TDCCategory> fileCustomCategories) {
    final map = <String, dynamic>{
      'id': id,
      'title': id,
      'description': '',
      'icon': 'BookOpen',
      'accent': 'creme',
      'level': 'beginner',
      'duration': '1h',
      'category': 'linux',
      'author': '',
      'author-key': '',
      'signature': '',
      'keywords': <String>[],
      'content': <Map<String, dynamic>>[],
      'custom_categories': fileCustomCategories.map((c) => c.toJson()).toList(),
    };

    map['title'] = _extractQuotedValue(body, 'title') ?? id;
    map['description'] = _extractQuotedValue(body, 'description') ?? '';
    map['category'] = _extractSimpleValue(body, 'category') ?? 'linux';
    map['accent'] = _extractSimpleValue(body, 'accent') ?? 'creme';
    map['level'] = _extractSimpleValue(body, 'level') ?? 'beginner';
    map['duration'] = _extractSimpleValue(body, 'duration') ?? '1h';
    map['icon'] = _extractSimpleValue(body, 'icon') ?? 'BookOpen';
    map['author'] = _extractQuotedValue(body, 'author') ?? '';
    map['author-key'] = _extractQuotedValue(body, 'author-key') ?? '';
    map['signature'] = _extractQuotedValue(body, 'signature') ?? '';

    // Extraction des keywords
    final kwMatch = RegExp(r'keywords:\s*\[(.*?)\]', dotAll: true).firstMatch(body);
    if (kwMatch != null) {
      final kwStr = kwMatch.group(1)!;
      final kws = kwStr
          .split(',')
          .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
          .where((s) => s.isNotEmpty)
          .toList();
      map['keywords'] = kws;
    }

    // Extraction des modules
    final modules = <Map<String, dynamic>>[];
    final moduleRegex = RegExp(r'module\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{', multiLine: true);
    final moduleMatches = moduleRegex.allMatches(body).toList();

    for (int i = 0; i < moduleMatches.length; i++) {
      final mMatch = moduleMatches[i];
      final moduleId = mMatch.group(1)!;
      final mStart = mMatch.end;
      final mEnd = (i + 1 < moduleMatches.length) ? moduleMatches[i + 1].start : body.lastIndexOf('}');
      final mBody = body.substring(mStart, mEnd >= mStart ? mEnd : body.length);

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
      'markdown': '',
      'content': '',
      'codeBlocks': <Map<String, dynamic>>[],
      'quiz': <Map<String, dynamic>>[],
    };

    // Contenu Markdown
    final contentTriple = RegExp(r'(?:content|markdown)\s+"""([\s\S]*?)"""').firstMatch(body);
    if (contentTriple != null) {
      final mdText = contentTriple.group(1)!.trim();
      module['markdown'] = mdText;
      module['content'] = mdText;
    } else {
      final mdQuoted = _extractQuotedValue(body, 'markdown') ?? _extractQuotedValue(body, 'content') ?? '';
      module['markdown'] = mdQuoted;
      module['content'] = mdQuoted;
    }

    // Extraction des codeblocks
    final codeBlocksList = <Map<String, dynamic>>[];
    final cbRegex = RegExp(r'codeblock\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{([\s\S]*?)\}', multiLine: true);
    final cbMatches = cbRegex.allMatches(body);
    for (final cb in cbMatches) {
      final lang = cb.group(1)!;
      final cbBody = cb.group(2)!;
      final cbTitle = _extractQuotedValue(cbBody, 'title') ?? '';
      final codeTriple = RegExp(r'code\s+"""([\s\S]*?)"""').firstMatch(cbBody);
      final codeText = codeTriple != null
          ? codeTriple.group(1)!.trim()
          : (_extractQuotedValue(cbBody, 'code') ?? '');
      codeBlocksList.add({'language': lang, 'title': cbTitle, 'code': codeText});
    }
    module['codeBlocks'] = codeBlocksList;

    // Extraction des questions QCM
    final quizList = <Map<String, dynamic>>[];
    final qRegex = RegExp(r'question\s+["' "'" r']([^"' "'" r']+)["' "'" r']\s*\{', multiLine: true);
    final qMatches = qRegex.allMatches(body).toList();

    for (int j = 0; j < qMatches.length; j++) {
      final qMatch = qMatches[j];
      final questionText = qMatch.group(1)!;
      final qStart = qMatch.end;
      final qEnd = (j + 1 < qMatches.length) ? qMatches[j + 1].start : body.length;
      final qBody = body.substring(qStart, qEnd);

      final optionsList = <String>[];
      final optBlockMatch = RegExp(r'options:\s*\[(.*?)\]', dotAll: true).firstMatch(qBody);
      if (optBlockMatch != null) {
        final optStr = optBlockMatch.group(1)!;
        final opts = RegExp(r'["' "'" r']([^"' "'" r']+)["' "'" r']')
            .allMatches(optStr)
            .map((m) => m.group(1)!)
            .toList();
        optionsList.addAll(opts);
      }

      int correctAnswer = 0;
      final correctMatch = RegExp(r'correctAnswer:\s*(\d+)').firstMatch(qBody);
      if (correctMatch != null) {
        correctAnswer = int.tryParse(correctMatch.group(1)!) ?? 0;
      }

      for (final line in qBody.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('- ') || trimmed.startsWith('+ ')) {
          final isCorrect = trimmed.startsWith('+ ');
          var val = trimmed.substring(2).trim();
          if ((val.startsWith('"') && val.endsWith('"')) ||
              (val.startsWith("'") && val.endsWith("'"))) {
            if (val.length >= 2) {
              val = val.substring(1, val.length - 1);
            }
          }
          if (val.isNotEmpty && !optionsList.contains(val)) {
            if (isCorrect) {
              correctAnswer = optionsList.length;
            }
            optionsList.add(val);
          }
        }
      }

      final explanation = _extractQuotedValue(qBody, 'explanation') ?? '';

      quizList.add({
        'question': questionText,
        'options': optionsList,
        'choices': optionsList,
        'correctIndex': correctAnswer,
        'correctAnswer': correctAnswer,
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
    final match = RegExp('$key:\\s*([a-zA-Z0-9_\\-\\.\\+]+)', multiLine: true).firstMatch(text);
    return match?.group(1);
  }

  /// Converts a JSON course map into readable TDC DSL syntax v2.
  static String serializeToTdc(Map<String, dynamic> course) {
    final sb = StringBuffer();
    final catId = course['category'] ?? 'linux';

    // Sérialisation des catégories custom si le cours utilise une catégorie custom
    final customCats = (course['custom_categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final c in customCats) {
      sb.writeln('category custom "${c['id']}" {');
      sb.writeln('  label: "${c['label']}"');
      sb.writeln('  color: ${c['colorToken'] ?? 'mint'}');
      sb.writeln('  icon: ${c['iconToken'] ?? 'BookOpen'}');
      sb.writeln('}');
      sb.writeln();
    }

    final id = course['id'] ?? 'nouveau-cours';
    sb.writeln('course "$id" {');
    sb.writeln('  title: "${course['title'] ?? 'Nouveau Cours'}"');
    sb.writeln('  description: "${course['description'] ?? ''}"');
    sb.writeln('  category: $catId');
    if (course['accent'] != null && course['accent'].toString().isNotEmpty && course['accent'] != 'creme') {
      sb.writeln('  accent: ${course['accent']}');
    }
    sb.writeln('  level: ${course['level'] ?? 'beginner'}');
    sb.writeln('  duration: ${course['duration'] ?? '1h'}');
    sb.writeln('  icon: ${course['icon'] ?? 'BookOpen'}');

    if (course['author'] != null && course['author'].toString().isNotEmpty) {
      sb.writeln('  author: "${course['author']}"');
    }
    if (course['author-key'] != null && course['author-key'].toString().isNotEmpty) {
      sb.writeln('  author-key: "${course['author-key']}"');
    }

    final keywords = (course['keywords'] as List?)?.cast<String>() ?? [];
    if (keywords.isNotEmpty) {
      final kwFormatted = keywords.map((k) => '"$k"').join(', ');
      sb.writeln('  keywords: [$kwFormatted]');
    }

    final modules = (course['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final mod in modules) {
      sb.writeln();
      final mId = mod['id'] ?? 'module-1';
      sb.writeln('  module "$mId" {');
      sb.writeln('    title: "${mod['title'] ?? mId}"');
      sb.writeln('    duration: ${mod['duration'] ?? '15min'}');

      final md = mod['markdown'] ?? mod['content'] ?? '';
      if (md.toString().isNotEmpty) {
        sb.writeln('    content """');
        sb.writeln(md);
        sb.writeln('    """');
      }

      final codeBlocks = (mod['codeBlocks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final cb in codeBlocks) {
        final lang = cb['language'] ?? 'text';
        final cbTitle = cb['title'] ?? '';
        final code = cb['code'] ?? '';
        sb.writeln('    codeblock "$lang" {');
        if (cbTitle.toString().isNotEmpty) {
          sb.writeln('      title: "$cbTitle"');
        }
        sb.writeln('      code """');
        sb.writeln(code);
        sb.writeln('      """');
        sb.writeln('    }');
      }

      final quiz = (mod['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (quiz.isNotEmpty) {
        sb.writeln('    quiz {');
        for (final q in quiz) {
          final qText = q['question'] ?? 'Question ?';
          sb.writeln('      question "$qText" {');
          final opts = (q['options'] as List?)?.cast<String>() ?? [];
          final optsFormatted = opts.map((o) => '"$o"').join(', ');
          sb.writeln('        options: [$optsFormatted]');
          sb.writeln('        correctAnswer: ${q['correctAnswer'] ?? 0}');
          if (q['explanation'] != null && q['explanation'].toString().isNotEmpty) {
            sb.writeln('        explanation: "${q['explanation']}"');
          }
          sb.writeln('      }');
        }
        sb.writeln('    }');
      }

      sb.writeln('  }');
    }

    if (course['signature'] != null && course['signature'].toString().isNotEmpty) {
      sb.writeln();
      sb.writeln('  signature: "${course['signature']}"');
    }

    sb.writeln('}');
    return sb.toString();
  }
}
