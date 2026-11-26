// SPDX-License-Identifier: GPL-3.0-only
// Vérifie chaque cours .tdc livré avec l'application (assets/courses/<langue>/).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/services/tdc_dsl_parser.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadAll : cours .tdc + anciens cours JSON non encore remplacés', () async {
    final cours = await Course.loadAll('fr');
    final ids = cours.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'aucun cours en double');
    expect(ids, contains('ipv6'));
    expect(ids, contains('linux-basics'), reason: 'ancien cours pas encore réécrit');
    expect(ids, isNot(contains('bash-scripting')),
        reason: 'remplacé par assets/courses/fr/bash-scripting.tdc');
  });

  final fichiers = <File>[
    for (final langue in ['fr', 'en'])
      if (Directory('assets/courses/$langue').existsSync())
        ...Directory('assets/courses/$langue')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.tdc')),
  ]..sort((a, b) => a.path.compareTo(b.path));

  test('au moins un cours .tdc en français', () {
    expect(fichiers.where((f) => f.path.contains('/fr/')), isNotEmpty);
  });

  for (final f in fichiers) {
    test('cours valide : ${f.path}', () {
      final course = Course.fromMap(TdcDslParser.parse(f.readAsStringSync()));
      expect(course.title, isNotEmpty);
      expect(course.chapters.length, greaterThanOrEqualTo(6),
          reason: 'un cours complet a au moins 6 chapitres');
      for (final ch in course.chapters) {
        expect(ch.content.trim(), isNotEmpty, reason: 'chapitre ${ch.id} vide');
        final quiz = ch.quiz ?? const <QuizQuestion>[];
        expect(quiz, isNotEmpty, reason: 'chapitre ${ch.id} sans questionnaire');
        if (ch.quizPick != null) {
          expect(quiz.length, greaterThanOrEqualTo(ch.quizPick!),
              reason: 'chapitre ${ch.id} : banque plus petite que pick');
        }
        for (final q in quiz) {
          expect(q.choices.length, greaterThanOrEqualTo(2),
              reason: '${ch.id} : « ${q.question} »');
          expect(q.correctIndex, inInclusiveRange(0, q.choices.length - 1),
              reason: '${ch.id} : « ${q.question} »');
          expect(q.choices.toSet().length, q.choices.length,
              reason: '${ch.id} : réponses en double dans « ${q.question} »');
        }
      }
    });
  }

  test('un cours anglais a son équivalent français (même nom de fichier)', () {
    final fr = fichiers
        .where((f) => f.path.contains('/fr/'))
        .map((f) => f.uri.pathSegments.last)
        .toSet();
    for (final f in fichiers.where((f) => f.path.contains('/en/'))) {
      expect(fr, contains(f.uri.pathSegments.last));
    }
  });
}
