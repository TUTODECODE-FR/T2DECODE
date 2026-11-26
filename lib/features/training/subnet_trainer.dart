// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
//
// Entraînement « Sous-réseaux IPv4 » : calcul d'un sous-réseau, appartenance au même
// réseau (ET logique) et découpage VLSM. La logique (génération et vérification) est
// pure et testable sans interface ; le widget SubnetTrainer ne fait que l'afficher.
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/training/training_kit.dart';

// ---------------------------------------------------------------------------
// Outils IPv4 (adresses sur 32 bits non signés)
// ---------------------------------------------------------------------------

const int _all32 = 0xFFFFFFFF;

/// Masque sur 32 bits correspondant à un préfixe (0 à 32).
int prefixToMask(int prefix) {
  if (prefix <= 0) return 0;
  if (prefix >= 32) return _all32;
  return (_all32 << (32 - prefix)) & _all32;
}

/// Nombre d'adresses d'un bloc /prefix (prefix de 1 à 32).
int blockSizeOf(int prefix) => 1 << (32 - prefix);

/// Les quatre octets d'une adresse, du premier au dernier.
List<int> octetsOf(int ip) =>
    [(ip >> 24) & 0xFF, (ip >> 16) & 0xFF, (ip >> 8) & 0xFF, ip & 0xFF];

String formatIpv4(int ip) => octetsOf(ip).join('.');

/// Lit une adresse en notation décimale pointée. Tolère les espaces, la virgule à la
/// place du point et un suffixe « /nn » (ignoré). Renvoie null si l'adresse est invalide.
int? parseIpv4(String input) {
  var s = input.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  final slash = s.indexOf('/');
  if (slash >= 0) s = s.substring(0, slash);
  final parts = s.split('.');
  if (parts.length != 4) return null;
  var v = 0;
  for (final p in parts) {
    if (!RegExp(r'^\d{1,3}$').hasMatch(p)) return null;
    final n = int.parse(p);
    if (n > 255) return null;
    v = v * 256 + n;
  }
  return v;
}

/// Lit un masque en décimal pointé seulement (255.255.255.192), éventuellement suivi
/// du préfixe correspondant (« 255.255.255.192 (/26) »). Renvoie le préfixe, ou null
/// si le masque est invalide (bits à 1 non contigus) ou contredit le suffixe.
int? parseDottedMask(String input) {
  final s = input.replaceAll(RegExp(r'[\s()]'), '').replaceAll(',', '.');
  final slash = s.indexOf('/');
  final dotted = slash >= 0 ? s.substring(0, slash) : s;
  if (dotted.split('.').length != 4) return null;
  final mask = parseIpv4(dotted);
  if (mask == null) return null;
  final inv = mask ^ _all32;
  if ((inv & (inv + 1)) != 0) return null;
  final p = 32 - inv.bitLength;
  if (slash >= 0) {
    final m = RegExp(r'^/(\d{1,2})$').firstMatch(s.substring(slash));
    if (m == null || int.parse(m.group(1)!) != p) return null;
  }
  return p;
}

/// Lit un masque : décimal pointé (255.255.255.192), « /26 » ou « 26 ».
/// Renvoie le préfixe, ou null si le masque est invalide (bits à 1 non contigus).
int? parsePrefix(String input) {
  final s = input.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  if (s.isEmpty) return null;
  final m = RegExp(r'^/?(\d{1,2})$').firstMatch(s);
  if (m != null) {
    final p = int.parse(m.group(1)!);
    return p <= 32 ? p : null;
  }
  return parseDottedMask(s);
}

/// Lit un nombre d'hôtes : « 62 », « 62 hôtes », « 16 777 214 », « 2^6-2 ».
int? parseHostCount(String input) {
  var s = normalizeAnswer(input).replaceAll(RegExp(r"[\s._,']"), '');
  s = s.replaceAll(
      RegExp(
          r'(h[oô]tes?|hosts?|adresses?|machines?|postes?)?(utilisables?)?$'),
      '');
  final pow = RegExp(r'^2(?:\^|\*\*)(\d{1,2})(?:-(\d{1,10}))?$').firstMatch(s);
  if (pow != null) {
    final e = int.parse(pow.group(1)!);
    if (e > 32) return null;
    final sub = pow.group(2) == null ? 0 : int.parse(pow.group(2)!);
    return (1 << e) - sub;
  }
  if (!RegExp(r'^\d{1,10}$').hasMatch(s)) return null;
  return int.parse(s);
}

/// Vrai si l'élève indique qu'une adresse n'existe pas (« aucune », « - »…).
bool isNoneAnswer(String input) {
  final s = normalizeAnswer(input);
  if (s.isEmpty) return false;
  const words = {
    '-',
    '--',
    '—',
    'x',
    'néant',
    'neant',
    'n/a',
    'na',
    'none',
    'sans',
    'rien',
    'inexistante',
    'inexistant',
    'non applicable',
  };
  return words.contains(s) || s.startsWith('aucun') || s.startsWith('pas de');
}

String _bits8(int v, [int cut = 0]) {
  final b = v.toRadixString(2).padLeft(8, '0');
  if (cut <= 0 || cut >= 8) return b;
  return '${b.substring(0, cut)}|${b.substring(cut)}';
}

/// Les 32 bits groupés par octet ; « | » marque la frontière réseau / hôte.
String ipv4ToBinary(int ip, [int? prefix]) {
  final bits = ip.toRadixString(2).padLeft(32, '0');
  final buf = StringBuffer();
  for (var i = 0; i < 32; i++) {
    final boundary = prefix != null && i == prefix && i > 0;
    if (i > 0 && i % 8 == 0) {
      buf.write(boundary ? '|' : '.');
    } else if (boundary) {
      buf.write('|');
    }
    buf.write(bits[i]);
  }
  return buf.toString();
}

/// Octet « significatif » : celui où passe la frontière réseau / hôte (si le préfixe
/// tombe sur une frontière d'octet, le premier octet de la partie hôte ; le 4e pour /32).
int significantOctet(int prefix) => prefix >= 32 ? 3 : prefix ~/ 8;

int _netBitsIn(int octet, int prefix) {
  final n = prefix - 8 * octet;
  return n < 0 ? 0 : (n > 8 ? 8 : n);
}

String _ord(int k) => const ['1er', '2e', '3e', '4e'][k];

String _given(String s) => s.trim().isEmpty ? 'vide' : '« ${s.trim()} »';

String _fieldLine(String label, bool ok, String expected, String given) => ok
    ? '$label : juste.'
    : '$label : à revoir, attendu $expected (ta réponse : ${_given(given)}).';

/// Plus petit préfixe (2 bits d'hôte au moins) dont le bloc contient [hosts] hôtes
/// utilisables, avec la règle 2^n - 2 >= hôtes.
int prefixForHosts(int hosts) {
  for (var n = 2; n <= 30; n++) {
    if ((1 << n) - 2 >= hosts) return 32 - n;
  }
  return 2;
}

/// Aide-mémoire : préfixe, masque, taille du bloc et hôtes utilisables.
String subnetCheatSheet({int from = 8}) {
  final b = StringBuffer('Préfixe  Masque             Bloc       Hôtes\n');
  for (var p = from; p <= 32; p++) {
    final hosts = p == 32 ? 1 : (p == 31 ? 2 : blockSizeOf(p) - 2);
    final note = p == 31 ? '  (RFC 3021)' : (p == 32 ? '  (hôte seul)' : '');
    b.writeln(
        '/${p.toString().padRight(7)} ${formatIpv4(prefixToMask(p)).padRight(18)} '
        '${blockSizeOf(p).toString().padRight(10)} $hosts$note');
  }
  return b.toString().trimRight();
}

// ---------------------------------------------------------------------------
// Génération commune
// ---------------------------------------------------------------------------

enum SubnetLevel { beginner, advanced }

class _Rfc1918 {
  const _Rfc1918(this.base, this.prefix);
  final int base;
  final int prefix;
}

/// Plages privées RFC 1918 : 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16.
const List<_Rfc1918> _private = [
  _Rfc1918(0x0A000000, 8),
  _Rfc1918(0xAC100000, 12),
  _Rfc1918(0xC0A80000, 16),
];

/// Adresse privée aléatoire dans une plage RFC 1918 compatible avec [prefix]
/// (plage au moins aussi grande ; strictement plus grande si [strict]).
int _randomPrivate(TrainingRandom r, int prefix, {bool strict = false}) {
  final ranges = _private
      .where((x) => strict ? x.prefix < prefix : x.prefix <= prefix)
      .toList();
  final range = r.pick(ranges);
  return range.base | r.nextInt(1 << (32 - range.prefix));
}

_Rfc1918 _rangeOf(int ip) =>
    _private.firstWhere((x) => (ip & prefixToMask(x.prefix)) == x.base);

/// Adresse d'hôte aléatoire (ni réseau ni broadcast) dans le réseau [network]/[prefix].
int _randomHost(TrainingRandom r, int network, int prefix) {
  if (prefix >= 31) return network | r.nextInt(blockSizeOf(prefix));
  return network | r.range(1, blockSizeOf(prefix) - 2);
}

/// Résultat d'une vérification : verdict + explication (TrainingCheck), état de chaque
/// champ (clé → juste ou non) et calcul détaillé à afficher en police à chasse fixe.
class SubnetGrade {
  const SubnetGrade(this.check, this.fields, this.workings);
  final TrainingCheck check;
  final Map<String, bool> fields;
  final String workings;
}

String _row(String label, int ip, int prefix) =>
    '${label.padRight(11)} ${formatIpv4(ip).padRight(16)} ${ipv4ToBinary(ip, prefix)}';

// ---------------------------------------------------------------------------
// Mode 1 : calcul d'un sous-réseau
// ---------------------------------------------------------------------------

class SubnetCalcExercise {
  const SubnetCalcExercise(this.ip, this.prefix);

  factory SubnetCalcExercise.generate(TrainingRandom r, SubnetLevel level) {
    int prefix;
    if (level == SubnetLevel.beginner) {
      prefix = r.nextInt(10) < 7 ? r.range(24, 30) : r.range(16, 23);
    } else {
      final x = r.nextInt(100);
      prefix = x < 8 ? 31 : (x < 12 ? 32 : r.range(8, 30));
    }
    final seed = _randomPrivate(r, prefix);
    return SubnetCalcExercise(
        _randomHost(r, seed & prefixToMask(prefix), prefix), prefix);
  }

  final int ip;
  final int prefix;

  int get mask => prefixToMask(prefix);
  int get network => ip & mask;
  int get broadcast => network | (mask ^ _all32);

  /// Un /31 (RFC 3021) ou un /32 n'a pas d'adresse de broadcast dirigé.
  bool get hasBroadcast => prefix <= 30;
  int get firstHost => prefix >= 31 ? network : network + 1;
  int get lastHost =>
      prefix == 32 ? network : (prefix == 31 ? network + 1 : broadcast - 1);
  int get hostCount =>
      prefix == 32 ? 1 : (prefix == 31 ? 2 : blockSizeOf(prefix) - 2);
}

class SubnetCalcAnswer {
  const SubnetCalcAnswer({
    this.network = '',
    this.mask = '',
    this.broadcast = '',
    this.first = '',
    this.last = '',
    this.hosts = '',
  });
  final String network;
  final String mask;
  final String broadcast;
  final String first;
  final String last;
  final String hosts;
}

/// Clés des champs du mode calcul, dans l'ordre d'affichage.
const List<String> subnetCalcKeys = [
  'network',
  'mask',
  'broadcast',
  'first',
  'last',
  'hosts',
];

const Map<String, String> subnetCalcLabels = {
  'network': 'Adresse réseau',
  'mask': 'Masque (décimal pointé)',
  'broadcast': 'Adresse de broadcast',
  'first': 'Première adresse utilisable',
  'last': 'Dernière adresse utilisable',
  'hosts': "Nombre d'hôtes utilisables",
};

SubnetGrade checkSubnetCalc(SubnetCalcExercise e, SubnetCalcAnswer a) {
  final bc = parseIpv4(a.broadcast);
  final fields = <String, bool>{
    'network': parseIpv4(a.network) == e.network,
    // Le préfixe est donné dans l'énoncé : seul le décimal pointé prouve la conversion.
    'mask': parseDottedMask(a.mask) == e.prefix,
    'broadcast': e.hasBroadcast
        ? bc == e.broadcast
        : (isNoneAnswer(a.broadcast) || (e.prefix == 31 && bc == _all32)),
    'first': parseIpv4(a.first) == e.firstHost,
    'last': parseIpv4(a.last) == e.lastHost,
    'hosts': parseHostCount(a.hosts) == e.hostCount,
  };
  final expected = <String, String>{
    'network': formatIpv4(e.network),
    'mask': '${formatIpv4(e.mask)} (/${e.prefix})',
    'broadcast': e.hasBroadcast ? formatIpv4(e.broadcast) : '« aucune »',
    'first': formatIpv4(e.firstHost),
    'last': formatIpv4(e.lastHost),
    'hosts': '${e.hostCount}',
  };
  final given = <String, String>{
    'network': a.network,
    'mask': a.mask,
    'broadcast': a.broadcast,
    'first': a.first,
    'last': a.last,
    'hosts': a.hosts,
  };
  final ok = fields.values.every((v) => v);
  final nOk = fields.values.where((v) => v).length;

  final p = e.prefix;
  final h = 32 - p;
  final k = significantOctet(p);
  final cut = _netBitsIn(k, p);
  final ipO = octetsOf(e.ip);
  final mO = octetsOf(e.mask);
  final nO = octetsOf(e.network);
  final bO = octetsOf(e.broadcast);
  final block = 256 - mO[k];
  final after = k < 3;

  final b = StringBuffer()
    ..writeln(ok
        ? 'Les six réponses sont justes.'
        : '$nOk réponse${nOk > 1 ? 's' : ''} juste${nOk > 1 ? 's' : ''} sur 6.');
  for (final key in subnetCalcKeys) {
    b.writeln(_fieldLine(
        subnetCalcLabels[key]!, fields[key]!, expected[key]!, given[key]!));
  }
  b
    ..writeln()
    ..writeln('Méthode pas à pas (${formatIpv4(e.ip)}/$p) :')
    ..writeln(
        '1. /$p = $p bits à 1 (partie réseau) puis $h bit${h > 1 ? 's' : ''} '
        'à 0 (partie hôte) : ${ipv4ToBinary(e.mask, p)}, soit ${formatIpv4(e.mask)}. '
        'Chaque octet du masque vaut 255 (8 bits à 1), 0, ou une valeur de la suite '
        '128, 192, 224, 240, 248, 252, 254.');
  if (p == 32) {
    b.writeln(
        '2. Le masque vaut 255 sur les quatre octets : aucun bit d\'hôte, '
        'l\'adresse est seule dans son réseau.');
  } else if (p % 8 == 0) {
    b
      ..writeln(
          '2. Le préfixe /$p tombe sur une frontière d\'octet : les octets où le '
          'masque vaut 255 sont recopiés, ceux où il vaut 0 forment la partie hôte. '
          'Premier octet hôte : le ${_ord(k)}. ET logique bit à bit :')
      ..writeln('   adresse ${ipO[k]} = ${_bits8(ipO[k])}')
      ..writeln('   masque  ${mO[k]} = ${_bits8(mO[k])}')
      ..writeln('   ET      ${nO[k]} = ${_bits8(nO[k])}');
  } else {
    b
      ..writeln(
          '2. L\'octet significatif est le ${_ord(k)}, où le masque vaut ${mO[k]} '
          '(ni 255 ni 0) : $cut bit${cut > 1 ? 's' : ''} réseau et ${8 - cut} bit'
          '${8 - cut > 1 ? 's' : ''} hôte. ET logique bit à bit (1 ET 1 = 1, sinon 0) :')
      ..writeln('   adresse ${ipO[k]} = ${_bits8(ipO[k], cut)}')
      ..writeln('   masque  ${mO[k]} = ${_bits8(mO[k], cut)}')
      ..writeln('   ET      ${nO[k]} = ${_bits8(nO[k], cut)}')
      ..writeln(
          '   Raccourci : taille de bloc = 256 - ${mO[k]} = $block ; le multiple '
          'de $block inférieur ou égal à ${ipO[k]} est ${nO[k]}.');
  }
  b.writeln('3. Adresse réseau = adresse ET masque (bits d\'hôte à 0) : '
      '${p < 32 ? 'octets réseau recopiés, ${_ord(k)} octet à ${nO[k]}${after ? ', octets suivants à 0' : ''}' : 'l\'adresse elle-même'}'
      ' → ${formatIpv4(e.network)}.');
  if (p <= 30) {
    b
      ..writeln('4. Broadcast = tous les bits d\'hôte à 1 : ${_ord(k)} octet à '
          '${nO[k]} + $block - 1 = ${bO[k]}${after ? ', octets suivants à 255' : ''}'
          ' → ${formatIpv4(e.broadcast)}.')
      ..writeln(
          '5. Première utilisable = réseau + 1 = ${formatIpv4(e.firstHost)} ; '
          'dernière utilisable = broadcast - 1 = ${formatIpv4(e.lastHost)}.')
      ..writeln('6. Hôtes utilisables = 2^$h - 2 = ${e.hostCount} (on retire '
          'l\'adresse réseau et l\'adresse de broadcast).');
  } else if (p == 31) {
    b.writeln(
        '4. Cas particulier /31 (RFC 3021) : un seul bit d\'hôte, donc deux '
        'adresses (${formatIpv4(e.network)} et ${formatIpv4(e.network + 1)}). La règle '
        'classique donnerait 2^1 - 2 = 0 hôte. La RFC 3021 autorise le /31 sur une '
        'liaison point à point : les deux adresses sont attribuées aux deux extrémités, '
        'sans adresse réseau ni broadcast dirigé réservés (seul le broadcast limité '
        '255.255.255.255 reste possible). Broadcast : « aucune » ; première = '
        '${formatIpv4(e.firstHost)}, dernière = ${formatIpv4(e.lastHost)}, 2 hôtes.');
  } else {
    b.writeln(
        '4. Cas particulier /32 : aucun bit d\'hôte, une seule adresse. Elle '
        'désigne un hôte unique (route d\'hôte, adresse de bouclage d\'un routeur). '
        'Pas de broadcast (« aucune ») ; première = dernière = '
        '${formatIpv4(e.ip)}, 1 hôte.');
  }

  final w = StringBuffer()
    ..writeln(_row('Adresse', e.ip, p))
    ..writeln(_row('Masque', e.mask, p))
    ..writeln(_row('Réseau', e.network, p));
  if (p <= 30) w.writeln(_row('Broadcast', e.broadcast, p));
  return SubnetGrade(TrainingCheck(ok, b.toString().trimRight()), fields,
      w.toString().trimRight());
}

// ---------------------------------------------------------------------------
// Mode 2 : même réseau ?
// ---------------------------------------------------------------------------

class SameNetworkExercise {
  const SameNetworkExercise(this.a, this.b, this.prefix,
      {this.showPrefix = true});

  factory SameNetworkExercise.generate(TrainingRandom r, SubnetLevel level) {
    final beginner = level == SubnetLevel.beginner;
    final prefix = beginner
        ? r.pick(const [16, 24, 24, 25, 26, 27, 28])
        : (r.nextInt(5) == 0 ? r.range(9, 15) : r.range(17, 30));
    final mask = prefixToMask(prefix);
    final seed = _randomPrivate(r, prefix, strict: true);
    final netA = seed & mask;
    final a = _randomHost(r, netA, prefix);
    int b;
    if (r.nextBool()) {
      do {
        b = _randomHost(r, netA, prefix);
      } while (b == a);
    } else {
      // Réseau voisin : on inverse un des derniers bits réseau (reste dans la plage).
      final range = _rangeOf(seed);
      final lo = 32 - prefix;
      final hi =
          (lo + 2 < 32 - range.prefix - 1) ? lo + 2 : 32 - range.prefix - 1;
      final bit = r.range(lo, hi);
      b = _randomHost(r, netA ^ (1 << bit), prefix);
    }
    return SameNetworkExercise(a, b, prefix, showPrefix: beginner);
  }

  final int a;
  final int b;
  final int prefix;

  /// Débutant : le masque est aussi donné en notation /n.
  final bool showPrefix;

  int get mask => prefixToMask(prefix);
  int get networkA => a & mask;
  int get networkB => b & mask;
  bool get same => networkA == networkB;
}

class SameNetworkAnswer {
  const SameNetworkAnswer({this.same, this.networkA = '', this.networkB = ''});
  final bool? same;
  final String networkA;
  final String networkB;
}

SubnetGrade checkSameNetwork(SameNetworkExercise e, SameNetworkAnswer a) {
  final fields = <String, bool>{
    'same': a.same == e.same,
    'networkA': parseIpv4(a.networkA) == e.networkA,
    'networkB': parseIpv4(a.networkB) == e.networkB,
  };
  final ok = fields.values.every((v) => v);
  final p = e.prefix;
  final k = significantOctet(p);
  final cut = _netBitsIn(k, p);
  final mO = octetsOf(e.mask);
  final yes = e.same ? 'oui' : 'non';

  final b = StringBuffer()
    ..writeln(
        ok ? 'Réponse juste et justifiée.' : 'Réponse incomplète ou fausse.')
    ..writeln(a.same == null
        ? 'Même réseau : aucune réponse choisie (attendu : $yes).'
        : (fields['same']!
            ? 'Même réseau : juste ($yes).'
            : 'Même réseau : à revoir, attendu $yes.'))
    ..writeln(_fieldLine(
        'Réseau de A', fields['networkA']!, formatIpv4(e.networkA), a.networkA))
    ..writeln(_fieldLine(
        'Réseau de B', fields['networkB']!, formatIpv4(e.networkB), a.networkB))
    ..writeln()
    ..writeln('Méthode pas à pas :')
    ..writeln(
        '1. Masque ${formatIpv4(e.mask)} = /$p : ${ipv4ToBinary(e.mask, p)}. '
        'Deux adresses sont dans le même réseau si « adresse ET masque » donne le '
        'même résultat (même partie réseau).');
  void side(String n, int ip, int net) {
    final o = octetsOf(ip);
    final no = octetsOf(net);
    if (p % 8 == 0) {
      b.writeln(
          '   $n = ${formatIpv4(ip)} : le préfixe tombe sur une frontière '
          'd\'octet, on garde les ${p ~/ 8} premiers octets et on met les autres à 0 '
          '→ ${formatIpv4(net)}.');
    } else {
      b.writeln(
          '   $n = ${formatIpv4(ip)} : ${_ord(k)} octet ${o[k]} ET ${mO[k]} '
          '= ${_bits8(o[k], cut)} ET ${_bits8(mO[k], cut)} = ${_bits8(no[k], cut)} '
          '= ${no[k]} → réseau ${formatIpv4(net)}/$p.');
    }
  }

  b.writeln('2. ET logique pour chaque adresse :');
  side('A', e.a, e.networkA);
  side('B', e.b, e.networkB);
  if (p % 8 != 0) {
    b.writeln(
        '   Raccourci : taille de bloc = 256 - ${mO[k]} = ${256 - mO[k]} ; on '
        'prend le multiple de ${256 - mO[k]} inférieur ou égal à l\'octet.');
  }
  if (e.same) {
    b.writeln(
        '3. Même adresse réseau (${formatIpv4(e.networkA)}/$p) : A et B sont '
        'dans le même réseau et communiquent directement, sans routeur.');
  } else {
    final diff = e.networkA ^ e.networkB;
    final pos = 32 - diff.bitLength + 1;
    b.writeln('3. Adresses réseau différentes (${formatIpv4(e.networkA)} et '
        '${formatIpv4(e.networkB)}) : elles diffèrent au bit $pos de la partie réseau '
        '(${_ord((pos - 1) ~/ 8)} octet). A et B ne sont pas dans le même réseau : il '
        'faut passer par un routeur.');
  }

  final w = StringBuffer()
    ..writeln(_row('A', e.a, p))
    ..writeln(_row('Masque', e.mask, p))
    ..writeln(_row('Réseau A', e.networkA, p))
    ..writeln()
    ..writeln(_row('B', e.b, p))
    ..writeln(_row('Masque', e.mask, p))
    ..writeln(_row('Réseau B', e.networkB, p));
  return SubnetGrade(TrainingCheck(ok, b.toString().trimRight()), fields,
      w.toString().trimRight());
}

// ---------------------------------------------------------------------------
// Mode 3 : découpage VLSM
// ---------------------------------------------------------------------------

class VlsmNeed {
  const VlsmNeed(this.name, this.hosts);
  final String name;

  /// Nombre d'hôtes à adresser (passerelle comprise).
  final int hosts;
}

class VlsmSubnet {
  const VlsmSubnet(this.network, this.prefix);
  final int network;
  final int prefix;
  int get size => blockSizeOf(prefix);
  int get broadcast => network + size - 1;
  int get mask => prefixToMask(prefix);
}

/// Ordre d'allocation : besoins du plus grand au plus petit (à égalité, ordre de la liste).
List<int> vlsmOrder(List<VlsmNeed> needs) {
  final idx = List<int>.generate(needs.length, (i) => i);
  idx.sort((x, y) {
    final c = needs[y].hosts.compareTo(needs[x].hosts);
    return c != 0 ? c : x.compareTo(y);
  });
  return idx;
}

/// Plan VLSM (un sous-réseau par besoin, dans l'ordre des besoins), ou null s'il ne
/// tient pas dans le réseau de départ.
List<VlsmSubnet>? computeVlsmPlan(
    int base, int basePrefix, List<VlsmNeed> needs) {
  final end = base + blockSizeOf(basePrefix);
  final plan = List<VlsmSubnet?>.filled(needs.length, null);
  var cursor = base;
  for (final i in vlsmOrder(needs)) {
    final p = prefixForHosts(needs[i].hosts);
    if (p < basePrefix) return null;
    plan[i] = VlsmSubnet(cursor, p);
    cursor += blockSizeOf(p);
    if (cursor > end) return null;
  }
  return [for (final s in plan) s!];
}

class VlsmExercise {
  VlsmExercise(this.base, this.basePrefix, this.needs)
      : plan = computeVlsmPlan(base, basePrefix, needs) ??
            (throw ArgumentError(
                'Les besoins ne tiennent pas dans le réseau.'));

  factory VlsmExercise.generate(TrainingRandom r, SubnetLevel level) {
    final beginner = level == SubnetLevel.beginner;
    final int basePrefix;
    final int base;
    if (beginner) {
      basePrefix = 24;
      base = 0xC0A80000 | (r.range(0, 254) << 8);
    } else {
      basePrefix = r.pick(const [22, 23, 24]);
      base = _randomPrivate(r, basePrefix) & prefixToMask(basePrefix);
    }
    final size = blockSizeOf(basePrefix);
    final n = beginner ? r.range(3, 4) : r.range(4, 5);
    final maxBits = 32 - basePrefix - 1;
    List<int>? bits;
    for (var t = 0; t < 300 && bits == null; t++) {
      final c = List<int>.generate(n, (_) => r.range(2, maxBits));
      final sum = c.fold<int>(0, (s, x) => s + (1 << x));
      if (sum <= size &&
          sum * 2 >= size &&
          c.where((x) => x == 2).length <= 2) {
        bits = c;
      }
    }
    bits ??= List<int>.generate(n, (i) => maxBits - i < 2 ? 2 : maxBits - i);
    final lans = r.shuffled(const [
      'Administration',
      'Pédagogie',
      'Wi-Fi invités',
      'Serveurs',
      'Comptabilité',
      'Atelier',
      'Direction',
      'Téléphonie IP',
      'Vidéosurveillance',
      'Laboratoire',
    ]);
    const links = ['Liaison R1-R2', 'Liaison R2-R3', 'Liaison R1-R3'];
    var li = 0;
    var ni = 0;
    final needs = <VlsmNeed>[];
    for (final x in bits) {
      if (x == 2) {
        needs.add(VlsmNeed(links[li++ % links.length], 2));
      } else {
        needs.add(VlsmNeed(lans[ni++ % lans.length],
            r.range((1 << (x - 1)) - 1, (1 << x) - 2)));
      }
    }
    return VlsmExercise(base, basePrefix, r.shuffled(needs));
  }

  final int base;
  final int basePrefix;
  final List<VlsmNeed> needs;

  /// Plan corrigé, aligné sur [needs].
  final List<VlsmSubnet> plan;
}

class VlsmAnswer {
  const VlsmAnswer({this.prefix = '', this.network = ''});
  final String prefix;
  final String network;
}

SubnetGrade checkVlsm(VlsmExercise e, List<VlsmAnswer> answers) {
  final fields = <String, bool>{};
  // Des blocs de même taille sont interchangeables : on accepte toute permutation.
  final pool = <int, List<int>>{};
  for (final s in e.plan) {
    pool.putIfAbsent(s.prefix, () => <int>[]).add(s.network);
  }
  final lines = <String>[];
  for (var i = 0; i < e.needs.length; i++) {
    final a = i < answers.length ? answers[i] : const VlsmAnswer();
    final s = e.plan[i];
    final pOk = parsePrefix(a.prefix) == s.prefix;
    final net = parseIpv4(a.network);
    final free = pool[s.prefix]!;
    final nOk = net != null && free.contains(net);
    if (nOk) free.remove(net);
    fields['prefix$i'] = pOk;
    fields['network$i'] = nOk;
    final n = e.needs[i];
    lines
      ..add(_fieldLine('${n.name}, préfixe', pOk, '/${s.prefix}', a.prefix))
      ..add(_fieldLine(
          '${n.name}, adresse réseau', nOk, formatIpv4(s.network), a.network));
  }
  final ok = fields.values.every((v) => v);
  final b = StringBuffer()
    ..writeln(ok ? 'Plan d\'adressage juste.' : 'Le plan contient des erreurs.')
    ..writeln(lines.join('\n'))
    ..writeln()
    ..writeln('Méthode pas à pas (${formatIpv4(e.base)}/${e.basePrefix}, '
        '${blockSizeOf(e.basePrefix)} adresses) :')
    ..writeln('1. Range les besoins du plus grand au plus petit.')
    ..writeln('2. Pour h hôtes, cherche le plus petit n tel que 2^n - 2 >= h '
        '(on retire réseau et broadcast) : préfixe = 32 - n, bloc de 2^n adresses.')
    ..writeln(
        '3. Place chaque bloc à la première adresse libre. Comme les blocs vont '
        'en décroissant, chaque début de bloc est un multiple de sa taille (aligné).')
    ..writeln('Plan corrigé :');
  var step = 0;
  for (final i in vlsmOrder(e.needs)) {
    final n = e.needs[i];
    final s = e.plan[i];
    final hb = 32 - s.prefix;
    step++;
    b.writeln(
        '$step) ${n.name} (${n.hosts} hôtes) : 2^$hb - 2 = ${s.size - 2} >= '
        '${n.hosts}${hb > 2 ? ' et 2^${hb - 1} - 2 = ${(s.size >> 1) - 2} < ${n.hosts}' : ''}'
        ' → /${s.prefix} (bloc de ${s.size}). Réseau ${formatIpv4(s.network)}/${s.prefix}, '
        'masque ${formatIpv4(s.mask)}, utilisables ${formatIpv4(s.network + 1)} à '
        '${formatIpv4(s.broadcast - 1)}, broadcast ${formatIpv4(s.broadcast)}.');
  }
  final used = e.plan.fold<int>(0, (t, s) => t + s.size);
  final total = blockSizeOf(e.basePrefix);
  final next = e.base + used;
  b.writeln(used == total
      ? 'Le réseau de départ est entièrement utilisé.'
      : 'Reste libre : ${formatIpv4(next)} à ${formatIpv4(e.base + total - 1)} '
          '(${total - used} adresses), pour de futurs besoins.');

  final w = StringBuffer()
    ..writeln('${'Besoin'.padRight(19)} ${'Hôtes'.padRight(6)} '
        '${'Réseau'.padRight(19)} ${'Masque'.padRight(16)} Broadcast');
  for (final i in vlsmOrder(e.needs)) {
    final s = e.plan[i];
    w.writeln(
        '${e.needs[i].name.padRight(19)} ${e.needs[i].hosts.toString().padRight(6)} '
        '${'${formatIpv4(s.network)}/${s.prefix}'.padRight(19)} '
        '${formatIpv4(s.mask).padRight(16)} ${formatIpv4(s.broadcast)}');
  }
  if (used < total) {
    w.writeln('${'(libre)'.padRight(26)} ${formatIpv4(next)}');
  }
  return SubnetGrade(TrainingCheck(ok, b.toString().trimRight()), fields,
      w.toString().trimRight());
}

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

enum SubnetMode { calc, sameNetwork, vlsm }

const Map<SubnetMode, String> _modeLabels = {
  SubnetMode.calc: 'Calcul',
  SubnetMode.sameNetwork: 'Même réseau ?',
  SubnetMode.vlsm: 'Découpage VLSM',
};

class SubnetTrainer extends StatefulWidget {
  const SubnetTrainer({super.key});

  @override
  State<SubnetTrainer> createState() => _SubnetTrainerState();
}

class _SubnetTrainerState extends State<SubnetTrainer> {
  final TrainingRandom _rnd = TrainingRandom();
  final List<TextEditingController> _ctrls = [];
  SubnetMode _mode = SubnetMode.calc;
  SubnetLevel _level = SubnetLevel.beginner;
  SubnetCalcExercise? _calc;
  SameNetworkExercise? _same;
  VlsmExercise? _vlsm;
  bool? _sameAnswer;
  SubnetGrade? _grade;
  int _score = 0;
  int _attempts = 0;
  bool _counted = false;
  bool _help = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _c(int i) {
    while (_ctrls.length <= i) {
      _ctrls.add(TextEditingController());
    }
    return _ctrls[i];
  }

  void _generate() {
    for (final c in _ctrls) {
      c.clear();
    }
    _sameAnswer = null;
    _grade = null;
    _counted = false;
    _calc = null;
    _same = null;
    _vlsm = null;
    switch (_mode) {
      case SubnetMode.calc:
        _calc = SubnetCalcExercise.generate(_rnd, _level);
        break;
      case SubnetMode.sameNetwork:
        _same = SameNetworkExercise.generate(_rnd, _level);
        break;
      case SubnetMode.vlsm:
        _vlsm = VlsmExercise.generate(_rnd, _level);
        break;
    }
  }

  void _next() => setState(_generate);

  void _check() {
    SubnetGrade g;
    switch (_mode) {
      case SubnetMode.calc:
        g = checkSubnetCalc(
            _calc!,
            SubnetCalcAnswer(
              network: _c(0).text,
              mask: _c(1).text,
              broadcast: _c(2).text,
              first: _c(3).text,
              last: _c(4).text,
              hosts: _c(5).text,
            ));
        break;
      case SubnetMode.sameNetwork:
        g = checkSameNetwork(
            _same!,
            SameNetworkAnswer(
                same: _sameAnswer, networkA: _c(0).text, networkB: _c(1).text));
        break;
      case SubnetMode.vlsm:
        g = checkVlsm(_vlsm!, [
          for (var i = 0; i < _vlsm!.needs.length; i++)
            VlsmAnswer(prefix: _c(2 * i).text, network: _c(2 * i + 1).text),
        ]);
        break;
    }
    setState(() {
      _grade = g;
      // Seule la première vérification d'un exercice compte dans le score.
      if (!_counted) {
        _counted = true;
        _attempts++;
        if (g.check.correct) _score++;
      }
    });
  }

  String get _instruction {
    switch (_mode) {
      case SubnetMode.calc:
        final e = _calc!;
        return 'Adresse : ${formatIpv4(e.ip)}/${e.prefix}\n\n'
            'Calcule l\'adresse réseau, le masque en décimal pointé, l\'adresse de '
            'broadcast, la première et la dernière adresse utilisable, et le nombre '
            'd\'hôtes utilisables.'
            '${_level == SubnetLevel.advanced ? '\nSi une adresse n\'existe pas pour ce préfixe, écris « aucune ».' : ''}';
      case SubnetMode.sameNetwork:
        final e = _same!;
        return 'Adresse A : ${formatIpv4(e.a)}\nAdresse B : ${formatIpv4(e.b)}\n'
            'Masque : ${formatIpv4(e.mask)}${e.showPrefix ? ' (/${e.prefix})' : ''}\n\n'
            'Ces deux adresses sont-elles dans le même réseau ? Justifie en calculant '
            'l\'adresse réseau de chacune (ET logique entre l\'adresse et le masque).';
      case SubnetMode.vlsm:
        final e = _vlsm!;
        final needs =
            e.needs.map((n) => '- ${n.name} : ${n.hosts} hôtes').join('\n');
        return 'Réseau de départ : ${formatIpv4(e.base)}/${e.basePrefix}\n'
            'Besoins (hôtes à adresser, passerelle comprise) :\n$needs\n\n'
            'Découpe en VLSM : alloue les sous-réseaux du plus grand au plus petit, '
            'à partir du début du réseau, chacun avec le plus petit préfixe suffisant. '
            'Donne pour chaque besoin le préfixe et l\'adresse réseau.';
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: TdcColors.accentDim,
      backgroundColor: TdcColors.surfaceAlt,
      side: BorderSide(color: selected ? TdcColors.accent : TdcColors.border),
      labelStyle: TextStyle(
          color: selected ? TdcColors.textPrimary : TdcColors.textSecondary,
          fontSize: 13),
    );
  }

  Widget _field(int i, String label, String key,
      {String? hint, double width = 270}) {
    return SizedBox(
      width: width,
      child: TrainingField(
        label: label,
        controller: _c(i),
        hint: hint,
        state: _grade?.fields[key],
        onSubmitted: (_) => _check(),
      ),
    );
  }

  Widget _exercise() {
    switch (_mode) {
      case SubnetMode.calc:
        final hints = {
          'network': 'ex. 192.168.1.64',
          'mask': 'ex. 255.255.255.192',
          'broadcast':
              _level == SubnetLevel.advanced ? 'adresse ou « aucune »' : null,
          'first': null,
          'last': null,
          'hosts': 'ex. 62',
        };
        return Wrap(spacing: 12, children: [
          for (var i = 0; i < subnetCalcKeys.length; i++)
            _field(i, subnetCalcLabels[subnetCalcKeys[i]]!, subnetCalcKeys[i],
                hint: hints[subnetCalcKeys[i]]),
        ]);
      case SubnetMode.sameNetwork:
        final st = _grade?.fields['same'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Même réseau ?',
                  style: TextStyle(
                      color: st == null
                          ? TdcColors.textSecondary
                          : (st ? TdcColors.success : TdcColors.danger))),
              const SizedBox(width: 12),
              _chip('Oui', _sameAnswer == true,
                  () => setState(() => _sameAnswer = true)),
              const SizedBox(width: 8),
              _chip('Non', _sameAnswer == false,
                  () => setState(() => _sameAnswer = false)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 12, children: [
              _field(0, 'Adresse réseau de A', 'networkA'),
              _field(1, 'Adresse réseau de B', 'networkB'),
            ]),
          ],
        );
      case SubnetMode.vlsm:
        final e = _vlsm!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < e.needs.length; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${e.needs[i].name} (${e.needs[i].hosts} hôtes)',
                    style: const TextStyle(
                        color: TdcColors.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
              Wrap(spacing: 12, children: [
                _field(2 * i, 'Préfixe', 'prefix$i',
                    hint: 'ex. /26', width: 140),
                _field(2 * i + 1, 'Adresse réseau', 'network$i',
                    hint: 'ex. 192.168.10.64', width: 250),
              ]),
            ],
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grade = _grade;
    return TrainingFrame(
      title: 'Sous-réseaux IPv4',
      subtitle:
          '${_modeLabels[_mode]} · ${_level == SubnetLevel.beginner ? 'débutant' : 'avancé'}',
      icon: Icons.lan_outlined,
      instruction: _instruction,
      onCheck: _check,
      onNext: _next,
      result: grade?.check,
      score: _score,
      attempts: _attempts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in SubnetMode.values)
              _chip(_modeLabels[m]!, _mode == m, () {
                if (_mode == m) return;
                setState(() {
                  _mode = m;
                  _generate();
                });
              }),
            const SizedBox(width: 12),
            _chip('Débutant', _level == SubnetLevel.beginner, () {
              if (_level == SubnetLevel.beginner) return;
              setState(() {
                _level = SubnetLevel.beginner;
                _generate();
              });
            }),
            _chip('Avancé', _level == SubnetLevel.advanced, () {
              if (_level == SubnetLevel.advanced) return;
              setState(() {
                _level = SubnetLevel.advanced;
                _generate();
              });
            }),
          ]),
          const SizedBox(height: 16),
          _exercise(),
          if (grade != null) ...[
            const SizedBox(height: 4),
            Text(
                _mode == SubnetMode.vlsm ? 'Plan corrigé' : 'Calcul en binaire',
                style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TrainingCode(grade.workings),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _help = !_help),
              icon:
                  Icon(_help ? Icons.expand_less : Icons.expand_more, size: 18),
              label: Text(_help
                  ? 'Masquer l\'aide-mémoire'
                  : 'Aide-mémoire des masques'),
              style: TextButton.styleFrom(
                  foregroundColor: TdcColors.textSecondary),
            ),
          ),
          if (_help) TrainingCode(subnetCheatSheet()),
        ],
      ),
    );
  }
}
