// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
//
// Lecteur TUTODECODE Script (.tdc) : transforme les blocs « course » en cartes
// au format des modules T2DECODE (mêmes clés que assets/courses/*.json).
// Même grammaire tolérante que le lecteur Go de T2C Phantom (pkg/tdc).
// Dart pur : aucune dépendance Flutter.

class TdcError implements Exception {
  final String message;
  TdcError(this.message);
  @override
  String toString() => 'TDC : $message';
}

enum _K { eof, word, str, punct }

class _Tok {
  final _K k;
  final String s;
  final int line;
  _Tok(this.k, this.s, this.line);
}

bool _space(int c) => c == 0x20 || c == 0x09 || c == 0x0D || c == 0x0A;

List<_Tok> _lex(String src) {
  final out = <_Tok>[];
  final r = src.runes.toList();
  var line = 1;
  var i = 0;
  String sub(int a, int b) => String.fromCharCodes(r.sublist(a, b));
  while (i < r.length) {
    final c = r[i];
    if (c == 0x0A) {
      line++;
      i++;
    } else if (_space(c)) {
      i++;
    } else if (c == 0x22 && i + 2 < r.length && r[i + 1] == 0x22 && r[i + 2] == 0x22) {
      // """ … """ (\""" = guillemets littéraux)
      var j = i + 3;
      var end = -1;
      while (j + 2 < r.length) {
        if (r[j] == 0x22 && r[j + 1] == 0x22 && r[j + 2] == 0x22 && r[j - 1] != 0x5C) {
          end = j;
          break;
        }
        j++;
      }
      if (end < 0) throw TdcError('ligne $line : """ non fermé');
      final body = sub(i + 3, end);
      out.add(_Tok(_K.str, _dedent(body).replaceAll('\\"""', '"""'), line));
      line += '\n'.allMatches(body).length;
      i = end + 3;
    } else if (c == 0x22) {
      final b = StringBuffer();
      var j = i + 1;
      for (; j < r.length && r[j] != 0x22; j++) {
        if (r[j] == 0x0A) throw TdcError('ligne $line : chaîne non fermée');
        if (r[j] == 0x5C && j + 1 < r.length) {
          j++;
          final e = r[j];
          b.write(e == 0x6E ? '\n' : e == 0x74 ? '\t' : String.fromCharCode(e));
          continue;
        }
        b.writeCharCode(r[j]);
      }
      if (j >= r.length) throw TdcError('ligne $line : chaîne non fermée');
      out.add(_Tok(_K.str, b.toString(), line));
      i = j + 1;
    } else if ('{}[],:'.codeUnits.contains(c)) {
      out.add(_Tok(_K.punct, String.fromCharCode(c), line));
      i++;
    } else if ((c == 0x2B || c == 0x2D) && (i + 1 >= r.length || _space(r[i + 1]) || r[i + 1] == 0x22)) {
      out.add(_Tok(_K.punct, String.fromCharCode(c), line));
      i++;
    } else {
      var j = i;
      while (j < r.length && !_space(r[j]) && !'{}[],:"'.codeUnits.contains(r[j])) {
        j++;
      }
      out.add(_Tok(_K.word, sub(i, j), line));
      i = j;
    }
  }
  out.add(_Tok(_K.eof, '', line));
  return out;
}

int _indent(String l) => l.length - l.trimLeft().length;

String _dedent(String s) {
  var lines = s.split('\n');
  if (lines.length > 1 && lines.first.trim().isEmpty) lines = lines.sublist(1);
  var closing = -1;
  if (lines.length > 1 && lines.last.trim().isEmpty) {
    closing = lines.last.length;
    lines = lines.sublist(0, lines.length - 1);
  }
  var min = -1;
  for (final l in lines) {
    if (l.trim().isEmpty) continue;
    final ind = _indent(l);
    if (min < 0 || ind < min) min = ind;
  }
  if (closing > 0 && closing < min) min = closing;
  return lines.map((l) {
    if (min > 0 && l.length >= min && l.substring(0, min).trim().isEmpty) return l.substring(min);
    if (l.trim().isEmpty) return '';
    return l;
  }).join('\n');
}

class _Node {
  final String kind;
  String name = '';
  final Map<String, Object> fields = {}; // String ou List<String>
  final List<_Node> children = [];
  final List<MapEntry<bool, String>> options = [];
  _Node(this.kind);
  String f(String k) => fields[k] is String ? fields[k] as String : '';
  List<String> list(String k) => fields[k] is List<String> ? fields[k] as List<String> : <String>[];
}

class _Parser {
  final List<_Tok> t;
  var i = 0;
  _Parser(this.t);
  _Tok peek([int o = 0]) => i + o < t.length ? t[i + o] : t.last;
  _Tok next() => t[i++];
  TdcError err(String m) => TdcError('ligne ${peek().line} : $m');

  void items(_Node n, bool top) {
    while (true) {
      final tk = peek();
      if (tk.k == _K.eof) {
        if (top) return;
        throw err('« } » manquant pour ${n.kind} "${n.name}"');
      } else if (tk.k == _K.punct && tk.s == '}') {
        if (top) throw err('« } » en trop');
        next();
        return;
      } else if (tk.k == _K.punct && (tk.s == '+' || tk.s == '-')) {
        next();
        final v = next();
        if (v.k != _K.str && v.k != _K.word) throw err('texte attendu après ${tk.s}');
        n.options.add(MapEntry(tk.s == '+', v.s));
      } else if (tk.k == _K.word) {
        next();
        final isBlock = (peek().k == _K.punct && peek().s == '{') ||
            (peek().k == _K.str && peek(1).k == _K.punct && peek(1).s == '{');
        if (isBlock) {
          final c = _Node(tk.s);
          if (peek().k == _K.str) c.name = next().s;
          next();
          items(c, false);
          n.children.add(c);
          continue;
        }
        if (peek().k == _K.punct && peek().s == ':') next();
        n.fields[tk.s] = value();
      } else {
        throw err('élément inattendu "${tk.s}"');
      }
    }
  }

  Object value() {
    final tk = next();
    if (tk.k == _K.str || tk.k == _K.word) return tk.s;
    if (tk.k == _K.punct && tk.s == '[') {
      final l = <String>[];
      while (true) {
        final e = next();
        if (e.k == _K.punct && e.s == ']') return l;
        if (e.k == _K.punct && e.s == ',') continue;
        if (e.k == _K.str || e.k == _K.word) {
          l.add(e.s);
          continue;
        }
        throw err('liste mal formée');
      }
    }
    throw err('valeur attendue');
  }
}

/// Cours d'un fichier .tdc, au format des modules T2DECODE.
/// La description est ramenée à 500 caractères (limite de l'application).
List<Map<String, dynamic>> parseTdcCourses(String src) {
  final root = _Node('file');
  _Parser(_lex(src)).items(root, true);
  final out = <Map<String, dynamic>>[];
  for (final n in root.children.where((c) => c.kind == 'course')) {
    var desc = n.f('description').trim();
    if (desc.runes.length > 500) desc = '${String.fromCharCodes(desc.runes.take(499)).trim()}…';
    final chapters = <Map<String, dynamic>>[];
    for (final m in n.children.where((c) => c.kind == 'module')) {
      final code = <Map<String, dynamic>>[];
      final quiz = <Map<String, dynamic>>[];
      for (final b in m.children) {
        if (b.kind == 'codeblock') {
          code.add({'language': b.name, 'title': b.f('title'), 'code': b.f('code')});
        } else if (b.kind == 'quiz') {
          for (final q in b.children.where((c) => c.kind == 'question')) {
            final ok = q.options.indexWhere((o) => o.key);
            if (ok < 0) throw TdcError('cours "${n.name}" : question sans bonne réponse (+)');
            quiz.add({
              'question': q.name,
              'choices': q.options.map((o) => o.value).toList(),
              'correctIndex': ok,
              if (q.f('explanation').isNotEmpty) 'explanation': q.f('explanation'),
            });
          }
        }
      }
      chapters.add({
        'id': m.name,
        'title': m.f('title'),
        'duration': m.f('duration'),
        'content': m.f('content'),
        if (code.isNotEmpty) 'codeBlocks': code,
        if (quiz.isNotEmpty) 'quiz': quiz,
      });
    }
    out.add({
      'id': n.name,
      'title': n.f('title'),
      'description': desc,
      'category': n.f('category'),
      'level': n.f('level'),
      'duration': n.f('duration'),
      'icon': n.f('icon'),
      'keywords': n.list('keywords'),
      'content': chapters,
    });
  }
  return out;
}
