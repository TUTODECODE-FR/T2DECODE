// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// TDC DSL parser — implements TDC_SPEC.md v1.0 EBNF grammar.
// Converts a .tdc source string into a list of raw course maps
// compatible with Course.fromMap().
import 'package:flutter/foundation.dart';

class TdcParseError {
  final int line;
  final String message;
  TdcParseError(this.line, this.message);
  @override
  String toString() => 'TDC parse error at line $line: $message';
}

class TdcParser {
  final String _src;
  int _pos = 0;
  int _line = 1;

  TdcParser(this._src);

  // ── Public entry point ────────────────────────────────────────────────────

  /// Parses a full .tdc source and returns a list of course maps
  /// compatible with [Course.fromMap].
  static List<Map<String, dynamic>> parse(String source) {
    final parser = TdcParser(source);
    return parser._parseCourses();
  }

  /// Parses a cheat sheet `.tdc` source (blocks `entry "id" { ... }`).
  static List<Map<String, dynamic>> parseCheatSheets(String source) {
    final parser = TdcParser(source);
    return parser._parseCheatEntries();
  }

  List<Map<String, dynamic>> _parseCheatEntries() {
    final entries = <Map<String, dynamic>>[];
    _skipWhitespaceAndComments();
    while (_pos < _src.length) {
      _expect('entry');
      entries.add(_parseCheatEntry());
      _skipWhitespaceAndComments();
    }
    return entries;
  }

  Map<String, dynamic> _parseCheatEntry() {
    _skipWhitespace();
    _parseString(); // entry id (informational)
    _skipWhitespace();
    _expectChar('{');

    final entry = <String, dynamic>{
      'command': '',
      'description': '',
      'category': '',
      'dangerLevel': 1,
    };

    _skipWhitespaceAndComments();
    while (_pos < _src.length && _peek() != '}') {
      final key = _parseIdent();
      _skipWhitespace();
      _expectChar(':');
      _skipWhitespace();

      if (key == 'command' || key == 'description') {
        entry[key] = _parseString();
      } else if (key == 'category') {
        entry['category'] = _parseStringOrBare();
      } else if (key == 'dangerLevel') {
        entry['dangerLevel'] = _parseInt();
      } else if (key == 'explanation') {
        entry['detailedExplanation'] = _src.startsWith('"""', _pos)
            ? _parseTripleString()
            : _parseString();
      } else if (key == 'options' || key == 'examples') {
        entry[key] = _parseList();
      } else if (key == 'colorHex') {
        entry['colorHex'] = _parseStringOrBare();
      } else if (key == 'iconName') {
        entry['iconName'] = _parseIdent();
      } else {
        _skipValue();
      }
      _skipWhitespaceAndComments();
    }
    _expectChar('}');
    return entry;
  }

  int _parseInt() {
    _skipWhitespace();
    final start = _pos;
    while (_pos < _src.length && RegExp(r'[0-9]').hasMatch(_src[_pos])) {
      _pos++;
    }
    if (start == _pos) {
      throw TdcParseError(_line, 'Expected integer');
    }
    return int.parse(_src.substring(start, _pos));
  }

  void _skipValue() {
    if (_peek() == '"') {
      if (_src.startsWith('"""', _pos)) {
        _parseTripleString();
      } else {
        _parseString();
      }
    } else if (_peek() == '[') {
      _parseList();
    } else {
      while (_pos < _src.length && _src[_pos] != '\n' && _src[_pos] != '}') {
        _pos++;
      }
    }
  }

  // ── Top-level ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _parseCourses() {
    final courses = <Map<String, dynamic>>[];
    _skipWhitespaceAndComments();
    while (_pos < _src.length) {
      _expect('course');
      courses.add(_parseCourse());
      _skipWhitespaceAndComments();
    }
    return courses;
  }

  Map<String, dynamic> _parseCourse() {
    _skipWhitespace();
    final id = _parseString();
    _skipWhitespace();
    _expectChar('{');

    final course = <String, dynamic>{
      'id': id,
      'title': '',
      'description': '',
      'category': 'linux',
      'level': 'beginner',
      'duration': '',
      'icon': 'BookOpen',
      'keywords': <String>[],
      'content': <Map<String, dynamic>>[],
    };

    _skipWhitespaceAndComments();
    while (_pos < _src.length && _peek() != '}') {
      final key = _parseIdent();
      _skipWhitespace();
      if (key == 'title') {
        _expectChar(':'); _skipWhitespace();
        course['title'] = _parseString();
      } else if (key == 'description') {
        _expectChar(':'); _skipWhitespace();
        course['description'] = _parseString();
      } else if (key == 'category') {
        _expectChar(':'); _skipWhitespace();
        course['category'] = _parseIdent();
      } else if (key == 'level') {
        _expectChar(':'); _skipWhitespace();
        course['level'] = _parseIdent();
      } else if (key == 'duration') {
        _expectChar(':'); _skipWhitespace();
        course['duration'] = _parseStringOrBare();
      } else if (key == 'icon') {
        _expectChar(':'); _skipWhitespace();
        course['icon'] = _parseIdent();
      } else if (key == 'keywords') {
        _expectChar(':'); _skipWhitespace();
        course['keywords'] = _parseList();
      } else if (key == 'module') {
        final mod = _parseModule();
        (course['content'] as List<Map<String, dynamic>>).add(mod);
      } else {
        _skipToNextLine();
      }
      _skipWhitespaceAndComments();
    }
    _expectChar('}');
    return course;
  }

  Map<String, dynamic> _parseModule() {
    _skipWhitespace();
    final id = _parseString();
    _skipWhitespace();
    _expectChar('{');

    final module = <String, dynamic>{
      'id': id,
      'title': '',
      'duration': '15min',
      'content': '',
      'codeBlocks': <Map<String, dynamic>>[],
      'quiz': <Map<String, dynamic>>[],
    };

    _skipWhitespaceAndComments();
    while (_pos < _src.length && _peek() != '}') {
      final key = _parseIdent();
      _skipWhitespace();
      if (key == 'title') {
        _expectChar(':'); _skipWhitespace();
        module['title'] = _parseString();
      } else if (key == 'duration') {
        _expectChar(':'); _skipWhitespace();
        module['duration'] = _parseStringOrBare();
      } else if (key == 'content') {
        _skipWhitespace();
        module['content'] = _parseTripleString();
      } else if (key == 'codeblock') {
        (module['codeBlocks'] as List<Map<String, dynamic>>).add(_parseCodeBlock());
      } else if (key == 'quiz') {
        module['quiz'] = _parseQuiz();
      } else {
        _skipToNextLine();
      }
      _skipWhitespaceAndComments();
    }
    _expectChar('}');

    if ((module['codeBlocks'] as List).isEmpty) module.remove('codeBlocks');
    if ((module['quiz'] as List).isEmpty) module.remove('quiz');
    return module;
  }

  Map<String, dynamic> _parseCodeBlock() {
    _skipWhitespace();
    final lang = _parseString();
    _skipWhitespace();
    _expectChar('{');

    String title = '';
    String code = '';

    _skipWhitespaceAndComments();
    while (_pos < _src.length && _peek() != '}') {
      final key = _parseIdent();
      _skipWhitespace();
      if (key == 'title') {
        _expectChar(':'); _skipWhitespace();
        title = _parseString();
      } else if (key == 'code') {
        _skipWhitespace();
        code = _parseTripleString();
      } else {
        _skipToNextLine();
      }
      _skipWhitespaceAndComments();
    }
    _expectChar('}');
    return {'language': lang, 'title': title, 'code': code};
  }

  List<Map<String, dynamic>> _parseQuiz() {
    _skipWhitespace();
    _expectChar('{');

    final questions = <Map<String, dynamic>>[];
    _skipWhitespaceAndComments();
    while (_pos < _src.length && _peek() != '}') {
      final key = _parseIdent();
      if (key == 'question') {
        questions.add(_parseQuestion());
      } else {
        _skipToNextLine();
      }
      _skipWhitespaceAndComments();
    }
    _expectChar('}');
    return questions;
  }

  Map<String, dynamic> _parseQuestion() {
    _skipWhitespace();
    final text = _parseString();
    _skipWhitespace();
    _expectChar('{');

    final choices = <String>[];
    int correctIndex = 0;
    String? explanation;

    _skipWhitespaceAndComments();
    while (_pos < _src.length && _peek() != '}') {
      final ch = _peek();
      if (ch == '+' || ch == '-') {
        final isCorrect = ch == '+';
        _pos++;
        _skipWhitespace();
        final choice = _parseString();
        if (isCorrect) correctIndex = choices.length;
        choices.add(choice);
      } else {
        final key = _parseIdent();
        if (key == 'explanation') {
          _skipWhitespace();
          if (_peek() == ':') { _pos++; _skipWhitespace(); }
          explanation = _parseString();
        } else {
          _skipToNextLine();
        }
      }
      _skipWhitespaceAndComments();
    }
    _expectChar('}');

    final q = <String, dynamic>{
      'question': text,
      'choices': choices,
      'correctIndex': correctIndex,
    };
    if (explanation != null) q['explanation'] = explanation;
    return q;
  }

  // ── Lexer primitives ──────────────────────────────────────────────────────

  String _peek() {
    if (_pos >= _src.length) return '';
    return _src[_pos];
  }

  void _skipWhitespace() {
    while (_pos < _src.length) {
      final c = _src[_pos];
      if (c == '\n') {
        _line++;
        _pos++;
      } else if (c == ' ' || c == '\t' || c == '\r') {
        _pos++;
      } else {
        break;
      }
    }
  }

  void _skipWhitespaceAndComments() {
    while (_pos < _src.length) {
      _skipWhitespace();
      if (_pos + 1 < _src.length && _src[_pos] == '/' && _src[_pos + 1] == '/') {
        while (_pos < _src.length && _src[_pos] != '\n') { _pos++; }
      } else if (_pos + 1 < _src.length && _src[_pos] == '#') {
        while (_pos < _src.length && _src[_pos] != '\n') { _pos++; }
      } else {
        break;
      }
    }
  }

  void _skipToNextLine() {
    while (_pos < _src.length && _src[_pos] != '\n') { _pos++; }
  }

  void _expect(String keyword) {
    _skipWhitespaceAndComments();
    if (!_src.startsWith(keyword, _pos)) {
      throw TdcParseError(_line, 'Expected "$keyword"');
    }
    _pos += keyword.length;
  }

  void _expectChar(String ch) {
    _skipWhitespace();
    if (_pos >= _src.length || _src[_pos] != ch) {
      throw TdcParseError(_line, 'Expected "$ch", got "${_peek()}"');
    }
    _pos++;
  }

  String _parseIdent() {
    final buf = StringBuffer();
    while (_pos < _src.length) {
      final c = _src[_pos];
      if (RegExp(r'[\w\-]').hasMatch(c)) {
        buf.write(c);
        _pos++;
      } else {
        break;
      }
    }
    return buf.toString();
  }

  /// Parses a quoted "..." string (single-line, with \\" escape support).
  String _parseString() {
    if (_peek() != '"') {
      throw TdcParseError(_line, 'Expected "...", got "${_peek()}"');
    }
    _pos++; // opening "
    final buf = StringBuffer();
    while (_pos < _src.length) {
      final c = _src[_pos];
      if (c == '\\' && _pos + 1 < _src.length && _src[_pos + 1] == '"') {
        buf.write('"');
        _pos += 2;
      } else if (c == '"') {
        _pos++;
        break;
      } else {
        if (c == '\n') _line++;
        buf.write(c);
        _pos++;
      }
    }
    return buf.toString();
  }

  /// Parses either "quoted" or bare word (for duration like 15min, 2h).
  String _parseStringOrBare() {
    if (_peek() == '"') return _parseString();
    return _parseIdent();
  }

  /// Parses a triple-quoted string: """..."""
  /// Closing delimiter must be alone on its line (only whitespace before/after),
  /// so embedded Python/docstring """ inside content does not terminate early.
  String _parseTripleString() {
    if (!_src.startsWith('"""', _pos)) {
      throw TdcParseError(_line, 'Expected triple-quoted string """');
    }
    _pos += 3;
    // Skip immediate newline after opening """
    if (_pos < _src.length && _src[_pos] == '\n') {
      _line++;
      _pos++;
    }
    final start = _pos;
    while (_pos < _src.length) {
      if (_src.startsWith('"""', _pos) && _isTripleStringClosingDelimiter(_pos)) {
        final raw = _src.substring(start, _pos);
        _pos += 3;
        return _dedent(raw).trimRight();
      }
      if (_src[_pos] == '\n') _line++;
      _pos++;
    }
    throw TdcParseError(_line, 'Unterminated triple-quoted string');
  }

  /// True when [pos] points to a line that contains only optional whitespace + """.
  bool _isTripleStringClosingDelimiter(int pos) {
    final lineStart = _src.lastIndexOf('\n', pos - 1) + 1;
    final lineEnd = _src.indexOf('\n', pos);
    final line = _src.substring(
      lineStart,
      lineEnd == -1 ? _src.length : lineEnd,
    );
    return line.trim() == '"""';
  }

  /// Removes common leading indent from a multi-line block.
  String _dedent(String block) {
    final lines = block.split('\n');
    int? minIndent;
    for (final l in lines) {
      if (l.trim().isEmpty) continue;
      final indent = l.length - l.trimLeft().length;
      if (minIndent == null || indent < minIndent) minIndent = indent;
    }
    if (minIndent == null || minIndent == 0) return block;
    return lines.map((l) => l.length >= minIndent! ? l.substring(minIndent) : l).join('\n');
  }

  /// Parses a bracketed list: [item1, item2, ...]
  /// Items may be bare identifiers or quoted strings; commas inside quoted
  /// strings are allowed. Unquoted items may contain / and spaces (e.g. TCP/IP).
  List<String> _parseList() {
    _expectChar('[');
    final items = <String>[];
    _skipWhitespace();
    while (_peek() != ']' && _pos < _src.length) {
      String item;
      if (_peek() == '"') {
        item = _parseString();
      } else {
        item = _parseListItem();
      }
      if (item.isNotEmpty) items.add(item);
      _skipWhitespace();
      if (_peek() == ',') {
        _pos++;
        _skipWhitespace();
      } else if (_peek() != ']' && _pos < _src.length) {
        // Skip stray characters (malformed lists) to avoid infinite loops.
        _pos++;
      }
    }
    _expectChar(']');
    return items;
  }

  /// Reads a single unquoted list item until `,` or `]`.
  String _parseListItem() {
    final start = _pos;
    while (_pos < _src.length) {
      final c = _src[_pos];
      if (c == ',' || c == ']') break;
      _pos++;
    }
    return _src.substring(start, _pos).trim();
  }
}

/// Parses cheat sheet `.tdc`; returns [] on error.
List<Map<String, dynamic>> parseCheatSheetsSafe(String source) {
  try {
    return TdcParser.parseCheatSheets(source);
  } catch (e) {
    if (kDebugMode) debugPrint('[TdcParser:cheats] $e');
    return [];
  }
}

/// Convenience function — parses a .tdc string; returns [] on error.
List<Map<String, dynamic>> parseTdcSafe(String source) {
  try {
    return TdcParser.parse(source);
  } catch (e) {
    if (kDebugMode) debugPrint('[TdcParser] $e');
    return [];
  }
}
