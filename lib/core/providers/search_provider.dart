// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/features/courses/data/cheat_sheet_repository.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/features/courses/screens/cheat_sheet_screen.dart';

class SearchDocKind {
  static const String course = 'course';
  static const String chapter = 'chapter';
  static const String cheat = 'cheat';
}

class SearchDocument {
  final String id;
  final String kind;
  final String title;
  final String body;
  final Map<String, String> nav; // route + ids

  const SearchDocument({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.nav,
  });
}

class SearchResult {
  final SearchDocument doc;
  final double score;
  final bool favorite;
  const SearchResult(
      {required this.doc, required this.score, required this.favorite});
}

class SearchProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<SearchDocument> _docs = const [];
  Map<String, Map<String, int>> _tfByDoc = const {};
  Map<String, int> _df = const {};
  Map<String, int> _docLen = const {};

  List<String> _favorites = const [];
  List<String> _history = const [];

  bool _ready = false;
  bool get ready => _ready;

  List<String> get favorites => _favorites;
  List<String> get history => _history;

  SearchDocument? docById(String id) {
    for (final d in _docs) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> init(CoursesProvider courses) async {
    _favorites = await _storage.getSearchFavorites();
    _history = await _storage.getSearchHistory();
    await rebuildIndex(courses);
  }

  Future<void> rebuildIndex(CoursesProvider courses) async {
    final docs = <SearchDocument>[];

    for (final course in courses.courses) {
      docs.add(SearchDocument(
        id: 'course:${course.id}',
        kind: SearchDocKind.course,
        title: course.title,
        body: '''${course.description}
${course.category}
${course.keywords.join(' ')}''',
        nav: {'route': '/', 'courseId': course.id},
      ));

      for (final ch in course.chapters) {
        docs.add(SearchDocument(
          id: 'chapter:${course.id}:${ch.id}',
          kind: SearchDocKind.chapter,
          title: '${course.title} — ${ch.title}',
          body: ch.content,
          nav: {'route': '/chapter', 'courseId': course.id, 'chapterId': ch.id},
        ));
      }
    }

    try {
      final cheatSheets = await CheatSheetRepository.loadAll();
      for (final entry in cheatSheets) {
        docs.add(_cheatDoc(entry));
      }
    } catch (_) {}

    final tfByDoc = <String, Map<String, int>>{};
    final df = <String, int>{};
    final docLen = <String, int>{};

    for (final d in docs) {
      final tokens = _tokenize('''${d.title}
${d.body}''');
      docLen[d.id] = tokens.length;
      final tf = <String, int>{};
      for (final t in tokens) {
        tf[t] = (tf[t] ?? 0) + 1;
      }
      tfByDoc[d.id] = tf;
      for (final t in tf.keys) {
        df[t] = (df[t] ?? 0) + 1;
      }
    }

    _docs = docs;
    _tfByDoc = tfByDoc;
    _df = df;
    _docLen = docLen;
    _ready = true;
    notifyListeners();
  }

  /// Effectue une recherche optimisée avec tolérance aux fautes de frappe.
  /// Utilise une combinaison de BM25, Trigrammes et de la distance de Levenshtein.
  List<SearchResult> search(String query, {int limit = 20}) {
    final q = query.trim();
    if (q.isEmpty || !_ready) return const [];

    final qTokens = _tokenize(q);
    final results = <SearchResult>[];

    for (final d in _docs) {
      final score = _bm25(d.id, qTokens);
      var finalScore = score > 0
          ? score
          : _trigramScore(q.toLowerCase(), d.title.toLowerCase());

      // Si aucun résultat direct, tenter la correspondance floue (tolérance aux fautes de frappe)
      if (finalScore <= 0 && q.length >= 3) {
        finalScore = _fuzzyScore(
            q.toLowerCase(), d.title.toLowerCase(), d.body.toLowerCase());
      }

      if (finalScore <= 0) continue;
      results.add(SearchResult(
        doc: d,
        score: finalScore,
        favorite: _favorites.contains(d.id),
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    if (results.length > limit) return results.sublist(0, limit);
    return results;
  }

  /// Calcule un score de tolérance aux fautes de frappe basé sur la distance de Levenshtein.
  /// Permet jusqu'à 2 fautes de frappe pour les requêtes de plus de 4 caractères.
  double _fuzzyScore(String query, String title, String body) {
    final titleWords = _tokenize(title);
    final queryWords = _tokenize(query);
    double maxScore = 0.0;

    for (final qWord in queryWords) {
      if (qWord.length < 3) continue;
      final maxAllowedDistance = qWord.length <= 4 ? 1 : 2;

      for (final tWord in titleWords) {
        final dist = _levenshteinDistance(qWord, tWord);
        if (dist <= maxAllowedDistance) {
          final similarity = 1.0 - (dist / max(qWord.length, tWord.length));
          if (similarity > maxScore) {
            maxScore = similarity * 0.75; // Score pondéré pour faute de frappe
          }
        }
      }
    }
    return maxScore;
  }

  /// Algorithme de calcul de la distance de Levenshtein (nombre minimal de modifications pour passer d'un mot à un autre).
  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);

    for (var i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (var j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  /// Enregistre une requête dans l'historique de recherche utilisateur.
  Future<void> recordQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    await _storage.pushSearchHistory(q);
    _history = [q, ..._history.where((x) => x != q)].take(20).toList();
    notifyListeners();
  }

  /// Active ou désactive un document des favoris de recherche.
  Future<void> toggleFavorite(String docId) async {
    final next = [..._favorites];
    if (next.contains(docId)) {
      next.remove(docId);
    } else {
      next.insert(0, docId);
    }
    _favorites = next;
    await _storage.setSearchFavorites(_favorites);
    notifyListeners();
  }

  /// Efface l'historique de recherche sauvegardé.
  Future<void> clearHistory() async {
    await _storage.clearSearchHistory();
    _history = const [];
    notifyListeners();
  }

  /// Convertit une entrée de fiches réseau/commandes en document de recherche.
  SearchDocument _cheatDoc(CheatSheetEntry entry) {
    final id = 'cheat:${entry.category}:${entry.command}';
    final bodyParts = <String>[
      entry.description,
      entry.detailedExplanation ?? '',
      ...(entry.options ?? const []),
      ...(entry.examples ?? const []),
    ];
    return SearchDocument(
      id: id,
      kind: SearchDocKind.cheat,
      title: '${entry.command} — ${entry.description}',
      body: bodyParts.join('\n'),
      nav: {
        'route': '/cheat-sheets',
        'command': entry.command,
        'category': entry.category,
      },
    );
  }

  /// Calcul de pertinence selon le modèle probabiliste BM25.
  double _bm25(String docId, List<String> qTokens) {
    final tf = _tfByDoc[docId];
    if (tf == null) return 0;
    final docLength = _docLen[docId] ?? 0;
    if (docLength == 0) return 0;
    final n = _docs.length;
    final avgdl = _docLen.values.isEmpty
        ? 1.0
        : _docLen.values.reduce((a, b) => a + b) / _docLen.length;

    const k1 = 1.2;
    const b = 0.75;
    var score = 0.0;

    for (final term in qTokens) {
      final f = tf[term] ?? 0;
      if (f == 0) continue;
      final dfi = _df[term] ?? 0;
      final idf = log(1 + (n - dfi + 0.5) / (dfi + 0.5));
      final denom = f + k1 * (1 - b + b * (docLength / avgdl));
      score += idf * ((f * (k1 + 1)) / denom);
    }
    return score;
  }

  /// Score d'intersection par n-grammes de 3 lettres.
  double _trigramScore(String q, String text) {
    if (q.length < 3) return text.contains(q) ? 0.1 : 0.0;
    final qSet = _trigrams(q);
    final tSet = _trigrams(text);
    if (qSet.isEmpty || tSet.isEmpty) return 0.0;
    final inter = qSet.intersection(tSet).length;
    final union = qSet.union(tSet).length;
    return union == 0 ? 0.0 : inter / union;
  }

  /// Extrait l'ensemble des trigrammes d'une chaîne de caractères.
  Set<String> _trigrams(String s) {
    final out = <String>{};
    final cleaned = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    for (var i = 0; i + 3 <= cleaned.length; i++) {
      out.add(cleaned.substring(i, i + 3));
    }
    return out;
  }

  /// Découpe le texte en jetons de mots nettoyés.
  List<String> _tokenize(String s) {
    return s
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9à-ÿ]+'))
        .where((t) => t.length >= 2)
        .take(10000)
        .toList();
  }
}
