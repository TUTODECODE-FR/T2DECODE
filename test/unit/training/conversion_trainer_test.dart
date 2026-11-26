import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/training/conversion_trainer.dart';
import 'package:tutodecode/features/training/training_kit.dart';

ConversionExercise num8(ConversionKind k, int v) =>
    ConversionExercise(topic: ConversionTopic.octet, kind: k, value: v);
ConversionExercise num16(ConversionKind k, int v) => ConversionExercise(
    topic: ConversionTopic.mot16, kind: k, width: 16, value: v);
ConversionExercise ip(ConversionKind k, List<int> b) =>
    ConversionExercise(topic: ConversionTopic.ipv4, kind: k, bytes: b);
ConversionExercise mac(ConversionKind k, List<int> b) =>
    ConversionExercise(topic: ConversionTopic.mac, kind: k, bytes: b);
ConversionExercise pre(ConversionKind k, int p, [int p2 = 0]) =>
    ConversionExercise(
        topic: ConversionTopic.prefixe, kind: k, prefix: p, prefix2: p2);

bool ok(ConversionExercise ex, String a) => checkConversion(ex, a).correct;

/// Réponse attendue recalculée indépendamment (par d'autres moyens que le code testé).
String independent(ConversionExercise ex) {
  String dotted(List<int> b) => b.join('.');
  List<int> mask(int p) {
    final bits = '1' * p + '0' * (32 - p);
    return [
      for (var i = 0; i < 4; i++)
        int.parse(bits.substring(8 * i, 8 * i + 8), radix: 2)
    ];
  }

  switch (ex.kind) {
    case ConversionKind.decToBin:
    case ConversionKind.hexToBin:
      return ex.value.toRadixString(2).padLeft(ex.width, '0');
    case ConversionKind.decToHex:
    case ConversionKind.binToHex:
      return '0x${ex.value.toRadixString(16)}';
    case ConversionKind.binToDec:
    case ConversionKind.hexToDec:
      return '${ex.value}';
    case ConversionKind.cidrToMask:
      return dotted(mask(ex.prefix));
    case ConversionKind.cidrToWildcard:
      return dotted(mask(ex.prefix).map((b) => 255 - b).toList());
    case ConversionKind.maskToCidr:
      return '${ex.prefix}';
    case ConversionKind.prefixAddresses:
      return BigInt.two.pow(32 - ex.prefix).toString();
    case ConversionKind.prefixHosts:
      return (BigInt.two.pow(32 - ex.prefix) - BigInt.two).toString();
    case ConversionKind.subnetCount:
      return BigInt.two.pow(ex.prefix2 - ex.prefix).toString();
    case ConversionKind.ipToBin:
      return ex.bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join();
    case ConversionKind.ipToHex:
      return ex.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    case ConversionKind.binToIp:
    case ConversionKind.hexToIp:
    case ConversionKind.intToIp:
      return dotted(ex.bytes);
    case ConversionKind.ipToInt:
      return ex.bytes
          .fold<BigInt>(
              BigInt.zero, (a, b) => a * BigInt.from(256) + BigInt.from(b))
          .toString();
    case ConversionKind.macToDec:
      return ex.bytes.join(',');
    case ConversionKind.decToMac:
      return ex.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('-');
    case ConversionKind.macFirstOctetBin:
      return '0b${ex.bytes.first.toRadixString(2).padLeft(8, '0')}';
  }
}

void main() {
  group('cas connus calculés à la main', () {
    test('octets', () {
      expect(num8(ConversionKind.decToBin, 200).expected, '1100 1000');
      expect(ok(num8(ConversionKind.decToBin, 200), '11001000'), isTrue);
      expect(ok(num8(ConversionKind.decToBin, 200), '0b1100 1000'), isTrue);
      expect(ok(num8(ConversionKind.decToBin, 200), '11001001'), isFalse);
      expect(ok(num8(ConversionKind.decToBin, 5), '101'), isTrue);
      expect(ok(num8(ConversionKind.decToBin, 5), '0000 0101'), isTrue);
      expect(ok(num8(ConversionKind.decToBin, 5), '000000101'), isFalse,
          reason: '9 bits pour un octet');
      expect(num8(ConversionKind.decToHex, 200).expected, 'C8');
      expect(ok(num8(ConversionKind.decToHex, 200), '0xc8'), isTrue);
      expect(ok(num8(ConversionKind.decToHex, 200), 'C8h'), isTrue);
      expect(ok(num8(ConversionKind.decToHex, 10), '0A'), isTrue);
      expect(ok(num8(ConversionKind.decToHex, 10), 'a'), isTrue);
      expect(ok(num8(ConversionKind.hexToDec, 200), '200'), isTrue);
      expect(ok(num8(ConversionKind.hexToDec, 200), '0xC8'), isFalse,
          reason: 'on demande du décimal');
      expect(num8(ConversionKind.binToHex, 0xAF).given, '1010 1111');
      expect(ok(num8(ConversionKind.binToHex, 0xAF), 'AF'), isTrue);
      expect(num8(ConversionKind.hexToBin, 0x3C).expected, '0011 1100');
      expect(ok(num8(ConversionKind.binToDec, 255), '255'), isTrue);
    });

    test('mots de 16 bits', () {
      expect(num16(ConversionKind.decToHex, 443).expected, '01BB');
      expect(
          num16(ConversionKind.decToBin, 443).expected, '0000 0001 1011 1011');
      expect(ok(num16(ConversionKind.decToHex, 4660), '0x1234'), isTrue);
      expect(num16(ConversionKind.hexToDec, 0x86DD).given, '0x86DD');
      expect(ok(num16(ConversionKind.hexToDec, 0x86DD), '34525'), isTrue);
      expect(ok(num16(ConversionKind.hexToDec, 0x86DD), '34 525'), isTrue);
      expect(ok(num16(ConversionKind.binToHex, 8080), '1F90'), isTrue);
      expect(explainConversion(num16(ConversionKind.hexToDec, 4660)),
          contains('1 × 4096 + 2 × 256 + 3 × 16 + 4 × 1'));
    });

    test('masques', () {
      const m = ConversionTopic.masque;
      const e20 = ConversionExercise(
          topic: m, kind: ConversionKind.cidrToMask, prefix: 20);
      expect(e20.expected, '255.255.240.0');
      expect(ok(e20, ' 255 . 255 . 240 . 0 '), isTrue);
      expect(ok(e20, '255.255.248.0'), isFalse);
      const w20 = ConversionExercise(
          topic: m, kind: ConversionKind.cidrToWildcard, prefix: 20);
      expect(w20.expected, '0.0.15.255');
      const c26 = ConversionExercise(
          topic: m, kind: ConversionKind.maskToCidr, prefix: 26);
      expect(c26.given, '255.255.255.192');
      expect(ok(c26, '/26'), isTrue);
      expect(ok(c26, '26'), isTrue);
      expect(ok(c26, '/27'), isFalse);
      expect(maskBytes(0), [0, 0, 0, 0]);
      expect(maskBytes(32), [255, 255, 255, 255]);
      expect(maskBytes(9), [255, 128, 0, 0]);
      expect(maskBytes(30), [255, 255, 255, 252]);
      final x25 = explainConversion(const ConversionExercise(
          topic: m, kind: ConversionKind.cidrToMask, prefix: 25));
      expect(x25, contains('1 bit à 1 → 128'));
      expect(x25, isNot(contains('→ 128 = 128')));
      expect(x25, contains('Masque : 255.255.255.128'));
    });

    test('nombre d\'adresses', () {
      expect(pre(ConversionKind.prefixAddresses, 26).expected, '64');
      expect(pre(ConversionKind.prefixHosts, 26).expected, '62');
      expect(pre(ConversionKind.prefixAddresses, 0).expected, '4 294 967 296');
      expect(pre(ConversionKind.prefixAddresses, 32).expected, '1');
      expect(ok(pre(ConversionKind.prefixAddresses, 16), '65536'), isTrue);
      expect(ok(pre(ConversionKind.prefixAddresses, 16), '65 536'), isTrue);
      expect(ok(pre(ConversionKind.prefixAddresses, 16), '2^16'), isTrue);
      expect(ok(pre(ConversionKind.prefixAddresses, 16), '65534'), isFalse);
      expect(ok(pre(ConversionKind.prefixHosts, 24), '254'), isTrue);
      expect(ok(pre(ConversionKind.prefixHosts, 24), '256'), isFalse);
      expect(ok(pre(ConversionKind.subnetCount, 24, 27), '8'), isTrue);
      expect(explainConversion(pre(ConversionKind.prefixHosts, 30)),
          contains('RFC 3021'));
    });

    test('adresses IPv4', () {
      const a = [192, 168, 1, 1];
      expect(ip(ConversionKind.ipToInt, a).expected, '3 232 235 777');
      expect(ok(ip(ConversionKind.ipToInt, a), '3232235777'), isTrue);
      expect(ok(ip(ConversionKind.intToIp, a), '192.168.1.1'), isTrue);
      expect(
          ip(ConversionKind.intToIp, const [10, 0, 0, 1]).given, '167 772 161');
      expect(ip(ConversionKind.ipToBin, a).expected,
          '11000000.10101000.00000001.00000001');
      expect(
          ok(ip(ConversionKind.ipToBin, a), '11000000 10101000 1 1'), isTrue);
      expect(
          ok(ip(ConversionKind.ipToBin, a), '11000000101010000000000100000001'),
          isTrue);
      expect(ok(ip(ConversionKind.ipToHex, a), 'C0.A8.01.01'), isTrue);
      expect(ok(ip(ConversionKind.ipToHex, a), 'c0 a8 1 1'), isTrue);
      expect(ok(ip(ConversionKind.ipToHex, a), '0xC0A80101'), isTrue);
      expect(
          ip(ConversionKind.hexToIp, const [10, 0, 0, 1]).given, '0A 00 00 01');
      expect(ok(ip(ConversionKind.hexToIp, const [10, 0, 0, 1]), '10.0.0.1'),
          isTrue);
      expect(ok(ip(ConversionKind.binToIp, a), '192.168.1.2'), isFalse);
    });

    test('adresses MAC', () {
      const m = [0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E];
      expect(mac(ConversionKind.macToDec, m).expected, '0 26 43 60 77 94');
      expect(ok(mac(ConversionKind.macToDec, m), '0.26.43.60.77.94'), isTrue);
      expect(
          ok(mac(ConversionKind.macToDec, m), '0, 26, 43, 60, 77, 94'), isTrue);
      for (final f in [
        '00:1A:2B:3C:4D:5E',
        '00-1a-2b-3c-4d-5e',
        '001a.2b3c.4d5e',
        '001A2B3C4D5E',
        '0:1a:2b:3c:4d:5e',
      ]) {
        expect(ok(mac(ConversionKind.decToMac, m), f), isTrue, reason: f);
      }
      expect(ok(mac(ConversionKind.decToMac, m), '00:1A:2B:3C:4D:5F'), isFalse);
      const v6 = [0x33, 0x33, 0, 0, 0, 1];
      expect(mac(ConversionKind.macFirstOctetBin, v6).expected, '0011 0011');
      final x = explainConversion(mac(ConversionKind.macFirstOctetBin, v6));
      expect(x, contains('multicast'));
      expect(x, contains('RFC 2464'));
      const local = [0x02, 0x42, 0xAC, 0x11, 0x00, 0x02];
      expect(explainConversion(mac(ConversionKind.macFirstOctetBin, local)),
          contains('administrée localement'));
    });

    test('explications détaillées', () {
      final d = explainConversion(num8(ConversionKind.decToBin, 200));
      expect(d, contains('128 : 200 ≥ 128 → 1, reste 72'));
      expect(d, contains('Restes lus de bas en haut : 11001000'));
      final h = explainConversion(num8(ConversionKind.decToHex, 200));
      expect(h, contains('200 ÷ 16 = 12, reste 8'));
      expect(h, contains('1100 = 8 + 4 = 12 → C'));
      expect(explainConversion(num8(ConversionKind.hexToBin, 0xC8)),
          contains('C = 12 = 8 + 4 → 1100'));
      final c = checkConversion(num8(ConversionKind.decToBin, 200), 'abc');
      expect(c.correct, isFalse);
      expect(c.explanation, contains('Format non reconnu'));
      expect(checkConversion(num8(ConversionKind.decToBin, 200), '').correct,
          isFalse);
    });
  });

  test('300 graines par niveau et par thème : cohérence, sans exception', () {
    for (final level in ConversionLevel.values) {
      for (final topic in <ConversionTopic?>[
        null,
        ...conversionTopicsFor(level)
      ]) {
        for (var seed = 0; seed < 300; seed++) {
          final ex = generateConversion(TrainingRandom(seed),
              level: level, topic: topic);
          if (topic != null) expect(ex.topic, topic);
          expect(conversionTopicsFor(level), contains(ex.topic));
          // Bornes.
          if (ex.topic == ConversionTopic.octet) {
            expect(ex.value, inInclusiveRange(1, 255));
          }
          if (ex.topic == ConversionTopic.mot16) {
            expect(ex.value, inInclusiveRange(0, 65535));
          }
          if (ex.topic == ConversionTopic.ipv4) {
            expect(ex.bytes.length, 4);
            expect(ex.bytes.every((b) => b >= 0 && b <= 255), isTrue);
          }
          if (ex.topic == ConversionTopic.mac) {
            expect(ex.bytes.length, 6);
            expect(ex.bytes.every((b) => b >= 0 && b <= 255), isTrue);
          }
          if (ex.kind == ConversionKind.prefixHosts) {
            expect(ex.prefix, lessThanOrEqualTo(30));
          }
          if (ex.kind == ConversionKind.subnetCount) {
            expect(ex.prefix2, greaterThan(ex.prefix));
            expect(ex.prefix2, lessThanOrEqualTo(30));
          }
          expect(ex.prefix, inInclusiveRange(0, 32));
          expect(ex.instruction, isNotEmpty);
          expect(ex.given, isNotEmpty);
          expect(ex.hint, isNotEmpty);
          // La réponse canonique et une réponse calculée autrement sont acceptées.
          final good = checkConversion(ex, ex.expected);
          expect(good.correct, isTrue, reason: '${ex.kind} ${ex.expected}');
          expect(good.explanation, contains('Réponse attendue'));
          expect(good.explanation.split('\n').length, greaterThan(3));
          expect(ok(ex, independent(ex)), isTrue,
              reason: '${ex.kind} ${independent(ex)} / ${ex.expected}');
          expect(ok(ex, ex.expected.toLowerCase()), isTrue);
          // Une réponse fausse ou absurde est refusée sans exception.
          expect(ok(ex, 'zz'), isFalse);
          expect(ok(ex, ''), isFalse);
          expect(ok(ex, '-1'), isFalse);
        }
      }
    }
  });

  group('bugs corrigés (relecture)', () {
    test('IPv4 binaire : octets écrits en demi-octets séparés par des espaces',
        () {
      const a = [192, 168, 1, 1];
      final ex = ip(ConversionKind.ipToBin, a);
      expect(ok(ex, '1100 0000.1010 1000.0000 0001.0000 0001'), isTrue);
      expect(ok(ex, '1100 0000 1010 1000 0000 0001 0000 0001'), isTrue);
      expect(ok(ex, '0b1100 0000.1010 1000.0000 0001.0000 0010'), isFalse);
      expect(ok(ex, '11000000..10101000.00000001.00000001'), isFalse);
    });

    test('IPv4 hexadécimal : deux mots de 16 bits', () {
      final ex = ip(ConversionKind.ipToHex, const [10, 0, 0, 1]);
      expect(ok(ex, '0A00 0001'), isTrue);
      expect(ok(ex, '0x0A00 0001'), isTrue);
      expect(ok(ex, '0A00 0002'), isFalse);
    });

    test('remarque des zéros de tête : suffixe b non compté comme un bit', () {
      // 4 = 100 ; « 00000100b » fait bien 8 bits : pas de remarque.
      final ex = num8(ConversionKind.decToBin, 4);
      final c = checkConversion(ex, '00000100b');
      expect(c.correct, isTrue);
      expect(c.explanation, isNot(contains('zéros de tête')));
      expect(checkConversion(ex, '100').explanation, contains('zéros de tête'));
    });

    test('hexadécimal vers décimal sur 8 bits : poids 1 et 16 seulement', () {
      final e = explainConversion(num8(ConversionKind.hexToDec, 0xAD));
      expect(e, contains('(de droite à gauche : 1, 16)'));
      expect(e, isNot(contains('4096')));
      expect(explainConversion(num16(ConversionKind.hexToDec, 0x1F90)),
          contains('1, 16, 256, 4096'));
    });
  });

  test('aide-mémoire', () {
    final s = conversionCheatSheet();
    expect(s, contains('C = 12 = 1100'));
    expect(s, contains('4→240'));
  });

  testWidgets('écran autonome : vérification et score', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConversionTrainer(seed: 7))));
    expect(find.text('Binaire, décimal, hexadécimal'), findsOneWidget);
    final state = tester.state(find.byType(ConversionTrainer));
    expect(state, isNotNull);
    await tester.enterText(find.byType(TextField), 'zz');
    await tester.tap(find.text('Vérifier'));
    await tester.pump();
    expect(find.text('Pas encore'), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);
    await tester.tap(find.text('Nouvel exercice'));
    await tester.pump();
    expect(find.text('Pas encore'), findsNothing);
    await tester.tap(find.text('Avancé'));
    await tester.pump();
    expect(find.text('Adresses MAC'), findsOneWidget);
  });
}
