// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';

import 'package:tutodecode/core/services/tdc_dsl_parser.dart';

/// Structural view of a TDC Studio document (.tdc v2).
///
/// A real document is not identified by its extension. It declares
/// `tdc-version`, then `type`, then one root block of that same type.
/// Nested blocks must follow the Studio hierarchy (course/module,
/// cheat_sheet/entry, and the other resource trees).
class TdcStudioDocument {
  static const notStudioMessage =
      "Ce fichier n'est pas un document TDC Studio. L'extension .tdc ne suffit pas : "
      'il faut tdc-version, un type (course, cheat_sheet, locale, template ou asset_pack) '
      'et le bloc racine correspondant.';

  static const resourceTypes = <String>{
    'course',
    'cheat_sheet',
    'locale',
    'template',
    'asset_pack',
  };

  /// Direct child blocks allowed for each parent. `assets` accepts any
  /// asset block (icon, image, ...), matching the Studio parser.
  static const childBlocks = <String, Set<String>>{
    'course': {'module'},
    'module': {'codeblock', 'quiz'},
    'codeblock': {},
    'quiz': {'question'},
    'question': {},
    'cheat_sheet': {'entry'},
    'entry': {},
    'locale': {},
    'template': {'structure', 'modules'},
    'structure': {},
    'modules': {'module'},
    'asset_pack': {'assets'},
    'icon': {},
    'image': {},
  };

  final String version;
  final String type;
  final String id;
  final String title;

  const TdcStudioDocument({
    required this.version,
    required this.type,
    required this.id,
    required this.title,
  });

  String get openedMessage {
    final label = title.isEmpty ? id : title;
    return 'Document TDC Studio «$label» ($type) ouvert.';
  }

  static TdcStudioInspection inspect(String source) {
    try {
      final scanner = _Scanner(source);
      final tokens = scanner.tokenize();
      return _Parser(tokens).parse();
    } on _DocumentError catch (error) {
      return TdcStudioInspection.rejected(
        error.headerSeen ? _hierarchyMessage(error.detail) : notStudioMessage,
      );
    }
  }

  static String _hierarchyMessage(String detail) {
    return 'Document TDC refusé : la hiérarchie est invalide ($detail).';
  }
}

class TdcStudioInspection {
  final TdcStudioDocument? document;
  final String? rejection;

  const TdcStudioInspection._({this.document, this.rejection});

  bool get accepted => document != null;

  factory TdcStudioInspection.accepted(TdcStudioDocument document) {
    return TdcStudioInspection._(document: document);
  }

  factory TdcStudioInspection.rejected(String message) {
    return TdcStudioInspection._(rejection: message);
  }
}

/// Decision applied before any import of a file the user opened.
class TdcOpenDecision {
  final bool importCourse;
  final bool rejected;
  final bool continueLegacy;
  final String? message;
  final TdcStudioDocument? document;

  const TdcOpenDecision._({
    required this.importCourse,
    required this.rejected,
    required this.continueLegacy,
    required this.message,
    required this.document,
  });

  static bool claimsTdc(String value) {
    final base = value.split(RegExp(r'[\\/]')).last.toLowerCase().trim();
    return base.endsWith('.tdc');
  }

  /// [namedTdc] is true when the only thing the caller knows so far is the
  /// file name. Legacy JSON courses and TDCB backups stay on their own path
  /// when [allowLegacyPayloads] is true. Finder open keeps that flag false:
  /// a renamed file is rejected and not imported.
  static TdcOpenDecision decide(
    String text, {
    required bool namedTdc,
    bool allowLegacyPayloads = true,
  }) {
    final inspection = TdcStudioDocument.inspect(text);
    if (inspection.accepted) {
      final document = inspection.document!;
      if (document.type == 'course') {
        return TdcOpenDecision._(
          importCourse: true,
          rejected: false,
          continueLegacy: false,
          message: null,
          document: document,
        );
      }
      return TdcOpenDecision._(
        importCourse: false,
        rejected: false,
        continueLegacy: false,
        message: document.openedMessage,
        document: document,
      );
    }

    final legacyPayload = allowLegacyPayloads &&
        namedTdc &&
        (_isEncryptedBackup(text) ||
            _isJsonCourse(text) ||
            TdcDslParser.isTdcDsl(text));
    if (namedTdc && !legacyPayload) {
      return TdcOpenDecision._(
        importCourse: false,
        rejected: true,
        continueLegacy: false,
        message: inspection.rejection ?? TdcStudioDocument.notStudioMessage,
        document: null,
      );
    }
    return TdcOpenDecision._(
      importCourse: false,
      rejected: false,
      continueLegacy: true,
      message: null,
      document: null,
    );
  }
}

bool _isEncryptedBackup(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map) return false;
    final header = decoded['header'];
    return header is Map && header['magic'] == 'TDCB';
  } catch (_) {
    return false;
  }
}

bool _isJsonCourse(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map) return false;
    return decoded['id'] != null &&
        decoded['content'] is List &&
        decoded['header'] == null &&
        decoded['settings'] == null;
  } catch (_) {
    return false;
  }
}

enum _Kind {
  ident,
  string,
  number,
  colon,
  lbrace,
  rbrace,
  lbracket,
  rbracket,
  comma,
  plus,
  minus,
  newline,
  eof,
}

class _Tok {
  final _Kind kind;
  final String text;
  const _Tok(this.kind, this.text);
}

class _DocumentError implements Exception {
  final String detail;
  final bool headerSeen;
  const _DocumentError(this.detail, {required this.headerSeen});
}

class _Scanner {
  final String _source;
  int _pos = 0;
  bool headerSeen = false;

  _Scanner(String source) : _source = _stripBom(source);

  static String _stripBom(String source) {
    if (source.startsWith('\uFEFF')) return source.substring(1);
    return source;
  }

  List<_Tok> tokenize() {
    final tokens = <_Tok>[];
    while (!_isAtEnd) {
      final char = _peek();
      if (char == '\n') {
        tokens.add(const _Tok(_Kind.newline, '\n'));
        _pos++;
        continue;
      }
      if (char == ' ' || char == '\t' || char == '\r' || char == '\f') {
        _pos++;
        continue;
      }
      if (char == '/' && _peekAt(1) == '/') {
        while (!_isAtEnd && _peek() != '\n') {
          _pos++;
        }
        continue;
      }
      if (char == '{') {
        tokens.add(const _Tok(_Kind.lbrace, '{'));
        _pos++;
        continue;
      }
      if (char == '}') {
        tokens.add(const _Tok(_Kind.rbrace, '}'));
        _pos++;
        continue;
      }
      if (char == '[') {
        tokens.add(const _Tok(_Kind.lbracket, '['));
        _pos++;
        continue;
      }
      if (char == ']') {
        tokens.add(const _Tok(_Kind.rbracket, ']'));
        _pos++;
        continue;
      }
      if (char == ':') {
        tokens.add(const _Tok(_Kind.colon, ':'));
        _pos++;
        continue;
      }
      if (char == ',') {
        tokens.add(const _Tok(_Kind.comma, ','));
        _pos++;
        continue;
      }
      if (char == '+') {
        tokens.add(const _Tok(_Kind.plus, '+'));
        _pos++;
        continue;
      }
      if (char == '-') {
        tokens.add(const _Tok(_Kind.minus, '-'));
        _pos++;
        continue;
      }
      if (char == '"') {
        tokens.add(_Tok(_Kind.string, _string()));
        continue;
      }
      if (_isDigit(char)) {
        tokens.add(_Tok(_Kind.number, _number()));
        continue;
      }
      if (_isIdentStart(char)) {
        final text = _identifier();
        if (text == 'tdc-version') headerSeen = true;
        tokens.add(_Tok(_Kind.ident, text));
        continue;
      }
      throw _DocumentError(
        'caractère inattendu «$char»',
        headerSeen: headerSeen,
      );
    }
    tokens.add(const _Tok(_Kind.eof, ''));
    return tokens;
  }

  String _string() {
    _pos++; // opening quote
    final triple = _peek() == '"' && _peekAt(1) == '"';
    if (triple) {
      _pos += 2;
      final buffer = StringBuffer();
      while (true) {
        if (_isAtEnd) {
          throw _DocumentError(
            'chaîne triple non fermée',
            headerSeen: headerSeen,
          );
        }
        if (_peek() == '"' && _peekAt(1) == '"' && _peekAt(2) == '"') {
          _pos += 3;
          break;
        }
        buffer.write(_source[_pos]);
        _pos++;
      }
      var value = buffer.toString();
      if (value.startsWith('\n')) value = value.substring(1);
      if (value.endsWith('\n')) value = value.substring(0, value.length - 1);
      return value;
    }

    final buffer = StringBuffer();
    while (!_isAtEnd && _peek() != '"') {
      if (_peek() == '\\') {
        _pos++;
        if (_isAtEnd) break;
        final escaped = _source[_pos];
        _pos++;
        switch (escaped) {
          case 'n':
            buffer.write('\n');
            break;
          case 't':
            buffer.write('\t');
            break;
          case 'r':
            buffer.write('\r');
            break;
          default:
            buffer.write(escaped);
            break;
        }
      } else {
        buffer.write(_source[_pos]);
        _pos++;
      }
    }
    if (_isAtEnd) {
      throw _DocumentError('chaîne non fermée', headerSeen: headerSeen);
    }
    _pos++; // closing quote
    return buffer.toString();
  }

  String _number() {
    final start = _pos;
    while (!_isAtEnd && _isDigit(_peek())) {
      _pos++;
    }
    return _source.substring(start, _pos);
  }

  String _identifier() {
    final start = _pos;
    _pos++;
    while (!_isAtEnd && _isIdentPart(_peek())) {
      _pos++;
    }
    return _source.substring(start, _pos);
  }

  bool get _isAtEnd => _pos >= _source.length;
  String _peek() => _isAtEnd ? '\x00' : _source[_pos];
  String _peekAt(int offset) {
    final index = _pos + offset;
    if (index < 0 || index >= _source.length) return '\x00';
    return _source[index];
  }

  static bool _isDigit(String char) =>
      char.compareTo('0') >= 0 && char.compareTo('9') <= 0;

  static bool _isIdentStart(String char) =>
      (char.compareTo('a') >= 0 && char.compareTo('z') <= 0) ||
      (char.compareTo('A') >= 0 && char.compareTo('Z') <= 0) ||
      char == '_';

  static bool _isIdentPart(String char) =>
      _isIdentStart(char) ||
      _isDigit(char) ||
      char == '.' ||
      char == '-' ||
      char == '_';
}

class _Block {
  final String type;
  final String? id;
  final String title;
  final int modules;
  final int entries;

  const _Block({
    required this.type,
    required this.id,
    required this.title,
    required this.modules,
    required this.entries,
  });
}

class _Parser {
  final List<_Tok> _tokens;
  int _pos = 0;
  bool _headerSeen = false;

  _Parser(this._tokens);

  TdcStudioInspection parse() {
    _skipNewlines();
    if (!_is(_Kind.ident) || _peek.text != 'tdc-version') {
      return TdcStudioInspection.rejected(TdcStudioDocument.notStudioMessage);
    }
    _advance();
    _headerSeen = true;
    _expect(_Kind.colon, '«:» après tdc-version');
    if (!_is(_Kind.number) && !_is(_Kind.ident)) {
      _fail('numéro de tdc-version attendu');
    }
    final version = _advance().text;
    if (version != '2') {
      _fail('tdc-version «$version» au lieu de 2');
    }

    _skipNewlines();
    if (!_is(_Kind.ident) || _peek.text != 'type') {
      _fail('clé type absente après tdc-version');
    }
    _advance();
    _expect(_Kind.colon, '«:» après type');
    if (!_is(_Kind.ident)) _fail('type de ressource attendu');
    final type = _advance().text;
    if (!TdcStudioDocument.resourceTypes.contains(type)) {
      _fail('type «$type» inconnu');
    }

    _skipNewlines();
    final block = _parseBlock(null);
    if (block.type != type) {
      _fail(
          'le type déclaré «$type» ne correspond pas au bloc «${block.type}»');
    }
    if (block.id == null || block.id!.isEmpty) {
      _fail('le bloc «$type» n\'a pas d\'identifiant');
    }
    if (type == 'course' && block.modules == 0) {
      _fail('un cours doit contenir au moins un module');
    }
    if (type == 'cheat_sheet' && block.entries == 0) {
      _fail('une cheat_sheet doit contenir au moins une entry');
    }
    _skipNewlines();
    if (!_is(_Kind.eof)) {
      _fail('contenu inattendu après le bloc racine');
    }

    return TdcStudioInspection.accepted(
      TdcStudioDocument(
        version: version,
        type: type,
        id: block.id!,
        title: block.title,
      ),
    );
  }

  _Block _parseBlock(String? parent) {
    if (!_is(_Kind.ident)) {
      _fail('type de bloc attendu');
    }
    final type = _advance().text;
    if (parent != null && !_childAllowed(parent, type)) {
      _fail('le bloc «$type» n\'est pas autorisé dans «$parent»');
    }

    _skipNewlines();
    String? id;
    if (_is(_Kind.string) || (_is(_Kind.ident) && _isAt(1, _Kind.lbrace))) {
      id = _advance().text;
    }
    _skipNewlines();
    _expect(_Kind.lbrace, '«{» pour ouvrir «$type»');

    var title = '';
    var modules = 0;
    var entries = 0;
    while (true) {
      _skipNewlines();
      if (_is(_Kind.rbrace) || _is(_Kind.eof)) break;
      if (_is(_Kind.plus) || _is(_Kind.minus)) {
        _advance();
        _expect(_Kind.string, 'texte de réponse après + ou -');
        continue;
      }
      if (_is(_Kind.ident) && _isAt(1, _Kind.colon)) {
        final key = _advance().text;
        _advance();
        final value = _parseValue();
        if (key == 'title' && title.isEmpty) title = value;
        continue;
      }
      if (_is(_Kind.ident) &&
          _isAt(1, _Kind.string) &&
          !_isAt(2, _Kind.lbrace)) {
        _advance();
        _advance();
        continue;
      }
      final child = _parseBlock(type);
      if (type == 'course' && child.type == 'module') modules++;
      if (type == 'cheat_sheet' && child.type == 'entry') entries++;
    }
    _expect(_Kind.rbrace, '«}» pour fermer «$type»');
    return _Block(
      type: type,
      id: id,
      title: title,
      modules: modules,
      entries: entries,
    );
  }

  bool _childAllowed(String parent, String child) {
    if (parent == 'assets') return true;
    final allowed = TdcStudioDocument.childBlocks[parent];
    if (allowed == null) return false;
    return allowed.contains(child);
  }

  String _parseValue() {
    if (_is(_Kind.string)) return _advance().text;
    // Newlines are not tokens, so the next key sits against this value.
    // Consume one token, plus a unit suffix such as the "min" in "15min".
    if (_is(_Kind.number)) {
      final buffer = StringBuffer(_advance().text);
      if (_is(_Kind.ident) && !_isAt(1, _Kind.colon)) {
        buffer.write(_advance().text);
      }
      return buffer.toString();
    }
    if (_is(_Kind.ident)) return _advance().text;
    if (_is(_Kind.lbracket)) {
      _advance();
      while (!_is(_Kind.rbracket) && !_is(_Kind.eof)) {
        _skipNewlines();
        if (_is(_Kind.rbracket) || _is(_Kind.eof)) break;
        if (_is(_Kind.string) || _is(_Kind.ident) || _is(_Kind.number)) {
          _advance();
        }
        if (_is(_Kind.comma)) _advance();
        if (!_is(_Kind.rbracket) &&
            !_is(_Kind.comma) &&
            !_is(_Kind.string) &&
            !_is(_Kind.ident) &&
            !_is(_Kind.number)) {
          _fail('élément de liste inattendu');
        }
      }
      _expect(_Kind.rbracket, '«]» pour fermer la liste');
      return '';
    }
    _fail('valeur attendue');
  }

  void _skipNewlines() {
    while (_is(_Kind.newline)) {
      _advance();
    }
  }

  void _expect(_Kind kind, String what) {
    if (_is(kind)) {
      _advance();
      return;
    }
    _fail('$what, reçu «${_peek.text}»');
  }

  bool _is(_Kind kind) => _peek.kind == kind;

  bool _isAt(int offset, _Kind kind) {
    final index = _pos + offset;
    if (index < 0 || index >= _tokens.length) return false;
    return _tokens[index].kind == kind;
  }

  _Tok get _peek => _tokens[_pos];

  _Tok _advance() {
    final token = _peek;
    if (_pos + 1 < _tokens.length) _pos++;
    return token;
  }

  Never _fail(String detail) {
    throw _DocumentError(detail, headerSeen: _headerSeen);
  }
}
