// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
//
// Entraînement « Tables de routage » : lire une table (format Linux « ip route » ou
// Windows « route print »), appliquer la règle du préfixe le plus long, puis trouver
// la route statique qui manque pour qu'un ping passe entre deux réseaux.
//
// La logique (génération, recherche de route, simulation d'un ping, vérification) est
// séparée du widget et testable sans interface.
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/training/training_kit.dart';

// ---------------------------------------------------------------------------
// Adresses IPv4 (entiers 0..2^32-1, calculs sûrs aussi sur le web)
// ---------------------------------------------------------------------------

int _pow2(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 2;
  }
  return v;
}

/// Masque d'un préfixe (/0 à /32) sous forme d'entier.
int prefixMask(int prefix) =>
    prefix <= 0 ? 0 : (_pow2(32) - _pow2(32 - prefix));

/// Adresse réseau : adresse ET masque. Mettre à 0 les (32 - préfixe) bits de droite
/// revient à retirer le reste de la division par 2^(32 - préfixe) ; ce calcul
/// arithmétique reste exact au-delà de 2^31 (le « & » serait signé sur 32 bits en web).
int networkOf(int ip, int prefix) {
  if (prefix <= 0) return 0;
  return ip - ip % _pow2(32 - prefix);
}

/// Adresse de diffusion d'un réseau.
int broadcastOf(int network, int prefix) => network + _pow2(32 - prefix) - 1;

int ipOf(int a, int b, int c, int d) => a * 16777216 + b * 65536 + c * 256 + d;

List<int> ipOctets(int ip) => [
      (ip ~/ 16777216) % 256,
      (ip ~/ 65536) % 256,
      (ip ~/ 256) % 256,
      ip % 256,
    ];

String ipToString(int ip) => ipOctets(ip).join('.');

final RegExp _ipRe = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

/// Lit une adresse IPv4 pointée ; null si invalide.
int? parseIpv4(String s) {
  final m = _ipRe.firstMatch(s.trim());
  if (m == null) return null;
  final o = [for (var i = 1; i <= 4; i++) int.parse(m.group(i)!)];
  if (o.any((x) => x > 255)) return null;
  return ipOf(o[0], o[1], o[2], o[3]);
}

/// Longueur de préfixe d'un masque pointé ; null si le masque n'est pas contigu.
int? prefixFromMask(int mask) {
  for (var p = 0; p <= 32; p++) {
    if (prefixMask(p) == mask) return p;
  }
  return null;
}

String cidr(int network, int prefix) => '${ipToString(network)}/$prefix';

String _bin8(int v) => v.toRadixString(2).padLeft(8, '0');

// ---------------------------------------------------------------------------
// Modèle : interfaces, routes, recherche du préfixe le plus long
// ---------------------------------------------------------------------------

enum RoutingMode { debutant, avance, routeManquante }

enum RoutingOs { linux, windows }

enum RouteOrigin { connected, local, staticRoute, loopback }

class NetIface {
  const NetIface(this.name, this.ip, this.prefix);
  final String name;
  final int ip;
  final int prefix;

  int get network => networkOf(ip, prefix);
  bool contains(int a) => networkOf(a, prefix) == network;
  String get cidrText => cidr(network, prefix);
}

class RouteEntry {
  const RouteEntry({
    required this.network,
    required this.prefix,
    this.gateway,
    required this.iface,
    this.metric = 0,
    this.origin = RouteOrigin.staticRoute,
  });

  final int network;
  final int prefix;

  /// null : réseau directement connecté (pas de passerelle).
  final int? gateway;
  final String iface;
  final int metric;
  final RouteOrigin origin;

  bool get isDefault => prefix == 0;
  bool matches(int dest) => networkOf(dest, prefix) == network;

  String get destText =>
      isDefault ? 'default (0.0.0.0/0)' : cidr(network, prefix);
}

class RouteLookup {
  const RouteLookup(this.matches, this.chosen);

  /// Routes qui correspondent, triées : préfixe le plus long d'abord, puis métrique.
  final List<RouteEntry> matches;
  final RouteEntry? chosen;
}

/// Règle de sélection : parmi les routes dont (destination ET masque) = réseau,
/// on garde le préfixe le plus long ; à égalité, la métrique la plus faible.
RouteLookup lookupRoute(List<RouteEntry> routes, int dest) {
  final m = routes.where((r) => r.matches(dest)).toList()
    ..sort((a, b) {
      final c = b.prefix.compareTo(a.prefix);
      return c != 0 ? c : a.metric.compareTo(b.metric);
    });
  return RouteLookup(m, m.isEmpty ? null : m.first);
}

// ---------------------------------------------------------------------------
// Table de routage d'une machine (modes débutant et avancé)
// ---------------------------------------------------------------------------

class RoutingTable {
  RoutingTable({
    required this.os,
    required this.hostName,
    required this.ifaces,
    required this.routes,
  });

  final RoutingOs os;
  final String hostName;
  final List<NetIface> ifaces;
  final List<RouteEntry> routes;

  NetIface ifaceNamed(String name) => ifaces.firstWhere((i) => i.name == name);

  /// Nom de l'interface tel que l'élève doit le donner : nom (Linux) ou adresse (Windows).
  String ifaceLabel(String name) =>
      os == RoutingOs.linux ? name : ipToString(ifaceNamed(name).ip);

  String render() => os == RoutingOs.linux ? _renderLinux() : _renderWindows();

  String _renderLinux() {
    final rs = routes
        .where((r) =>
            r.origin == RouteOrigin.connected ||
            r.origin == RouteOrigin.staticRoute)
        .toList()
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        var c = a.network.compareTo(b.network);
        if (c != 0) return c;
        c = a.prefix.compareTo(b.prefix);
        return c != 0 ? c : a.metric.compareTo(b.metric);
      });
    final b = StringBuffer('$hostName\$ ip route\n');
    for (final r in rs) {
      final dest = r.isDefault ? 'default' : cidr(r.network, r.prefix);
      if (r.gateway == null) {
        b.write('$dest dev ${r.iface} proto kernel scope link src '
            '${ipToString(ifaceNamed(r.iface).ip)}');
      } else {
        b.write(
            '$dest via ${ipToString(r.gateway!)} dev ${r.iface} proto static');
      }
      if (r.metric > 0) b.write(' metric ${r.metric}');
      b.write('\n');
    }
    return b.toString().trimRight();
  }

  String _renderWindows() {
    final rs = List<RouteEntry>.from(routes)
      ..sort((a, b) {
        var c = a.network.compareTo(b.network);
        if (c != 0) return c;
        c = a.prefix.compareTo(b.prefix);
        return c != 0 ? c : a.metric.compareTo(b.metric);
      });
    const sep =
        '===========================================================================';
    final b = StringBuffer(
        'C:\\> route print -4\n$sep\nIPv4 Table de routage\n$sep\n'
        'Itinéraires actifs :\n'
        'Destination réseau    Masque réseau  Adr. passerelle   Adr. interface Métrique\n');
    for (final r in rs) {
      b.write(ipToString(r.network).padLeft(18));
      b.write(ipToString(prefixMask(r.prefix)).padLeft(17));
      b.write(
          (r.gateway == null ? 'On-link' : ipToString(r.gateway!)).padLeft(17));
      b.write(ipToString(ifaceNamed(r.iface).ip).padLeft(17));
      b.write('${r.metric}'.padLeft(9));
      b.write('\n');
    }
    b.write(sep);
    return b.toString();
  }
}

/// Exercice de lecture de table : une table et plusieurs destinations.
class RoutingTableExercise {
  RoutingTableExercise({
    required this.mode,
    required this.table,
    required this.destinations,
  });

  final RoutingMode mode;
  final RoutingTable table;
  final List<int> destinations;

  RouteLookup lookup(int i) => lookupRoute(table.routes, destinations[i]);

  /// Interface attendue (nom ou adresse selon l'OS), '' s'il n'y a pas de route.
  String expectedInterface(int i) {
    final r = lookup(i).chosen;
    return r == null ? '' : table.ifaceLabel(r.iface);
  }

  /// Passerelle attendue : adresse, « direct » ou « aucune route ».
  String expectedGateway(int i) {
    final r = lookup(i).chosen;
    if (r == null) return 'aucune route';
    return r.gateway == null ? 'direct' : ipToString(r.gateway!);
  }

  String get instruction {
    final fmt = table.os == RoutingOs.linux
        ? 'format Linux « ip route »'
        : 'format Windows « route print »';
    final ifaceHint = table.os == RoutingOs.linux
        ? 'l\'interface de sortie (son nom, par exemple eth1)'
        : 'l\'interface de sortie (son adresse, colonne « Adr. interface »)';
    final adv = mode == RoutingMode.avance
        ? '\nAttention : des routes se chevauchent, certaines ont le même préfixe '
            '(départage par la métrique la plus faible) et il n\'y a pas toujours '
            'de route par défaut.'
        : '';
    return 'Voici la table de routage de ${table.hostName} ($fmt).\n'
        'Pour chaque destination, indique $ifaceHint et la passerelle : son adresse, '
        '« direct » si le réseau est directement connecté, ou « aucune » si aucune '
        'route ne correspond. Applique la règle du préfixe le plus long.$adv';
  }
}

int _hostIn(TrainingRandom r, int network, int prefix, Set<int> exclude) {
  final size = _pow2(32 - prefix);
  final first = prefix >= 31 ? network : network + 1;
  final last = prefix >= 31 ? network + size - 1 : network + size - 2;
  for (var k = 0; k < 200; k++) {
    final ip = first + r.nextInt(last - first + 1);
    if (!exclude.contains(ip)) return ip;
  }
  for (var ip = first; ip <= last; ip++) {
    if (!exclude.contains(ip)) return ip;
  }
  throw StateError('réseau plein');
}

const List<int> _publicFirstOctets = [
  8,
  31,
  45,
  51,
  62,
  80,
  91,
  93,
  104,
  151,
  185,
  193,
  203,
  212
];

int _publicIp(TrainingRandom r) => ipOf(r.pick(_publicFirstOctets),
    r.range(0, 255), r.range(0, 255), r.range(1, 254));

/// Génère un exercice de lecture de table (mode débutant ou avancé).
RoutingTableExercise generateRoutingTableExercise(
  TrainingRandom r, {
  RoutingMode mode = RoutingMode.debutant,
  RoutingOs os = RoutingOs.linux,
}) {
  final advanced = mode == RoutingMode.avance;
  final win = os == RoutingOs.windows;
  final ifaces = <NetIface>[];
  final routes = <RouteEntry>[];
  final ifMetric = <String, int>{'eth0': 25, 'eth1': 35, 'eth2': 45, 'lo': 75};

  // Interfaces et réseaux directement connectés.
  final a = r.range(1, advanced ? 199 : 254);
  final eth0 = NetIface('eth0', ipOf(192, 168, a, r.range(10, 99)), 24);
  ifaces.add(eth0);
  if (advanced) {
    final k = r.range(0, 63);
    ifaces.add(NetIface(
        'eth1', ipOf(10, r.range(0, 49), r.range(0, 255), 4 * k + 1), 30));
    ifaces.add(NetIface(
        'eth2',
        ipOf(10, r.range(50, 99), r.range(0, 255),
            64 * r.range(0, 3) + r.range(1, 20)),
        26));
  } else {
    ifaces.add(NetIface('eth1',
        ipOf(10, r.range(0, 99), r.range(0, 255), r.range(2, 250)), 24));
  }
  final used = <int>{for (final i in ifaces) i.ip};

  int gwOn(NetIface i) {
    final g = _hostIn(r, i.network, i.prefix, used);
    used.add(g);
    return g;
  }

  int connectedMetric(String n) => win ? 256 + ifMetric[n]! : 0;
  int staticMetric(String n, int base) => win ? base + ifMetric[n]! : base;

  for (final i in ifaces) {
    routes.add(RouteEntry(
        network: i.network,
        prefix: i.prefix,
        iface: i.name,
        metric: connectedMetric(i.name),
        origin: RouteOrigin.connected));
    if (win) {
      routes.add(RouteEntry(
          network: i.ip,
          prefix: 32,
          iface: i.name,
          metric: connectedMetric(i.name),
          origin: RouteOrigin.local));
      routes.add(RouteEntry(
          network: broadcastOf(i.network, i.prefix),
          prefix: 32,
          iface: i.name,
          metric: connectedMetric(i.name),
          origin: RouteOrigin.local));
    }
  }
  if (win) {
    ifaces.add(NetIface('lo', ipOf(127, 0, 0, 1), 8));
    routes.add(RouteEntry(
        network: ipOf(127, 0, 0, 0),
        prefix: 8,
        iface: 'lo',
        metric: 331,
        origin: RouteOrigin.loopback));
  }

  final destinations = <int>[];
  final hostName = win ? 'PC-${r.range(10, 99)}' : 'srv-${r.range(10, 99)}';

  if (!advanced) {
    final eth1 = ifaces[1];
    final gwDef = gwOn(eth0);
    final gwB = gwOn(eth1);
    final gwC = gwOn(eth0);
    final s1 = RouteEntry(
        network: ipOf(10, r.range(100, 199), 0, 0),
        prefix: 16,
        gateway: gwB,
        iface: 'eth1',
        metric: staticMetric('eth1', win ? 1 : 0));
    final s2 = RouteEntry(
        network: ipOf(172, r.range(16, 31), r.range(0, 255), 0),
        prefix: 24,
        gateway: gwC,
        iface: 'eth0',
        metric: staticMetric('eth0', win ? 1 : 0));
    routes.addAll([
      s1,
      s2,
      RouteEntry(
          network: 0,
          prefix: 0,
          gateway: gwDef,
          iface: 'eth0',
          metric: win ? ifMetric['eth0']! : 100),
    ]);
    final conn = r.pick([eth0, eth1]);
    destinations.addAll([
      _hostIn(r, conn.network, conn.prefix, used),
      _hostIn(r, s1.network, 16, used),
      _hostIn(r, s2.network, 24, used),
      _publicIp(r),
    ]);
  } else {
    final eth1 = ifaces[1];
    final eth2 = ifaces[2];
    final gws = r.shuffled([gwOn(eth0), gwOn(eth0), gwOn(eth1), gwOn(eth2)]);
    String ifaceOf(int gw) => ifaces.firstWhere((i) => i.contains(gw)).name;

    // Famille de routes qui se chevauchent : /16, /24 dedans, /26 dedans.
    final b2 = r.range(16, 31);
    final y = r.range(0, 255);
    final k = r.range(0, 3);
    final n16 = ipOf(172, b2, 0, 0);
    final n24 = ipOf(172, b2, y, 0);
    final n26 = ipOf(172, b2, y, 64 * k);
    RouteEntry st(int net, int p, int gw, int base) => RouteEntry(
        network: net,
        prefix: p,
        gateway: gw,
        iface: ifaceOf(gw),
        metric: staticMetric(ifaceOf(gw), base));
    routes.addAll([
      st(n16, 16, gws[0], win ? 1 : 0),
      st(n24, 24, gws[1], win ? 1 : 0),
      st(n26, 26, gws[2], win ? 1 : 0),
    ]);

    // Même préfixe deux fois : la métrique départage.
    final nTie = ipOf(192, 168, r.range(200, 250), 0);
    final gA = gws[3];
    final gB = gws[r.pick([0, 1, 2])];
    int mA, mB;
    do {
      mA = r.pick([5, 10, 20, 50, 100]);
      mB = r.pick([5, 10, 20, 50, 100]);
    } while (staticMetric(ifaceOf(gA), mA) == staticMetric(ifaceOf(gB), mB) ||
        gA == gB);
    routes.add(st(nTie, 24, gA, mA));
    routes.add(st(nTie, 24, gB, mB));

    // Route par défaut une fois sur deux : sans elle, une destination publique n'a
    // aucune route.
    if (r.nextBool()) {
      final g = gws[r.pick([0, 1])];
      routes.add(RouteEntry(
          network: 0,
          prefix: 0,
          gateway: g,
          iface: ifaceOf(g),
          metric: win ? ifMetric[ifaceOf(g)]! : 100));
    }

    // Destinations : une par cas de figure.
    final in26 = _hostIn(r, n26, 26, used);
    int in24not26;
    do {
      in24not26 = _hostIn(r, n24, 24, used);
    } while (networkOf(in24not26, 26) == n26);
    int third;
    do {
      third = r.range(0, 255);
    } while (third == y);
    final in16not24 = ipOf(172, b2, third, r.range(1, 254));
    final other =
        r.nextBool() ? in16not24 : _hostIn(r, eth2.network, eth2.prefix, used);
    destinations.addAll([
      in26,
      in24not26,
      other,
      _hostIn(r, nTie, 24, used),
      _publicIp(r),
    ]);
  }

  return RoutingTableExercise(
    mode: mode,
    table: RoutingTable(
        os: os, hostName: hostName, ifaces: ifaces, routes: routes),
    destinations: r.shuffled(destinations),
  );
}

// ---------------------------------------------------------------------------
// Vérification d'une table
// ---------------------------------------------------------------------------

const Set<String> _directWords = {
  'direct',
  'directe',
  'directement connecte',
  'directement connecté',
  'directement connectée',
  'directement connectee',
  'connecte',
  'connecté',
  'connectée',
  'connected',
  'directly connected',
  'on-link',
  'on link',
  'onlink',
  'lien direct',
  'aucune passerelle',
  'pas de passerelle',
  'sans passerelle',
  'local',
  '0.0.0.0',
  '*',
};

const Set<String> _noRouteWords = {
  'aucune',
  'aucune route',
  'aucun',
  'pas de route',
  'sans route',
  'rejet',
  'rejete',
  'rejeté',
  'rejetee',
  'rejetée',
  'injoignable',
  'unreachable',
  'network is unreachable',
  'network unreachable',
  'drop',
  'none',
  'no route',
  'aucune route ne correspond',
};

bool _isNoRoute(String s) => _noRouteWords.contains(normalizeAnswer(s));

String _stripLead(String s, List<String> words) {
  var t = normalizeAnswer(s);
  for (final w in words) {
    if (t.startsWith('$w ')) t = t.substring(w.length + 1).trim();
  }
  return t;
}

class RoutingTableResult {
  const RoutingTableResult(this.interfaceOk, this.gatewayOk, this.check);
  final List<bool> interfaceOk;
  final List<bool> gatewayOk;
  final TrainingCheck check;
}

/// Explication pas à pas de la recherche de route pour une destination.
String explainLookup(RoutingTable t, int dest) {
  final b = StringBuffer();
  final sorted = List<RouteEntry>.from(t.routes)
    ..sort((x, y) {
      final c = y.prefix.compareTo(x.prefix);
      return c != 0 ? c : x.metric.compareTo(y.metric);
    });
  final d = ipToString(dest);
  for (final r in sorted) {
    final res = networkOf(dest, r.prefix);
    final ok = res == r.network;
    final label = r.isDefault ? 'default' : cidr(r.network, r.prefix);
    if (r.isDefault) {
      b.write('  $label : masque 0.0.0.0, le ET donne toujours 0.0.0.0 '
          '-> correspond toujours');
    } else {
      b.write('  $label : $d ET ${ipToString(prefixMask(r.prefix))} = '
          '${ipToString(res)} -> ${ok ? 'égal au réseau, correspond' : 'différent de ${ipToString(r.network)}, ne correspond pas'}');
    }
    final metricText = (t.os == RoutingOs.windows || r.metric > 0)
        ? ' (métrique ${r.metric})'
        : '';
    if (ok) b.write(metricText);
    b.write('\n');
    final partial = r.prefix % 8;
    if (!r.isDefault && partial != 0) {
      final idx = r.prefix ~/ 8;
      final o = ipOctets(dest)[idx];
      final m = ipOctets(prefixMask(r.prefix))[idx];
      b.write('      octet ${idx + 1} : $o = ${_bin8(o)} ET $m = ${_bin8(m)} '
          '-> ${_bin8(o & m)} = ${o & m}\n');
    }
  }
  final lk = lookupRoute(t.routes, dest);
  if (lk.chosen == null) {
    b.write(
        '  Aucune route ne correspond et il n\'y a pas de route par défaut : '
        'le paquet est rejeté (Linux affiche « Network is unreachable », un routeur '
        'renverrait un ICMP Destination Unreachable).\n');
    return b.toString();
  }
  final best = lk.chosen!;
  final cands = lk.matches.map((r) => '/${r.prefix}').toSet().join(', ');
  b.write(
      '  Préfixes qui correspondent : $cands. Le plus long gagne : /${best.prefix}');
  final same = lk.matches.where((r) => r.prefix == best.prefix).toList();
  if (same.length > 1) {
    b.write('. Plusieurs routes /${best.prefix} : métriques '
        '${same.map((r) => r.metric).join(' et ')}, la plus faible gagne '
        '(${best.metric})');
  }
  b.write('.\n');
  final iface = t.ifaceLabel(best.iface);
  if (best.gateway == null) {
    b.write('  Route directement connectée : le paquet sort par $iface et est '
        'remis directement à $d (adresse MAC obtenue par ARP), sans passerelle.\n');
  } else {
    b.write('  Le paquet sort par $iface vers la passerelle '
        '${ipToString(best.gateway!)}, qui le relaiera.\n');
  }
  return b.toString();
}

RoutingTableResult checkRoutingTable(
  RoutingTableExercise ex,
  List<String> interfaces,
  List<String> gateways,
) {
  final t = ex.table;
  final n = ex.destinations.length;
  final ifOk = List<bool>.filled(n, false);
  final gwOk = List<bool>.filled(n, false);
  final b = StringBuffer(
      'Méthode : pour chaque route, on calcule « destination ET masque » (bit à bit : '
      '1 ET 1 = 1, sinon 0). Si le résultat est égal au réseau de la route, elle '
      'correspond. Parmi les routes qui correspondent, on garde le préfixe le plus '
      'long (la plus précise) ; à préfixe égal, la métrique la plus faible. La route '
      'par défaut (/0) correspond à tout mais perd contre n\'importe quelle autre.\n');

  for (var i = 0; i < n; i++) {
    final dest = ex.destinations[i];
    final lk = ex.lookup(i);
    final ia = i < interfaces.length ? interfaces[i] : '';
    final ga = i < gateways.length ? gateways[i] : '';
    final r = lk.chosen;
    if (r == null) {
      final saysNone = _isNoRoute(ga) || _isNoRoute(ia);
      final ok = saysNone &&
          (normalizeAnswer(ia).isEmpty || _isNoRoute(ia) || ia.trim() == '-') &&
          (normalizeAnswer(ga).isEmpty || _isNoRoute(ga) || ga.trim() == '-');
      ifOk[i] = ok;
      gwOk[i] = ok;
    } else {
      final expIface = t.ifaceLabel(r.iface);
      final ian = _stripLead(ia, ['interface', 'dev', 'if']);
      if (t.os == RoutingOs.linux) {
        ifOk[i] = ian == expIface.toLowerCase();
      } else {
        ifOk[i] = parseIpv4(ian) == t.ifaceNamed(r.iface).ip;
      }
      final gan = _stripLead(ga, ['via', 'gw', 'passerelle']);
      if (r.gateway == null) {
        gwOk[i] = _directWords.contains(gan);
      } else {
        gwOk[i] = parseIpv4(gan) == r.gateway;
      }
    }
    final ok = ifOk[i] && gwOk[i];
    b.write(
        '\nDestination ${ipToString(dest)} : ${ok ? 'juste' : 'à revoir'}\n');
    b.write(explainLookup(t, dest));
    final expected = r == null
        ? 'aucune route'
        : 'interface ${t.ifaceLabel(r.iface)}, passerelle '
            '${r.gateway == null ? 'direct (réseau directement connecté)' : ipToString(r.gateway!)}';
    b.write('  Réponse attendue : $expected.');
    if (!ok) {
      final yi = ia.trim().isEmpty ? '(vide)' : ia.trim();
      final yg = ga.trim().isEmpty ? '(vide)' : ga.trim();
      b.write(' Ta réponse : $yi / $yg.');
    }
    b.write('\n');
  }
  final allOk = ifOk.every((x) => x) && gwOk.every((x) => x);
  return RoutingTableResult(
      ifOk, gwOk, TrainingCheck(allOk, b.toString().trimRight()));
}

// ---------------------------------------------------------------------------
// Mode « trouve la route manquante » : topologie, simulation d'un ping
// ---------------------------------------------------------------------------

class NetDevice {
  NetDevice(this.name,
      {required this.isRouter, required this.ifaces, required this.routes});
  final String name;
  final bool isRouter;
  final List<NetIface> ifaces;
  final List<RouteEntry> routes;

  NetIface ifaceNamed(String n) => ifaces.firstWhere((i) => i.name == n);
  NetDevice copy() => NetDevice(name,
      isRouter: isRouter, ifaces: ifaces, routes: List.of(routes));

  String renderRoutes() {
    final rs = List<RouteEntry>.from(routes)
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        final c = a.network.compareTo(b.network);
        return c != 0 ? c : a.prefix.compareTo(b.prefix);
      });
    final b = StringBuffer('$name# ip route\n');
    for (final r in rs) {
      final dest = r.isDefault ? 'default' : cidr(r.network, r.prefix);
      if (r.gateway == null) {
        b.write('$dest dev ${r.iface} proto kernel scope link src '
            '${ipToString(ifaceNamed(r.iface).ip)}\n');
      } else {
        b.write('$dest via ${ipToString(r.gateway!)} dev ${r.iface}\n');
      }
    }
    return b.toString().trimRight();
  }
}

class SimHop {
  const SimHop(this.device, this.route);
  final NetDevice device;
  final RouteEntry route;
}

class SimTrace {
  SimTrace(this.delivered, this.steps, this.hops,
      {this.failedAt, this.failure});
  final bool delivered;
  final List<String> steps;
  final List<SimHop> hops;
  final NetDevice? failedAt;

  /// 'route' (aucune route), 'arp' (prochain saut absent), 'boucle'.
  final String? failure;
}

/// Suit un paquet de [from] vers [dst], équipement par équipement.
SimTrace simulatePacket(List<NetDevice> devices, NetDevice from, int dst) {
  final steps = <String>[];
  final hops = <SimHop>[];
  var cur = from;
  final d = ipToString(dst);
  for (var ttl = 0; ttl < 16; ttl++) {
    if (cur.ifaces.any((i) => i.ip == dst)) {
      steps.add('${cur.name} : $d est sa propre adresse, paquet reçu.');
      return SimTrace(true, steps, hops);
    }
    final lk = lookupRoute(cur.routes, dst);
    final r = lk.chosen;
    if (r == null) {
      steps.add('${cur.name} : aucune route ne correspond à $d '
          '(pas de route par défaut) -> paquet rejeté, ICMP Destination Net Unreachable.');
      return SimTrace(false, steps, hops, failedAt: cur, failure: 'route');
    }
    hops.add(SimHop(cur, r));
    final out = cur.ifaceNamed(r.iface);
    final nh = r.gateway ?? dst;
    NetDevice? next;
    for (final dv in devices) {
      if (identical(dv, cur)) continue;
      if (dv.ifaces.any((i) =>
          i.ip == nh && i.network == out.network && i.prefix == out.prefix)) {
        next = dv;
        break;
      }
    }
    final how = r.gateway == null
        ? 'route ${r.destText} directement connectée (${r.iface})'
        : 'route ${r.destText} via ${ipToString(r.gateway!)} (${r.iface})';
    if (next == null) {
      steps.add('${cur.name} : $how -> personne ne répond en ${ipToString(nh)} '
          '(ARP sans réponse), paquet perdu.');
      return SimTrace(false, steps, hops, failedAt: cur, failure: 'arp');
    }
    steps.add('${cur.name} : $how -> ${next.name}');
    cur = next;
  }
  steps.add('Boucle de routage : le TTL s\'épuise, paquet détruit.');
  return SimTrace(false, steps, hops, failedAt: cur, failure: 'boucle');
}

class PingResult {
  PingResult(this.request, this.reply);
  final SimTrace request;
  final SimTrace? reply;
  bool get ok => request.delivered && (reply?.delivered ?? false);
}

PingResult simulatePing(List<NetDevice> devices, NetDevice src, NetDevice dst) {
  final dstIp = dst.ifaces.first.ip;
  final req = simulatePacket(devices, src, dstIp);
  if (!req.delivered) return PingResult(req, null);
  return PingResult(req, simulatePacket(devices, dst, src.ifaces.first.ip));
}

class MissingRouteExercise {
  MissingRouteExercise({
    required this.devices,
    required this.source,
    required this.target,
    required this.removedRouter,
    required this.removedRoute,
    required this.neededNetwork,
    required this.neededPrefix,
    required this.schema,
  });

  /// Tables actuelles (la route manquante est absente).
  final List<NetDevice> devices;
  final NetDevice source;
  final NetDevice target;
  final String removedRouter;
  final RouteEntry removedRoute;

  /// Réseau local que le paquet en échec cherche à joindre (cible de la route à ajouter).
  final int neededNetwork;
  final int neededPrefix;
  final String schema;

  List<NetDevice> get routers => devices.where((d) => d.isRouter).toList();
  NetDevice deviceNamed(String n) => devices.firstWhere((d) => d.name == n);

  PingResult currentPing() => simulatePing(devices, source, target);

  String get _gw => ipToString(removedRoute.gateway!);

  /// Une solution (route vers le réseau manquant) en syntaxe Linux, Cisco, Windows.
  String get solutionLinux =>
      'ip route add ${cidr(neededNetwork, neededPrefix)} via $_gw';

  String get solutionCisco => 'ip route ${ipToString(neededNetwork)} '
      '${ipToString(prefixMask(neededPrefix))} $_gw';

  String get solutionWindows => 'route add ${ipToString(neededNetwork)} '
      'mask ${ipToString(prefixMask(neededPrefix))} $_gw';

  String pingOutput() {
    final p = currentPing();
    final d = ipToString(target.ifaces.first.ip);
    final b = StringBuffer('${source.name}\$ ping -c 2 $d\n'
        'PING $d ($d) 56(84) bytes of data.\n');
    String? from;
    if (!p.request.delivered && p.request.failure == 'route') {
      final fr = p.request.failedAt!;
      // Le routeur renvoie un ICMP depuis l'adresse de l'interface par laquelle il
      // repart vers la source, à condition que ce message puisse revenir.
      final back = lookupRoute(fr.routes, source.ifaces.first.ip).chosen;
      if (back != null &&
          simulatePacket(devices, fr, source.ifaces.first.ip).delivered) {
        from = ipToString(fr.ifaceNamed(back.iface).ip);
      }
    }
    if (from != null) {
      b.write('From $from icmp_seq=1 Destination Net Unreachable\n'
          'From $from icmp_seq=2 Destination Net Unreachable\n\n'
          '--- $d ping statistics ---\n'
          '2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1001ms');
    } else {
      b.write('\n--- $d ping statistics ---\n'
          '2 packets transmitted, 0 received, 100% packet loss, time 1023ms');
    }
    return b.toString();
  }

  String get tables => routers.map((d) => d.renderRoutes()).join('\n\n');

  String get instruction =>
      'Le ping de ${source.name} vers ${target.name} échoue : il manque une route '
      'statique sur un des routeurs (une seule). Les machines ont toutes la bonne '
      'passerelle par défaut et les interfaces sont bien configurées.\n'
      'Indique le routeur à corriger et la route à ajouter (syntaxe Linux, Cisco ou '
      'Windows, par exemple « ip route add 172.16.5.0/24 via 10.0.12.2 »). '
      'Pense au trajet aller ET au trajet retour.';
}

int _link30(TrainingRandom r) =>
    ipOf(10, r.range(0, 254), r.range(0, 255), 4 * r.range(0, 63));

/// Génère une topologie de 2 ou 3 routeurs dans laquelle exactement une route manque.
/// On ne retire qu'une route dont l'absence laisse un routeur sans aucune route pour
/// le paquet (pas de boucle) : le diagnostic par le ping reste net.
MissingRouteExercise generateMissingRouteExercise(TrainingRandom r) {
  for (var k = 0; k < 100; k++) {
    final ex = _tryMissingRoute(r);
    if (ex != null) return ex;
  }
  throw StateError('aucune topologie exploitable');
}

MissingRouteExercise? _tryMissingRoute(TrainingRandom r) {
  final three = r.nextBool();
  final lanA = ipOf(192, 168, r.range(1, 99), 0);
  final pB = r.pick([24, 25, 26]);
  final lanB = ipOf(172, r.range(16, 31), r.range(0, 255),
      pB == 24 ? 0 : (pB == 25 ? 128 * r.range(0, 1) : 64 * r.range(0, 3)));
  final withC = r.nextBool();
  final lanC = ipOf(192, 168, r.range(100, 199), 0);
  final l12 = _link30(r);
  int l23;
  do {
    l23 = _link30(r);
  } while (l23 == l12);

  final r1a = lanA + r.pick<int>([1, 254]);
  final pcA = _hostIn(r, lanA, 24, {r1a});
  final rLastB = lanB + 1;
  final pcB = _hostIn(r, lanB, pB, {rLastB});

  RouteEntry conn(NetIface i) => RouteEntry(
      network: i.network,
      prefix: i.prefix,
      iface: i.name,
      origin: RouteOrigin.connected);
  RouteEntry via(int net, int p, int gw, String ifn) =>
      RouteEntry(network: net, prefix: p, gateway: gw, iface: ifn);
  NetDevice mk(
          String n, bool router, List<NetIface> ifs, List<RouteEntry> extra) =>
      NetDevice(n,
          isRouter: router,
          ifaces: ifs,
          routes: [for (final i in ifs) conn(i), ...extra]);

  final hostA =
      mk('PC-A', false, [NetIface('eth0', pcA, 24)], [via(0, 0, r1a, 'eth0')]);
  final hostB = mk(
      'PC-B', false, [NetIface('eth0', pcB, pB)], [via(0, 0, rLastB, 'eth0')]);

  final devices = <NetDevice>[hostA];
  final schema = StringBuffer();
  final r1 = [NetIface('eth0', r1a, 24), NetIface('eth1', l12 + 1, 30)];
  final useDefault1 = r.nextBool();
  if (!three) {
    final r2 = [
      NetIface('eth0', l12 + 2, 30),
      NetIface('eth1', rLastB, pB),
      if (withC) NetIface('eth2', lanC + 1, 24),
    ];
    final useDefault2 = r.nextBool();
    devices.add(mk('R1', true, r1, [
      if (useDefault1)
        via(0, 0, l12 + 2, 'eth1')
      else ...[
        via(lanB, pB, l12 + 2, 'eth1'),
        if (withC) via(lanC, 24, l12 + 2, 'eth1'),
      ],
    ]));
    devices.add(mk('R2', true, r2, [
      if (useDefault2)
        via(0, 0, l12 + 1, 'eth0')
      else
        via(lanA, 24, l12 + 1, 'eth0'),
    ]));
  } else {
    final r2 = [
      NetIface('eth0', l12 + 2, 30),
      NetIface('eth1', l23 + 1, 30),
      if (withC) NetIface('eth2', lanC + 1, 24),
    ];
    final r3 = [NetIface('eth0', l23 + 2, 30), NetIface('eth1', rLastB, pB)];
    final useDefault3 = r.nextBool();
    final r2DefaultToR3 = r.nextBool();
    devices.add(mk('R1', true, r1, [
      if (useDefault1)
        via(0, 0, l12 + 2, 'eth1')
      else ...[
        via(lanB, pB, l12 + 2, 'eth1'),
        via(l23, 30, l12 + 2, 'eth1'),
        if (withC) via(lanC, 24, l12 + 2, 'eth1'),
      ],
    ]));
    devices.add(mk('R2', true, r2, [
      via(lanA, 24, l12 + 1, 'eth0'),
      if (r2DefaultToR3)
        via(0, 0, l23 + 2, 'eth1')
      else
        via(lanB, pB, l23 + 2, 'eth1'),
    ]));
    devices.add(mk('R3', true, r3, [
      if (useDefault3)
        via(0, 0, l23 + 1, 'eth0')
      else ...[
        via(lanA, 24, l23 + 1, 'eth0'),
        via(l12, 30, l23 + 1, 'eth0'),
        if (withC) via(lanC, 24, l23 + 1, 'eth0'),
      ],
    ]));
  }
  devices.add(hostB);

  // Schéma textuel.
  String ifs(NetDevice d) => d.ifaces
      .map((i) => '${i.name} ${ipToString(i.ip)}/${i.prefix}')
      .join(' | ');
  schema
      .write('PC-A  ${ipToString(pcA)}/24  (passerelle ${ipToString(r1a)})\n');
  for (final d in devices.where((d) => d.isRouter)) {
    schema.write('  |\n[${d.name}]  ${ifs(d)}\n');
  }
  schema.write(
      '  |\nPC-B  ${ipToString(pcB)}/$pB  (passerelle ${ipToString(rLastB)})');
  if (withC) {
    schema.write(
        '\n\n(Le réseau ${cidr(lanC, 24)} est un autre réseau local, branché sur R2.)');
  }

  final toB = r.nextBool();
  final src = toB ? hostA : hostB;
  final dst = toB ? hostB : hostA;

  // Routes statiques réellement utilisées par le ping (aller et retour).
  final full = simulatePing(devices, src, dst);
  if (!full.ok) return null;
  final usedRoutes = <SimHop>[
    ...full.request.hops,
    ...full.reply!.hops,
  ].where((h) => h.device.isRouter && h.route.gateway != null).toList();
  for (final h in r.shuffled(usedRoutes)) {
    h.device.routes.remove(h.route);
    final p = simulatePing(devices, src, dst);
    final failed = p.reply ?? p.request;
    if (!p.ok &&
        failed.failure == 'route' &&
        identical(failed.failedAt, h.device)) {
      final lan = p.request.delivered ? src.ifaces.first : dst.ifaces.first;
      return MissingRouteExercise(
        devices: devices,
        source: src,
        target: dst,
        removedRouter: h.device.name,
        removedRoute: h.route,
        neededNetwork: lan.network,
        neededPrefix: lan.prefix,
        schema: schema.toString(),
      );
    }
    h.device.routes.add(h.route);
  }
  return null;
}

// ---------------------------------------------------------------------------
// Lecture d'une commande de route (Linux, Cisco, Windows, notation libre)
// ---------------------------------------------------------------------------

class ParsedRoute {
  const ParsedRoute(this.network, this.prefix, this.gateway,
      {this.dev, this.replace = false});
  final int network;
  final int prefix;
  final int gateway;
  final String? dev;
  final bool replace;
}

class RouteParse {
  const RouteParse.ok(ParsedRoute this.route) : error = null;
  const RouteParse.error(String this.error) : route = null;
  final ParsedRoute? route;
  final String? error;
}

RouteParse parseRouteCommand(String input) {
  final toks = normalizeAnswer(input.replaceAll(',', ' '))
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList();
  int? dest, prefix, mask, gw;
  String? dev;
  var replace = false;
  var hostFlag = false;
  final ips = <int>[];
  String? next(int i) => i + 1 < toks.length ? toks[i + 1] : null;
  for (var i = 0; i < toks.length; i++) {
    final t = toks[i];
    if (t == 'via' || t == 'gw' || t == 'gateway') {
      final g = parseIpv4(next(i) ?? '');
      if (g == null)
        return const RouteParse.error('passerelle illisible après « via ».');
      gw = g;
      i++;
    } else if (t == 'dev') {
      dev = next(i);
      i++;
    } else if (t == 'mask' || t == 'netmask') {
      final m = parseIpv4(next(i) ?? '');
      if (m == null) return const RouteParse.error('masque illisible.');
      mask = m;
      i++;
    } else if (const {
      'metric',
      'if',
      'proto',
      'table',
      'src',
      'scope',
      'onlink'
    }.contains(t)) {
      if (t != 'onlink') i++;
    } else if (t == 'default') {
      dest = 0;
      prefix = 0;
    } else if (t == 'replace' || t == 'change') {
      replace = true;
    } else if (t == '-host') {
      hostFlag = true;
    } else if (t.contains('/') && !RegExp(r'^\d').hasMatch(t)) {
      // Interface de sortie Cisco (GigabitEthernet0/1, fa0/0...) : ignorée, la
      // passerelle suffit à déterminer le lien.
      continue;
    } else if (t.contains('/')) {
      final parts = t.split('/');
      final ip = parseIpv4(parts[0]);
      final p = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (ip == null || p == null || p < 0 || p > 32) {
        return RouteParse.error(
            '« $t » n\'est pas une notation réseau/préfixe valide.');
      }
      dest = ip;
      prefix = p;
    } else {
      final ip = parseIpv4(t);
      if (ip != null) ips.add(ip);
    }
  }
  if (dest == null) {
    if (ips.isEmpty)
      return const RouteParse.error(
          'je ne trouve pas le réseau de destination.');
    dest = ips.removeAt(0);
    if (mask == null) {
      if (hostFlag) {
        prefix = 32;
      } else if (ips.length >= 2 ||
          (ips.length == 1 && (gw != null || prefixFromMask(ips[0]) != null))) {
        mask = ips.removeAt(0);
      } else {
        return const RouteParse.error(
            'précise le masque ou le préfixe du réseau (par exemple /24 ou 255.255.255.0).');
      }
    }
    if (mask != null) {
      prefix = prefixFromMask(mask);
      if (prefix == null) {
        return RouteParse.error(
            'le masque ${ipToString(mask)} n\'est pas contigu '
            '(les 1 doivent être tous à gauche).');
      }
    }
  }
  if (gw == null) {
    if (ips.isEmpty) {
      return const RouteParse.error(
          'il manque la passerelle (le prochain saut, « via ... »).');
    }
    gw = ips.removeAt(0);
  }
  if (ips.isNotEmpty) {
    return const RouteParse.error(
        'trop d\'adresses dans la commande, je ne sais pas laquelle est la passerelle.');
  }
  return RouteParse.ok(
      ParsedRoute(dest, prefix!, gw, dev: dev, replace: replace));
}

/// « R2 », « r2 », « routeur 2 », « 2 » -> « R2 » ; null si illisible.
String? parseRouterName(String s) {
  var t = normalizeAnswer(s).replaceAll(' ', '');
  for (final w in ['routeur', 'router']) {
    if (t.startsWith(w)) t = t.substring(w.length);
  }
  if (t.startsWith('r')) t = t.substring(1);
  final n = int.tryParse(t);
  return n == null ? null : 'R$n';
}

class MissingRouteResult {
  const MissingRouteResult(this.routerOk, this.routeOk, this.check);
  final bool routerOk;
  final bool routeOk;
  final TrainingCheck check;
}

String _traceText(String title, SimTrace t) =>
    '  $title :\n${t.steps.map((s) => '    $s').join('\n')}\n';

MissingRouteResult checkMissingRoute(
    MissingRouteExercise ex, String routerAnswer, String routeAnswer) {
  final b = StringBuffer(
      'Méthode : on suit le ping pas à pas, à l\'aller (requête) puis au retour '
      '(réponse), en faisant sur chaque équipement la recherche du préfixe le plus '
      'long. Le premier équipement qui n\'a aucune route pour l\'adresse visée est '
      'celui qu\'il faut corriger. « Destination Net Unreachable » signale un routeur '
      'sans route à l\'aller ; l\'absence de toute réponse (ni écho, ni erreur) fait plutôt penser au retour.\n\n'
      'Avec les tables actuelles :\n');
  final cur = ex.currentPing();
  b.write(_traceText('aller', cur.request));
  if (cur.reply != null) b.write(_traceText('retour', cur.reply!));

  final rr = ex.removedRoute;
  final targetIp = cur.request.delivered
      ? ex.source.ifaces.first.ip
      : ex.target.ifaces.first.ip;
  final lanText = cidr(ex.neededNetwork, ex.neededPrefix);
  final neighbor = ex.devices.firstWhere((d) =>
      !identical(d, ex.deviceNamed(ex.removedRouter)) &&
      d.ifaces.any((i) => i.ip == rr.gateway));
  b.write('\nUne solution : sur ${ex.removedRouter}, ajouter une route vers '
      '$lanText (${ipToString(targetIp)} ET '
      '${ipToString(prefixMask(ex.neededPrefix))} = ${ipToString(ex.neededNetwork)})'
      ' via ${ipToString(rr.gateway!)}, l\'adresse de ${neighbor.name} sur le '
      'lien commun : le prochain saut doit toujours être sur un réseau directement '
      'connecté au routeur.');
  if (rr.isDefault) {
    b.write(
        ' La configuration d\'origine utilisait ici une route par défaut via '
        '${ipToString(rr.gateway!)} : elle convient aussi.');
  }
  b.write('\n'
      '    Linux   : ${ex.solutionLinux}\n'
      '    Cisco   : ${ex.solutionCisco}\n'
      '    Windows : ${ex.solutionWindows}\n');

  final routerName = parseRouterName(routerAnswer);
  final parse = parseRouteCommand(routeAnswer);
  final routerExists =
      routerName != null && ex.routers.any((d) => d.name == routerName);
  if (!routerExists) {
    b.write('\nTa réponse : routeur « ${routerAnswer.trim()} » inconnu '
        '(choisis parmi ${ex.routers.map((d) => d.name).join(', ')}).');
    return MissingRouteResult(false, false, TrainingCheck(false, b.toString()));
  }
  if (parse.route == null) {
    b.write('\nTa réponse : route illisible : ${parse.error}');
    return MissingRouteResult(routerName == ex.removedRouter, false,
        TrainingCheck(false, b.toString()));
  }
  final p = parse.route!;
  b.write(
      '\nTa réponse : sur $routerName, ${p.prefix == 0 ? 'route par défaut' : 'route vers ${cidr(p.network, p.prefix)}'} '
      'via ${ipToString(p.gateway)}.\n');

  String? refusal;
  if (networkOf(p.network, p.prefix) != p.network) {
    refusal =
        '${ipToString(p.network)} n\'est pas une adresse de réseau pour un /${p.prefix} '
        '(le réseau est ${ipToString(networkOf(p.network, p.prefix))}) : Linux refuse '
        '(« Invalid prefix for given prefix length »), Cisco et Windows aussi.';
  }
  final devs = ex.devices.map((d) => d.copy()).toList();
  final router = devs.firstWhere((d) => d.name == routerName);
  NetIface? outIf;
  if (refusal == null) {
    for (final i in router.ifaces) {
      if (i.contains(p.gateway) && i.ip != p.gateway) outIf = i;
    }
    if (outIf == null) {
      refusal =
          '${ipToString(p.gateway)} n\'est sur aucun réseau directement connecté à '
          '$routerName (ou c\'est sa propre adresse) : le routeur ne peut pas joindre ce '
          'prochain saut (Linux : « Nexthop has invalid gateway »).';
    } else if (p.dev != null && p.dev != outIf.name) {
      refusal =
          'la passerelle ${ipToString(p.gateway)} est joignable par ${outIf.name}, '
          'pas par ${p.dev}.';
    }
  }
  if (refusal == null) {
    final existing = router.routes
        .where((x) => x.network == p.network && x.prefix == p.prefix)
        .toList();
    if (existing.isNotEmpty && !p.replace) {
      refusal =
          '$routerName a déjà une route vers ${cidr(p.network, p.prefix)} : '
          '« ip route add » répond « File exists ». La route manquante est ailleurs.';
    } else {
      router.routes
          .removeWhere((x) => x.network == p.network && x.prefix == p.prefix);
      router.routes.add(RouteEntry(
          network: p.network,
          prefix: p.prefix,
          gateway: p.gateway,
          iface: outIf!.name));
    }
  }
  if (refusal != null) {
    b.write('  Route refusée : $refusal');
    return MissingRouteResult(routerName == ex.removedRouter, false,
        TrainingCheck(false, b.toString()));
  }

  final src = devs.firstWhere((d) => d.name == ex.source.name);
  final dst = devs.firstWhere((d) => d.name == ex.target.name);
  final after = simulatePing(devs, src, dst);
  b.write('Simulation avec ta route :\n');
  b.write(_traceText('aller', after.request));
  if (after.reply != null) b.write(_traceText('retour', after.reply!));
  // Une route plus précise que le réseau visé (/32 vers une seule machine, demi-réseau…)
  // fait passer ce ping mais laisse le reste du réseau injoignable : la route
  // manquante doit couvrir le réseau entier.
  final narrow = p.prefix > ex.neededPrefix;
  final correct = after.ok && !narrow;
  if (after.ok && narrow) {
    b.write(
        'Le ping réussit, mais ta route (/${p.prefix}) ne couvre qu\'une partie du '
        'réseau $lanText : les autres machines de ce réseau resteraient injoignables. '
        'La route à ajouter doit viser le réseau entier (/${ex.neededPrefix} ou plus large).');
  } else if (after.ok) {
    b.write('Le ping réussit.');
    if (p.prefix < ex.neededPrefix && !rr.isDefault) {
      b.write(' Remarque : ta route est plus large que nécessaire '
          '($lanText suffisait) ; elle fonctionne grâce au préfixe le plus '
          'long, mais elle attirera aussi d\'autres destinations.');
    }
  } else {
    b.write('Le ping échoue toujours.');
  }
  return MissingRouteResult(after.ok || routerName == ex.removedRouter, correct,
      TrainingCheck(correct, b.toString()));
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class RoutingTrainer extends StatefulWidget {
  const RoutingTrainer({super.key});

  @override
  State<RoutingTrainer> createState() => _RoutingTrainerState();
}

class _RoutingTrainerState extends State<RoutingTrainer> {
  RoutingMode _mode = RoutingMode.debutant;
  RoutingOs _os = RoutingOs.linux;
  RoutingTableExercise? _table;
  MissingRouteExercise? _missing;
  final List<TextEditingController> _ifCtrls = [];
  final List<TextEditingController> _gwCtrls = [];
  final TextEditingController _routerCtrl = TextEditingController();
  final TextEditingController _routeCtrl = TextEditingController();
  RoutingTableResult? _tableResult;
  MissingRouteResult? _missingResult;
  bool _counted = false;
  int _score = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _newExercise();
  }

  @override
  void dispose() {
    for (final c in [..._ifCtrls, ..._gwCtrls, _routerCtrl, _routeCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _newExercise() {
    final r = TrainingRandom();
    for (final c in [..._ifCtrls, ..._gwCtrls]) {
      c.dispose();
    }
    _ifCtrls.clear();
    _gwCtrls.clear();
    _routerCtrl.clear();
    _routeCtrl.clear();
    _tableResult = null;
    _missingResult = null;
    _counted = false;
    if (_mode == RoutingMode.routeManquante) {
      _table = null;
      _missing = generateMissingRouteExercise(r);
    } else {
      _missing = null;
      _table = generateRoutingTableExercise(r, mode: _mode, os: _os);
      for (var i = 0; i < _table!.destinations.length; i++) {
        _ifCtrls.add(TextEditingController());
        _gwCtrls.add(TextEditingController());
      }
    }
  }

  void _check() {
    setState(() {
      bool ok;
      if (_missing != null) {
        _missingResult =
            checkMissingRoute(_missing!, _routerCtrl.text, _routeCtrl.text);
        ok = _missingResult!.check.correct;
      } else {
        _tableResult = checkRoutingTable(
            _table!,
            _ifCtrls.map((c) => c.text).toList(),
            _gwCtrls.map((c) => c.text).toList());
        ok = _tableResult!.check.correct;
      }
      if (!_counted) {
        _counted = true;
        _attempts++;
        if (ok) _score++;
      }
    });
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: TdcColors.accentDim,
        backgroundColor: TdcColors.surfaceAlt,
        labelStyle: TextStyle(
            color: selected ? TdcColors.accent : TdcColors.textSecondary,
            fontSize: 13),
        side: BorderSide(color: selected ? TdcColors.accent : TdcColors.border),
      );

  Widget _selectors() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
            'Débutant',
            _mode == RoutingMode.debutant,
            () => setState(() {
                  _mode = RoutingMode.debutant;
                  _newExercise();
                })),
        _chip(
            'Avancé',
            _mode == RoutingMode.avance,
            () => setState(() {
                  _mode = RoutingMode.avance;
                  _newExercise();
                })),
        _chip(
            'Route manquante',
            _mode == RoutingMode.routeManquante,
            () => setState(() {
                  _mode = RoutingMode.routeManquante;
                  _newExercise();
                })),
        if (_mode != RoutingMode.routeManquante) ...[
          const SizedBox(width: 16),
          _chip(
              'Linux',
              _os == RoutingOs.linux,
              () => setState(() {
                    _os = RoutingOs.linux;
                    _newExercise();
                  })),
          _chip(
              'Windows',
              _os == RoutingOs.windows,
              () => setState(() {
                    _os = RoutingOs.windows;
                    _newExercise();
                  })),
        ],
      ],
    );
  }

  Widget _tableBody(RoutingTableExercise ex) {
    final res = _tableResult;
    final win = ex.table.os == RoutingOs.windows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainingCode(ex.table.render()),
        const SizedBox(height: 16),
        for (var i = 0; i < ex.destinations.length; i++) ...[
          Text('Destination ${ipToString(ex.destinations[i])}',
              style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace')),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TrainingField(
                  label: 'Interface',
                  hint: win ? 'adresse de l\'interface' : 'eth0, eth1…',
                  controller: _ifCtrls[i],
                  state: res?.interfaceOk[i],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TrainingField(
                  label: 'Passerelle',
                  hint: 'adresse, direct ou aucune',
                  controller: _gwCtrls[i],
                  state: res?.gatewayOk[i],
                  onSubmitted:
                      i == ex.destinations.length - 1 ? (_) => _check() : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _missingBody(MissingRouteExercise ex) {
    final res = _missingResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainingCode(ex.schema),
        const SizedBox(height: 12),
        TrainingCode(ex.tables),
        const SizedBox(height: 12),
        TrainingCode(ex.pingOutput()),
        const SizedBox(height: 16),
        TrainingField(
          label: 'Routeur à corriger',
          hint: ex.routers.map((d) => d.name).join(', '),
          controller: _routerCtrl,
          state: res?.routerOk,
        ),
        TrainingField(
          label: 'Route à ajouter',
          hint: 'ip route add réseau/préfixe via passerelle',
          controller: _routeCtrl,
          state: res?.routeOk,
          onSubmitted: (_) => _check(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final instruction =
        _missing != null ? _missing!.instruction : _table!.instruction;
    final result = _missingResult?.check ?? _tableResult?.check;
    return TrainingFrame(
      title: 'Tables de routage',
      subtitle: 'Préfixe le plus long, métrique, route manquante',
      icon: Icons.alt_route,
      instruction: instruction,
      score: _score,
      attempts: _attempts,
      result: result,
      onCheck: _check,
      onNext: () => setState(_newExercise),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _selectors(),
          const SizedBox(height: 16),
          if (_missing != null)
            _missingBody(_missing!)
          else
            _tableBody(_table!),
        ],
      ),
    );
  }
}
