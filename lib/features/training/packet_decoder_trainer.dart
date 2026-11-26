// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
//
// Entraînement « Décoder une trame » : une trame Ethernet II (éventuellement étiquetée
// 802.1Q) contenant un paquet IPv4 et un segment TCP, un datagramme UDP ou un message
// ICMP echo est générée avec des en-têtes cohérents et des sommes de contrôle exactes
// (RFC 791, RFC 9293, RFC 768, RFC 792, RFC 1071), puis affichée comme Wireshark ou
// tcpdump -XX. L'élève décode les champs ; la correction indique la position des octets
// et la conversion hexadécimal -> décimal, pas à pas.
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/training/training_kit.dart';

// ---------------------------------------------------------------------------
// Logique pure (testable sans interface)
// ---------------------------------------------------------------------------

enum PacketLevel { debutant, avance, expert }

enum DumpStyle { wireshark, tcpdump }

extension PacketLevelLabel on PacketLevel {
  String get label {
    switch (this) {
      case PacketLevel.debutant:
        return 'Débutant';
      case PacketLevel.avance:
        return 'Avancé';
      case PacketLevel.expert:
        return 'Expert';
    }
  }
}

/// Protocole de couche 4 transporté par le paquet IPv4.
enum PacketTransport { tcp, udp, icmp }

const int etherTypeIpv4 = 0x0800;
const int etherTypeVlan = 0x8100;

/// Bits de l'octet de drapeaux TCP (octet 13 de l'en-tête, RFC 9293 / RFC 3168).
const int tcpFin = 0x01;
const int tcpSyn = 0x02;
const int tcpRst = 0x04;
const int tcpPsh = 0x08;
const int tcpAck = 0x10;
const int tcpUrg = 0x20;
const int tcpEce = 0x40;
const int tcpCwr = 0x80;

/// Drapeaux TCP, du bit de poids faible (FIN) au bit de poids fort (CWR).
const List<int> _flagBits = [
  tcpFin,
  tcpSyn,
  tcpRst,
  tcpPsh,
  tcpAck,
  tcpUrg,
  tcpEce,
  tcpCwr
];
const Map<int, String> _flagName = {
  tcpFin: 'FIN',
  tcpSyn: 'SYN',
  tcpRst: 'RST',
  tcpPsh: 'PSH',
  tcpAck: 'ACK',
  tcpUrg: 'URG',
  tcpEce: 'ECE',
  tcpCwr: 'CWR',
};

/// Noms des drapeaux à 1, dans l'ordre où Wireshark les affiche (bit de poids faible
/// d'abord : « SYN, ACK », « FIN, ACK », « SYN, ECE, CWR »).
String tcpFlagsToText(int flags) {
  final names = [
    for (final f in _flagBits)
      if (flags & f != 0) _flagName[f]!
  ];
  return names.isEmpty ? 'aucun' : names.join(', ');
}

/// Notation de tcpdump (print-tcp.c, tcp_flag_values), dans son ordre : F, S, R, P,
/// « . » pour ACK, U, E (ECE), W (CWR). Exemples : [S.], [P.], [F.], [S.E], [SEW].
String tcpFlagsToTcpdump(int flags) {
  final b = StringBuffer();
  if (flags & tcpFin != 0) b.write('F');
  if (flags & tcpSyn != 0) b.write('S');
  if (flags & tcpRst != 0) b.write('R');
  if (flags & tcpPsh != 0) b.write('P');
  if (flags & tcpAck != 0) b.write('.');
  if (flags & tcpUrg != 0) b.write('U');
  if (flags & tcpEce != 0) b.write('E');
  if (flags & tcpCwr != 0) b.write('W');
  return '[${b.isEmpty ? 'none' : b}]';
}

/// Service associé à un port bien connu ou enregistré (registre IANA).
class PortService {
  const PortService(this.port, this.transport, this.name, this.accepted);
  final int port;
  final PacketTransport transport;
  final String name;

  /// Noms acceptés, en minuscules, sans espace ni ponctuation.
  final List<String> accepted;
}

const List<PortService> knownServices = [
  PortService(21, PacketTransport.tcp, 'FTP (contrôle)', ['ftp']),
  PortService(22, PacketTransport.tcp, 'SSH', ['ssh', 'sftp', 'scp']),
  PortService(23, PacketTransport.tcp, 'Telnet', ['telnet']),
  PortService(25, PacketTransport.tcp, 'SMTP', ['smtp']),
  PortService(80, PacketTransport.tcp, 'HTTP', ['http', 'www']),
  PortService(110, PacketTransport.tcp, 'POP3', ['pop3', 'pop']),
  PortService(143, PacketTransport.tcp, 'IMAP', ['imap', 'imap4']),
  PortService(443, PacketTransport.tcp, 'HTTPS (HTTP sur TLS)',
      ['https', 'tls', 'ssl', 'httpstls']),
  PortService(445, PacketTransport.tcp, 'SMB (partage de fichiers Windows)',
      ['smb', 'cifs', 'microsoftds', 'smb2', 'smb3']),
  PortService(587, PacketTransport.tcp, 'SMTP soumission (submission)',
      ['smtp', 'submission']),
  PortService(993, PacketTransport.tcp, 'IMAPS (IMAP sur TLS)',
      ['imaps', 'imap', 'imaptls']),
  PortService(
      3306, PacketTransport.tcp, 'MySQL / MariaDB', ['mysql', 'mariadb']),
  PortService(3389, PacketTransport.tcp, 'RDP (bureau à distance)', [
    'rdp',
    'msrdp',
    'msterminalserver',
    'terminalserver',
    'bureauadistance'
  ]),
  PortService(5432, PacketTransport.tcp, 'PostgreSQL',
      ['postgresql', 'postgres', 'pgsql']),
  PortService(8080, PacketTransport.tcp, 'HTTP alternatif (http-alt, proxy)',
      ['http', 'httpalt', 'httpproxy', 'proxy', 'webcache']),
  PortService(53, PacketTransport.udp, 'DNS', ['dns', 'domain']),
  PortService(69, PacketTransport.udp, 'TFTP', ['tftp']),
  PortService(123, PacketTransport.udp, 'NTP', ['ntp']),
  PortService(161, PacketTransport.udp, 'SNMP', ['snmp']),
  PortService(
      443, PacketTransport.udp, 'QUIC (HTTP/3)', ['quic', 'http3', 'https']),
  PortService(514, PacketTransport.udp, 'Syslog', ['syslog']),
];

/// Une question posée sur la trame, avec sa réponse attendue et la méthode.
class PacketQuestion {
  const PacketQuestion({
    required this.id,
    required this.label,
    required this.hint,
    required this.expected,
    required this.accepts,
    required this.method,
  });

  final String id;
  final String label;
  final String hint;

  /// Réponse attendue, sous sa forme usuelle.
  final String expected;
  final bool Function(String answer) accepts;

  /// Explication pas à pas (positions des octets, conversions).
  final String method;
}

/// Exercice généré : la trame et tout ce qu'elle contient, décodé.
class PacketExercise {
  PacketExercise({
    required this.level,
    required this.bytes,
    required this.transport,
    required this.dstMac,
    required this.srcMac,
    required this.vlanId,
    required this.ipOffset,
    required this.l4Offset,
    required this.srcIp,
    required this.dstIp,
    required this.ttl,
    required this.initialTtl,
    required this.totalLength,
    required this.identification,
    required this.dontFragment,
    required this.ipChecksum,
    required this.ipChecksumExpected,
    required this.srcPort,
    required this.dstPort,
    required this.tcpFlags,
    required this.tcpHeaderLength,
    required this.service,
    required this.icmpType,
    required this.icmpSequence,
    required this.payloadLength,
    required this.paddingLength,
    required this.toServer,
  });

  final PacketLevel level;
  final List<int> bytes;
  final PacketTransport transport;
  final List<int> dstMac;
  final List<int> srcMac;

  /// null si la trame n'est pas étiquetée 802.1Q.
  final int? vlanId;
  final int ipOffset;
  final int l4Offset;
  final List<int> srcIp;
  final List<int> dstIp;
  final int ttl;
  final int initialTtl;
  final int totalLength;
  final int identification;
  final bool dontFragment;

  /// Somme présente dans la trame (fausse en mode expert, une fois sur deux).
  final int ipChecksum;

  /// Somme correcte, calculée selon la RFC 1071.
  final int ipChecksumExpected;
  final int? srcPort;
  final int? dstPort;
  final int? tcpFlags;
  final int? tcpHeaderLength;
  final PortService? service;
  final int? icmpType;
  final int? icmpSequence;
  final int payloadLength;
  final int paddingLength;
  final bool toServer;

  late final List<PacketQuestion> questions = _buildQuestions(this);

  String dump(DumpStyle style) => hexDump(bytes, style);

  int get ipHeaderLength => (bytes[ipOffset] & 0x0f) * 4;
  bool get ipChecksumValid => ipChecksum == ipChecksumExpected;

  String get transportName => transportNameOf(transport);

  int get protocolNumber => protocolNumberOf(transport);

  int get l4HeaderLength =>
      transport == PacketTransport.tcp ? tcpHeaderLength! : 8;

  /// Résumé d'une ligne, façon liste des paquets de Wireshark.
  String get summary {
    final s = formatIp(srcIp), d = formatIp(dstIp);
    switch (transport) {
      case PacketTransport.tcp:
        return 'TCP $s:$srcPort -> $d:$dstPort ${tcpFlagsToTcpdump(tcpFlags!)} '
            'données $payloadLength octet(s)';
      case PacketTransport.udp:
        return 'UDP $s:$srcPort -> $d:$dstPort données $payloadLength octet(s)';
      case PacketTransport.icmp:
        return 'ICMP $s -> $d ${icmpType == 8 ? 'Echo Request' : 'Echo Reply'} '
            'seq=$icmpSequence';
    }
  }

  /// Plan de la trame : couches et intervalles d'octets.
  String get structure {
    final parts = <String>[];
    parts.add('Ethernet II : ${_span(0, ipOffset)}'
        '${vlanId != null ? ' (dont étiquette 802.1Q en 12 à 15)' : ''}');
    parts.add('IPv4 : ${_span(ipOffset, ipHeaderLength)}');
    parts.add('$transportName : ${_span(l4Offset, l4HeaderLength)}');
    if (payloadLength > 0) {
      parts.add('Données : ${_span(l4Offset + l4HeaderLength, payloadLength)}');
    }
    if (paddingLength > 0) {
      parts.add(
          'Bourrage Ethernet : ${_span(bytes.length - paddingLength, paddingLength)}');
    }
    return parts.join('\n');
  }
}

String transportNameOf(PacketTransport t) {
  switch (t) {
    case PacketTransport.tcp:
      return 'TCP';
    case PacketTransport.udp:
      return 'UDP';
    case PacketTransport.icmp:
      return 'ICMP';
  }
}

/// Numéro de protocole IP (registre IANA) : 1 ICMP, 6 TCP, 17 UDP.
int protocolNumberOf(PacketTransport t) {
  switch (t) {
    case PacketTransport.tcp:
      return 6;
    case PacketTransport.udp:
      return 17;
    case PacketTransport.icmp:
      return 1;
  }
}

String _span(int start, int len) =>
    'octets $start à ${start + len - 1} (0x${hex4(start)} à 0x${hex4(start + len - 1)}), $len octets';

String hex2(int b) => b.toRadixString(16).padLeft(2, '0');
String hex4(int v) => v.toRadixString(16).padLeft(4, '0');
String formatMac(List<int> m) => m.map(hex2).join(':');
String formatIp(List<int> ip) => ip.join('.');

/// Somme de contrôle Internet (RFC 1071) : complément à un de la somme en complément
/// à un des mots de 16 bits (un octet final impair est complété par un zéro).
int internetChecksum(List<int> data) {
  var sum = 0;
  for (var i = 0; i < data.length; i += 2) {
    final hi = data[i];
    final lo = i + 1 < data.length ? data[i + 1] : 0;
    sum += (hi << 8) | lo;
  }
  while (sum >> 16 != 0) {
    sum = (sum & 0xffff) + (sum >> 16);
  }
  return ~sum & 0xffff;
}

/// Somme TCP/UDP : pseudo-en-tête (IP source, IP destination, zéro, protocole,
/// longueur du segment) suivi du segment (RFC 9293 §3.1, RFC 768).
int transportChecksum(
    List<int> src, List<int> dst, int proto, List<int> segment) {
  final pseudo = <int>[
    ...src,
    ...dst,
    0,
    proto,
    (segment.length >> 8) & 0xff,
    segment.length & 0xff,
  ];
  return internetChecksum([...pseudo, ...segment]);
}

/// Vidage hexadécimal avec offsets, comme Wireshark (octets bruts) ou tcpdump -XX.
String hexDump(List<int> bytes, DumpStyle style) {
  final lines = <String>[];
  for (var off = 0; off < bytes.length; off += 16) {
    final end = (off + 16 < bytes.length) ? off + 16 : bytes.length;
    final row = bytes.sublist(off, end);
    String ascii(List<int> part) => part
        .map((b) => (b >= 0x20 && b < 0x7f) ? String.fromCharCode(b) : '.')
        .join();
    if (style == DumpStyle.wireshark) {
      final hexCells = <String>[];
      for (var i = 0; i < 16; i++) {
        hexCells.add(i < row.length ? hex2(row[i]) : '  ');
      }
      final hex =
          '${hexCells.sublist(0, 8).join(' ')}  ${hexCells.sublist(8).join(' ')}';
      final left = row.length > 8 ? row.sublist(0, 8) : row;
      final right = row.length > 8 ? row.sublist(8) : <int>[];
      final asc =
          right.isEmpty ? ascii(left) : '${ascii(left)} ${ascii(right)}';
      lines.add('${hex4(off)}  $hex   $asc');
    } else {
      final groups = <String>[];
      for (var i = 0; i < 16; i += 2) {
        if (i >= row.length) {
          groups.add('    ');
        } else if (i + 1 >= row.length) {
          groups.add('${hex2(row[i])}  ');
        } else {
          groups.add('${hex2(row[i])}${hex2(row[i + 1])}');
        }
      }
      lines.add('0x${hex4(off)}:  ${groups.join(' ')}  ${ascii(row)}');
    }
  }
  return lines.join('\n');
}

// --------------------------- Analyse des réponses ---------------------------

String _deaccent(String s) {
  const from = 'àâäéèêëîïôöùûüç';
  const to = 'aaaeeeeiioouuuc';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

String _compact(String s) => _deaccent(s).replaceAll(RegExp(r'[^a-z0-9]'), '');

/// MAC en 12 chiffres hexadécimaux minuscules (séparateurs : rien, deux-points,
/// tirets, points, espaces), ou null.
String? parseMac(String s) {
  final c = s.trim().toLowerCase().replaceAll(RegExp(r'[\s:\-.]'), '');
  return RegExp(r'^[0-9a-f]{12}$').hasMatch(c) ? c : null;
}

/// Entier en décimal, ou en hexadécimal avec « 0x » ou suffixe « h ».
int? parseFlexibleInt(String s) {
  final t = normalizeAnswer(s).replaceAll(' ', '');
  if (t.isEmpty) return null;
  final hexA = RegExp(r'^0x([0-9a-f]+)$').firstMatch(t);
  if (hexA != null) return int.tryParse(hexA.group(1)!, radix: 16);
  final hexB = RegExp(r'^([0-9a-f]+)h$').firstMatch(t);
  if (hexB != null) return int.tryParse(hexB.group(1)!, radix: 16);
  if (RegExp(r'^[0-9]+$').hasMatch(t)) return int.tryParse(t);
  return null;
}

/// Nombre suivi d'une précision sans chiffre : « 443/tcp », « 443 (HTTPS) », « 64 (Linux) ».
/// Une liste de plusieurs nombres (« 64 ou 128 ») reste refusée.
int? parseNumberAnswer(String s) {
  final n = parseFlexibleInt(s);
  if (n != null) return n;
  final m = RegExp(r'^(0x[0-9a-f]+|[0-9]+)\s*(/\s*(tcp|udp)|\([^0-9()]*\))$')
      .firstMatch(normalizeAnswer(s));
  return m == null ? null : parseFlexibleInt(m.group(1)!);
}

/// Valeur hexadécimale (avec ou sans « 0x », espaces ignorés).
int? parseHexValue(String s) {
  var t = normalizeAnswer(s).replaceAll(' ', '');
  if (t.startsWith('0x')) t = t.substring(2);
  if (t.endsWith('h')) t = t.substring(0, t.length - 1);
  if (!RegExp(r'^[0-9a-f]{1,8}$').hasMatch(t)) return null;
  return int.parse(t, radix: 16);
}

/// Adresse IPv4 en notation décimale pointée.
List<int>? parseIpv4(String s) {
  final t = s.trim().replaceAll(' ', '');
  if (!RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(t)) return null;
  final parts = t.split('.').map(int.parse).toList();
  return parts.every((p) => p <= 255) ? parts : null;
}

/// EtherType : hexadécimal (0x0800, 0800, 800, 0800h) ou nom (IPv4, 802.1Q...).
int? parseEtherType(String s) {
  final t = normalizeAnswer(s);
  if (t.isEmpty) return null;
  if (t.contains('ipv4')) return etherTypeIpv4;
  if (t.contains('ipv6')) return 0x86dd;
  if (t.contains('arp')) return 0x0806;
  if (t.contains('802.1q') || t.contains('8021q') || t.contains('vlan')) {
    return etherTypeVlan;
  }
  final v = parseHexValue(t);
  return (v != null && v <= 0xffff) ? v : null;
}

/// Numéro de protocole IP : nombre (décimal ou 0x..) ou nom.
int? parseIpProtocol(String s) {
  final n = parseFlexibleInt(s);
  if (n != null) return n;
  for (final w in normalizeAnswer(s).split(RegExp(r'[^a-z0-9]+'))) {
    const names = {'tcp': 6, 'udp': 17, 'icmp': 1};
    final v = names[w] ?? parseFlexibleInt(w);
    if (v != null) return v;
  }
  return null;
}

/// Drapeaux TCP : noms (« SYN, ACK », « syn+ack »), notation tcpdump (« [S.] »),
/// ou valeur de l'octet (« 0x12 »). « aucun » donne 0. null si illisible.
int? parseTcpFlags(String s) {
  final raw = s.trim();
  if (raw.isEmpty) return null;
  // Notation tcpdump (« . » = ACK) ou Scapy (« A » = ACK : SA, PA, FA, RA).
  final tcpdump = RegExp(r'^\[?([SFPRUWEA.]+)\]?$').firstMatch(raw);
  if (tcpdump != null) {
    var v = 0;
    for (final ch in tcpdump.group(1)!.split('')) {
      const letters = {
        'S': tcpSyn,
        'F': tcpFin,
        'P': tcpPsh,
        'R': tcpRst,
        'U': tcpUrg,
        'E': tcpEce,
        'W': tcpCwr,
        '.': tcpAck,
        'A': tcpAck,
      };
      v |= letters[ch]!;
    }
    return v;
  }
  final t = normalizeAnswer(raw);
  final hexA = RegExp(r'^0x([0-9a-f]{1,3})$').firstMatch(t);
  if (hexA != null) return int.parse(hexA.group(1)!, radix: 16) & 0xff;
  var v = 0;
  var any = false;
  for (final w in _deaccent(t).split(RegExp(r'[^a-z]+'))) {
    // Mots de liaison ou de précision, sans effet sur la valeur.
    const fillers = {
      'et',
      'and',
      'plus',
      'drapeau',
      'drapeaux',
      'flag',
      'flags',
      'bit',
      'bits',
      'seul',
      'seule',
      'seulement',
      'uniquement',
      'only',
      'positionne',
      'positionnes',
    };
    if (w.isEmpty || fillers.contains(w)) continue;
    const words = {
      'syn': tcpSyn,
      'ack': tcpAck,
      'fin': tcpFin,
      'rst': tcpRst,
      'reset': tcpRst,
      'psh': tcpPsh,
      'push': tcpPsh,
      'urg': tcpUrg,
      'ece': tcpEce,
      'cwr': tcpCwr,
      'synack': tcpSyn | tcpAck,
      'finack': tcpFin | tcpAck,
      'pshack': tcpPsh | tcpAck,
      'rstack': tcpRst | tcpAck,
      'aucun': 0,
      'none': 0,
      'rien': 0,
    };
    final bit = words[w] ?? -1;
    if (bit < 0) return null;
    v |= bit;
    any = true;
  }
  return any ? v : null;
}

/// Oui / non : true, false ou null.
bool? parseYesNo(String s) {
  final r = _yesNo(_compact(s));
  if (r != null) return r;
  // « Oui, positionné », « non (0) » : le premier mot suffit.
  final words =
      _deaccent(s).split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty);
  return words.isEmpty ? null : _yesNo(words.first);
}

bool? _yesNo(String c) {
  if (const [
    'oui',
    'o',
    'yes',
    'y',
    'vrai',
    'true',
    '1',
    'correcte',
    'correct',
    'valide'
  ].contains(c)) {
    return true;
  }
  if (const [
    'non',
    'n',
    'no',
    'faux',
    'false',
    '0',
    'incorrecte',
    'incorrect',
    'invalide',
    'fausse'
  ].contains(c)) {
    return false;
  }
  return null;
}

/// Mots qui accompagnent un nom de service sans en désigner un autre
/// (« IMAP sur TLS », « QUIC (HTTP/3) », « HTTP alternatif »).
const Set<String> _serviceNeutralWords = {'tls', 'ssl', 'http', 'www', 'proxy'};

bool _serviceAccepts(PortService svc, String answer) {
  final c = _compact(answer);
  if (c.isEmpty) return false;
  if (svc.accepted.contains(c)) return true;
  final words = [
    for (final w in _deaccent(answer).split(RegExp(r'[^a-z0-9]+')))
      if (w.isNotEmpty) w
  ];
  // Plusieurs services proposés à la fois (« HTTP ou HTTPS ») : refusé.
  for (final w in words) {
    if (svc.accepted.contains(w) || _serviceNeutralWords.contains(w)) continue;
    if (knownServices.any((o) => o.accepted.contains(w))) return false;
  }
  return words.any(svc.accepted.contains);
}

bool? _icmpTypeFromAnswer(String s) {
  // true = Echo Request (8), false = Echo Reply (0).
  final n = parseFlexibleInt(s);
  if (n == 8) return true;
  if (n == 0) return false;
  final c = _compact(s);
  if (c.contains('request') || c.contains('requete') || c.contains('demande'))
    return true;
  if (c.contains('reply') || c.contains('reponse')) return false;
  return null;
}

// ------------------------------- Génération -------------------------------

List<int> _randomMac(TrainingRandom r) {
  // Adresse individuelle (bit I/G à 0) et universelle (bit U/L à 0).
  final m = [for (var i = 0; i < 6; i++) r.nextInt(256)];
  m[0] &= 0xfc;
  return m;
}

List<int> _privateIp(TrainingRandom r) {
  switch (r.nextInt(3)) {
    case 0:
      return [
        192,
        168,
        r.pick([0, 1, 1, 10, 50, 100]),
        r.range(2, 254)
      ];
    case 1:
      return [10, r.nextInt(256), r.nextInt(256), r.range(2, 254)];
    default:
      return [172, r.range(16, 31), r.nextInt(256), r.range(2, 254)];
  }
}

List<int> _serverIp(TrainingRandom r, List<int> client) {
  if (r.nextInt(3) == 0) {
    // Serveur du même réseau local.
    var last = r.range(1, 254);
    if (last == client[3]) last = last == 254 ? 1 : last + 1;
    return [client[0], client[1], client[2], last];
  }
  // Plages réservées à la documentation (RFC 5737).
  final base = r.pick([
    [192, 0, 2],
    [198, 51, 100],
    [203, 0, 113],
  ]);
  return [...base, r.range(1, 254)];
}

List<int> _ascii(String s) => s.codeUnits;

List<int> _randomBytes(TrainingRandom r, int n) =>
    [for (var i = 0; i < n; i++) r.nextInt(256)];

List<int> _dnsQuery(TrainingRandom r) {
  final name =
      r.pick(['example.org', 'example.com', 'tutodecode.org', 'wikipedia.org']);
  final q = <int>[
    r.nextInt(256), r.nextInt(256), // identifiant
    0x01, 0x00, // requête standard, récursion demandée
    0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 1 question
  ];
  for (final label in name.split('.')) {
    q.add(label.length);
    q.addAll(_ascii(label));
  }
  q.addAll([0x00, 0x00, 0x01, 0x00, 0x01]); // fin du nom, type A, classe IN
  return q;
}

/// Réponse DNS à une question de type A (RFC 1035) : en-tête QR=1, RD=1, RA=1,
/// 1 question, 1 réponse ; la réponse désigne le nom par un pointeur (0xc00c).
List<int> _dnsResponse(TrainingRandom r) {
  final q = _dnsQuery(r);
  q[2] = 0x81;
  q[3] = 0x80;
  q[7] = 0x01; // ANCOUNT = 1
  final ttl = r.range(60, 86400);
  return [
    ...q,
    0xc0, 0x0c, 0x00, 0x01, 0x00, 0x01, // nom (pointeur), type A, classe IN
    (ttl >> 24) & 0xff, (ttl >> 16) & 0xff, (ttl >> 8) & 0xff, ttl & 0xff,
    0x00, 0x04, 203, 0, 113, r.range(1, 254), // RDLENGTH 4, adresse (RFC 5737)
  ];
}

/// Données d'un ping Linux (iputils) : horodatage struct timeval de 16 octets (secondes
/// puis microsecondes, petit-boutiste sur x86-64), puis les octets 0x10 à 0x37.
List<int> _linuxPingData(TrainingRandom r) {
  final sec = 1700000000 + r.nextInt(100000000);
  final usec = r.nextInt(1000000);
  List<int> le64(int v) => [for (var i = 0; i < 8; i++) (v >> (8 * i)) & 0xff];
  return [...le64(sec), ...le64(usec), for (var b = 0x10; b <= 0x37; b++) b];
}

List<int> _tcpPayload(TrainingRandom r, PortService svc, bool toServer) {
  switch (svc.port) {
    case 80:
    case 8080:
      return _ascii(toServer
          ? r.pick([
              'GET / HTTP/1.1\r\n',
              'GET /index.html HTTP/1.1\r\n',
              'HEAD / HTTP/1.1\r\n'
            ])
          : r.pick([
              'HTTP/1.1 200 OK\r\n',
              'HTTP/1.1 404 Not Found\r\n',
              'HTTP/1.1 301 Moved\r\n'
            ]));
    case 22:
      return _ascii(
          r.pick(['SSH-2.0-OpenSSH_9.6\r\n', 'SSH-2.0-OpenSSH_9.9\r\n']));
    case 21:
      return _ascii(toServer ? 'USER anonymous\r\n' : '220 FTP ready\r\n');
    case 25:
    case 587:
      return _ascii(
          toServer ? 'EHLO client.example\r\n' : '220 mail.example ESMTP\r\n');
    case 110:
      return _ascii(toServer ? 'USER eleve\r\n' : '+OK POP3 ready\r\n');
    case 143:
      return _ascii(
          toServer ? 'a1 CAPABILITY\r\n' : '* OK IMAP4rev1 ready\r\n');
    case 443:
    case 993:
      // Enregistrement TLS « application data » (type 0x17, version 0x0303).
      final n = r.range(8, 20);
      return [0x17, 0x03, 0x03, 0x00, n, ..._randomBytes(r, n)];
    default:
      return _randomBytes(r, r.range(6, 20));
  }
}

List<int> _udpPayload(TrainingRandom r, PortService svc, bool toServer) {
  if (svc.port == 53) return toServer ? _dnsQuery(r) : _dnsResponse(r);
  if (svc.port == 69) {
    // TFTP (RFC 1350) : demande de lecture (RRQ, opcode 1), mode « octet ».
    return [
      0x00,
      0x01,
      ..._ascii(r.pick(['boot.cfg', 'config.txt', 'pxelinux.0'])),
      0x00,
      ..._ascii('octet'),
      0x00
    ];
  }
  if (svc.port == 514) {
    // Syslog (RFC 3164) : priorité <PRI> puis le message, en texte.
    return _ascii(r.pick([
      '<13>Nov 26 10:15:02 pc1 eleve: test',
      '<34>Nov 26 10:15:02 srv su: echec',
      '<86>Nov 26 10:15:02 srv sshd: ok',
    ]));
  }
  if (svc.port == 123) {
    // En-tête NTP de 48 octets : LI=0, VN=4, Mode=3 (client) ou 4 (serveur).
    return [toServer ? 0x23 : 0x24, ...List.filled(47, 0)];
  }
  return _randomBytes(r, r.range(8, 24));
}

/// Génère un exercice complet à partir du générateur aléatoire.
PacketExercise generatePacketExercise(TrainingRandom r, PacketLevel level) {
  final adv = level != PacketLevel.debutant;
  final expert = level == PacketLevel.expert;

  final transport = (adv && r.nextInt(5) == 0)
      ? PacketTransport.icmp
      : (r.nextInt(3) == 0 ? PacketTransport.udp : PacketTransport.tcp);
  final toServer = r.nextBool();

  final client = _privateIp(r);
  final server = _serverIp(r, client);
  final srcIp = toServer ? client : server;
  final dstIp = toServer ? server : client;
  final srcMac = _randomMac(r);
  var dstMac = _randomMac(r);
  while (formatMac(dstMac) == formatMac(srcMac)) {
    dstMac = _randomMac(r);
  }

  // TTL : TTL initial du système émetteur moins le nombre de routeurs traversés.
  final initialTtl =
      (transport == PacketTransport.icmp && !toServer && r.nextInt(3) == 0)
          ? 255
          : r.pick([64, 64, 128]);
  // Même réseau local (mêmes trois premiers octets) : aucun routeur traversé. Sinon,
  // un paquet venant du serveur a traversé au moins la passerelle du client.
  final sameLan = client[0] == server[0] &&
      client[1] == server[1] &&
      client[2] == server[2];
  final hops = sameLan ? 0 : (toServer ? r.range(0, 20) : r.range(1, 20));
  final ttl = initialTtl - hops;

  // Couche 4.
  PortService? service;
  int? srcPort, dstPort, flags, tcpHeaderLen, icmpType, icmpSeq;
  List<int> payload = [];
  final l4 = <int>[];
  final protocol = protocolNumberOf(transport);

  if (transport == PacketTransport.icmp) {
    icmpType = toServer ? 8 : 0;
    final id = r.nextInt(65536);
    icmpSeq = r.nextInt(65536);
    payload = initialTtl == 128
        ? _ascii(
            'abcdefghijklmnopqrstuvwabcdefghi') // ping de Windows : 32 octets
        : _linuxPingData(r); // ping de Linux : 56 octets
    l4.addAll([
      icmpType,
      0,
      0,
      0,
      id >> 8,
      id & 0xff,
      icmpSeq >> 8,
      icmpSeq & 0xff,
      ...payload
    ]);
    final c = internetChecksum(l4);
    l4[2] = c >> 8;
    l4[3] = c & 0xff;
  } else {
    final candidates = knownServices
        .where((s) =>
            s.transport == transport &&
            (adv || !(s.port == 443 && s.transport == PacketTransport.udp)) &&
            // Syslog est à sens unique ; un serveur TFTP répond depuis un autre port
            // que 69 (RFC 1350, TID) : ces deux services ne sont tirés que vers le serveur.
            (toServer || !(s.port == 514 || s.port == 69)))
        .toList();
    final svc = r.pick(candidates);
    service = svc;
    final ephemeral = r.range(49152, 65535);
    final sp = toServer ? ephemeral : svc.port;
    final dp = toServer ? svc.port : ephemeral;
    srcPort = sp;
    dstPort = dp;

    if (transport == PacketTransport.tcp) {
      final choices = toServer
          ? [
              tcpSyn,
              tcpAck,
              tcpPsh | tcpAck,
              tcpFin | tcpAck,
              tcpRst,
              tcpRst | tcpAck
            ]
          : [
              tcpSyn | tcpAck,
              tcpAck,
              tcpPsh | tcpAck,
              tcpFin | tcpAck,
              tcpRst | tcpAck
            ];
      if (expert) {
        // Négociation ECN (RFC 3168) : SYN+ECE+CWR puis SYN+ACK+ECE.
        choices.add(
            toServer ? (tcpSyn | tcpEce | tcpCwr) : (tcpSyn | tcpAck | tcpEce));
      }
      final fl = r.pick(choices);
      flags = fl;
      if (fl & tcpPsh != 0) payload = _tcpPayload(r, svc, toServer);
      final withMss = adv && (fl & tcpSyn != 0);
      final hl = withMss ? 24 : 20;
      tcpHeaderLen = hl;
      final seq = r.nextInt(1 << 32);
      final ack = (fl & tcpAck != 0) ? r.range(1, (1 << 32) - 1) : 0;
      final window = (fl & tcpRst != 0)
          ? 0
          : r.pick([64240, 65535, 29200, 502, 2052, 8192]);
      l4.addAll([
        sp >> 8, sp & 0xff, dp >> 8, dp & 0xff,
        (seq >> 24) & 0xff, (seq >> 16) & 0xff, (seq >> 8) & 0xff, seq & 0xff,
        (ack >> 24) & 0xff, (ack >> 16) & 0xff, (ack >> 8) & 0xff, ack & 0xff,
        (hl ~/ 4) << 4, fl,
        window >> 8, window & 0xff,
        0, 0, // somme de contrôle, calculée plus bas
        0, 0, // pointeur urgent
        if (withMss) ...[0x02, 0x04, 0x05, 0xb4], // option MSS = 1460
        ...payload,
      ]);
      final c = transportChecksum(srcIp, dstIp, 6, l4);
      l4[16] = c >> 8;
      l4[17] = c & 0xff;
    } else {
      payload = _udpPayload(r, svc, toServer);
      final len = 8 + payload.length;
      l4.addAll([
        sp >> 8,
        sp & 0xff,
        dp >> 8,
        dp & 0xff,
        len >> 8,
        len & 0xff,
        0,
        0,
        ...payload,
      ]);
      var c = transportChecksum(srcIp, dstIp, 17, l4);
      if (c == 0) c = 0xffff; // RFC 768 : 0 signifie « pas de somme »
      l4[6] = c >> 8;
      l4[7] = c & 0xff;
    }
  }

  // En-tête IPv4 (RFC 791), sans option : IHL = 5.
  final totalLength = 20 + l4.length;
  final identification = r.nextInt(65536);
  final df =
      transport == PacketTransport.tcp ? r.nextInt(4) != 0 : r.nextBool();
  final tos = r.pick([0x00, 0x00, 0x00, 0x10, 0x28, 0xb8]);
  final ip = <int>[
    0x45,
    tos,
    totalLength >> 8,
    totalLength & 0xff,
    identification >> 8,
    identification & 0xff,
    df ? 0x40 : 0x00,
    0x00,
    ttl,
    protocol,
    0,
    0,
    ...srcIp,
    ...dstIp,
  ];
  final expected = internetChecksum(ip);
  var actual = expected;
  if (expert && r.nextBool()) {
    // Somme volontairement fausse : l'élève doit la recalculer.
    actual = (expected + r.range(1, 0xfffe)) & 0xffff;
  }
  ip[10] = actual >> 8;
  ip[11] = actual & 0xff;

  // Trame Ethernet II, éventuellement étiquetée 802.1Q.
  int? vlanId;
  final frame = <int>[...dstMac, ...srcMac];
  if (adv && r.nextInt(10) < 3) {
    vlanId = r.range(2, 4094);
    final pcp = r.pick([0, 0, 0, 3, 5]);
    final tci = (pcp << 13) | vlanId;
    frame.addAll([0x81, 0x00, tci >> 8, tci & 0xff]);
  }
  frame.addAll([0x08, 0x00]);
  final ipOffset = frame.length;
  frame.addAll(ip);
  final l4Offset = frame.length;
  frame.addAll(l4);

  // Bourrage : une trame Ethernet fait au moins 64 octets FCS comprise, donc 60 sans
  // la FCS (que les captures n'affichent pas). Montré à partir du niveau avancé.
  var padding = 0;
  if (adv && frame.length < 60) {
    padding = 60 - frame.length;
    frame.addAll(List.filled(padding, 0));
  }

  return PacketExercise(
    level: level,
    bytes: List.unmodifiable(frame),
    transport: transport,
    dstMac: dstMac,
    srcMac: srcMac,
    vlanId: vlanId,
    ipOffset: ipOffset,
    l4Offset: l4Offset,
    srcIp: srcIp,
    dstIp: dstIp,
    ttl: ttl,
    initialTtl: initialTtl,
    totalLength: totalLength,
    identification: identification,
    dontFragment: df,
    ipChecksum: actual,
    ipChecksumExpected: expected,
    srcPort: srcPort,
    dstPort: dstPort,
    tcpFlags: flags,
    tcpHeaderLength: tcpHeaderLen,
    service: service,
    icmpType: icmpType,
    icmpSequence: icmpSeq,
    payloadLength: payload.length,
    paddingLength: padding,
    toServer: toServer,
  );
}

// ------------------------------- Explications -------------------------------

String _ord(int n) => n == 1 ? '1er' : '${n}e';

String _where(int off) =>
    'ligne 0x${hex4(off & ~0xf)}, ${_ord((off & 0xf) + 1)} octet de la ligne';

String _at(int off) => 'octet $off (0x${hex4(off)} ; ${_where(off)})';

String _range(int start, int len) => 'octets $start à ${start + len - 1} '
    '(0x${hex4(start)} à 0x${hex4(start + len - 1)} ; début : ${_where(start)})';

String _bytesHex(List<int> b, int start, int len) =>
    [for (var i = 0; i < len; i++) hex2(b[start + i])].join(' ');

String _byteToDec(int b) => '0x${hex2(b)} = ${b >> 4}×16 + ${b & 0xf} = $b';

String _wordToDec(int hi, int lo) {
  final v = (hi << 8) | lo;
  return '0x${hex4(v)} = 0x${hex2(hi)}×256 + 0x${hex2(lo)} = $hi×256 + $lo = $v';
}

String _bin8(int b) {
  final s = b.toRadixString(2).padLeft(8, '0');
  return '${s.substring(0, 4)} ${s.substring(4)}';
}

String _bin16(int v) {
  final s = v.toRadixString(2).padLeft(16, '0');
  return [for (var i = 0; i < 16; i += 4) s.substring(i, i + 4)].join(' ');
}

String _ttlOs(int initial) {
  if (initial == 64) return 'Linux, macOS, Android, iOS';
  if (initial == 128) return 'Windows';
  return 'équipement réseau (routeur, commutateur)';
}

List<PacketQuestion> _buildQuestions(PacketExercise ex) {
  final b = ex.bytes;
  final e = ex.ipOffset;
  final t = ex.l4Offset;
  final adv = ex.level != PacketLevel.debutant;
  final expert = ex.level == PacketLevel.expert;
  final qs = <PacketQuestion>[];

  qs.add(PacketQuestion(
    id: 'dstMac',
    label: 'MAC destination',
    hint: 'ex. 00:1a:2b:3c:4d:5e',
    expected: formatMac(ex.dstMac),
    accepts: (a) => parseMac(a) == ex.dstMac.map(hex2).join(),
    method: '${_range(0, 6)} : ${_bytesHex(b, 0, 6)}.\n'
        'Une trame Ethernet II commence toujours par l\'adresse de destination (6 octets), '
        'ce qui permet à la carte réseau de savoir tout de suite si la trame la concerne.\n'
        'On l\'écrit en hexadécimal, octets séparés par « : » -> ${formatMac(ex.dstMac)}.',
  ));
  qs.add(PacketQuestion(
    id: 'srcMac',
    label: 'MAC source',
    hint: 'ex. 00:1a:2b:3c:4d:5e',
    expected: formatMac(ex.srcMac),
    accepts: (a) => parseMac(a) == ex.srcMac.map(hex2).join(),
    method: '${_range(6, 6)} : ${_bytesHex(b, 6, 6)}.\n'
        'Les 6 octets suivants sont l\'adresse de l\'émetteur -> ${formatMac(ex.srcMac)}.\n'
        'Attention au piège classique : la destination vient AVANT la source.',
  ));

  if (ex.vlanId != null) {
    final tci = (b[14] << 8) | b[15];
    qs.add(PacketQuestion(
      id: 'tpid',
      label: 'Type aux octets 12-13 (hex)',
      hint: 'ex. 0x0800',
      expected: '0x8100',
      accepts: (a) => parseEtherType(a) == etherTypeVlan,
      method: '${_range(12, 2)} : ${_bytesHex(b, 12, 2)} -> 0x8100.\n'
          '0x8100 n\'est pas un protocole de couche 3 : c\'est le TPID d\'une étiquette '
          'IEEE 802.1Q (VLAN). L\'étiquette fait 4 octets : TPID (2) puis TCI (2), '
          'et le vrai EtherType vient juste après. Tout le reste de la trame est décalé de 4 octets.',
    ));
    qs.add(PacketQuestion(
      id: 'vlan',
      label: 'Numéro de VLAN (décimal)',
      hint: 'ex. 10',
      expected: '${ex.vlanId}',
      accepts: (a) => parseNumberAnswer(a) == ex.vlanId,
      method:
          '${_range(14, 2)} : TCI = 0x${hex4(tci)} = ${_bin16(tci)} en binaire.\n'
          'Le TCI contient PCP (3 bits de priorité = ${tci >> 13}), DEI (1 bit = ${(tci >> 12) & 1}) '
          'puis le VLAN ID sur les 12 bits de poids faible.\n'
          'VLAN ID = 0x${hex4(tci)} ET 0x0fff = 0x${hex4(tci & 0xfff)} = '
          '${(tci & 0xfff) >> 8}×256 + ${tci & 0xff} = ${ex.vlanId}.',
    ));
  }

  qs.add(PacketQuestion(
    id: 'etherType',
    label: ex.vlanId != null ? 'EtherType encapsulé (hex)' : 'EtherType (hex)',
    hint: 'ex. 0x0806',
    expected: '0x0800 (IPv4)',
    accepts: (a) => parseEtherType(a) == etherTypeIpv4,
    method:
        '${_range(e - 2, 2)} : ${_bytesHex(b, e - 2, 2)} -> 0x0800 = IPv4.\n'
        'L\'EtherType indique ce que transporte la trame : 0x0800 IPv4, 0x86dd IPv6, '
        '0x0806 ARP, 0x8100 étiquette VLAN. Une valeur ≥ 0x0600 (1536) est un EtherType ; '
        'une valeur ≤ 0x05dc (1500) serait la longueur des données d\'une trame IEEE 802.3.',
  ));

  final ipHdr =
      'L\'en-tête IPv4 commence à l\'octet $e (0x${hex4(e)}), juste après l\'EtherType ; '
      'octet $e = 0x${hex2(b[e])} : version ${b[e] >> 4}, IHL ${b[e] & 0xf} -> '
      '${b[e] & 0xf}×4 = ${ex.ipHeaderLength} octets d\'en-tête.';

  String ipMethod(int off, List<int> ip, String role) => '$ipHdr\n'
      'L\'adresse $role est à E+${off - e} : ${_range(off, 4)} : ${_bytesHex(b, off, 4)}.\n'
      'Chaque octet se convertit en décimal : '
      '${[
        for (var i = 0; i < 4; i++) '0x${hex2(ip[i])} = ${ip[i]}'
      ].join(', ')} '
      '-> ${formatIp(ip)}.';

  qs.add(PacketQuestion(
    id: 'srcIp',
    label: 'IP source',
    hint: 'ex. 192.168.1.10',
    expected: formatIp(ex.srcIp),
    accepts: (a) => parseIpv4(a)?.join('.') == formatIp(ex.srcIp),
    method: ipMethod(e + 12, ex.srcIp, 'source'),
  ));
  qs.add(PacketQuestion(
    id: 'dstIp',
    label: 'IP destination',
    hint: 'ex. 203.0.113.5',
    expected: formatIp(ex.dstIp),
    accepts: (a) => parseIpv4(a)?.join('.') == formatIp(ex.dstIp),
    method: ipMethod(e + 16, ex.dstIp, 'destination'),
  ));
  qs.add(PacketQuestion(
    id: 'ttl',
    label: 'TTL (décimal)',
    hint: 'ex. 64',
    expected: '${ex.ttl}',
    accepts: (a) => parseNumberAnswer(a) == ex.ttl,
    method: 'TTL = 9e octet de l\'en-tête IP (E+8) : ${_at(e + 8)}.\n'
        '${_byteToDec(b[e + 8])}.\n'
        'Chaque routeur décrémente le TTL de 1 ; à 0, le paquet est détruit '
        '(c\'est ce qu\'exploite traceroute).',
  ));
  if (adv) {
    qs.add(PacketQuestion(
      id: 'initialTtl',
      label: 'TTL initial probable',
      hint: '64, 128 ou 255',
      expected: '${ex.initialTtl}',
      accepts: (a) => parseNumberAnswer(a) == ex.initialTtl,
      method:
          'Les systèmes partent d\'un TTL fixe : 64 (Linux, macOS, Android, iOS), '
          '128 (Windows), 255 (équipements réseau).\n'
          'On prend la plus petite de ces valeurs supérieure ou égale au TTL observé (${ex.ttl}) : '
          '${ex.initialTtl}, soit ${ex.initialTtl - ex.ttl} routeur(s) traversé(s). '
          'Émetteur probable : ${_ttlOs(ex.initialTtl)}. C\'est une indication, pas une preuve '
          '(le TTL initial se règle).',
    ));
  }
  qs.add(PacketQuestion(
    id: 'protocol',
    label: 'Protocole (numéro)',
    hint: 'ex. 17',
    expected: '${ex.protocolNumber} (${ex.transportName})',
    accepts: (a) => parseIpProtocol(a) == ex.protocolNumber,
    method: 'Protocole = 10e octet de l\'en-tête IP (E+9) : ${_at(e + 9)}.\n'
        '${_byteToDec(b[e + 9])} -> ${ex.transportName}.\n'
        'Numéros à connaître (registre IANA) : 1 ICMP, 6 TCP, 17 UDP.',
  ));

  if (adv) {
    qs.add(PacketQuestion(
      id: 'totalLength',
      label: 'Longueur totale IP (octets)',
      hint: 'ex. 60',
      expected: '${ex.totalLength}',
      accepts: (a) => parseNumberAnswer(a) == ex.totalLength,
      method: 'Longueur totale = E+2 et E+3 : ${_range(e + 2, 2)}.\n'
          '${_wordToDec(b[e + 2], b[e + 3])} octets.\n'
          'Elle compte l\'en-tête IP et ses données, mais ni l\'en-tête Ethernet ni le bourrage'
          '${ex.paddingLength > 0 ? ' (ici ${ex.paddingLength} octets de bourrage à zéro terminent la trame : '
              '${b.length} octets affichés = $e (Ethernet) + ${ex.totalLength} (IP) + ${ex.paddingLength})' : ''}.',
    ));
    final ff = (b[e + 6] << 8) | b[e + 7];
    qs.add(PacketQuestion(
      id: 'df',
      label: 'Drapeau DF positionné ? (oui/non)',
      hint: 'oui ou non',
      expected: ex.dontFragment ? 'oui' : 'non',
      accepts: (a) => parseYesNo(a) == ex.dontFragment,
      method:
          'Drapeaux et décalage de fragment = E+6 et E+7 : ${_range(e + 6, 2)} : 0x${hex4(ff)}.\n'
          'En binaire : ${_bin16(ff)}. Les 3 bits de poids fort sont : réservé (0), '
          'DF = 0x4000 (Don\'t Fragment), MF = 0x2000 (More Fragments) ; les 13 autres bits '
          'donnent le décalage.\n'
          'Ici DF = ${(ff >> 14) & 1}, MF = ${(ff >> 13) & 1}, décalage = ${ff & 0x1fff} '
          '-> ${ex.dontFragment ? 'DF positionné : le paquet ne doit pas être fragmenté' : 'DF absent : un routeur pourrait fragmenter le paquet'}.',
    ));
  }

  if (ex.transport == PacketTransport.icmp) {
    qs.add(PacketQuestion(
      id: 'icmpType',
      label: 'Type ICMP',
      hint: 'numéro ou nom',
      expected:
          '${ex.icmpType} (${ex.icmpType == 8 ? 'Echo Request' : 'Echo Reply'})',
      accepts: (a) => _icmpTypeFromAnswer(a) == (ex.icmpType == 8),
      method:
          'L\'en-tête ICMP commence après les ${ex.ipHeaderLength} octets d\'en-tête IP : '
          'octet $e + ${ex.ipHeaderLength} = $t.\n'
          'Type = 1er octet ICMP : ${_at(t)} = ${_byteToDec(b[t])}, code = 0x${hex2(b[t + 1])}.\n'
          'Type 8 = Echo Request (ping envoyé), type 0 = Echo Reply (réponse) (RFC 792).',
    ));
    qs.add(PacketQuestion(
      id: 'icmpSeq',
      label: 'Numéro de séquence ICMP (décimal)',
      hint: 'ex. 1',
      expected: '${ex.icmpSequence}',
      accepts: (a) => parseNumberAnswer(a) == ex.icmpSequence,
      method:
          'Echo ICMP : type (1), code (1), somme (2), identifiant (2), séquence (2).\n'
          'Séquence = T+6 et T+7 : ${_range(t + 6, 2)}.\n'
          '${_wordToDec(b[t + 6], b[t + 7])}.\n'
          'Comme tous les champs d\'en-tête, il est écrit octet de poids fort en premier (ordre réseau, '
          'gros-boutiste). Wireshark affiche aussi une lecture « LE » (petit-boutiste) car certains '
          'systèmes remplissent ce champ dans l\'ordre de leur processeur.',
    ));
  } else {
    final proto = ex.transportName;
    final l4Intro =
        'L\'en-tête $proto commence après les ${ex.ipHeaderLength} octets d\'en-tête IP : '
        'T = $e + ${ex.ipHeaderLength} = $t (0x${hex4(t)}).';
    qs.add(PacketQuestion(
      id: 'srcPort',
      label: 'Port source',
      hint: 'ex. 51234',
      expected: '${ex.srcPort}',
      accepts: (a) => parseNumberAnswer(a) == ex.srcPort,
      method: '$l4Intro\nPort source = T+0 et T+1 : ${_range(t, 2)}.\n'
          '${_wordToDec(b[t], b[t + 1])}.',
    ));
    qs.add(PacketQuestion(
      id: 'dstPort',
      label: 'Port destination',
      hint: 'ex. 443',
      expected: '${ex.dstPort}',
      accepts: (a) => parseNumberAnswer(a) == ex.dstPort,
      method: 'Port destination = T+2 et T+3 : ${_range(t + 2, 2)}.\n'
          '${_wordToDec(b[t + 2], b[t + 3])}.\n'
          'Les ports sont sur 16 bits, octet de poids fort en premier (ordre réseau).',
    ));

    if (ex.transport == PacketTransport.tcp) {
      final f = ex.tcpFlags!;
      final bits = [
        for (final n in _flagBits.reversed)
          if (f & n != 0) '0x${hex2(n)} ${_flagName[n]}'
      ];
      qs.add(PacketQuestion(
        id: 'flags',
        label: 'Drapeaux TCP',
        hint: 'ex. SYN, ACK',
        expected: tcpFlagsToText(f),
        accepts: (a) => parseTcpFlags(a) == f,
        method:
            'Les drapeaux sont dans le 14e octet de l\'en-tête TCP (T+13) : ${_at(t + 13)} = 0x${hex2(f)}.\n'
            'En binaire : ${_bin8(f)}. De gauche à droite : CWR ECE URG ACK PSH RST SYN FIN '
            '(valeurs 0x80 0x40 0x20 0x10 0x08 0x04 0x02 0x01).\n'
            'Bits à 1 : ${bits.join(' + ')} = 0x${hex2(f)} -> ${tcpFlagsToText(f)} '
            '(tcpdump : ${tcpFlagsToTcpdump(f)}).\n'
            '${_flagsMeaning(f)}',
      ));
    }

    final svc = ex.service!;
    final clientPort = ex.toServer ? ex.srcPort! : ex.dstPort!;
    qs.add(PacketQuestion(
      id: 'service',
      label: 'Service probable',
      hint: 'ex. DNS',
      expected: svc.name,
      accepts: (a) => _serviceAccepts(svc, a),
      method:
          'Ports : ${ex.srcPort} -> ${ex.dstPort}. Le port $clientPort est éphémère '
          '(49152 à 65535, choisi au hasard par le client) ; l\'autre, ${svc.port}, est le port '
          'du serveur, attribué par l\'IANA.\n'
          '${svc.port}/$proto = ${svc.name}. Le paquet va '
          '${ex.toServer ? 'du client vers le serveur (port de destination bien connu)' : 'du serveur vers le client (port source bien connu : c\'est une réponse)'}.\n'
          'Le port ne prouve rien : n\'importe quel service peut écouter sur n\'importe quel port ; '
          'seul le contenu le confirme.',
    ));

    if (adv) {
      final String calc;
      if (ex.transport == PacketTransport.tcp) {
        final doff = b[t + 12];
        calc =
            'Data offset = quartet haut de T+12 : ${_at(t + 12)} = 0x${hex2(doff)} '
            '-> ${doff >> 4} mots de 32 bits = ${doff >> 4}×4 = ${ex.tcpHeaderLength} octets d\'en-tête TCP'
            '${ex.tcpHeaderLength! > 20 ? ' (20 + 4 octets d\'options : MSS = 0x05b4 = 1460)' : ''}.\n'
            'Données = longueur totale IP - en-tête IP - en-tête TCP = '
            '${ex.totalLength} - ${ex.ipHeaderLength} - ${ex.tcpHeaderLength} = ${ex.payloadLength}.';
      } else {
        final ul = (b[t + 4] << 8) | b[t + 5];
        calc =
            'Longueur UDP = T+4 et T+5 : ${_range(t + 4, 2)} = ${_wordToDec(b[t + 4], b[t + 5])} '
            '(en-tête de 8 octets compris).\n'
            'Données = $ul - 8 = ${ex.payloadLength}. '
            'Vérification : longueur totale IP - en-tête IP = ${ex.totalLength} - ${ex.ipHeaderLength} = '
            '${ex.totalLength - ex.ipHeaderLength} = longueur UDP.';
      }
      qs.add(PacketQuestion(
        id: 'payload',
        label: 'Octets de données applicatives',
        hint: 'ex. 0',
        expected: '${ex.payloadLength}',
        accepts: (a) => parseNumberAnswer(a) == ex.payloadLength,
        method: '$calc\n'
            'Ne pas compter les octets jusqu\'à la fin de la trame : '
            '${ex.paddingLength > 0 ? 'les ${ex.paddingLength} derniers octets sont du bourrage Ethernet.' : 'un éventuel bourrage Ethernet n\'en fait pas partie.'}',
      ));
    }
  }

  if (expert) {
    final words = <int>[
      for (var i = 0; i < 20; i += 2)
        (i == 10) ? 0 : (b[e + i] << 8) | b[e + i + 1]
    ];
    var sum = words.fold<int>(0, (s, w) => s + w);
    final steps = <String>['Somme = 0x${sum.toRadixString(16)}'];
    while (sum >> 16 != 0) {
      final folded = (sum & 0xffff) + (sum >> 16);
      steps.add(
          'report de la retenue : 0x${hex4(sum & 0xffff)} + 0x${(sum >> 16).toRadixString(16)} '
          '= 0x${folded.toRadixString(16)}');
      sum = folded;
    }
    final method =
        'Somme de contrôle IP (RFC 1071), sur les ${ex.ipHeaderLength} octets d\'en-tête '
        '(${_range(e, ex.ipHeaderLength)}).\n'
        '1. Découper l\'en-tête en mots de 16 bits, en remplaçant le champ somme (E+10, E+11) par 0000 :\n'
        '   ${words.map(hex4).join(' + ')}\n'
        '2. ${steps.join(' ; ')}.\n'
        '3. Complément à un (inverser tous les bits) : NON 0x${hex4(sum)} = 0x${hex4(ex.ipChecksumExpected)}.\n'
        'Somme présente dans la trame (${_range(e + 10, 2)}) : 0x${hex4(ex.ipChecksum)} -> '
        '${ex.ipChecksumValid ? 'identique : l\'en-tête est intact.' : 'différente : un routeur ou une carte réseau jetterait ce paquet.'}\n'
        'Astuce : en additionnant les 10 mots AVEC la somme reçue puis en reportant les retenues, '
        'un en-tête correct donne 0xffff.';
    qs.add(PacketQuestion(
      id: 'checksum',
      label: 'Somme de contrôle IP correcte (hex)',
      hint: 'ex. 0xb1e6',
      expected: '0x${hex4(ex.ipChecksumExpected)}',
      accepts: (a) => parseHexValue(a) == ex.ipChecksumExpected,
      method: method,
    ));
    qs.add(PacketQuestion(
      id: 'checksumOk',
      label: 'La somme reçue est-elle correcte ? (oui/non)',
      hint: 'oui ou non',
      expected: ex.ipChecksumValid ? 'oui' : 'non',
      accepts: (a) => parseYesNo(a) == ex.ipChecksumValid,
      method:
          'Comparer la somme calculée (0x${hex4(ex.ipChecksumExpected)}) à celle de la trame '
          '(0x${hex4(ex.ipChecksum)}, ${_range(e + 10, 2)}).',
    ));
  }
  return qs;
}

String _flagsMeaning(int f) {
  if (f & tcpRst != 0) {
    return 'RST : la connexion est refusée ou coupée net (port fermé, ou abandon).';
  }
  if (f & tcpSyn != 0 && f & tcpAck != 0) {
    return 'SYN + ACK : 2e étape de la poignée de main en trois temps (le serveur accepte).'
        '${f & tcpEce != 0 ? ' ECE ici : le serveur accepte ECN (RFC 3168).' : ''}';
  }
  if (f & tcpSyn != 0) {
    return 'SYN seul : 1re étape de la poignée de main (le client demande l\'ouverture).'
        '${f & tcpEce != 0 ? ' ECE + CWR : le client propose ECN (RFC 3168).' : ''}';
  }
  if (f & tcpFin != 0)
    return 'FIN : l\'émetteur n\'a plus rien à envoyer (fermeture).';
  if (f & tcpPsh != 0)
    return 'PSH + ACK : segment de données à remettre tout de suite à l\'application.';
  return 'ACK seul : acquittement (ou 3e étape de la poignée de main).';
}

/// Résultat champ par champ (true = juste).
Map<String, bool> gradePacketAnswers(
        PacketExercise ex, Map<String, String> answers) =>
    {
      for (final q in ex.questions) q.id: q.accepts(answers[q.id] ?? ''),
    };

/// Vérifie toutes les réponses et construit la correction pas à pas.
TrainingCheck checkPacketExercise(
    PacketExercise ex, Map<String, String> answers) {
  final grades = gradePacketAnswers(ex, answers);
  final ok = grades.values.where((v) => v).length;
  final all = ok == ex.questions.length;
  final out = StringBuffer()
    ..writeln('$ok / ${ex.questions.length} réponses justes.')
    ..writeln()
    ..writeln('Paquet : ${ex.summary}')
    ..writeln()
    ..writeln(
        'Plan de la trame (E = début IP = octet ${ex.ipOffset}, T = début ${ex.transportName} = octet ${ex.l4Offset}) :')
    ..writeln(ex.structure)
    ..writeln()
    ..writeln(
        'Pour lire une position : l\'offset en début de ligne est celui du 1er octet de la ligne ; '
        'chaque ligne contient 16 octets. L\'octet 0x0026 est donc sur la ligne 0x0020, 7e octet.');
  var n = 0;
  for (final q in ex.questions) {
    n++;
    final given = (answers[q.id] ?? '').trim();
    out
      ..writeln()
      ..writeln('$n. ${q.label} : ${grades[q.id]! ? 'juste' : 'à revoir'} '
          '(attendu : ${q.expected}${grades[q.id]! || given.isEmpty ? '' : ' ; ta réponse : $given'}'
          '${given.isEmpty && !grades[q.id]! ? ' ; pas de réponse' : ''})')
      ..writeln(q.method.split('\n').map((l) => '   $l').join('\n'));
  }
  return TrainingCheck(all, out.toString().trimRight());
}

/// Aide-mémoire des en-têtes (positions relatives).
const String packetCheatSheet = '''
Ethernet II   0-5 MAC destination | 6-11 MAC source | 12-13 EtherType
              (0x0800 IPv4, 0x86dd IPv6, 0x0806 ARP ; 0x8100 = étiquette VLAN de
              4 octets, l'EtherType réel passe alors en 16-17)
IPv4  (E)     E+0 version (4 bits) + IHL (4 bits, ×4 octets) | E+1 DSCP/ECN
              E+2-3 longueur totale | E+4-5 identification | E+6-7 DF/MF + décalage
              E+8 TTL | E+9 protocole (1 ICMP, 6 TCP, 17 UDP) | E+10-11 somme
              E+12-15 IP source | E+16-19 IP destination
TCP   (T = E + IHL×4)
              T+0-1 port source | T+2-3 port destination | T+4-7 séquence
              T+8-11 acquittement | T+12 data offset (4 bits, ×4) | T+13 drapeaux
              T+14-15 fenêtre | T+16-17 somme | T+18-19 pointeur urgent
              drapeaux : CWR 80  ECE 40  URG 20  ACK 10  PSH 08  RST 04  SYN 02  FIN 01
UDP           T+0-1 port source | T+2-3 port destination | T+4-5 longueur | T+6-7 somme
ICMP echo     T+0 type (8 requête, 0 réponse) | T+1 code | T+2-3 somme
              T+4-5 identifiant | T+6-7 séquence
Conversion    0xAB = A×16 + B ; 0xABCD = 0xAB×256 + 0xCD
              (A=10, B=11, C=12, D=13, E=14, F=15)''';

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

class PacketDecoderTrainer extends StatefulWidget {
  const PacketDecoderTrainer({super.key});

  @override
  State<PacketDecoderTrainer> createState() => _PacketDecoderTrainerState();
}

class _PacketDecoderTrainerState extends State<PacketDecoderTrainer> {
  final TrainingRandom _random = TrainingRandom();
  PacketLevel _level = PacketLevel.debutant;
  DumpStyle _style = DumpStyle.wireshark;
  late PacketExercise _exercise;
  final Map<String, TextEditingController> _controllers = {};
  Map<String, bool>? _grades;
  TrainingCheck? _result;
  bool _counted = false;
  bool _showCheatSheet = false;
  int _score = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _newExercise();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _newExercise() {
    // Les contrôleurs sont réutilisés (un par identifiant de question) et seulement
    // vidés : en libérer un pendant qu'un champ affiché l'utilise encore est une erreur.
    for (final c in _controllers.values) {
      c.clear();
    }
    _exercise = generatePacketExercise(_random, _level);
    for (final q in _exercise.questions) {
      _controllers.putIfAbsent(q.id, TextEditingController.new);
    }
    _grades = null;
    _result = null;
    _counted = false;
  }

  void _check() {
    final answers = {
      for (final q in _exercise.questions) q.id: _controllers[q.id]!.text
    };
    final result = checkPacketExercise(_exercise, answers);
    setState(() {
      _grades = gradePacketAnswers(_exercise, answers);
      _result = result;
      if (!_counted) {
        // Seule la première vérification d'un exercice compte dans le score.
        _counted = true;
        _attempts++;
        if (result.correct) _score++;
      }
    });
  }

  Widget _chip<T>(String label, T value, T group, ValueChanged<T> onSelected) {
    final selected = value == group;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: TdcColors.accentDim,
      backgroundColor: TdcColors.surfaceAlt,
      side: BorderSide(color: selected ? TdcColors.accent : TdcColors.border),
      labelStyle: TextStyle(
          color: selected ? TdcColors.accent : TdcColors.textSecondary,
          fontSize: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ex = _exercise;
    final questions = ex.questions;
    final styleName =
        _style == DumpStyle.wireshark ? 'Wireshark' : 'tcpdump -XX';
    return TrainingFrame(
      title: 'Décoder une trame',
      subtitle: 'Ethernet II, IPv4, TCP / UDP / ICMP en hexadécimal',
      icon: Icons.lan_outlined,
      instruction:
          'Voici une trame capturée sur le réseau, affichée comme dans $styleName : '
          'à gauche l\'offset (en hexadécimal) du premier octet de chaque ligne, puis 16 octets, '
          'puis leur traduction ASCII. Décode les champs demandés.\n'
          'Niveau ${_level.label.toLowerCase()} : ${questions.length} questions.',
      onCheck: _check,
      onNext: () => setState(_newExercise),
      result: _result,
      score: _score,
      attempts: _attempts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final l in PacketLevel.values)
                _chip(l.label, l, _level, (v) {
                  setState(() {
                    _level = v;
                    _newExercise();
                  });
                }),
              const SizedBox(width: 12),
              _chip('Wireshark', DumpStyle.wireshark, _style,
                  (v) => setState(() => _style = v)),
              _chip('tcpdump -XX', DumpStyle.tcpdump, _style,
                  (v) => setState(() => _style = v)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 560),
              child: IntrinsicWidth(child: TrainingCode(ex.dump(_style))),
            ),
          ),
          const SizedBox(height: 4),
          Text(
              '${ex.bytes.length} octets affichés (sans la FCS, que les captures ne montrent pas).',
              style: const TextStyle(color: TdcColors.textMuted, fontSize: 12)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _showCheatSheet = !_showCheatSheet),
              icon: Icon(
                  _showCheatSheet ? Icons.expand_less : Icons.expand_more,
                  size: 18),
              label: Text(_showCheatSheet
                  ? 'Masquer l\'aide-mémoire des en-têtes'
                  : 'Afficher l\'aide-mémoire des en-têtes'),
            ),
          ),
          if (_showCheatSheet) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 560),
                child:
                    const IntrinsicWidth(child: TrainingCode(packetCheatSheet)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final twoCols = constraints.maxWidth >= 560;
            final w = twoCols
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              children: [
                for (var i = 0; i < questions.length; i++)
                  SizedBox(
                    width: w,
                    child: TrainingField(
                      label: questions[i].label,
                      hint: questions[i].hint,
                      controller: _controllers[questions[i].id]!,
                      state: _grades?[questions[i].id],
                      onSubmitted:
                          i == questions.length - 1 ? (_) => _check() : null,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
