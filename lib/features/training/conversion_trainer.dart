// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
//
// Entraînement « Binaire, décimal, hexadécimal » : conversions d'octets, de mots de 16 bits,
// d'adresses IPv4 et MAC, masques CIDR et nombre d'adresses d'un préfixe.
// La logique (génération, vérification, explication) est pure et testable sans interface.
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/training/training_kit.dart';

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

enum ConversionLevel { debutant, avance }

enum ConversionTopic { octet, masque, prefixe, mot16, ipv4, mac }

const Map<ConversionLevel, String> conversionLevelLabels = {
  ConversionLevel.debutant: 'Débutant',
  ConversionLevel.avance: 'Avancé',
};

const Map<ConversionTopic, String> conversionTopicLabels = {
  ConversionTopic.octet: 'Octets',
  ConversionTopic.masque: 'Masques',
  ConversionTopic.prefixe: "Nombre d'adresses",
  ConversionTopic.mot16: 'Mots 16 bits',
  ConversionTopic.ipv4: 'Adresses IPv4',
  ConversionTopic.mac: 'Adresses MAC',
};

/// Thèmes proposés pour un niveau.
List<ConversionTopic> conversionTopicsFor(ConversionLevel level) =>
    level == ConversionLevel.debutant
        ? const [
            ConversionTopic.octet,
            ConversionTopic.masque,
            ConversionTopic.prefixe
          ]
        : ConversionTopic.values;

enum ConversionKind {
  // Nombres (octet ou mot de 16 bits, selon width).
  decToBin,
  decToHex,
  binToDec,
  hexToDec,
  binToHex,
  hexToBin,
  // Masques.
  cidrToMask,
  maskToCidr,
  cidrToWildcard,
  // Nombre d'adresses.
  prefixAddresses,
  prefixHosts,
  subnetCount,
  // Adresses IPv4 complètes.
  ipToBin,
  binToIp,
  ipToHex,
  hexToIp,
  ipToInt,
  intToIp,
  // Adresses MAC.
  macToDec,
  decToMac,
  macFirstOctetBin,
}

/// Forme attendue de la réponse.
enum _AnswerType {
  binary,
  hex,
  decimal,
  dotted,
  cidr,
  count,
  ipBinary,
  ipHex,
  macHex,
  macDecimal
}

/// Un exercice de conversion. [value] sert aux nombres (octet, mot 16 bits, entier 32 bits),
/// [bytes] aux adresses (4 octets IPv4, 6 octets MAC), [prefix] et [prefix2] aux masques
/// et préfixes.
class ConversionExercise {
  const ConversionExercise({
    required this.topic,
    required this.kind,
    this.width = 8,
    this.value = 0,
    this.bytes = const [],
    this.prefix = 0,
    this.prefix2 = 0,
    this.context,
  });

  final ConversionTopic topic;
  final ConversionKind kind;

  /// Nombre de bits du nombre à convertir (8 ou 16).
  final int width;
  final int value;
  final List<int> bytes;
  final int prefix;
  final int prefix2;

  /// Contexte réel facultatif (port, EtherType…).
  final String? context;

  int get hexDigits => width ~/ 4;

  _AnswerType get _answerType {
    switch (kind) {
      case ConversionKind.decToBin:
      case ConversionKind.hexToBin:
      case ConversionKind.macFirstOctetBin:
        return _AnswerType.binary;
      case ConversionKind.decToHex:
      case ConversionKind.binToHex:
        return _AnswerType.hex;
      case ConversionKind.binToDec:
      case ConversionKind.hexToDec:
        return _AnswerType.decimal;
      case ConversionKind.cidrToMask:
      case ConversionKind.cidrToWildcard:
      case ConversionKind.binToIp:
      case ConversionKind.hexToIp:
      case ConversionKind.intToIp:
        return _AnswerType.dotted;
      case ConversionKind.maskToCidr:
        return _AnswerType.cidr;
      case ConversionKind.prefixAddresses:
      case ConversionKind.prefixHosts:
      case ConversionKind.subnetCount:
      case ConversionKind.ipToInt:
        return _AnswerType.count;
      case ConversionKind.ipToBin:
        return _AnswerType.ipBinary;
      case ConversionKind.ipToHex:
        return _AnswerType.ipHex;
      case ConversionKind.macToDec:
        return _AnswerType.macDecimal;
      case ConversionKind.decToMac:
        return _AnswerType.macHex;
    }
  }

  /// Valeur attendue : un entier, ou une liste d'octets pour les adresses.
  Object get _target {
    switch (kind) {
      case ConversionKind.decToBin:
      case ConversionKind.decToHex:
      case ConversionKind.binToDec:
      case ConversionKind.hexToDec:
      case ConversionKind.binToHex:
      case ConversionKind.hexToBin:
        return value;
      case ConversionKind.cidrToMask:
        return maskBytes(prefix);
      case ConversionKind.cidrToWildcard:
        return maskBytes(prefix).map((b) => 255 - b).toList();
      case ConversionKind.maskToCidr:
        return prefix;
      case ConversionKind.prefixAddresses:
        return pow2(32 - prefix);
      case ConversionKind.prefixHosts:
        return pow2(32 - prefix) - 2;
      case ConversionKind.subnetCount:
        return pow2(prefix2 - prefix);
      case ConversionKind.ipToBin:
      case ConversionKind.binToIp:
      case ConversionKind.ipToHex:
      case ConversionKind.hexToIp:
      case ConversionKind.intToIp:
      case ConversionKind.macToDec:
      case ConversionKind.decToMac:
        return bytes;
      case ConversionKind.ipToInt:
        return ipv4ToInt(bytes);
      case ConversionKind.macFirstOctetBin:
        return bytes.first;
    }
  }

  /// Consigne affichée.
  String get instruction {
    switch (kind) {
      case ConversionKind.decToBin:
        return 'Convertis ce nombre décimal en binaire sur $width bits.${_ctx()}';
      case ConversionKind.decToHex:
        return 'Convertis ce nombre décimal en hexadécimal ($hexDigits chiffres).${_ctx()}';
      case ConversionKind.binToDec:
        return 'Convertis ce nombre binaire en décimal.${_ctx()}';
      case ConversionKind.hexToDec:
        return 'Convertis ce nombre hexadécimal en décimal.${_ctx()}';
      case ConversionKind.binToHex:
        return 'Convertis ce nombre binaire en hexadécimal.${_ctx()}';
      case ConversionKind.hexToBin:
        return 'Convertis ce nombre hexadécimal en binaire sur $width bits.${_ctx()}';
      case ConversionKind.cidrToMask:
        return 'Écris le masque de sous-réseau correspondant à ce préfixe, en décimal pointé.';
      case ConversionKind.maskToCidr:
        return 'Donne la longueur de préfixe (notation CIDR) de ce masque de sous-réseau.';
      case ConversionKind.cidrToWildcard:
        return 'Écris le masque générique (wildcard, utilisé dans les ACL Cisco et OSPF) '
            'correspondant à ce préfixe, en décimal pointé.';
      case ConversionKind.prefixAddresses:
        return "Combien d'adresses IPv4 contient un réseau de ce préfixe ? "
            "(adresse de réseau et adresse de diffusion comprises)";
      case ConversionKind.prefixHosts:
        return "Combien d'adresses peut-on attribuer à des machines dans un réseau de ce préfixe ? "
            "(sans l'adresse de réseau ni l'adresse de diffusion)";
      case ConversionKind.subnetCount:
        return 'Combien de sous-réseaux /$prefix2 peut-on découper dans un réseau /$prefix ?';
      case ConversionKind.ipToBin:
        return 'Écris cette adresse IPv4 en binaire, octet par octet (8 bits par octet, '
            'séparés par des points).';
      case ConversionKind.binToIp:
        return 'Écris cette adresse IPv4 en décimal pointé.';
      case ConversionKind.ipToHex:
        return 'Écris cette adresse IPv4 en hexadécimal, comme dans une capture réseau '
            '(deux chiffres par octet).';
      case ConversionKind.hexToIp:
        return "Ces 4 octets, relevés dans l'en-tête IP d'une capture, forment une adresse IPv4. "
            'Écris-la en décimal pointé.';
      case ConversionKind.ipToInt:
        return 'Écris cette adresse IPv4 sous forme d\'un seul entier décimal sur 32 bits.';
      case ConversionKind.intToIp:
        return 'Cet entier sur 32 bits est une adresse IPv4. Écris-la en décimal pointé.';
      case ConversionKind.macToDec:
        return 'Convertis chaque octet de cette adresse MAC en décimal (6 nombres).';
      case ConversionKind.decToMac:
        return 'Les 6 octets d\'une adresse MAC sont donnés en décimal. '
            'Écris l\'adresse en hexadécimal (format 00:1A:2B:3C:4D:5E).';
      case ConversionKind.macFirstOctetBin:
        return 'Écris le premier octet de cette adresse MAC en binaire (8 bits). '
            'La correction explique ce que révèlent ses deux bits de poids faible.';
    }
  }

  String _ctx() => context == null ? '' : '\nContexte : $context.';

  /// Valeur donnée à convertir.
  String get given {
    switch (kind) {
      case ConversionKind.decToBin:
      case ConversionKind.decToHex:
        return '$value';
      case ConversionKind.binToDec:
      case ConversionKind.binToHex:
        return group4(toBin(value, width));
      case ConversionKind.hexToDec:
      case ConversionKind.hexToBin:
        return '0x${toHex(value, hexDigits)}';
      case ConversionKind.cidrToMask:
      case ConversionKind.cidrToWildcard:
      case ConversionKind.prefixAddresses:
      case ConversionKind.prefixHosts:
        return '/$prefix';
      case ConversionKind.maskToCidr:
        return maskBytes(prefix).join('.');
      case ConversionKind.subnetCount:
        return 'Réseau /$prefix découpé en sous-réseaux /$prefix2';
      case ConversionKind.ipToBin:
      case ConversionKind.ipToHex:
      case ConversionKind.ipToInt:
        return bytes.join('.');
      case ConversionKind.binToIp:
        return bytes.map((b) => toBin(b, 8)).join('.');
      case ConversionKind.hexToIp:
        return bytes.map((b) => toHex(b, 2)).join(' ');
      case ConversionKind.intToIp:
        return formatThousands(ipv4ToInt(bytes));
      case ConversionKind.macToDec:
      case ConversionKind.macFirstOctetBin:
        return macString(bytes);
      case ConversionKind.decToMac:
        return bytes.join(', ');
    }
  }

  /// Réponse attendue, sous sa forme canonique.
  String get expected {
    switch (kind) {
      case ConversionKind.decToBin:
      case ConversionKind.hexToBin:
        return group4(toBin(value, width));
      case ConversionKind.decToHex:
      case ConversionKind.binToHex:
        return toHex(value, hexDigits);
      case ConversionKind.binToDec:
      case ConversionKind.hexToDec:
        return '$value';
      case ConversionKind.cidrToMask:
      case ConversionKind.cidrToWildcard:
        return (_target as List<int>).join('.');
      case ConversionKind.maskToCidr:
        return '/$prefix';
      case ConversionKind.prefixAddresses:
      case ConversionKind.prefixHosts:
      case ConversionKind.subnetCount:
      case ConversionKind.ipToInt:
        return formatThousands(_target as int);
      case ConversionKind.ipToBin:
        return bytes.map((b) => toBin(b, 8)).join('.');
      case ConversionKind.binToIp:
      case ConversionKind.hexToIp:
      case ConversionKind.intToIp:
        return bytes.join('.');
      case ConversionKind.ipToHex:
        return bytes.map((b) => toHex(b, 2)).join('.');
      case ConversionKind.macToDec:
        return bytes.join(' ');
      case ConversionKind.decToMac:
        return macString(bytes);
      case ConversionKind.macFirstOctetBin:
        return group4(toBin(bytes.first, 8));
    }
  }

  String get fieldLabel {
    switch (_answerType) {
      case _AnswerType.binary:
        return 'Ta réponse (binaire)';
      case _AnswerType.hex:
        return 'Ta réponse (hexadécimal)';
      case _AnswerType.decimal:
        return 'Ta réponse (décimal)';
      case _AnswerType.dotted:
        return 'Ta réponse (décimal pointé)';
      case _AnswerType.cidr:
        return 'Ta réponse (préfixe)';
      case _AnswerType.count:
        return 'Ta réponse (nombre)';
      case _AnswerType.ipBinary:
        return 'Ta réponse (4 octets en binaire)';
      case _AnswerType.ipHex:
        return 'Ta réponse (4 octets en hexadécimal)';
      case _AnswerType.macHex:
        return 'Ta réponse (adresse MAC)';
      case _AnswerType.macDecimal:
        return 'Ta réponse (6 nombres décimaux)';
    }
  }

  String get hint {
    switch (_answerType) {
      case _AnswerType.binary:
        return width == 16
            ? 'ex. 0000 0001 0000 0000 ou 0b100000000'
            : 'ex. 1010 0101 ou 0b10100101';
      case _AnswerType.hex:
        return width == 16 ? 'ex. 1F90 ou 0x1F90' : 'ex. 3F ou 0x3F';
      case _AnswerType.decimal:
        return 'ex. 173';
      case _AnswerType.dotted:
        return 'ex. 192.168.0.1';
      case _AnswerType.cidr:
        return 'ex. /24';
      case _AnswerType.count:
        return kind == ConversionKind.ipToInt
            ? 'ex. 167 772 161'
            : 'ex. 1 024 ou 2^10';
      case _AnswerType.ipBinary:
        return 'ex. 00001010.00000000.00000000.00000001';
      case _AnswerType.ipHex:
        return 'ex. 0A.00.00.01, 0A 00 00 01 ou 0x0A000001';
      case _AnswerType.macHex:
        return 'ex. 00:1A:2B:3C:4D:5E ou 001A.2B3C.4D5E';
      case _AnswerType.macDecimal:
        return 'ex. 0 26 43 60 77 94';
    }
  }
}

// ---------------------------------------------------------------------------
// Outils numériques (sans opérateurs bit à bit : valeurs jusqu'à 2^32 sûres aussi sur le web)
// ---------------------------------------------------------------------------

int pow2(int k) {
  var v = 1;
  for (var i = 0; i < k; i++) {
    v *= 2;
  }
  return v;
}

String toBin(int v, int width) => v.toRadixString(2).padLeft(width, '0');

String toHex(int v, int digits) =>
    v.toRadixString(16).toUpperCase().padLeft(digits, '0');

/// Regroupe des bits par 4 en partant de la droite : « 11001000 » → « 1100 1000 ».
String group4(String bits) {
  final b = StringBuffer();
  for (var i = 0; i < bits.length; i++) {
    if (i > 0 && (bits.length - i) % 4 == 0) b.write(' ');
    b.write(bits[i]);
  }
  return b.toString();
}

/// 4294967296 → « 4 294 967 296 ».
String formatThousands(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

/// Les 4 octets du masque d'un préfixe /0 à /32.
List<int> maskBytes(int prefix) => List<int>.generate(4, (i) {
      final k = (prefix - 8 * i).clamp(0, 8);
      return 256 - pow2(8 - k);
    });

int ipv4ToInt(List<int> b) => ((b[0] * 256 + b[1]) * 256 + b[2]) * 256 + b[3];

String macString(List<int> b) => b.map((x) => toHex(x, 2)).join(':');

/// Poids des bits à 1 d'un octet : 200 → « 128 + 64 + 8 ».
String _weightsOf(int v, [int width = 8]) {
  final parts = <String>[];
  for (var i = width - 1; i >= 0; i--) {
    final w = pow2(i);
    if ((v ~/ w) % 2 == 1) parts.add('$w');
  }
  return parts.isEmpty ? '0' : parts.join(' + ');
}

String _hexDigitName(int d) => toHex(d, 1);

// ---------------------------------------------------------------------------
// Génération
// ---------------------------------------------------------------------------

class _Notable {
  const _Notable(this.value, this.context);
  final int value;
  final String context;
}

const List<_Notable> _notable16 = [
  _Notable(22, 'port TCP de SSH'),
  _Notable(25, 'port TCP de SMTP'),
  _Notable(53, 'port de DNS'),
  _Notable(80, 'port TCP de HTTP'),
  _Notable(443, 'port TCP de HTTPS'),
  _Notable(993, 'port TCP de IMAPS'),
  _Notable(1194, "port d'OpenVPN"),
  _Notable(3306, 'port TCP de MySQL'),
  _Notable(3389, 'port TCP de RDP (bureau à distance Windows)'),
  _Notable(5060, 'port de SIP (téléphonie sur IP)'),
  _Notable(8080, 'port HTTP alternatif'),
  _Notable(51820, 'port UDP par défaut de WireGuard'),
  _Notable(0x0800, 'EtherType de IPv4 dans une trame Ethernet'),
  _Notable(0x0806, 'EtherType de ARP'),
  _Notable(0x86DD, 'EtherType de IPv6'),
  _Notable(0x8100, "EtherType d'une étiquette VLAN 802.1Q"),
  _Notable(0x88CC, 'EtherType de LLDP'),
];

const List<ConversionKind> _numberKinds = [
  ConversionKind.decToBin,
  ConversionKind.decToHex,
  ConversionKind.binToDec,
  ConversionKind.hexToDec,
  ConversionKind.binToHex,
  ConversionKind.hexToBin,
];

/// Génère un exercice. [topic] restreint le thème (ignoré s'il n'existe pas au niveau choisi).
ConversionExercise generateConversion(
  TrainingRandom r, {
  ConversionLevel level = ConversionLevel.debutant,
  ConversionTopic? topic,
}) {
  final topics = conversionTopicsFor(level);
  final t = (topic != null && topics.contains(topic)) ? topic : r.pick(topics);
  final adv = level == ConversionLevel.avance;
  switch (t) {
    case ConversionTopic.octet:
      return ConversionExercise(
          topic: t, kind: r.pick(_numberKinds), value: r.range(1, 255));
    case ConversionTopic.mot16:
      if (r.nextInt(10) < 4) {
        final n = r.pick(_notable16);
        return ConversionExercise(
            topic: t,
            kind: r.pick(_numberKinds),
            width: 16,
            value: n.value,
            context: n.context);
      }
      return ConversionExercise(
          topic: t,
          kind: r.pick(_numberKinds),
          width: 16,
          value: r.range(256, 65535));
    case ConversionTopic.masque:
      final kinds = adv
          ? const [
              ConversionKind.cidrToMask,
              ConversionKind.maskToCidr,
              ConversionKind.cidrToWildcard
            ]
          : const [ConversionKind.cidrToMask, ConversionKind.maskToCidr];
      return ConversionExercise(
          topic: t,
          kind: r.pick(kinds),
          prefix: adv ? r.range(0, 32) : r.range(8, 30));
    case ConversionTopic.prefixe:
      final kinds = adv
          ? const [
              ConversionKind.prefixAddresses,
              ConversionKind.prefixHosts,
              ConversionKind.subnetCount
            ]
          : const [ConversionKind.prefixAddresses, ConversionKind.prefixHosts];
      final kind = r.pick(kinds);
      switch (kind) {
        case ConversionKind.prefixAddresses:
          return ConversionExercise(
              topic: t,
              kind: kind,
              prefix: adv ? r.range(0, 32) : r.range(16, 30));
        case ConversionKind.prefixHosts:
          return ConversionExercise(
              topic: t,
              kind: kind,
              prefix: adv ? r.range(8, 30) : r.range(20, 30));
        default:
          final n = r.range(8, 28);
          final m = r.range(n + 1, (n + 8).clamp(n + 1, 30));
          return ConversionExercise(
              topic: t, kind: kind, prefix: n, prefix2: m);
      }
    case ConversionTopic.ipv4:
      return ConversionExercise(
          topic: t,
          kind: r.pick(const [
            ConversionKind.ipToBin,
            ConversionKind.binToIp,
            ConversionKind.ipToHex,
            ConversionKind.hexToIp,
            ConversionKind.ipToInt,
            ConversionKind.intToIp,
          ]),
          bytes: _randomIpv4(r));
    case ConversionTopic.mac:
      return ConversionExercise(
          topic: t,
          kind: r.pick(const [
            ConversionKind.macToDec,
            ConversionKind.decToMac,
            ConversionKind.macFirstOctetBin,
          ]),
          bytes: _randomMac(r));
  }
}

List<int> _randomIpv4(TrainingRandom r) {
  final last = r.range(1, 254);
  switch (r.nextInt(4)) {
    case 0:
      return [10, r.range(0, 255), r.range(0, 255), last];
    case 1:
      return [172, r.range(16, 31), r.range(0, 255), last];
    case 2:
      return [192, 168, r.range(0, 255), last];
    default:
      var first = r.range(1, 223);
      if (first == 127 || first == 10) first = 93;
      return [first, r.range(0, 255), r.range(0, 255), last];
  }
}

List<int> _randomMac(TrainingRandom r) {
  int b() => r.range(0, 255);
  switch (r.nextInt(5)) {
    case 0: // multicast IPv4 (RFC 1112) : 01:00:5E puis 23 bits
      return [0x01, 0x00, 0x5E, r.range(0, 127), b(), b()];
    case 1: // multicast IPv6 (RFC 2464) : 33:33 puis 32 bits
      return [0x33, 0x33, b(), b(), b(), b()];
    case 2: // administrée localement, unicast (adresse aléatoire de téléphone, VM…)
      return [r.range(0, 63) * 4 + 2, b(), b(), b(), b(), b()];
    default: // universelle (OUI du constructeur), unicast
      return [r.range(0, 63) * 4, b(), b(), b(), b(), b()];
  }
}

// ---------------------------------------------------------------------------
// Lecture des réponses (variantes acceptées)
// ---------------------------------------------------------------------------

final RegExp _spaces = RegExp(r'[\s_  ]+');

int? _parseBinary(String s, int width) {
  var t = s.toLowerCase().replaceAll(_spaces, '');
  if (t.startsWith('0b')) t = t.substring(2);
  if (t.endsWith('b')) t = t.substring(0, t.length - 1);
  if (t.isEmpty || t.length > width || !RegExp(r'^[01]+$').hasMatch(t)) {
    return null;
  }
  return int.parse(t, radix: 2);
}

/// Nombre de bits réellement écrits, sans préfixe 0b, suffixe b ni espaces.
int _bitCount(String s) {
  var t = s.toLowerCase().replaceAll(_spaces, '');
  if (t.startsWith('0b')) t = t.substring(2);
  if (t.endsWith('b')) t = t.substring(0, t.length - 1);
  return t.length;
}

int? _parseHex(String s, int digits) {
  var t = s.toLowerCase().replaceAll(_spaces, '');
  if (t.startsWith('0x')) {
    t = t.substring(2);
  } else if (t.startsWith(r'$') || t.startsWith('#')) {
    t = t.substring(1);
  } else if (t.endsWith('h')) {
    t = t.substring(0, t.length - 1);
  }
  if (t.isEmpty || t.length > digits || !RegExp(r'^[0-9a-f]+$').hasMatch(t)) {
    return null;
  }
  return int.parse(t, radix: 16);
}

int? _parseDecimal(String s) {
  final t = s.replaceAll(_spaces, '');
  if (!RegExp(r'^\d{1,12}$').hasMatch(t)) return null;
  return int.parse(t);
}

/// Nombre entier, avec séparateurs de milliers en espaces, ou puissance de 2 (« 2^10 »).
int? _parseCount(String s) {
  final t = s.replaceAll(_spaces, '');
  final p = RegExp(r'^2(?:\^|\*\*)(\d{1,2})$').firstMatch(t);
  if (p != null) {
    final k = int.parse(p.group(1)!);
    return k <= 40 ? pow2(k) : null;
  }
  return _parseDecimal(t);
}

int? _parseCidr(String s) {
  var t = s.replaceAll(_spaces, '');
  if (t.startsWith('/')) t = t.substring(1);
  if (!RegExp(r'^\d{1,2}$').hasMatch(t)) return null;
  final v = int.parse(t);
  return v <= 32 ? v : null;
}

List<int>? _parseDotted(String s) {
  final parts = s.trim().split(RegExp(r'\s*\.\s*'));
  if (parts.length != 4) return null;
  final out = <int>[];
  for (final p in parts) {
    if (!RegExp(r'^\d{1,3}$').hasMatch(p)) return null;
    final v = int.parse(p);
    if (v > 255) return null;
    out.add(v);
  }
  return out;
}

/// Découpe une adresse en groupes : par les points s'ils existent (espaces internes ignorés,
/// ex. « 1100 0000.1010 1000… »), sinon par les espaces et autres séparateurs.
List<String> _addressGroups(String t) {
  if (t.contains('.')) {
    return t.split('.').map((g) => g.replaceAll(_spaces, '')).toList();
  }
  return t.split(RegExp(r'[\s:_-]+')).where((g) => g.isNotEmpty).toList();
}

List<int>? _parseIpBinary(String s) {
  var t = s.trim().toLowerCase();
  if (t.startsWith('0b')) t = t.substring(2);
  var groups = _addressGroups(t);
  // 8 demi-octets de 4 bits (« 1100 0000 1010 1000 … ») : on les recolle par paires.
  if (groups.length == 8 && groups.every((g) => g.length == 4)) {
    groups = [for (var i = 0; i < 8; i += 2) groups[i] + groups[i + 1]];
  }
  if (groups.length == 1) {
    final g = groups.first;
    if (g.length != 32 || !RegExp(r'^[01]+$').hasMatch(g)) return null;
    return List<int>.generate(
        4, (i) => int.parse(g.substring(8 * i, 8 * i + 8), radix: 2));
  }
  if (groups.length != 4) return null;
  final out = <int>[];
  for (final g in groups) {
    if (g.isEmpty || g.length > 8 || !RegExp(r'^[01]+$').hasMatch(g)) {
      return null;
    }
    out.add(int.parse(g, radix: 2));
  }
  return out;
}

List<int>? _parseIpHex(String s) {
  var t = s.trim().toLowerCase();
  if (t.startsWith('0x')) t = t.substring(2);
  var groups = _addressGroups(t);
  // Deux mots de 16 bits (« 0A00 0001 ») : même valeur que 8 chiffres d'affilée.
  if (groups.length == 2 && groups.every((g) => g.length == 4)) {
    groups = [groups.join()];
  }
  if (groups.length == 1) {
    final g = groups.first;
    if (g.length != 8 || !RegExp(r'^[0-9a-f]+$').hasMatch(g)) return null;
    return List<int>.generate(
        4, (i) => int.parse(g.substring(2 * i, 2 * i + 2), radix: 16));
  }
  if (groups.length != 4) return null;
  final out = <int>[];
  for (var g in groups) {
    if (g.startsWith('0x')) g = g.substring(2);
    if (g.isEmpty || g.length > 2 || !RegExp(r'^[0-9a-f]+$').hasMatch(g)) {
      return null;
    }
    out.add(int.parse(g, radix: 16));
  }
  return out;
}

/// Formats acceptés : 00:1A:2B:3C:4D:5E, 00-1A-…, 00 1A …, 001A.2B3C.4D5E (Cisco), 001A2B3C4D5E.
List<int>? _parseMac(String s) {
  final t = s.trim().toLowerCase();
  final groups =
      t.split(RegExp(r'[\s.:-]+')).where((g) => g.isNotEmpty).toList();
  if (groups.any((g) => !RegExp(r'^[0-9a-f]+$').hasMatch(g))) return null;
  List<int> split2(String g) => List<int>.generate(g.length ~/ 2,
      (i) => int.parse(g.substring(2 * i, 2 * i + 2), radix: 16));
  if (groups.length == 6 && groups.every((g) => g.length <= 2)) {
    return groups.map((g) => int.parse(g, radix: 16)).toList();
  }
  if (groups.length == 3 && groups.every((g) => g.length == 4)) {
    return groups.expand(split2).toList();
  }
  if (groups.length == 1 && groups.first.length == 12) {
    return split2(groups.first);
  }
  return null;
}

List<int>? _parseMacDecimal(String s) {
  final groups = s
      .trim()
      .split(RegExp(r'[\s.,;:/-]+'))
      .where((g) => g.isNotEmpty)
      .toList();
  if (groups.length != 6) return null;
  final out = <int>[];
  for (final g in groups) {
    if (!RegExp(r'^\d{1,3}$').hasMatch(g)) return null;
    final v = int.parse(g);
    if (v > 255) return null;
    out.add(v);
  }
  return out;
}

Object? _parseAnswer(ConversionExercise ex, String answer) {
  switch (ex._answerType) {
    case _AnswerType.binary:
      return _parseBinary(answer, ex.width);
    case _AnswerType.hex:
      return _parseHex(answer, ex.hexDigits);
    case _AnswerType.decimal:
      return _parseDecimal(answer);
    case _AnswerType.dotted:
      return _parseDotted(answer);
    case _AnswerType.cidr:
      return _parseCidr(answer);
    case _AnswerType.count:
      return _parseCount(answer);
    case _AnswerType.ipBinary:
      return _parseIpBinary(answer);
    case _AnswerType.ipHex:
      return _parseIpHex(answer);
    case _AnswerType.macHex:
      return _parseMac(answer);
    case _AnswerType.macDecimal:
      return _parseMacDecimal(answer);
  }
}

bool _same(Object? a, Object b) {
  if (a is int && b is int) return a == b;
  if (a is List<int> && b is List<int>) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  return false;
}

String _formatHelp(ConversionExercise ex) {
  switch (ex._answerType) {
    case _AnswerType.binary:
      return 'uniquement des 0 et des 1, au plus ${ex.width} bits (préfixe 0b et espaces acceptés)';
    case _AnswerType.hex:
      return 'chiffres 0-9 et lettres A-F, au plus ${ex.hexDigits} chiffres (préfixe 0x accepté)';
    case _AnswerType.decimal:
      return 'un nombre entier en base 10';
    case _AnswerType.dotted:
      return '4 nombres de 0 à 255 séparés par des points';
    case _AnswerType.cidr:
      return 'un préfixe de /0 à /32';
    case _AnswerType.count:
      return 'un nombre entier (espaces acceptés) ou une puissance de 2 comme 2^10';
    case _AnswerType.ipBinary:
      return '4 groupes de 8 bits séparés par des points ou des espaces, ou 32 bits d\'affilée';
    case _AnswerType.ipHex:
      return '4 octets de deux chiffres hexadécimaux, ou 8 chiffres d\'affilée';
    case _AnswerType.macHex:
      return '6 octets hexadécimaux séparés par « : », « - » ou des espaces, ou 12 chiffres';
    case _AnswerType.macDecimal:
      return '6 nombres de 0 à 255 séparés par des espaces, des points ou des virgules';
  }
}

// ---------------------------------------------------------------------------
// Vérification et correction
// ---------------------------------------------------------------------------

/// Vérifie la réponse et renvoie la correction détaillée (méthode pas à pas).
TrainingCheck checkConversion(ConversionExercise ex, String answer) {
  final raw = answer.trim();
  final parsed = raw.isEmpty ? null : _parseAnswer(ex, normalizeAnswer(raw));
  final ok = parsed != null && _same(parsed, ex._target);
  final head = StringBuffer();
  if (raw.isEmpty) {
    head.writeln('Aucune réponse saisie.');
  } else if (parsed == null) {
    head.writeln('Ta réponse : $raw');
    head.writeln('Format non reconnu : ${_formatHelp(ex)}.');
  } else {
    head.writeln('Ta réponse : $raw');
  }
  head.writeln('Réponse attendue : ${ex.expected}');
  if (ok &&
      ex._answerType == _AnswerType.binary &&
      _bitCount(normalizeAnswer(raw)) < ex.width) {
    head.writeln(
        'Juste. Sur ${ex.width} bits, on garde les zéros de tête : ${ex.expected}.');
  }
  return TrainingCheck(
      ok, '${head.toString().trimRight()}\n\n${explainConversion(ex)}');
}

/// Explication pédagogique de la méthode, pas à pas.
String explainConversion(ConversionExercise ex) {
  final v = ex.value;
  final w = ex.width;
  final out = StringBuffer();
  switch (ex.kind) {
    case ConversionKind.decToBin:
      if (w == 8) {
        out.writeln(
            'Méthode 1 : puissances de 2. On parcourt les poids de 128 à 1 ; '
            'si le reste est supérieur ou égal au poids, le bit vaut 1 et on le retire.');
        out.writeln(_powersSteps(v));
        out.writeln('Résultat : ${group4(toBin(v, 8))}');
        out.writeln();
        out.writeln(
            'Méthode 2 : divisions successives par 2, on lit les restes de bas en haut.');
        out.writeln(_divisionSteps(v, 2));
      } else {
        out.writeln('Méthode rapide sur 16 bits : passe par l\'hexadécimal '
            '(divisions successives par 16), puis écris chaque chiffre sur 4 bits.');
        out.writeln(_divisionSteps(v, 16));
        out.writeln('Sur 4 chiffres : 0x${toHex(v, 4)}');
        out.writeln(_hexToBinSteps(v, 4));
        out.writeln('Résultat : ${group4(toBin(v, 16))}');
        out.writeln(
            '(Les divisions successives par 2 donnent le même résultat, '
            'mais en 16 étapes.)');
      }
      out.write(_check(v, w));
      break;
    case ConversionKind.binToDec:
      out.writeln(
          'Méthode : chaque bit à 1 vaut une puissance de 2 selon sa position '
          '(le bit de droite vaut 1, puis 2, 4, 8…). On additionne les poids des bits à 1.');
      out.writeln('Bits : ${group4(toBin(v, w))}');
      out.writeln(_bitWeightsLine(v, w));
      out.write('Résultat : $v');
      break;
    case ConversionKind.decToHex:
      out.writeln(
          'Méthode : divisions successives par 16, on lit les restes de bas en haut '
          '(10 = A, 11 = B, 12 = C, 13 = D, 14 = E, 15 = F).');
      out.writeln(_divisionSteps(v, 16));
      out.writeln('Sur ${ex.hexDigits} chiffres : ${toHex(v, ex.hexDigits)}');
      out.writeln();
      out.writeln('Autre chemin : en binaire, puis regroupement par 4 bits.');
      out.write(_binToHexSteps(v, w));
      break;
    case ConversionKind.hexToDec:
      out.writeln(
          'Méthode : chaque chiffre est multiplié par une puissance de 16 selon sa '
          'position (de droite à gauche : '
          '${[
        for (var i = 0; i < ex.hexDigits; i++) pow2(4 * i)
      ].join(', ')}).');
      out.write(_hexToDecSteps(v, ex.hexDigits));
      break;
    case ConversionKind.binToHex:
      out.writeln('Méthode : regroupe les bits par 4 en partant de la droite ; '
          'chaque groupe de 4 bits donne exactement un chiffre hexadécimal.');
      out.write(_binToHexSteps(v, w));
      break;
    case ConversionKind.hexToBin:
      out.writeln(
          'Méthode : chaque chiffre hexadécimal s\'écrit sur exactement 4 bits '
          '(poids 8, 4, 2, 1).');
      out.writeln(_hexToBinSteps(v, ex.hexDigits));
      out.write('Résultat : ${group4(toBin(v, w))}');
      break;
    case ConversionKind.cidrToMask:
      out.write(_cidrToMaskSteps(ex.prefix));
      break;
    case ConversionKind.maskToCidr:
      out.write(_maskToCidrSteps(ex.prefix));
      break;
    case ConversionKind.cidrToWildcard:
      final m = maskBytes(ex.prefix);
      out.writeln(_cidrToMaskSteps(ex.prefix));
      out.writeln();
      out.writeln('Masque générique : on inverse chaque bit du masque, '
          'soit 255 − chaque octet.');
      for (var i = 0; i < 4; i++) {
        out.writeln('255 − ${m[i]} = ${255 - m[i]}');
      }
      out.writeln('Masque générique : ${m.map((b) => 255 - b).join('.')}');
      out.write(
          'Les bits à 0 du masque générique sont ceux qui doivent correspondre, '
          'les bits à 1 sont ignorés.');
      break;
    case ConversionKind.prefixAddresses:
      final h = 32 - ex.prefix;
      out.writeln(
          'Une adresse IPv4 fait 32 bits. Le préfixe /${ex.prefix} fixe '
          '${ex.prefix} bits pour le réseau ; il reste 32 − ${ex.prefix} = $h bits pour les hôtes.');
      out.writeln(
          'Chaque bit d\'hôte double le nombre de combinaisons : 2^$h = '
          '${formatThousands(pow2(h))} adresses.');
      out.write(_prefixLadder(ex.prefix));
      break;
    case ConversionKind.prefixHosts:
      final h = 32 - ex.prefix;
      final total = pow2(h);
      out.writeln('32 − ${ex.prefix} = $h bits d\'hôte, donc 2^$h = '
          '${formatThousands(total)} adresses au total.');
      out.writeln(
          'On retire l\'adresse de réseau (bits d\'hôte tous à 0) et l\'adresse de '
          'diffusion (bits d\'hôte tous à 1) : ${formatThousands(total)} − 2 = '
          '${formatThousands(total - 2)} adresses attribuables.');
      out.write(
          'Cas particuliers : un /31 sert aux liaisons point à point et ses 2 adresses '
          'sont utilisables (RFC 3021) ; un /32 désigne une seule machine.');
      break;
    case ConversionKind.subnetCount:
      final k = ex.prefix2 - ex.prefix;
      final size = pow2(32 - ex.prefix2);
      out.writeln(
          'Passer de /${ex.prefix} à /${ex.prefix2} emprunte ${ex.prefix2} − '
          '${ex.prefix} = $k bits à la partie hôte.');
      out.writeln(
          'Ces $k bits donnent 2^$k = ${formatThousands(pow2(k))} sous-réseaux.');
      out.write(
          'Vérification : un /${ex.prefix} contient ${formatThousands(pow2(32 - ex.prefix))} '
          'adresses, un /${ex.prefix2} en contient ${formatThousands(size)} ; '
          '${formatThousands(pow2(32 - ex.prefix))} ÷ ${formatThousands(size)} = '
          '${formatThousands(pow2(k))}.');
      break;
    case ConversionKind.ipToBin:
      out.writeln('Méthode : chaque octet se convertit séparément sur 8 bits '
          '(poids 128, 64, 32, 16, 8, 4, 2, 1).');
      for (final b in ex.bytes) {
        out.writeln(_byteToBinLine(b));
      }
      out.write('Résultat : ${ex.expected}');
      break;
    case ConversionKind.binToIp:
      out.writeln('Méthode : chaque groupe de 8 bits est un octet ; '
          'on additionne les poids des bits à 1.');
      for (final b in ex.bytes) {
        final ws = _weightsOf(b);
        out.writeln('${toBin(b, 8)} → ${ws == '$b' ? '$b' : '$ws = $b'}');
      }
      out.write('Résultat : ${ex.expected}');
      break;
    case ConversionKind.ipToHex:
      out.writeln('Méthode : chaque octet donne deux chiffres hexadécimaux '
          '(quotient et reste de la division par 16).');
      for (final b in ex.bytes) {
        out.writeln(_byteToHexLine(b));
      }
      out.writeln('Résultat : ${ex.expected}');
      out.write(
          'Dans une capture (Wireshark, tcpdump -X), ces octets apparaissent tels '
          'quels, dans l\'ordre, dans les champs adresse source ou destination de l\'en-tête IP.');
      break;
    case ConversionKind.hexToIp:
      out.writeln(
          'Méthode : chaque paire de chiffres hexadécimaux est un octet : '
          'premier chiffre × 16 + second chiffre.');
      for (final b in ex.bytes) {
        out.writeln(_hexByteToDecLine(b));
      }
      out.write('Résultat : ${ex.expected}');
      break;
    case ConversionKind.ipToInt:
      final b = ex.bytes;
      out.writeln(
          'Méthode : l\'adresse est un nombre en base 256. Poids des octets : '
          '256^3 = 16 777 216, 256^2 = 65 536, 256 et 1.');
      out.writeln('${b[0]} × 16 777 216 = ${formatThousands(b[0] * 16777216)}');
      out.writeln('${b[1]} × 65 536 = ${formatThousands(b[1] * 65536)}');
      out.writeln('${b[2]} × 256 = ${formatThousands(b[2] * 256)}');
      out.writeln('${b[3]} × 1 = ${b[3]}');
      out.write('Somme : ${formatThousands(ipv4ToInt(b))}');
      break;
    case ConversionKind.intToIp:
      final n = ipv4ToInt(ex.bytes);
      final r1 = n % 16777216;
      final r2 = r1 % 65536;
      out.writeln(
          'Méthode : divisions successives par les poids 16 777 216 (256^3), '
          '65 536 (256^2) et 256 ; chaque quotient est un octet.');
      out.writeln(
          '${formatThousands(n)} ÷ 16 777 216 = ${ex.bytes[0]}, reste ${formatThousands(r1)}');
      out.writeln(
          '${formatThousands(r1)} ÷ 65 536 = ${ex.bytes[1]}, reste ${formatThousands(r2)}');
      out.writeln(
          '${formatThousands(r2)} ÷ 256 = ${ex.bytes[2]}, reste ${ex.bytes[3]}');
      out.write('Résultat : ${ex.expected}');
      break;
    case ConversionKind.macToDec:
      out.writeln(
          'Méthode : une adresse MAC compte 6 octets écrits en hexadécimal ; '
          'chaque octet vaut premier chiffre × 16 + second chiffre.');
      for (final b in ex.bytes) {
        out.writeln(_hexByteToDecLine(b));
      }
      out.write('Résultat : ${ex.expected}');
      break;
    case ConversionKind.decToMac:
      out.writeln(
          'Méthode : chaque octet se divise par 16 ; le quotient donne le premier '
          'chiffre hexadécimal, le reste le second.');
      for (final b in ex.bytes) {
        out.writeln(_byteToHexLine(b));
      }
      out.write(
          'Résultat : ${ex.expected} (on écrit aussi ${ex.bytes.map((b) => toHex(b, 2)).join('-')} '
          'sous Windows, ou ${_ciscoMac(ex.bytes)} sur un équipement Cisco).');
      break;
    case ConversionKind.macFirstOctetBin:
      final b = ex.bytes.first;
      out.writeln(
          'Premier octet : ${toHex(b, 2)}. Chaque chiffre hexadécimal donne 4 bits.');
      out.writeln(_hexToBinSteps(b, 2));
      out.writeln('Résultat : ${group4(toBin(b, 8))}');
      out.writeln();
      out.write(_macBitsMeaning(ex.bytes));
      break;
  }
  return out.toString().trimRight();
}

String _check(int v, int width) =>
    'Vérification : ${_weightsOf(v, width)} = $v';

String _powersSteps(int v) {
  final lines = <String>[];
  var rest = v;
  for (var i = 7; i >= 0; i--) {
    final w = pow2(i);
    if (rest >= w) {
      lines.add('$w : $rest ≥ $w → 1, reste ${rest - w}');
      rest -= w;
    } else {
      lines.add('$w : $rest < $w → 0');
    }
  }
  return lines.join('\n');
}

String _divisionSteps(int v, int base) {
  final lines = <String>[];
  final digits = <int>[];
  var q = v;
  do {
    final quo = q ~/ base;
    final rem = q % base;
    final name = base == 16 && rem > 9 ? ' (${_hexDigitName(rem)})' : '';
    lines.add('$q ÷ $base = $quo, reste $rem$name');
    digits.add(rem);
    q = quo;
  } while (q > 0);
  final read = digits.reversed.map(_hexDigitName).join();
  lines.add('Restes lus de bas en haut : $read');
  return lines.join('\n');
}

String _bitWeightsLine(int v, int width) {
  final parts = <String>[];
  for (var i = width - 1; i >= 0; i--) {
    final w = pow2(i);
    if ((v ~/ w) % 2 == 1) parts.add('2^$i = $w');
  }
  if (parts.isEmpty) return 'Aucun bit à 1 : la valeur est 0.';
  return 'Bits à 1 : ${parts.join(', ')}\nSomme : ${_weightsOf(v, width)} = $v';
}

String _nibbleSum(int d) => _weightsOf(d, 4);

String _hexToBinSteps(int v, int digits) {
  final hex = toHex(v, digits);
  final lines = <String>[];
  for (final ch in hex.split('')) {
    final d = int.parse(ch, radix: 16);
    final parts = <String>[ch];
    if (d > 9) parts.add('$d');
    final sum = _nibbleSum(d);
    if (sum.contains('+')) parts.add(sum);
    lines.add('${parts.join(' = ')} → ${toBin(d, 4)}');
  }
  return lines.join('\n');
}

String _binToHexSteps(int v, int width) {
  final bits = toBin(v, width);
  final lines = <String>['Bits groupés par 4 : ${group4(bits)}'];
  final out = StringBuffer();
  for (var i = 0; i < bits.length; i += 4) {
    final g = bits.substring(i, i + 4);
    final d = int.parse(g, radix: 2);
    final parts = <String>[g];
    final sum = _nibbleSum(d);
    if (sum.contains('+')) parts.add(sum);
    parts.add('$d');
    lines.add('${parts.join(' = ')} → ${_hexDigitName(d)}');
    out.write(_hexDigitName(d));
  }
  lines.add('Résultat : $out');
  return lines.join('\n');
}

String _hexToDecSteps(int v, int digits) {
  final hex = toHex(v, digits);
  final letters = hex
      .split('')
      .toSet()
      .where((c) => RegExp('[A-F]').hasMatch(c))
      .toList()
    ..sort();
  final lines = <String>[];
  if (letters.isNotEmpty) {
    lines.add(
        'Lettres : ${letters.map((c) => '$c = ${int.parse(c, radix: 16)}').join(', ')}');
  }
  final terms = <String>[];
  final values = <String>[];
  for (var i = 0; i < digits; i++) {
    final d = int.parse(hex[i], radix: 16);
    final w = pow2(4 * (digits - 1 - i));
    terms.add('$d × $w');
    values.add('${d * w}');
  }
  lines.add('0x$hex = ${terms.join(' + ')}');
  lines.add('= ${values.join(' + ')}');
  lines.add('= $v');
  return lines.join('\n');
}

String _byteToBinLine(int b) {
  final ws = _weightsOf(b);
  final lhs = (b == 0 || ws == '$b') ? '$b' : '$b = $ws';
  return '$lhs → ${toBin(b, 8)}';
}

String _byteToHexLine(int b) =>
    '$b = ${b ~/ 16} × 16 + ${b % 16} → ${toHex(b, 2)}';

String _hexByteToDecLine(int b) {
  final hi = b ~/ 16;
  final lo = b % 16;
  return '${toHex(b, 2)} = $hi × 16 + $lo = $b';
}

String _ciscoMac(List<int> b) {
  final h = b.map((x) => toHex(x, 2).toLowerCase()).join();
  return '${h.substring(0, 4)}.${h.substring(4, 8)}.${h.substring(8, 12)}';
}

String _maskBinary(int prefix) {
  final bits = '1' * prefix + '0' * (32 - prefix);
  return [for (var i = 0; i < 4; i++) bits.substring(8 * i, 8 * i + 8)]
      .join('.');
}

String _cidrToMaskSteps(int prefix) {
  final m = maskBytes(prefix);
  final lines = <String>[
    '/$prefix = $prefix bits à 1, puis ${32 - prefix} bits à 0.',
    'En binaire : ${_maskBinary(prefix)}',
    'Octet par octet :',
  ];
  for (var i = 0; i < 4; i++) {
    final k = (prefix - 8 * i).clamp(0, 8);
    if (k == 8) {
      lines.add('8 bits à 1 → 255');
    } else if (k == 0) {
      lines.add('0 bit à 1 → 0');
    } else {
      final ws = _weightsOf(m[i]);
      lines.add(
          '$k bit${k > 1 ? 's' : ''} à 1 → ${ws == '${m[i]}' ? ws : '$ws = ${m[i]}'}');
    }
  }
  lines.add('Masque : ${m.join('.')}');
  final partial = prefix % 8;
  if (partial != 0) {
    lines.add('Astuce : un octet avec k bits à 1 vaut 256 − 2^(8 − k), '
        'ici 256 − 2^${8 - partial} = 256 − ${pow2(8 - partial)} = ${256 - pow2(8 - partial)}.');
  }
  return lines.join('\n');
}

String _maskToCidrSteps(int prefix) {
  final m = maskBytes(prefix);
  final lines = <String>[
    'Méthode : on compte les bits à 1 de chaque octet du masque (ils sont toujours '
        'contigus, à gauche).',
  ];
  final counts = <int>[];
  for (var i = 0; i < 4; i++) {
    final k = (prefix - 8 * i).clamp(0, 8);
    counts.add(k);
    lines.add(
        '${m[i]} = ${group4(toBin(m[i], 8))} → $k bit${k > 1 ? 's' : ''} à 1');
  }
  lines.add('Total : ${counts.join(' + ')} = $prefix, donc /$prefix');
  lines
      .add('À retenir : 128, 192, 224, 240, 248, 252, 254, 255 correspondent à '
          '1, 2, 3, 4, 5, 6, 7, 8 bits à 1.');
  return lines.join('\n');
}

String _prefixLadder(int prefix) {
  final lines = <String>[
    'Repères (chaque bit de préfixe en moins double le total) :'
  ];
  for (final p in [prefix - 1, prefix, prefix + 1]) {
    if (p < 0 || p > 32) continue;
    lines.add('/$p → ${formatThousands(pow2(32 - p))} adresses');
  }
  return lines.join('\n');
}

String _macBitsMeaning(List<int> mac) {
  final b = mac.first;
  final ig = b % 2;
  final ul = (b ~/ 2) % 2;
  final lines = <String>[
    'Les deux bits de poids faible du premier octet (les deux plus à droite) ont un sens précis (IEEE 802) :',
    'Bit I/G (tout à droite) = $ig → ${ig == 1 ? 'adresse de groupe (multicast ou diffusion)' : 'adresse individuelle (unicast)'}',
    'Bit U/L (juste à sa gauche) = $ul → ${ul == 1 ? 'adresse administrée localement (attribuée par logiciel : MAC aléatoire d\'un téléphone, machine virtuelle…)' : 'adresse universelle (les 3 premiers octets sont l\'OUI du constructeur)'}',
  ];
  if (mac[0] == 0x01 && mac[1] == 0x00 && mac[2] == 0x5E) {
    lines
        .add('01:00:5E est le préfixe des adresses multicast IPv4 (RFC 1112).');
  } else if (mac[0] == 0x33 && mac[1] == 0x33) {
    lines.add('33:33 est le préfixe des adresses multicast IPv6 (RFC 2464).');
  }
  return lines.join('\n');
}

/// Aide-mémoire affiché sous l'exercice.
String conversionCheatSheet() {
  final b = StringBuffer();
  b.writeln('Puissances de 2');
  b.writeln([for (var i = 0; i <= 7; i++) '2^$i=${pow2(i)}'].join('  '));
  b.writeln('2^8=256  2^10=1024  2^16=65536  2^24=16777216  2^32=4294967296');
  b.writeln();
  b.writeln('Chiffres hexadécimaux (4 bits chacun)');
  for (var row = 0; row < 4; row++) {
    b.writeln([
      for (var col = 0; col < 4; col++)
        '${_hexDigitName(row + 4 * col)} = ${(row + 4 * col).toString().padLeft(2)} = ${toBin(row + 4 * col, 4)}'
    ].join('   '));
  }
  b.writeln();
  b.writeln('Octets de masque (bits à 1 → valeur)');
  b.write([for (var k = 1; k <= 8; k++) '$k→${256 - pow2(8 - k)}'].join('  '));
  return b.toString();
}

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

class ConversionTrainer extends StatefulWidget {
  const ConversionTrainer({super.key, this.seed});

  /// Graine facultative (tests) ; sans graine, chaque exercice est différent.
  final int? seed;

  @override
  State<ConversionTrainer> createState() => _ConversionTrainerState();
}

class _ConversionTrainerState extends State<ConversionTrainer> {
  late final TrainingRandom _rng = TrainingRandom(widget.seed);
  final TextEditingController _ctrl = TextEditingController();
  ConversionLevel _level = ConversionLevel.debutant;
  ConversionTopic? _topic;
  late ConversionExercise _ex = generateConversion(_rng, level: _level);
  TrainingCheck? _result;
  bool _counted = false;
  int _score = 0;
  int _attempts = 0;
  bool _showMemo = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    setState(() {
      var n = generateConversion(_rng, level: _level, topic: _topic);
      for (var i = 0;
          i < 8 && n.kind == _ex.kind && n.given == _ex.given;
          i++) {
        n = generateConversion(_rng, level: _level, topic: _topic);
      }
      _ex = n;
      _result = null;
      _counted = false;
      _ctrl.clear();
    });
  }

  void _check() {
    if (_ctrl.text.trim().isEmpty || (_result?.correct ?? false)) return;
    final res = checkConversion(_ex, _ctrl.text);
    setState(() {
      _result = res;
      if (!_counted) {
        _counted = true;
        _attempts++;
        if (res.correct) _score++;
      }
    });
  }

  void _setLevel(ConversionLevel l) {
    if (l == _level) return;
    _level = l;
    if (_topic != null && !conversionTopicsFor(l).contains(_topic)) {
      _topic = null;
    }
    _next();
  }

  void _setTopic(ConversionTopic? t) {
    if (t == _topic) return;
    _topic = t;
    _next();
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: TdcColors.surfaceAlt,
      selectedColor: TdcColors.accentDim,
      side: BorderSide(color: selected ? TdcColors.accent : TdcColors.border),
      labelStyle: TextStyle(
          color: selected ? TdcColors.accent : TdcColors.textSecondary,
          fontSize: 12),
    );
  }

  Widget _options() {
    const labelStyle = TextStyle(color: TdcColors.textMuted, fontSize: 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Niveau', style: labelStyle),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final l in ConversionLevel.values)
            _chip(conversionLevelLabels[l]!, l == _level, () => _setLevel(l)),
        ]),
        const SizedBox(height: 10),
        const Text('Thème', style: labelStyle),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _chip('Tout mélanger', _topic == null, () => _setTopic(null)),
          for (final t in conversionTopicsFor(_level))
            _chip(conversionTopicLabels[t]!, t == _topic, () => _setTopic(t)),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final solved = _result?.correct ?? false;
    return Material(
      color: TdcColors.bg,
      child: TrainingFrame(
        title: 'Binaire, décimal, hexadécimal',
        subtitle:
            '${conversionLevelLabels[_level]} · ${conversionTopicLabels[_ex.topic]}',
        icon: Icons.numbers,
        instruction: _ex.instruction,
        score: _score,
        attempts: _attempts,
        result: _result,
        onCheck: solved ? null : _check,
        onNext: _next,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrainingCode(_ex.given),
            const SizedBox(height: 12),
            TrainingField(
              label: _ex.fieldLabel,
              hint: _ex.hint,
              controller: _ctrl,
              onSubmitted: (_) => _check(),
              state: _result?.correct,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showMemo = !_showMemo),
                icon: Icon(_showMemo ? Icons.expand_less : Icons.expand_more,
                    size: 18),
                label: Text(_showMemo
                    ? 'Masquer l\'aide-mémoire'
                    : 'Afficher l\'aide-mémoire'),
              ),
            ),
            if (_showMemo) ...[
              const SizedBox(height: 6),
              TrainingCode(conversionCheatSheet()),
            ],
            const SizedBox(height: 14),
            _options(),
          ],
        ),
      ),
    );
  }
}
