import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/training/subnet_trainer.dart';
import 'package:tutodecode/features/training/training_kit.dart';

/// Masque recalculé indépendamment (chaîne de bits), en entier 32 bits.
int maskOf(int p) => int.parse('${'1' * p}${'0' * (32 - p)}', radix: 2);

int ip(String s) {
  final o = s.split('.').map(int.parse).toList();
  return ((o[0] * 256 + o[1]) * 256 + o[2]) * 256 + o[3];
}

bool isPrivate(int a) =>
    (a & maskOf(8)) == ip('10.0.0.0') ||
    (a & maskOf(12)) == ip('172.16.0.0') ||
    (a & maskOf(16)) == ip('192.168.0.0');

SubnetCalcAnswer goodCalc(SubnetCalcExercise e) {
  final net = e.ip & maskOf(e.prefix);
  final size = 1 << (32 - e.prefix);
  final bc = net + size - 1;
  String f(int x) => formatIpv4(x);
  if (e.prefix == 32) {
    return SubnetCalcAnswer(
        network: f(net),
        mask: f(maskOf(32)),
        broadcast: 'aucune',
        first: f(net),
        last: f(net),
        hosts: '1');
  }
  if (e.prefix == 31) {
    return SubnetCalcAnswer(
        network: f(net),
        mask: f(maskOf(31)),
        broadcast: 'aucune',
        first: f(net),
        last: f(bc),
        hosts: '2');
  }
  return SubnetCalcAnswer(
      network: f(net),
      mask: f(maskOf(e.prefix)),
      broadcast: f(bc),
      first: f(net + 1),
      last: f(bc - 1),
      hosts: '${size - 2}');
}

void main() {
  group('outils', () {
    test('analyse des adresses et masques', () {
      expect(parseIpv4(' 192.168.1.1 '), ip('192.168.1.1'));
      expect(parseIpv4('192,168,1,1'), ip('192.168.1.1'));
      expect(parseIpv4('192.168.1.0/24'), ip('192.168.1.0'));
      expect(parseIpv4('192.168.1.256'), isNull);
      expect(parseIpv4('192.168.1'), isNull);
      expect(parsePrefix('255.255.255.192'), 26);
      expect(parsePrefix('/26'), 26);
      expect(parsePrefix('26'), 26);
      expect(parsePrefix('255.255.240.0'), 20);
      expect(parsePrefix('255.0.255.0'), isNull);
      expect(parsePrefix('/33'), isNull);
      expect(parseHostCount('62'), 62);
      expect(parseHostCount('62 hôtes'), 62);
      expect(parseHostCount('16 777 214'), 16777214);
      expect(parseHostCount('2^6-2'), 62);
      expect(parseHostCount('abc'), isNull);
      expect(isNoneAnswer('aucune'), isTrue);
      expect(isNoneAnswer('-'), isTrue);
      expect(isNoneAnswer('10.0.0.1'), isFalse);
      for (var p = 0; p <= 32; p++) {
        expect(prefixToMask(p), maskOf(p), reason: '/$p');
      }
      expect(prefixForHosts(2), 30);
      expect(prefixForHosts(62), 26);
      expect(prefixForHosts(63), 25);
      expect(prefixForHosts(100), 25);
      expect(ipv4ToBinary(ip('255.255.255.192'), 26),
          '11111111.11111111.11111111.11|000000');
    });
  });

  group('calcul (cas faits à la main)', () {
    test('192.168.1.130/26', () {
      const e = SubnetCalcExercise(0xC0A80182, 26);
      final g = checkSubnetCalc(
          e,
          const SubnetCalcAnswer(
              network: '192.168.1.128',
              mask: '255.255.255.192',
              broadcast: '192.168.1.191',
              first: '192.168.1.129',
              last: '192.168.1.190',
              hosts: '62'));
      expect(g.check.correct, isTrue);
      expect(g.check.explanation, contains('256 - 192 = 64'));
      expect(g.check.explanation, contains('130 = 10|000010'));
    });

    test('172.16.45.200/20', () {
      final e = SubnetCalcExercise(ip('172.16.45.200'), 20);
      expect(formatIpv4(e.network), '172.16.32.0');
      expect(formatIpv4(e.broadcast), '172.16.47.255');
      expect(e.hostCount, 4094);
      final g = checkSubnetCalc(
          e,
          const SubnetCalcAnswer(
              network: '172.16.32.0',
              mask: '255.255.240.0',
              broadcast: '172.16.47.255',
              first: '172.16.32.1',
              last: '172.16.47.254',
              hosts: '4094'));
      expect(g.check.correct, isTrue);
    });

    test('10.20.30.40/8', () {
      final e = SubnetCalcExercise(ip('10.20.30.40'), 8);
      final g = checkSubnetCalc(
          e,
          const SubnetCalcAnswer(
              network: '10.0.0.0',
              mask: '255.0.0.0',
              broadcast: '10.255.255.255',
              first: '10.0.0.1',
              last: '10.255.255.254',
              hosts: '16777214'));
      expect(g.check.correct, isTrue);
    });

    test('chaque champ est vérifié séparément', () {
      final e = SubnetCalcExercise(ip('192.168.1.130'), 26);
      final g = checkSubnetCalc(
          e,
          const SubnetCalcAnswer(
              network: '192.168.1.128',
              mask: '255.255.255.0',
              broadcast: '192.168.1.255',
              first: '192.168.1.129',
              last: '192.168.1.190',
              hosts: '64'));
      expect(g.check.correct, isFalse);
      expect(g.fields, {
        'network': true,
        'mask': false,
        'broadcast': false,
        'first': true,
        'last': true,
        'hosts': false,
      });
    });

    test('/31 (RFC 3021) et /32', () {
      final e31 = SubnetCalcExercise(ip('10.0.0.5'), 31);
      expect(formatIpv4(e31.firstHost), '10.0.0.4');
      expect(formatIpv4(e31.lastHost), '10.0.0.5');
      expect(e31.hostCount, 2);
      final g31 = checkSubnetCalc(
          e31,
          const SubnetCalcAnswer(
              network: '10.0.0.4',
              mask: '255.255.255.254',
              broadcast: 'aucune',
              first: '10.0.0.4',
              last: '10.0.0.5',
              hosts: '2'));
      expect(g31.check.correct, isTrue);
      expect(g31.check.explanation, contains('RFC 3021'));
      final bad = checkSubnetCalc(
          e31,
          const SubnetCalcAnswer(
              network: '10.0.0.4',
              mask: '255.255.255.254',
              broadcast: '10.0.0.5',
              first: '10.0.0.4',
              last: '10.0.0.5',
              hosts: '0'));
      expect(bad.fields['broadcast'], isFalse);
      expect(bad.fields['hosts'], isFalse);

      final e32 = SubnetCalcExercise(ip('192.168.7.9'), 32);
      final g32 = checkSubnetCalc(
          e32,
          const SubnetCalcAnswer(
              network: '192.168.7.9',
              mask: '255.255.255.255',
              broadcast: 'aucune',
              first: '192.168.7.9',
              last: '192.168.7.9',
              hosts: '1'));
      expect(g32.check.correct, isTrue);
    });

    test(
        'bug : le masque du calcul exige le décimal pointé (préfixe déjà donné)',
        () {
      final e = SubnetCalcExercise(ip('192.168.1.130'), 26);
      SubnetGrade g(String mask) => checkSubnetCalc(
          e,
          SubnetCalcAnswer(
              network: '192.168.1.128',
              mask: mask,
              broadcast: '192.168.1.191',
              first: '192.168.1.129',
              last: '192.168.1.190',
              hosts: '62'));
      expect(g('/26').fields['mask'], isFalse);
      expect(g('26').fields['mask'], isFalse);
      expect(g('255.255.255.192').check.correct, isTrue);
      expect(g('255.255.255.192 (/26)').check.correct, isTrue);
      expect(g('255.255.255.192/26').check.correct, isTrue);
      expect(g('255.255.255.192/24').fields['mask'], isFalse);
      // Le champ préfixe du VLSM accepte toujours les deux notations.
      expect(parsePrefix('255.255.255.192 (/26)'), 26);
      expect(parsePrefix('255.255.255.192/25'), isNull);
    });

    test('bug : « 62 hôtes utilisables » est accepté', () {
      expect(parseHostCount('62 hôtes utilisables'), 62);
      expect(parseHostCount('62 utilisables'), 62);
      expect(parseHostCount('2^6-2 hôtes'), 62);
      expect(parseHostCount('hôtes'), isNull);
    });
  });

  group('même réseau (cas faits à la main)', () {
    test('192.168.1.10 et 192.168.1.70 en /26 : non', () {
      final e = SameNetworkExercise(ip('192.168.1.10'), ip('192.168.1.70'), 26);
      expect(e.same, isFalse);
      final g = checkSameNetwork(
          e,
          const SameNetworkAnswer(
              same: false, networkA: '192.168.1.0', networkB: '192.168.1.64'));
      expect(g.check.correct, isTrue);
      expect(g.check.explanation, contains('70 ET 192'));
      final wrong = checkSameNetwork(
          e,
          const SameNetworkAnswer(
              same: true, networkA: '192.168.1.0', networkB: '192.168.1.64'));
      expect(wrong.check.correct, isFalse);
      expect(wrong.fields['same'], isFalse);
    });

    test('172.16.5.1 et 172.16.9.200 en /20 : oui', () {
      final e = SameNetworkExercise(ip('172.16.5.1'), ip('172.16.9.200'), 20);
      expect(e.same, isTrue);
      expect(formatIpv4(e.networkA), '172.16.0.0');
      final g = checkSameNetwork(
          e,
          const SameNetworkAnswer(
              same: true, networkA: '172.16.0.0', networkB: '172.16.0.0'));
      expect(g.check.correct, isTrue);
      expect(checkSameNetwork(e, const SameNetworkAnswer()).check.correct,
          isFalse);
    });
  });

  group('VLSM (cas fait à la main)', () {
    test('192.168.10.0/24 : 100, 50, 20, 2', () {
      final e = VlsmExercise(ip('192.168.10.0'), 24, const [
        VlsmNeed('Liaison', 2),
        VlsmNeed('B', 50),
        VlsmNeed('A', 100),
        VlsmNeed('C', 20),
      ]);
      final got = [
        for (final s in e.plan) '${formatIpv4(s.network)}/${s.prefix}'
      ];
      expect(got, [
        '192.168.10.224/30',
        '192.168.10.128/26',
        '192.168.10.0/25',
        '192.168.10.192/27',
      ]);
      final g = checkVlsm(e, const [
        VlsmAnswer(prefix: '/30', network: '192.168.10.224'),
        VlsmAnswer(prefix: '255.255.255.192', network: '192.168.10.128'),
        VlsmAnswer(prefix: '25', network: '192.168.10.0'),
        VlsmAnswer(prefix: '/27', network: '192.168.10.192'),
      ]);
      expect(g.check.correct, isTrue);
      expect(g.check.explanation, contains('192.168.10.228'));
      final bad = checkVlsm(e, const [
        VlsmAnswer(prefix: '/30', network: '192.168.10.0'),
      ]);
      expect(bad.check.correct, isFalse);
      expect(bad.fields['network0'], isFalse);
      expect(bad.fields['prefix0'], isTrue);
      expect(
          () => VlsmExercise(ip('192.168.10.0'), 24,
              const [VlsmNeed('X', 200), VlsmNeed('Y', 100)]),
          throwsArgumentError);
    });
  });

  group('200 graines par mode et niveau', () {
    for (final level in SubnetLevel.values) {
      test('calcul ${level.name}', () {
        final seen31 = <int>{};
        for (var seed = 0; seed < 300; seed++) {
          final e = SubnetCalcExercise.generate(TrainingRandom(seed), level);
          final p = e.prefix;
          expect(
              p,
              inInclusiveRange(level == SubnetLevel.beginner ? 16 : 8,
                  level == SubnetLevel.beginner ? 30 : 32));
          if (p >= 31) seen31.add(p);
          expect(isPrivate(e.ip), isTrue);
          final net = e.ip & maskOf(p);
          expect(e.network, net);
          if (p <= 30) {
            expect(e.ip, isNot(net));
            expect(e.ip, isNot(net + (1 << (32 - p)) - 1));
          }
          final g = checkSubnetCalc(e, goodCalc(e));
          expect(g.check.correct, isTrue, reason: '${formatIpv4(e.ip)}/$p');
          expect(g.check.explanation, contains('pas à pas'));
          expect(g.workings, isNotEmpty);
          expect(checkSubnetCalc(e, const SubnetCalcAnswer()).check.correct,
              isFalse);
        }
        if (level == SubnetLevel.advanced) expect(seen31, {31, 32});
      });

      test('même réseau ${level.name}', () {
        var same = 0;
        for (var seed = 0; seed < 300; seed++) {
          final e = SameNetworkExercise.generate(TrainingRandom(seed), level);
          expect(e.a, isNot(e.b));
          expect(isPrivate(e.a) && isPrivate(e.b), isTrue);
          final m = maskOf(e.prefix);
          final expected = (e.a & m) == (e.b & m);
          expect(e.same, expected);
          if (expected) same++;
          final g = checkSameNetwork(
              e,
              SameNetworkAnswer(
                  same: expected,
                  networkA: formatIpv4(e.a & m),
                  networkB: formatIpv4(e.b & m)));
          expect(g.check.correct, isTrue);
          expect(g.check.explanation, contains('ET'));
          expect(
              checkSameNetwork(e, SameNetworkAnswer(same: !expected))
                  .check
                  .correct,
              isFalse);
        }
        expect(same, inInclusiveRange(60, 240));
      });

      test('VLSM ${level.name}', () {
        for (var seed = 0; seed < 300; seed++) {
          final e = VlsmExercise.generate(TrainingRandom(seed), level);
          expect(e.needs.length, inInclusiveRange(3, 5));
          expect(isPrivate(e.base), isTrue);
          expect(e.base & maskOf(e.basePrefix), e.base);
          expect(e.needs.map((n) => n.name).toSet().length, e.needs.length);
          final end = e.base + (1 << (32 - e.basePrefix));
          final order = List<int>.generate(e.needs.length, (i) => i)
            ..sort((x, y) {
              final c = e.needs[y].hosts.compareTo(e.needs[x].hosts);
              return c != 0 ? c : x.compareTo(y);
            });
          var cursor = e.base;
          for (final i in order) {
            final s = e.plan[i];
            final size = 1 << (32 - s.prefix);
            final h = e.needs[i].hosts;
            expect(size - 2, greaterThanOrEqualTo(h));
            expect(size ~/ 2 - 2, lessThan(h));
            expect(s.network % size, 0);
            expect(s.network, cursor);
            cursor += size;
          }
          expect(cursor, lessThanOrEqualTo(end));
          final g = checkVlsm(e, [
            for (final s in e.plan)
              VlsmAnswer(
                  prefix: '/${s.prefix}', network: formatIpv4(s.network)),
          ]);
          expect(g.check.correct, isTrue);
          expect(g.check.explanation, contains('Plan corrigé'));
          expect(checkVlsm(e, const []).check.correct, isFalse);
        }
      });
    }
  });

  testWidgets('le widget se construit et vérifie', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: SubnetTrainer())));
    expect(find.text('Sous-réseaux IPv4'), findsOneWidget);
    await tester.tap(find.text('Vérifier'));
    await tester.pump();
    expect(find.text('0 / 1'), findsOneWidget);
    await tester.tap(find.text('Même réseau ?').first);
    await tester.pump();
    await tester.tap(find.text('Découpage VLSM'));
    await tester.pump();
    await tester.tap(find.text('Vérifier'));
    await tester.pump();
    expect(find.text('0 / 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
