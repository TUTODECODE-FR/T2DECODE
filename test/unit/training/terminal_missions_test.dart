// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/lab/services/virtual_shell.dart';
import 'package:tutodecode/features/training/terminal_missions.dart';
import 'package:tutodecode/features/training/training_kit.dart';

/// Messages d'erreur du shell qui ne doivent jamais apparaître en suivant la solution.
final _errorLine =
    RegExp(r'No such file|command not found|cannot |invalid|Is a directory|'
        r'Not a directory|missing operand|syntax error|paths must precede');

void main() {
  group('Génération et cohérence (200 graines x toutes les missions)', () {
    test('état initial non résolu, solution qui réussit, sans erreur', () {
      for (var seed = 0; seed < 200; seed++) {
        for (var kind = 0; kind < kMissionKinds; kind++) {
          final m = buildMission(kind, TrainingRandom(seed * 100 + kind));
          final where = 'graine $seed, mission $kind';
          expect(m.kind, kind, reason: where);
          expect(m.level, missionLevelOf(kind), reason: where);
          expect(m.instruction, isNotEmpty, reason: where);
          expect(m.hint, isNotEmpty, reason: where);
          expect(m.solution, isNotEmpty, reason: where);

          final shell = m.createShell();
          final before = m.check(shell);
          expect(before.correct, isFalse, reason: '$where : déjà résolue');
          expect(before.explanation, contains('Vérification pas à pas'));
          expect(before.explanation, contains('manque'), reason: where);
          expect(before.explanation, contains('Méthode : '));

          for (final cmd in m.solution) {
            final out = shell.execute(cmd);
            for (final l in out) {
              expect(_errorLine.hasMatch(l), isFalse,
                  reason: '$where : « $cmd » -> « $l »');
            }
          }
          final after = m.check(shell);
          expect(after.correct, isTrue,
              reason: '$where : solution refusée\n${after.explanation}');
          expect(after.explanation, startsWith('Mission accomplie'));
          expect(after.explanation, isNot(contains(': manque')));
        }
      }
    });

    test('même graine, même mission', () {
      for (var seed = 0; seed < 200; seed++) {
        final a = randomMission(TrainingRandom(seed));
        final b = randomMission(TrainingRandom(seed));
        expect(a.kind, b.kind);
        expect(a.instruction, b.instruction);
        expect(a.solution, b.solution);
      }
    });

    test('tirage par niveau', () {
      expect(kMissionKinds, greaterThanOrEqualTo(20));
      for (final level in MissionLevel.values) {
        expect(missionKindsOf(level), isNotEmpty);
        for (var seed = 0; seed < 200; seed++) {
          final m = randomMission(TrainingRandom(seed), level: level);
          expect(m.level, level);
        }
      }
      expect(missionKindsOf(null).length, kMissionKinds);
      expect(() => buildMission(kMissionKinds, TrainingRandom(1)),
          throwsRangeError);
    });

    test('les valeurs aléatoires changent d\'une graine à l\'autre', () {
      final instructions = {
        for (var seed = 0; seed < 50; seed++)
          buildMission(16, TrainingRandom(seed)).instruction
      };
      expect(instructions.length, greaterThan(5));
    });
  });

  group('Vérification : cas connus', () {
    test('mauvaise casse expliquée (mission 6)', () {
      final m = buildMission(6, TrainingRandom(3));
      final shell = m.createShell();
      final phrase = m.instruction.split('la ligne : ').last;
      final path = RegExp(r'~/\S+\.txt').firstMatch(m.instruction)!.group(0)!;
      shell.execute('echo "${phrase.toUpperCase()}" > $path');
      final c = m.check(shell);
      expect(c.correct, isFalse);
      expect(c.explanation, contains('la casse ou les espaces'));
    });

    test('> au lieu de >> efface les lignes (mission 7)', () {
      final m = buildMission(7, TrainingRandom(5));
      final shell = m.createShell();
      shell.execute(m.solution.first.replaceFirst('>>', '>'));
      final c = m.check(shell);
      expect(c.correct, isFalse);
      expect(c.explanation, contains('attention à >'));
    });

    test('find sans -type f compte un dossier en trop (mission 17)', () {
      for (var seed = 0; seed < 50; seed++) {
        final m = buildMission(17, TrainingRandom(seed));
        final shell = m.createShell();
        if (!shell.fs.isDir('$kMissionHome/config/modules.conf')) continue;
        shell.execute('find ~/config -name "*.conf" | wc -l > ~/nb_conf.txt');
        final c = m.check(shell);
        expect(c.correct, isFalse);
        expect(c.explanation, contains('Trouvé'));
        return;
      }
      fail('aucune graine avec le dossier piège');
    });

    test('chmod -R 755 rend les fichiers exécutables : refusé (mission 28)',
        () {
      final m = buildMission(28, TrainingRandom(1));
      final shell = m.createShell();
      shell.execute('chmod -R 755 ~/partage');
      final c = m.check(shell);
      expect(c.correct, isFalse);
      expect(c.explanation, contains('755 (rwxr-xr-x)'));
    });

    test('chmod +x accepté, chmod 777 refusé (mission 25)', () {
      final m = buildMission(25, TrainingRandom(2));
      final file = RegExp(r'~/\S+\.sh').firstMatch(m.instruction)!.group(0)!;
      var shell = m.createShell();
      shell.execute('chmod +x $file');
      expect(m.check(shell).correct, isTrue);
      shell = m.createShell();
      shell.execute('chmod 777 $file');
      final c = m.check(shell);
      expect(c.correct, isFalse);
      expect(c.explanation, contains('777 (rwxrwxrwx)'));
    });

    test('nombre suivi du nom de fichier accepté (mission 20)', () {
      final m = buildMission(20, TrainingRandom(4));
      final csv = RegExp(r'~/\S+\.csv').firstMatch(m.instruction)!.group(0)!;
      final shell = m.createShell();
      shell.execute('wc -l $csv > ~/lignes.txt');
      expect(shell.fs.readFile('$kMissionHome/lignes.txt'), contains(csv));
      expect(m.check(shell).correct, isTrue);
    });

    test('fichier vide réussi : pas de « Il contient du texte » (mission 8)',
        () {
      final m = buildMission(8, TrainingRandom(7));
      final shell = m.createShell();
      for (final cmd in m.solution) {
        shell.execute(cmd);
      }
      final c = m.check(shell);
      expect(c.correct, isTrue);
      expect(c.explanation, isNot(contains('Il contient du texte')));
      // Un fichier non vide reste signalé.
      final file = m.instruction.split(': ').last.split(', ').first;
      shell.execute('echo x > ~/brouillons/$file');
      expect(m.check(shell).explanation, contains('Il contient du texte'));
    });

    test('Recommencer redonne le même état de départ (mission 26)', () {
      for (var seed = 0; seed < 20; seed++) {
        final m = buildMission(26, TrainingRandom(seed));
        final path = '$kMissionHome/donnees/'
            '${RegExp(r'donnees/(\S+)').firstMatch(m.instruction)!.group(1)}';
        final a = m.createShell();
        final b = m.createShell();
        expect(a.fs.readFile(path), b.fs.readFile(path),
            reason: 'graine $seed');
        expect(a.fs.permissions(path), b.fs.permissions(path));
      }
    });

    test('dossier supprimé : libellé 755 et non 644 (mission 28)', () {
      final m = buildMission(28, TrainingRandom(3));
      final shell = m.createShell();
      shell.execute('rm -r ~/partage');
      final c = m.check(shell);
      expect(c.correct, isFalse);
      expect(c.explanation, contains('~/partage : 755 (rwxr-xr-x) : manque'));
    });

    test('ls -ld affiche le dossier lui-même (solution mission 27)', () {
      final m = buildMission(27, TrainingRandom(2));
      final shell = m.createShell();
      for (final cmd in m.solution) {
        final out = shell.execute(cmd);
        if (cmd.startsWith('ls -ld')) {
          expect(out.single, startsWith('drwx------'));
        }
      }
      expect(m.check(shell).correct, isTrue);
    });

    test('describeMode et modeString', () {
      expect(describeMode(0x1A0), '640 (rw-r-----)');
      expect(describeMode(0x1C0), '700 (rwx------)');
      expect(describeMode(0x100), '400 (r--------)');
      expect(VirtualFileSystem.modeString(0x1ED, isDir: true), 'drwxr-xr-x');
      expect(VirtualFileSystem.modeString(0x9ED), '-rwsr-xr-x');
      expect(VirtualFileSystem.modeString(0x3FF, isDir: true), 'drwxrwxrwt');
      expect(VirtualFileSystem.modeString(0x5A4), '-rw-r-Sr--');
    });

    test('applyMode (calculs faits à la main, umask 022)', () {
      int? m(String spec, int cur, {bool dir = false}) =>
          VirtualFileSystem.applyMode(spec, cur, isDir: dir);
      expect(m('u+x', 0x1A4), 0x1E4); // 644 -> 744
      expect(m('+x', 0x1A4), 0x1ED); // 644 -> 755
      expect(m('go-w', 0x1FF, dir: true), 0x1ED); // 777 -> 755
      expect(m('-w', 0x1A4), 0x124); // 644 -> 444 (umask : seul u perd w)
      expect(m('+w', 0x124), 0x1A4); // 444 -> 644 (umask : seul u gagne w)
      expect(m('a=r', 0x1FF), 0x124); // 777 -> 444
      expect(m('u=rwx,g=rx,o=', 0x1A4), 0x1E8); // 750
      expect(m('g=u', 0x1C0), 0x1F8); // 700 -> 770
      expect(m('a+X', 0x1A4), 0x1A4); // fichier sans x : X sans effet
      expect(m('a+X', 0x1A4, dir: true), 0x1ED); // dossier : X ajoute x
      expect(m('640', 0x1FF), 0x1A0);
      expect(m('z+q', 0x1A4), isNull);
    });
  });

  group('Shell virtuel : commandes utilisées par les missions', () {
    late VirtualShell sh;
    setUp(() => sh = VirtualShell());

    test('mkdir -p et accolades ; mkdir sans -p refuse un parent absent', () {
      expect(sh.execute('mkdir -p projet/{src,docs}'), isEmpty);
      expect(sh.fs.isDir('$kMissionHome/projet/src'), isTrue);
      expect(sh.fs.isDir('$kMissionHome/projet/docs'), isTrue);
      expect(sh.execute('mkdir -p projet/src'), isEmpty);
      expect(sh.execute('mkdir a/b').single,
          contains('No such file or directory'));
      expect(sh.fs.exists('$kMissionHome/a'), isFalse);
      expect(sh.execute('mkdir projet').single, contains('File exists'));
    });

    test('touch, echo >, >> et erreurs hors du fichier', () {
      expect(sh.execute('touch x/y.txt').single, contains('cannot touch'));
      sh.execute('echo "un  deux" > /tmp/f');
      sh.execute('echo trois >> /tmp/f');
      expect(sh.fs.readFile('/tmp/f'), 'un  deux\ntrois');
      final out = sh.execute('cat /tmp/absent > /tmp/g');
      expect(out.single, 'cat: /tmp/absent: No such file or directory');
      expect(sh.fs.readFile('/tmp/g'), '');
      expect(sh.execute('cat /tmp/absent 2>/dev/null'), isEmpty);
      expect(sh.execute("echo l'apostrophe'"), ['lapostrophe']);
      expect(sh.execute('echo "a > b"'), ['a > b']);
    });

    test('tubes : ls | wc -l, sort | uniq -c, wc -l < fichier', () {
      sh.fs.write('/tmp/v', 'b\na\nb\nc\nb');
      expect(sh.execute('ls /tmp | wc -l'), ['1']);
      expect(sh.execute('sort /tmp/v | uniq -c | sort -n'),
          ['      1 a', '      1 c', '      3 b']);
      expect(sh.execute('sort -u /tmp/v'), ['a', 'b', 'c']);
      expect(sh.execute('wc -l < /tmp/v'), ['5']);
      expect(sh.execute('wc -l /tmp/v'), ['5 /tmp/v']);
      expect(sh.execute('cat /tmp/v | grep -c b'), ['3']);
      expect(sh.execute('grep -v b /tmp/v'), ['a', 'c']);
      expect(sh.execute('grep -i B /tmp/v').length, 3);
      expect(sh.execute('head -2 /tmp/v'), ['b', 'a']);
      expect(sh.execute('cat /tmp/v|tail -n 1'), ['b']);
    });

    test('find : relatif, -type, motif non protégé', () {
      sh.fs.write('$kMissionHome/w/a.txt', 'x');
      sh.fs.write('$kMissionHome/w/sous/b.txt', 'y');
      sh.execute('cd w');
      expect(sh.execute('find . -name "*.txt"'), ['./a.txt', './sous/b.txt']);
      expect(sh.execute('find . -type d'), ['.', './sous']);
      expect(
          sh.execute('find ~/w -name b.txt'), ['$kMissionHome/w/sous/b.txt']);
      // *.txt non protégé : bash le développe en a.txt avant find.
      sh.fs.write('$kMissionHome/w/c.txt', 'z');
      expect(sh.execute('find . -name *.txt').single,
          contains('paths must precede expression'));
    });

    test('rm, cp, mv : jokers, dossiers et erreurs', () {
      for (final f in ['a.tmp', 'b.tmp', 'c.txt']) {
        sh.fs.write('/tmp/d/$f', f);
      }
      sh.execute('rm /tmp/d/*.tmp');
      expect(sh.fs.listDir('/tmp/d'), ['c.txt']);
      expect(
          sh.execute('cp /tmp/d /tmp/e').single, contains('-r not specified'));
      sh.execute('cp -r /tmp/d /tmp/e');
      expect(sh.fs.readFile('/tmp/e/c.txt'), 'c.txt');
      expect(sh.execute('mv /tmp/d /tmp/d/sous').single,
          contains('subdirectory of itself'));
      expect(sh.execute('rm /tmp/d').single, contains('Is a directory'));
      expect(sh.execute('rm -f /tmp/inexistant'), isEmpty);
      expect(
          sh.execute('rmdir /tmp/e').single, contains('Directory not empty'));
      sh.execute('mv /tmp/e/c.txt /tmp/z.txt');
      expect(sh.fs.exists('/tmp/e/c.txt'), isFalse);
      expect(sh.execute('rmdir /tmp/e'), isEmpty);
    });

    test('chmod met à jour ls -l et stat', () {
      sh.fs.write('/tmp/s', 'secret');
      sh.execute('chmod 600 /tmp/s');
      expect(sh.execute('ls -l /tmp/s').single, startsWith('-rw-------'));
      expect(sh.execute('stat /tmp/s')[2], contains('(0600/-rw-------)'));
      expect(sh.execute('chmod abc /tmp/s').single, contains('invalid mode'));
      expect(sh.execute('chmod 600 /tmp/x').single, contains('cannot access'));
      sh.fs.write('/tmp/p/f', '');
      sh.execute('chmod -R go-rx /tmp/p');
      expect(sh.fs.permissions('/tmp/p'), 0x1C0);
      expect(sh.fs.permissions('/tmp/p/f'), 0x180);
    });
  });

  testWidgets('widget : commande, vérification, solution après échec',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TerminalMissions(seed: 1))));
    expect(find.text('Terminal Linux : missions'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pwd');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    // certaines missions démarrent dans un sous-dossier du répertoire personnel
    expect(find.textContaining('/home/admin'), findsWidgets);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Voir la solution'))
            .onPressed,
        isNull);
    await tester.tap(find.text('Vérifier la mission'));
    await tester.pump();
    expect(find.text('Pas encore'), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);
    await tester.tap(find.text('Voir la solution'));
    await tester.pump();
    expect(find.text('Une solution possible :'), findsOneWidget);
    await tester.tap(find.text('Indice'));
    await tester.pump();
    expect(find.textContaining('Indice : '), findsOneWidget);
  });
}
