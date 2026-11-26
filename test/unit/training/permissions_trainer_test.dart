import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/training/permissions_trainer.dart';
import 'package:tutodecode/features/training/training_kit.dart';

int o(String s) => int.parse(s, radix: 8);

int? chmodOf(String oldMode, String mode,
        {bool dir = false, String umask = '022'}) =>
    applyChmod(o(oldMode), mode, dir: dir, umask: o(umask));

const _alice = UnixAccount('alice', 1001, 'alice', ['dev']);
const _bob = UnixAccount('bob', 1002, 'bob', []);
const _root = UnixAccount('root', 0, 'root', []);

AccessExercise access(
        AccessKind k, UnixAccount u, String mode, String owner, String group,
        {bool dir = false, LsEntry? parent}) =>
    AccessExercise(
        kind: k,
        user: u,
        target: LsEntry('cible', o(mode), owner, group, dir: dir),
        parent: parent);

String answerOf(AccessExercise ex) => ex.solve().answer;

void main() {
  group('Conversions rwx <-> octal', () {
    test('cas connus', () {
      expect(permString(o('755')), 'rwxr-xr-x');
      expect(permString(o('644')), 'rw-r--r--');
      expect(permString(o('4755')), 'rwsr-xr-x');
      expect(permString(o('4644')), 'rwSr--r--');
      expect(permString(o('2775')), 'rwxrwsr-x');
      expect(permString(o('2664')), 'rw-rwSr--');
      expect(permString(o('1777')), 'rwxrwxrwt');
      expect(permString(o('1776')), 'rwxrwxrwT');
      expect(permString(o('6755')), 'rwsr-sr-x');
      expect(permString(0), '---------');
      expect(lsMode(o('2775'), dir: true), 'drwxrwsr-x');
      expect(naturalOctal(o('640')), '640');
      expect(naturalOctal(o('1777')), '1777');
    });

    test('aller-retour sur les 4096 modes', () {
      for (var m = 0; m <= kModeBits; m++) {
        expect(parsePermString(permString(m)), m);
        expect(parsePermAnswer(lsMode(m, dir: true)), m);
        expect(parseOctalAnswer(toOctal(m, 4)), m);
      }
    });

    test('réponses acceptées et refusées', () {
      final ex =
          PermConversionExercise(o('2775'), dir: true, toOctalForm: true);
      expect(ex.check(['2775']).correct, isTrue);
      expect(ex.check(['02775']).correct, isTrue);
      expect(ex.check(['775']).correct, isFalse);
      expect(ex.check(['abc']).correct, isFalse);
      final back =
          PermConversionExercise(o('4755'), dir: false, toOctalForm: false);
      expect(back.check(['-rwsr-xr-x']).correct, isTrue);
      expect(back.check(['-rwSr-xr-x']).correct, isFalse);
      expect(back.check(['rwsr-xr-x']).correct, isFalse);
      expect(back.check(['drwsr-xr-x']).correct, isFalse);
    });
  });

  group('Simulation de chmod (GNU)', () {
    test('symbolique', () {
      expect(chmodOf('644', 'u+x'), o('744'));
      expect(chmodOf('644', 'go-r'), o('600'));
      expect(chmodOf('777', 'a=r'), o('444'));
      expect(chmodOf('000', 'u=rwx,g=rx,o='), o('750'));
      expect(chmodOf('754', 'g=u'), o('774'));
      expect(chmodOf('640', 'o=g'), o('644'));
      expect(chmodOf('644', 'u+x-w'), o('544'));
      expect(chmodOf('644', 'o+X'), o('644'));
      expect(chmodOf('744', 'o+X'), o('745'));
      expect(chmodOf('700', 'o+X', dir: true), o('701'));
      expect(chmodOf('755', 'u+s'), o('4755'));
      expect(chmodOf('755', 'g+s', dir: true), o('2755'));
      expect(chmodOf('777', 'o+t', dir: true), o('1777'));
      expect(chmodOf('2755', 'g-s', dir: true), o('755'));
      expect(chmodOf('6755', 'a-s'), o('755'));
    });

    test('octal et conservation SUID/SGID des dossiers', () {
      expect(chmodOf('4755', '755'), o('755'));
      expect(chmodOf('2755', '755', dir: true), o('2755'));
      expect(chmodOf('2755', '0755', dir: true), o('2755'));
      expect(chmodOf('2755', '00755', dir: true), o('755'));
      expect(chmodOf('2755', '=755', dir: true), o('755'));
      expect(chmodOf('1777', '777', dir: true), o('777'));
      expect(chmodOf('755', '2775', dir: true), o('2775'));
    });

    test('sans u/g/o/a : umask appliqué', () {
      expect(chmodOf('644', '+x'), o('755'));
      expect(chmodOf('644', '+x', umask: '077'), o('744'));
      expect(chmodOf('600', '+w', umask: '002'), o('620'));
      expect(chmodOf('600', '+w'), o('600'));
    });

    test('modes invalides', () {
      for (final bad in [
        '',
        'u',
        'u+x,',
        'z+x',
        'u+q',
        'u+7',
        '+7x',
        '77777'
      ]) {
        expect(ChmodMode.parse(bad).valid, isFalse, reason: bad);
      }
    });

    test('bug corrigé : très long nombre octal sans exception', () {
      final long = '7' * 40;
      expect(ChmodMode.parse(long).valid, isFalse);
      expect(ChmodMode.parse('=$long').valid, isFalse);
      expect(chmodOf('2755', '${'0' * 40}755', dir: true), o('755'));
      final ex = ChmodExercise(o('644'), o('755'), dir: false, name: 'f');
      expect(ex.check(['chmod $long f']).correct, isFalse);
      expect(ex.check(['chmod +$long f']).correct, isFalse);
    });

    test('bug corrigé : sudo et -- acceptés devant le mode', () {
      expect(
          evaluateChmodCommand('sudo chmod 755 f', o('644'), dir: false).result,
          o('755'));
      expect(
          evaluateChmodCommand('chmod -- a-w f', o('644'), dir: false).result,
          o('444'));
    });

    test('commande saisie', () {
      expect(
          evaluateChmodCommand('chmod u+x, g-w f', o('664'), dir: false).result,
          o('744'));
      expect(evaluateChmodCommand('chmod -R 750 d', o('755'), dir: true).result,
          o('750'));
      expect(
          evaluateChmodCommand('chmod u+x g-w f', o('664'), dir: false).error,
          isNotNull);
      final dep = evaluateChmodCommand('chmod +x f', o('644'), dir: false);
      expect(dep.result, isNull);
      expect(dep.umaskNote, contains('umask'));
      expect(evaluateChmodCommand('chmod a+x f', o('644'), dir: false).result,
          o('755'));
    });

    test('exercice : octal et symbolique acceptés', () {
      final ex = ChmodExercise(o('2755'), o('750'), dir: true, name: 'd');
      expect(ex.octalAnswer, '00750');
      expect(ex.check(['chmod 750 d']).correct, isFalse);
      expect(ex.check(['chmod 00750 d']).correct, isTrue);
      expect(ex.check(['chmod g-s,o-rx d']).correct, isTrue);
      expect(ex.check(['chmod ${ex.symbolicAnswer} d']).correct, isTrue);
      final f = ChmodExercise(o('644'), o('755'), dir: false, name: 'f');
      expect(f.check(['755']).correct, isTrue);
      expect(f.check(['chmod a+x f']).correct, isTrue);
      expect(f.check(['chmod u+x f']).correct, isFalse);
    });
  });

  group('Lecture de ls -l', () {
    test('une seule classe compte', () {
      expect(answerOf(access(AccessKind.read, _alice, '077', 'alice', 'dev')),
          'non');
      expect(answerOf(access(AccessKind.read, _alice, '470', 'bob', 'dev')),
          'oui');
      expect(answerOf(access(AccessKind.read, _alice, '407', 'bob', 'dev')),
          'non');
      expect(answerOf(access(AccessKind.write, _bob, '664', 'alice', 'dev')),
          'non');
      expect(answerOf(access(AccessKind.write, _bob, '666', 'alice', 'dev')),
          'oui');
    });

    test('dossiers : r liste, x traverse, w+x crée', () {
      expect(
          answerOf(access(AccessKind.enter, _alice, '644', 'alice', 'alice',
              dir: true)),
          'non');
      expect(
          answerOf(access(AccessKind.enter, _bob, '711', 'alice', 'alice',
              dir: true)),
          'oui');
      expect(
          answerOf(access(AccessKind.list, _bob, '711', 'alice', 'alice',
              dir: true)),
          'non');
      expect(
          answerOf(
              access(AccessKind.list, _alice, '750', 'bob', 'dev', dir: true)),
          'oui');
      expect(
          answerOf(access(AccessKind.create, _alice, '760', 'bob', 'dev',
              dir: true)),
          'non');
      expect(
          answerOf(access(AccessKind.create, _alice, '1770', 'bob', 'dev',
              dir: true)),
          'oui');
    });

    test('root', () {
      expect(answerOf(access(AccessKind.read, _root, '000', 'alice', 'alice')),
          'oui');
      expect(answerOf(access(AccessKind.write, _root, '444', 'alice', 'alice')),
          'oui');
      expect(answerOf(access(AccessKind.exec, _root, '644', 'alice', 'alice')),
          'non');
      expect(answerOf(access(AccessKind.exec, _root, '601', 'alice', 'alice')),
          'oui');
      expect(answerOf(access(AccessKind.exec, _root, '4644', 'alice', 'alice')),
          'non');
      expect(
          answerOf(access(AccessKind.enter, _root, '000', 'alice', 'alice',
              dir: true)),
          'oui');
    });

    test('SUID, sticky, traversée', () {
      expect(
          answerOf(access(AccessKind.suidUser, _alice, '4755', 'root', 'root')),
          'root');
      expect(
          answerOf(access(AccessKind.suidUser, _alice, '2755', 'root', 'root')),
          'alice');
      expect(answerOf(access(AccessKind.suidUser, _root, '4755', 'bob', 'bob')),
          'bob');
      final ex = access(AccessKind.suidUser, _alice, '4755', 'root', 'root');
      expect(ex.check(['root']).correct, isTrue);
      expect(ex.check(['0']).correct, isTrue);
      expect(ex.check(['alice']).correct, isFalse);

      final tmp = LsEntry('tmp', o('1777'), 'root', 'root', dir: true);
      final commun = LsEntry('commun', o('777'), 'root', 'root', dir: true);
      AccessExercise del(LsEntry d, UnixAccount u, String fOwner) =>
          AccessExercise(
              kind: AccessKind.deleteIn,
              user: u,
              target: LsEntry('f', o('600'), fOwner, fOwner, dir: false),
              parent: d);
      expect(answerOf(del(tmp, _alice, 'bob')), 'non');
      expect(answerOf(del(tmp, _alice, 'alice')), 'oui');
      expect(answerOf(del(commun, _alice, 'bob')), 'oui');
      expect(answerOf(del(tmp, _root, 'bob')), 'oui');
      // Bug corrigé (aide-mémoire) : le propriétaire du dossier sticky peut aussi supprimer.
      final mine = LsEntry('equipe', o('1777'), 'alice', 'alice', dir: true);
      expect(answerOf(del(mine, _alice, 'bob')), 'oui');
      expect(kMemoSpecial, contains('propriétaire du dossier'));

      AccessExercise through(String dMode, String fMode) => AccessExercise(
          kind: AccessKind.readThrough,
          user: _bob,
          target: LsEntry('f', o(fMode), 'alice', 'alice', dir: false),
          parent: LsEntry('d', o(dMode), 'alice', 'alice', dir: true));
      expect(answerOf(through('711', '644')), 'oui');
      expect(answerOf(through('744', '644')), 'non');
      expect(answerOf(through('755', '640')), 'non');

      expect(ex.check(['peut-être']).correct, isFalse);
      final yn = access(AccessKind.read, _alice, '400', 'alice', 'alice');
      expect(yn.check(['Oui']).correct, isTrue);
      expect(yn.check(['non']).correct, isFalse);
      expect(yn.check(['bof']).correct, isFalse);
    });
  });

  group('umask', () {
    test('cas connus', () {
      for (final c in const [
        ['022', '644', '755'],
        ['002', '664', '775'],
        ['027', '640', '750'],
        ['033', '644', '744'],
        ['077', '600', '700'],
        ['011', '666', '766'],
      ]) {
        final u = c[0], f = c[1], d = c[2];
        final ex = UmaskExercise(o(u), reverse: false);
        expect(toOctal(ex.fileMode), f, reason: u);
        expect(toOctal(ex.dirMode), d, reason: u);
        expect(ex.check([f, d]).correct, isTrue);
      }
      final ex = UmaskExercise(o('033'), reverse: false);
      expect(ex.check(['633', '744']).correct, isFalse);
      expect(ex.check(['rw-r--r--', 'drwxr--r--']).correct, isTrue);
    });

    test('umask inverse et format umask -S', () {
      expect(UmaskExercise.parseUmask('u=rwx,g=rx,o='), o('027'));
      expect(UmaskExercise.parseUmask('umask 0022'), o('022'));
      expect(UmaskExercise.parseUmask('a=rx,u=rwx'), o('022'));
      expect(UmaskExercise.parseUmask('u=rwx'), isNull);
      final ex = UmaskExercise(o('027'), reverse: true);
      expect(ex.check(['027']).correct, isTrue);
      expect(ex.check(['u=rwx,g=rx,o=']).correct, isTrue);
      expect(ex.check(['022']).correct, isFalse);
    });
  });

  group('Génération aléatoire', () {
    test('250 graines par mode et niveau : cohérence, aucune exception', () {
      for (final mode in PermExerciseMode.values) {
        for (final level in PermLevel.values) {
          for (var seed = 0; seed < 250; seed++) {
            final ex = generatePermExercise(TrainingRandom(seed), mode, level);
            final why = '$mode $level graine $seed';
            expect(ex.instruction, isNotEmpty, reason: why);
            expect(ex.labels.length, ex.hints.length, reason: why);
            expect(
                ex.expected.length, ex.choices != null ? 1 : ex.labels.length,
                reason: why);
            final good = ex.check(ex.expected);
            expect(good.correct, isTrue, reason: '$why ${ex.expected}');
            expect(good.explanation, isNotEmpty, reason: why);
            final bad = ex.check(List.filled(ex.expected.length, 'zzz'));
            expect(bad.correct, isFalse, reason: why);
            expect(bad.explanation, isNotEmpty, reason: why);

            if (ex is ChmodExercise) {
              expect(ex.from == ex.to, isFalse, reason: why);
              expect(applyChmod(ex.from, ex.octalAnswer, dir: ex.dir), ex.to,
                  reason: why);
              expect(applyChmod(ex.from, ex.symbolicAnswer, dir: ex.dir), ex.to,
                  reason: '$why ${ex.symbolicAnswer}');
              expect(
                  ex.check(['chmod ${ex.symbolicAnswer} ${ex.name}']).correct,
                  isTrue,
                  reason: why);
              if (level == PermLevel.debutant) {
                expect(ex.from & ~kPermBits, 0, reason: why);
              }
            }
            if (ex is PermConversionExercise) {
              if (level == PermLevel.debutant) {
                expect(ex.mode & ~kPermBits, 0, reason: why);
              }
              final other = ex.toOctalForm
                  ? toOctal(ex.mode, 4)
                  : lsMode(ex.mode, dir: ex.dir);
              expect(ex.check([other]).correct, isTrue, reason: why);
            }
            if (ex is UmaskExercise && !ex.reverse) {
              expect(
                  ex.check([
                    permString(ex.fileMode),
                    permString(ex.dirMode)
                  ]).correct,
                  isTrue,
                  reason: why);
            }
            if (ex is AccessExercise) {
              expect(ex.code, contains('uid='), reason: why);
              if (ex.kind != AccessKind.suidUser) {
                expect(ex.expected.single, anyOf('oui', 'non'), reason: why);
                final flip = ex.expected.single == 'oui' ? 'non' : 'oui';
                expect(ex.check([flip]).correct, isFalse, reason: why);
              }
            }
          }
        }
      }
    });
  });

  testWidgets('le widget se construit et vérifie', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PermissionsTrainer())));
    expect(find.text('Droits Linux'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '0');
    await tester.pump();
    final verifier = find.text('Vérifier');
    await tester.ensureVisible(verifier);
    await tester.tap(verifier);
    await tester.pump();
    expect(find.textContaining('/ 1'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'umask'));
    await tester.pump();
    expect(find.byType(TextField), findsWidgets);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Lire ls -l'));
    await tester.pump();
    await tester.tap(find.text('Avancé (SUID, SGID, sticky)'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
