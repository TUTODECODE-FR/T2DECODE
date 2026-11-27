// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:tutodecode/features/courses/widgets/lesson_interactive.dart';

QuizQuestion _q(int i) => QuizQuestion(
      question: 'Q$i',
      choices: const ['a', 'b'],
      correctIndex: 0,
    );

void main() {
  test('découpe aux titres, classe exercice et correction', () {
    const md = 'Intro\n\n### Idée\nTexte\n\n### À toi de jouer\nÉnoncé\n\n'
        '### Correction\nSolution\n';
    final s = splitLessonSegments(md);
    expect(s.map((e) => e.kind).toList(), [
      LessonSegmentKind.prose,
      LessonSegmentKind.prose,
      LessonSegmentKind.exercise,
      LessonSegmentKind.correction,
    ]);
    expect(s.first.heading, isNull);
    expect(s.last.markdown, contains('Solution'));
  });

  test('ne coupe pas un titre dans un bloc de code', () {
    const md = '### Partie\n```bash\n### pas un titre\necho ok\n```\nSuite\n';
    final s = splitLessonSegments(md);
    expect(s, hasLength(1));
    expect(s.single.markdown, contains('pas un titre'));
  });

  test('questions de contrôle : banque trop petite = aucune', () {
    expect(checkpointQuestions([for (var i = 0; i < 5; i++) _q(i)]), isEmpty);
    expect(checkpointQuestions(null), isEmpty);
  });

  test('questions de contrôle : fin de banque, 3 au plus', () {
    final bank = [for (var i = 0; i < 15; i++) _q(i)];
    expect(checkpointQuestions(bank).map((q) => q.question),
        ['Q14', 'Q13', 'Q12']);
    expect(
        checkpointQuestions([for (var i = 0; i < 6; i++) _q(i)]), hasLength(2));
  });

  test('entraînements liés au texte', () {
    expect(
      practiceTargetsFor('Calcul du masque de sous-réseau').map((t) => t.labId),
      ['training-subnet'],
    );
    expect(practiceTargetsFor('Histoire du Web'), isEmpty);
    expect(
      practiceTargetsFor('chmod, binaire, routage, terminal'),
      hasLength(2),
    );
  });
}
