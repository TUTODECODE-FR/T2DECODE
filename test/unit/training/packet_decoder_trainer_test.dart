// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/training/packet_decoder_trainer.dart';
import 'package:tutodecode/features/training/training_kit.dart';

int _w(List<int> b, int i) => (b[i] << 8) | b[i + 1];

/// Décodeur indépendant : relit la trame octet par octet et vérifie chaque champ.
void _checkFrame(PacketExercise ex) {
  final b = ex.bytes;
  expect(b.sublist(0, 6), ex.dstMac);
  expect(b.sublist(6, 12), ex.srcMac);
  expect(ex.dstMac[0] & 0x01, 0, reason: 'MAC destination individuelle');
  var e = 14;
  if (ex.vlanId != null) {
    expect(_w(b, 12), 0x8100);
    expect(_w(b, 14) & 0x0fff, ex.vlanId);
    expect(ex.vlanId, inInclusiveRange(1, 4094));
    e = 18;
  }
  expect(_w(b, e - 2), 0x0800);
  expect(ex.ipOffset, e);
  expect(b[e] >> 4, 4);
  expect(b[e] & 0xf, 5);
  final total = _w(b, e + 2);
  expect(total, ex.totalLength);
  expect(e + total + ex.paddingLength, b.length);
  if (ex.paddingLength > 0) {
    expect(b.length, 60);
    expect(b.sublist(b.length - ex.paddingLength).every((x) => x == 0), isTrue);
  }
  if (ex.level != PacketLevel.debutant)
    expect(b.length, greaterThanOrEqualTo(60));
  expect(_w(b, e + 6), ex.dontFragment ? 0x4000 : 0);
  expect(b[e + 8], ex.ttl);
  expect(ex.ttl, greaterThan(0));
  expect([64, 128, 255].where((t) => t >= ex.ttl).first, ex.initialTtl);
  expect(b[e + 9], ex.protocolNumber);
  expect(b.sublist(e + 12, e + 16), ex.srcIp);
  expect(b.sublist(e + 16, e + 20), ex.dstIp);
  final header = b.sublist(e, e + 20);
  expect(_w(b, e + 10), ex.ipChecksum);
  // Un en-tête intact donne une somme de vérification nulle (RFC 1071).
  expect(internetChecksum(header) == 0, ex.ipChecksumValid);
  final zeroed = [...header]
    ..[10] = 0
    ..[11] = 0;
  expect(internetChecksum(zeroed), ex.ipChecksumExpected);
  if (ex.level != PacketLevel.expert) expect(ex.ipChecksumValid, isTrue);

  final t = e + 20;
  expect(ex.l4Offset, t);
  final seg = b.sublist(t, e + total);
  switch (ex.transport) {
    case PacketTransport.tcp:
      expect(ex.protocolNumber, 6);
      expect(_w(b, t), ex.srcPort);
      expect(_w(b, t + 2), ex.dstPort);
      expect((b[t + 12] >> 4) * 4, ex.tcpHeaderLength);
      expect(b[t + 13], ex.tcpFlags);
      expect(total - 20 - ex.tcpHeaderLength!, ex.payloadLength);
      if (ex.tcpFlags! & tcpAck == 0) expect(seg.sublist(8, 12), [0, 0, 0, 0]);
      expect(transportChecksum(ex.srcIp, ex.dstIp, 6, seg), 0);
      if (ex.tcpHeaderLength == 24)
        expect(seg.sublist(20, 24), [2, 4, 0x05, 0xb4]);
      break;
    case PacketTransport.udp:
      expect(ex.protocolNumber, 17);
      expect(_w(b, t), ex.srcPort);
      expect(_w(b, t + 2), ex.dstPort);
      expect(_w(b, t + 4), total - 20);
      expect(_w(b, t + 4) - 8, ex.payloadLength);
      expect(_w(b, t + 6), isNot(0));
      expect(transportChecksum(ex.srcIp, ex.dstIp, 17, seg), 0);
      final svcPort = ex.service!.port;
      if (svcPort == 53) {
        // DNS : QR = 0 pour une requête, 1 pour une réponse ; QDCOUNT = 1.
        expect(seg[10] >> 7, ex.toServer ? 0 : 1);
        expect(_w(seg, 12), 1);
        expect(_w(seg, 14), ex.toServer ? 0 : 1);
      }
      if (svcPort == 69 || svcPort == 514) expect(ex.toServer, isTrue);
      if (svcPort == 69) expect(_w(seg, 8), 1);
      break;
    case PacketTransport.icmp:
      expect(ex.level, isNot(PacketLevel.debutant));
      expect(b[t], ex.icmpType);
      expect(b[t + 1], 0);
      expect(_w(b, t + 6), ex.icmpSequence);
      expect(internetChecksum(seg), 0);
      expect(ex.icmpType == 8, ex.toServer);
      // ping Windows : 32 octets ; ping Linux : 56 octets (timeval 16 + 0x10..0x37).
      expect(ex.payloadLength, ex.initialTtl == 128 ? 32 : 56);
      if (ex.initialTtl != 128) {
        expect(seg.sublist(8 + 16), [for (var x = 0x10; x <= 0x37; x++) x]);
      }
  }
  if (ex.transport != PacketTransport.icmp) {
    final svc = ex.service!;
    final wellKnown = ex.toServer ? ex.dstPort : ex.srcPort;
    final ephemeral = ex.toServer ? ex.srcPort : ex.dstPort;
    expect(wellKnown, svc.port);
    expect(ephemeral, inInclusiveRange(49152, 65535));
    expect(svc.transport, ex.transport);
  }
}

/// Réponses canoniques, construites à partir du décodage indépendant.
Map<String, String> _goodAnswers(PacketExercise ex) {
  final a = <String, String>{};
  for (final q in ex.questions) {
    final String v;
    switch (q.id) {
      case 'dstMac':
        v = formatMac(ex.dstMac);
        break;
      case 'srcMac':
        v = formatMac(ex.srcMac);
        break;
      case 'tpid':
        v = '0x8100';
        break;
      case 'vlan':
        v = '${ex.vlanId}';
        break;
      case 'etherType':
        v = '0x0800';
        break;
      case 'srcIp':
        v = formatIp(ex.srcIp);
        break;
      case 'dstIp':
        v = formatIp(ex.dstIp);
        break;
      case 'ttl':
        v = '${ex.ttl}';
        break;
      case 'initialTtl':
        v = '${ex.initialTtl}';
        break;
      case 'protocol':
        v = '${ex.protocolNumber}';
        break;
      case 'totalLength':
        v = '${ex.totalLength}';
        break;
      case 'df':
        v = ex.dontFragment ? 'oui' : 'non';
        break;
      case 'icmpType':
        v = '${ex.icmpType}';
        break;
      case 'icmpSeq':
        v = '${ex.icmpSequence}';
        break;
      case 'srcPort':
        v = '${ex.srcPort}';
        break;
      case 'dstPort':
        v = '${ex.dstPort}';
        break;
      case 'flags':
        v = tcpFlagsToText(ex.tcpFlags!);
        break;
      case 'service':
        v = ex.service!.accepted.first;
        break;
      case 'payload':
        v = '${ex.payloadLength}';
        break;
      case 'checksum':
        v = '0x${hex4(ex.ipChecksumExpected)}';
        break;
      case 'checksumOk':
        v = ex.ipChecksumValid ? 'oui' : 'non';
        break;
      default:
        throw StateError('question inconnue ${q.id}');
    }
    a[q.id] = v;
  }
  return a;
}

/// Variantes de saisie raisonnables (casse, séparateurs, hexadécimal...).
Map<String, String> _variantAnswers(PacketExercise ex) {
  final a = _goodAnswers(ex);
  a['dstMac'] = ex.dstMac.map(hex2).join('-').toUpperCase();
  a['srcMac'] = ex.srcMac.map(hex2).join();
  if (a.containsKey('etherType')) a['etherType'] = ' IPv4 ';
  a['ttl'] = '0x${hex2(ex.ttl)}';
  a['protocol'] = ex.transportName.toLowerCase();
  if (a.containsKey('flags')) a['flags'] = tcpFlagsToTcpdump(ex.tcpFlags!);
  if (a.containsKey('srcPort')) a['srcPort'] = ' ${ex.srcPort} ';
  if (a.containsKey('service'))
    a['service'] = ex.service!.accepted.last.toUpperCase();
  if (a.containsKey('icmpType')) {
    a['icmpType'] = ex.icmpType == 8 ? 'Echo request' : 'réponse d\'écho';
  }
  if (a.containsKey('df')) a['df'] = ex.dontFragment ? 'OUI' : 'Non';
  if (a.containsKey('checksum'))
    a['checksum'] = hex4(ex.ipChecksumExpected).toUpperCase();
  return a;
}

void main() {
  group('Sommes de contrôle (cas calculés à la main)', () {
    test('RFC 1071, exemple §3 : 00 01 f2 03 f4 f5 f6 f7', () {
      // Somme = 0001 + f203 + f4f5 + f6f7 = 0x2ddf0 -> 0xddf2 ; complément = 0x220d.
      expect(internetChecksum([0x00, 0x01, 0xf2, 0x03, 0xf4, 0xf5, 0xf6, 0xf7]),
          0x220d);
    });
    test('en-tête IPv4 classique 4500 0073 ... c0a8 00c7 -> 0xb861', () {
      final h = [
        0x45, 0x00, 0x00, 0x73, 0x00, 0x00, 0x40, 0x00, 0x40, 0x11, //
        0x00, 0x00, 0xc0, 0xa8, 0x00, 0x01, 0xc0, 0xa8, 0x00, 0xc7,
      ];
      expect(internetChecksum(h), 0xb861);
      h[10] = 0xb8;
      h[11] = 0x61;
      expect(internetChecksum(h), 0);
    });
    test('octet impair complété par un zéro', () {
      expect(internetChecksum([0x01]), (~0x0100) & 0xffff);
    });
  });

  group('Analyse des réponses', () {
    test('MAC', () {
      expect(parseMac('00:1A:2b:3c:4d:5e'), '001a2b3c4d5e');
      expect(parseMac('00-1a-2b-3c-4d-5e'), '001a2b3c4d5e');
      expect(parseMac('001a.2b3c.4d5e'), '001a2b3c4d5e');
      expect(parseMac('00:1a:2b:3c:4d'), isNull);
      expect(parseMac('zz:1a:2b:3c:4d:5e'), isNull);
    });
    test('entiers et hexadécimal', () {
      expect(parseFlexibleInt('443'), 443);
      expect(parseFlexibleInt('0x01BB'), 443);
      expect(parseFlexibleInt('1bbh'), 443);
      expect(parseFlexibleInt('abc'), isNull);
      expect(parseHexValue('B861'), 0xb861);
      expect(parseHexValue('0x b8 61'), 0xb861);
    });
    test('IPv4', () {
      expect(parseIpv4(' 192.168.1.10 '), [192, 168, 1, 10]);
      expect(parseIpv4('192.168.1.256'), isNull);
      expect(parseIpv4('192.168.1'), isNull);
    });
    test('EtherType', () {
      expect(parseEtherType('0x0800'), 0x0800);
      expect(parseEtherType('0800'), 0x0800);
      expect(parseEtherType('800'), 0x0800);
      expect(parseEtherType('IPv4'), 0x0800);
      expect(parseEtherType('0x8100'), 0x8100);
      expect(parseEtherType('802.1Q'), 0x8100);
    });
    test('protocole', () {
      expect(parseIpProtocol('6'), 6);
      expect(parseIpProtocol('TCP'), 6);
      expect(parseIpProtocol('17 (UDP)'), 17);
      expect(parseIpProtocol('0x11'), 17);
      expect(parseIpProtocol('icmp'), 1);
    });
    test('drapeaux TCP', () {
      expect(parseTcpFlags('SYN, ACK'), 0x12);
      expect(parseTcpFlags('syn+ack'), 0x12);
      expect(parseTcpFlags('ACK SYN'), 0x12);
      expect(parseTcpFlags('[S.]'), 0x12);
      expect(parseTcpFlags('S'), 0x02);
      expect(parseTcpFlags('0x18'), 0x18);
      expect(parseTcpFlags('PSH ACK'), 0x18);
      expect(parseTcpFlags('[P.]'), 0x18);
      expect(parseTcpFlags('FIN-ACK'), 0x11);
      expect(parseTcpFlags('RST'), 0x04);
      expect(parseTcpFlags('[SEW]'), 0xc2);
      expect(parseTcpFlags('syn et truc'), isNull);
      expect(parseTcpFlags(''), isNull);
      expect(tcpFlagsToText(0x12), 'SYN, ACK');
      expect(tcpFlagsToTcpdump(0x12), '[S.]');
      expect(tcpFlagsToTcpdump(0x18), '[P.]');
      // Ordre de tcpdump (print-tcp.c) : F S R P . U E W.
      expect(tcpFlagsToTcpdump(0x11), '[F.]');
      expect(tcpFlagsToTcpdump(0x14), '[R.]');
      expect(tcpFlagsToTcpdump(0x52), '[S.E]');
      expect(tcpFlagsToTcpdump(0xc2), '[SEW]');
      // Ordre de Wireshark : FIN SYN RST PSH ACK URG ECE CWR.
      expect(tcpFlagsToText(0x11), 'FIN, ACK');
      expect(tcpFlagsToText(0x18), 'PSH, ACK');
      expect(tcpFlagsToText(0xc2), 'SYN, ECE, CWR');
      expect(tcpFlagsToText(0), 'aucun');
      expect(parseTcpFlags('[S.E]'), 0x52);
    });
    test('oui / non', () {
      expect(parseYesNo('Oui'), isTrue);
      expect(parseYesNo('non'), isFalse);
      expect(parseYesNo('peut-être'), isNull);
    });
  });

  group('Vidage hexadécimal', () {
    final bytes = [
      for (var i = 0; i < 18; i++) 0x41 + i
    ]; // « ABCDEFGHIJKLMNOPQR »
    test('Wireshark', () {
      final d = hexDump(bytes, DumpStyle.wireshark).split('\n');
      expect(d, hasLength(2));
      expect(d[0],
          '0000  41 42 43 44 45 46 47 48  49 4a 4b 4c 4d 4e 4f 50   ABCDEFGH IJKLMNOP');
      expect(d[1].startsWith('0010  51 52 '), isTrue);
      expect(d[1].endsWith('   QR'), isTrue);
    });
    test('tcpdump -XX', () {
      final d = hexDump(bytes, DumpStyle.tcpdump).split('\n');
      expect(d[0],
          '0x0000:  4142 4344 4546 4748 494a 4b4c 4d4e 4f50  ABCDEFGHIJKLMNOP');
      expect(d[1].startsWith('0x0010:  5152 '), isTrue);
      expect(d[1].endsWith('  QR'), isTrue);
    });
    test('octets non imprimables remplacés par un point', () {
      expect(hexDump([0x00, 0x7f, 0x20], DumpStyle.wireshark).endsWith('.. '),
          isTrue);
    });
  });

  group('Générateur et vérification sur 300 graines par niveau', () {
    for (final level in PacketLevel.values) {
      test('niveau ${level.name}', () {
        final seen = <String>{};
        var vlan = 0, icmp = 0, udp = 0, badSum = 0, padded = 0;
        for (var seed = 0; seed < 300; seed++) {
          final ex = generatePacketExercise(TrainingRandom(seed), level);
          _checkFrame(ex);
          seen.add(ex.dump(DumpStyle.wireshark));
          if (ex.vlanId != null) vlan++;
          if (ex.transport == PacketTransport.icmp) icmp++;
          if (ex.transport == PacketTransport.udp) udp++;
          if (!ex.ipChecksumValid) badSum++;
          if (ex.paddingLength > 0) padded++;

          // Mêmes graines -> même exercice.
          final again = generatePacketExercise(TrainingRandom(seed), level);
          expect(again.bytes, ex.bytes);

          final ids = ex.questions.map((q) => q.id).toList();
          expect(ids.toSet().length, ids.length);
          expect(
              ids,
              containsAll([
                'dstMac',
                'srcMac',
                'etherType',
                'srcIp',
                'dstIp',
                'ttl',
                'protocol'
              ]));
          if (ex.transport == PacketTransport.tcp)
            expect(ids, contains('flags'));
          if (ex.transport != PacketTransport.icmp) {
            expect(ids, containsAll(['srcPort', 'dstPort', 'service']));
          }

          // Réponses justes (forme canonique, puis variantes).
          for (final answers in [_goodAnswers(ex), _variantAnswers(ex)]) {
            final grades = gradePacketAnswers(ex, answers);
            final wrong = grades.entries
                .where((g) => !g.value)
                .map((g) => '${g.key}=${answers[g.key]}');
            expect(wrong, isEmpty, reason: 'graine $seed ${ex.summary}');
            final res = checkPacketExercise(ex, answers);
            expect(res.correct, isTrue);
            expect(res.explanation,
                startsWith('${ex.questions.length} / ${ex.questions.length}'));
          }

          // Réponses vides : tout est faux, l'explication donne la méthode.
          final empty = checkPacketExercise(ex, const {});
          expect(empty.correct, isFalse);
          expect(empty.explanation, startsWith('0 / ${ex.questions.length}'));
          expect(empty.explanation, contains('octets 0 à 5'));
          expect(
              empty.explanation,
              contains(
                  '0x${hex2(ex.ttl)} = ${ex.ttl >> 4}×16 + ${ex.ttl & 0xf} = ${ex.ttl}'));

          // Pièges classiques refusés.
          final swapped = _goodAnswers(ex)
            ..['dstMac'] = formatMac(ex.srcMac)
            ..['srcIp'] = formatIp(ex.dstIp)
            ..['ttl'] = '${ex.ttl + 1}'
            ..['protocol'] = ex.protocolNumber == 6 ? '17' : '6';
          final g = gradePacketAnswers(ex, swapped);
          expect(g['dstMac'], isFalse);
          expect(g['srcIp'], isFalse);
          expect(g['ttl'], isFalse);
          expect(g['protocol'], isFalse);
          if (ex.transport == PacketTransport.tcp) {
            final f = ex.tcpFlags!;
            expect(
                gradePacketAnswers(
                    ex, {'flags': tcpFlagsToText(f ^ tcpAck)})['flags'],
                isFalse);
          }
          if (ex.transport != PacketTransport.icmp) {
            // Le port inversé n'est pas accepté.
            expect(
                gradePacketAnswers(ex, {'srcPort': '${ex.dstPort}'})['srcPort'],
                isFalse);
          }
          if (level == PacketLevel.expert) {
            expect(
                gradePacketAnswers(ex, {
                  'checksumOk': ex.ipChecksumValid ? 'non' : 'oui'
                })['checksumOk'],
                isFalse);
          }
        }
        expect(seen.length, greaterThan(295),
            reason: 'les exercices doivent varier');
        expect(udp, greaterThan(30));
        if (level == PacketLevel.debutant) {
          expect(vlan + icmp + badSum + padded, 0);
        } else {
          expect(vlan, greaterThan(30));
          expect(icmp, greaterThan(20));
          expect(padded, greaterThan(20));
        }
        if (level == PacketLevel.expert) {
          expect(badSum, inInclusiveRange(100, 200));
        } else {
          expect(badSum, 0);
        }
      });
    }
  });

  test('correction : conversion des ports et position des octets (cas connu)',
      () {
    // Trouve un segment TCP vers le port 443 et vérifie le texte de la correction.
    PacketExercise? ex;
    for (var seed = 0; ex == null; seed++) {
      final c =
          generatePacketExercise(TrainingRandom(seed), PacketLevel.debutant);
      if (c.transport == PacketTransport.tcp && c.dstPort == 443) ex = c;
    }
    final res = checkPacketExercise(ex, const {});
    expect(res.explanation,
        contains('0x01bb = 0x01×256 + 0xbb = 1×256 + 187 = 443'));
    // Débutant sans VLAN : port destination TCP aux octets 36-37 (0x0024, ligne 0x0020, 5e octet).
    expect(
        res.explanation,
        contains(
            'octets 36 à 37 (0x0024 à 0x0025 ; début : ligne 0x0020, 5e octet de la ligne)'));
    expect(res.explanation, contains('HTTPS'));
    // Drapeaux à l'octet 47 (0x002f).
    expect(res.explanation,
        contains('octet 47 (0x002f ; ligne 0x0020, 16e octet de la ligne)'));
  });

  test('somme de contrôle fausse expliquée en mode expert', () {
    PacketExercise? ex;
    for (var seed = 0; ex == null; seed++) {
      final c =
          generatePacketExercise(TrainingRandom(seed), PacketLevel.expert);
      if (!c.ipChecksumValid) ex = c;
    }
    final res = checkPacketExercise(ex, const {});
    expect(res.explanation, contains('0x${hex4(ex.ipChecksumExpected)}'));
    expect(res.explanation, contains('différente'));
    expect(
        gradePacketAnswers(ex, {'checksum': hex4(ex.ipChecksum)})['checksum'],
        isFalse);
  });

  testWidgets('le widget s\'affiche, vérifie et change de niveau',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PacketDecoderTrainer())));
    expect(find.text('Décoder une trame'), findsOneWidget);
    await tester.tap(find.text('Vérifier'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 1'), findsOneWidget);
    await tester.tap(find.text('Expert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('tcpdump -XX'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('aide-mémoire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvel exercice'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('Relecture : bugs corrigés', () {
    test(
        'TTL cohérent : même réseau local = aucun routeur, réponse distante = au moins un',
        () {
      var lan = 0, remote = 0;
      for (final level in PacketLevel.values) {
        for (var seed = 0; seed < 300; seed++) {
          final ex = generatePacketExercise(TrainingRandom(seed), level);
          final same = ex.srcIp[0] == ex.dstIp[0] &&
              ex.srcIp[1] == ex.dstIp[1] &&
              ex.srcIp[2] == ex.dstIp[2];
          if (same) {
            lan++;
            expect(ex.ttl, ex.initialTtl, reason: 'graine $seed ${ex.summary}');
          } else if (!ex.toServer) {
            remote++;
            expect(ex.ttl, lessThan(ex.initialTtl),
                reason: 'graine $seed ${ex.summary}');
          }
        }
      }
      expect(lan, greaterThan(50));
      expect(remote, greaterThan(50));
    });

    test('oui / non suivi d\'une précision', () {
      expect(parseYesNo('Oui, positionné'), isTrue);
      expect(parseYesNo('non (0)'), isFalse);
      expect(parseYesNo('peut-être'), isNull);
    });

    test('drapeaux TCP : mots de liaison et notation Scapy', () {
      expect(parseTcpFlags('SYN seul'), tcpSyn);
      expect(parseTcpFlags('ACK uniquement'), tcpAck);
      expect(parseTcpFlags('drapeaux SYN et ACK'), tcpSyn | tcpAck);
      expect(parseTcpFlags('SA'), tcpSyn | tcpAck);
      expect(parseTcpFlags('PA'), tcpPsh | tcpAck);
      expect(parseTcpFlags('drapeaux'), isNull);
      expect(parseTcpFlags('SYN bidule'), isNull);
    });

    test('nombre suivi d\'une précision ; plusieurs nombres refusés', () {
      expect(parseNumberAnswer('443/tcp'), 443);
      expect(parseNumberAnswer('53 / udp'), 53);
      expect(parseNumberAnswer('443 (HTTPS)'), 443);
      expect(parseNumberAnswer('64 (Linux)'), 64);
      expect(parseNumberAnswer('0x40'), 64);
      expect(parseNumberAnswer('64 ou 128'), isNull);
      expect(parseNumberAnswer('64 (ou 128)'), isNull);
    });

    PacketExercise find(bool Function(PacketExercise) ok, PacketLevel level) {
      for (var seed = 0;; seed++) {
        final c = generatePacketExercise(TrainingRandom(seed), level);
        if (ok(c)) return c;
      }
    }

    test('service : plusieurs services proposés à la fois refusés', () {
      final http = find((c) => c.service?.port == 80, PacketLevel.debutant);
      bool svc(PacketExercise ex, String a) =>
          gradePacketAnswers(ex, {'service': a})['service']!;
      expect(svc(http, 'HTTP'), isTrue);
      expect(svc(http, 'HTTP ou HTTPS'), isFalse);
      expect(svc(http, 'http, ssh, ftp'), isFalse);
      expect(
          gradePacketAnswers(
              http, {'dstPort': '${http.dstPort}/tcp'})['dstPort'],
          isTrue);

      final imaps = find((c) => c.service?.port == 993, PacketLevel.debutant);
      expect(svc(imaps, 'IMAP sur TLS'), isTrue);
      final https = find(
          (c) => c.service?.port == 443 && c.transport == PacketTransport.tcp,
          PacketLevel.debutant);
      expect(svc(https, 'HTTPS (HTTP sur TLS)'), isTrue);
      expect(svc(https, 'QUIC'), isFalse);
      final quic = find(
          (c) => c.service?.port == 443 && c.transport == PacketTransport.udp,
          PacketLevel.avance);
      expect(svc(quic, 'QUIC (HTTP/3)'), isTrue);
    });

    test('EtherType : seuil de longueur 802.3 exact (1500)', () {
      final ex =
          generatePacketExercise(TrainingRandom(1), PacketLevel.debutant);
      expect(checkPacketExercise(ex, const {}).explanation,
          contains('≤ 0x05dc (1500)'));
    });
  });

  testWidgets('nouvel exercice et changement de niveau avec un champ rempli',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PacketDecoderTrainer())));
    await tester.enterText(find.byType(TextField).first, 'aa:bb');
    await tester.pump();
    await tester.tap(find.text('Nouvel exercice'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('aa:bb'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'cc');
    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '1');
    await tester.tap(find.text('Débutant'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('cc'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
