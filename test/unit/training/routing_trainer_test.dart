import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/training/routing_trainer.dart';
import 'package:tutodecode/features/training/training_kit.dart';

int ip(String s) => parseIpv4(s)!;

/// Bits d'une adresse sous forme de chaîne, calculés sans le code testé.
String bits(int a) {
  final o = ipToString(a).split('.').map(int.parse);
  return o.map((x) => x.toRadixString(2).padLeft(8, '0')).join();
}

/// Recherche du préfixe le plus long recalculée indépendamment (comparaison de bits).
RouteEntry? independentLookup(List<RouteEntry> routes, int dest) {
  RouteEntry? best;
  for (final r in routes) {
    if (bits(dest).substring(0, r.prefix) !=
        bits(r.network).substring(0, r.prefix)) {
      continue;
    }
    if (best == null ||
        r.prefix > best.prefix ||
        (r.prefix == best.prefix && r.metric < best.metric)) {
      best = r;
    }
  }
  return best;
}

RouteEntry st(String net, int p, String gw, String dev, [int metric = 0]) =>
    RouteEntry(
        network: ip(net),
        prefix: p,
        gateway: ip(gw),
        iface: dev,
        metric: metric);

RoutingTableExercise handTable(List<int> dests) {
  final ifaces = [
    NetIface('eth0', ip('192.168.1.10'), 24),
    NetIface('eth1', ip('10.0.0.1'), 30),
  ];
  return RoutingTableExercise(
    mode: RoutingMode.avance,
    table: RoutingTable(
      os: RoutingOs.linux,
      hostName: 'srv-1',
      ifaces: ifaces,
      routes: [
        RouteEntry(
            network: ip('192.168.1.0'),
            prefix: 24,
            iface: 'eth0',
            origin: RouteOrigin.connected),
        RouteEntry(
            network: ip('10.0.0.0'),
            prefix: 30,
            iface: 'eth1',
            origin: RouteOrigin.connected),
        st('172.16.0.0', 16, '192.168.1.1', 'eth0'),
        st('172.16.5.0', 24, '10.0.0.2', 'eth1'),
        st('172.16.5.64', 26, '192.168.1.254', 'eth0'),
        st('192.168.200.0', 24, '192.168.1.1', 'eth0', 20),
        st('192.168.200.0', 24, '10.0.0.2', 'eth1', 10),
      ],
    ),
    destinations: dests,
  );
}

void main() {
  group('calculs IPv4', () {
    test('adresse réseau (ET logique) calculée à la main', () {
      expect(ipToString(networkOf(ip('192.168.1.77'), 26)), '192.168.1.64');
      expect(ipToString(networkOf(ip('172.16.5.200'), 25)), '172.16.5.128');
      expect(ipToString(networkOf(ip('200.1.2.3'), 8)), '200.0.0.0');
      expect(
          ipToString(networkOf(ip('255.255.255.255'), 30)), '255.255.255.252');
      expect(networkOf(ip('8.8.8.8'), 0), 0);
      expect(ipToString(prefixMask(26)), '255.255.255.192');
      expect(ipToString(prefixMask(30)), '255.255.255.252');
      expect(prefixFromMask(ip('255.255.240.0')), 20);
      expect(prefixFromMask(ip('255.0.255.0')), isNull);
      expect(parseIpv4('256.1.1.1'), isNull);
    });
  });

  group('préfixe le plus long', () {
    final ex = handTable([
      ip('172.16.5.70'),
      ip('172.16.5.10'),
      ip('172.16.9.1'),
      ip('8.8.8.8'),
      ip('192.168.200.5'),
      ip('192.168.1.50'),
    ]);

    test('choix calculés à la main', () {
      expect(ex.expectedGateway(0), '192.168.1.254'); // /26 : .70 ET .192 = .64
      expect(ex.expectedInterface(0), 'eth0');
      expect(ex.expectedGateway(1), '10.0.0.2'); // /24 seulement
      expect(ex.expectedInterface(1), 'eth1');
      expect(ex.expectedGateway(2), '192.168.1.1'); // /16 seulement
      expect(ex.expectedGateway(3), 'aucune route'); // pas de route par défaut
      expect(ex.expectedGateway(4), '10.0.0.2'); // métrique 10 < 20
      expect(ex.expectedGateway(5), 'direct');
    });

    test('réponses justes et variantes acceptées', () {
      final res = checkRoutingTable(ex, [
        'eth0',
        'dev eth1',
        'ETH0',
        '',
        'eth1',
        'eth0',
      ], [
        '192.168.1.254',
        'via 10.0.0.2',
        ' 192.168.1.1 ',
        'aucune route',
        '10.0.0.2',
        'directement connecté',
      ]);
      expect(res.check.correct, isTrue, reason: res.check.explanation);
      expect(res.check.explanation, contains('ET'));
      expect(res.check.explanation, contains('/26'));
      expect(res.check.explanation, contains('métrique'));
    });

    test('erreurs détectées', () {
      final res = checkRoutingTable(ex, [
        'eth1', // a pris le /24 au lieu du /26
        'eth1',
        'eth0',
        'eth0', // a inventé une route
        'eth0', // métrique la plus forte
        'eth0',
      ], [
        '10.0.0.2',
        '10.0.0.2',
        '192.168.1.1',
        '192.168.1.1',
        '192.168.1.1',
        '192.168.1.1', // passerelle pour un réseau connecté
      ]);
      expect(res.check.correct, isFalse);
      expect(res.interfaceOk, [false, true, true, false, false, true]);
      expect(res.gatewayOk, [false, true, true, false, false, false]);
    });

    test(
        'correction cohérente avec les mots acceptés (direct, none, connected)',
        () {
      // Bug corrigé : la correction affichait « passerelle aucune » pour un réseau
      // connecté, alors que « aucune » signifie « pas de route » et y est refusé.
      final bad = checkRoutingTable(ex, List.filled(6, ''), List.filled(6, ''));
      expect(
          bad.check.explanation,
          contains(
              'interface eth0, passerelle direct (réseau directement connecté)'));
      expect(bad.check.explanation, isNot(contains('passerelle aucune')));
      final res = checkRoutingTable(ex, [
        'eth0',
        'eth1',
        'eth0',
        '',
        'eth1',
        'eth0'
      ], [
        '192.168.1.254',
        '10.0.0.2',
        '192.168.1.1',
        'none',
        '10.0.0.2',
        'connected'
      ]);
      expect(res.check.correct, isTrue, reason: res.check.explanation);
    });

    test('format Windows : interface par son adresse, On-link', () {
      final r = TrainingRandom(7);
      final w = generateRoutingTableExercise(r, os: RoutingOs.windows);
      final text = w.table.render();
      expect(text, contains('On-link'));
      expect(text, contains('255.255.255.0'));
      expect(text, contains('127.0.0.0'));
      final ifs = [
        for (var i = 0; i < w.destinations.length; i++) w.expectedInterface(i)
      ];
      final gws = [
        for (var i = 0; i < w.destinations.length; i++)
          w.expectedGateway(i) == 'direct' ? 'On-link' : w.expectedGateway(i)
      ];
      expect(checkRoutingTable(w, ifs, gws).check.correct, isTrue);
    });
  });

  group('lecture de commande de route', () {
    void same(String cmd, String net, int p, String gw) {
      final r = parseRouteCommand(cmd).route;
      expect(r, isNotNull, reason: cmd);
      expect(ipToString(r!.network), net, reason: cmd);
      expect(r.prefix, p, reason: cmd);
      expect(ipToString(r.gateway), gw, reason: cmd);
    }

    test('syntaxes Linux, Cisco, Windows, net-tools', () {
      same('ip route add 172.16.5.0/24 via 10.0.12.2', '172.16.5.0', 24,
          '10.0.12.2');
      same('sudo ip route add 172.16.5.0/24 via 10.0.12.2 dev eth1',
          '172.16.5.0', 24, '10.0.12.2');
      same('ip route 172.16.5.0 255.255.255.0 10.0.12.2', '172.16.5.0', 24,
          '10.0.12.2');
      same('route add 172.16.5.0 mask 255.255.255.192 10.0.12.2', '172.16.5.0',
          26, '10.0.12.2');
      same('route add -net 172.16.5.0 netmask 255.255.255.0 gw 10.0.12.2',
          '172.16.5.0', 24, '10.0.12.2');
      same('ip route add default via 10.0.12.2', '0.0.0.0', 0, '10.0.12.2');
      same('172.16.5.0/24 10.0.12.2', '172.16.5.0', 24, '10.0.12.2');
    });

    test('erreurs', () {
      expect(parseRouteCommand('ip route add 172.16.5.0/24').error, isNotNull);
      expect(parseRouteCommand('ip route 172.16.5.0 255.255.255.0').error,
          contains('passerelle'));
      expect(
          parseRouteCommand('172.16.5.0 10.0.12.2').error, contains('masque'));
      expect(parseRouteCommand('ip route 10.0.0.0/33 via 1.1.1.1').error,
          isNotNull);
    });

    test('masque non contigu refusé', () {
      expect(parseRouteCommand('ip route 10.0.0.0 255.0.255.0 10.1.1.1').error,
          contains('contigu'));
    });

    test('nom de routeur', () {
      expect(parseRouterName('r2'), 'R2');
      expect(parseRouterName('Routeur 3'), 'R3');
      expect(parseRouterName('1'), 'R1');
      expect(parseRouterName('PC-A'), isNull);
    });
  });

  group('route manquante', () {
    test('cas construit à la main : R1 sans route vers le LAN B', () {
      // PC-A 192.168.1.10/24 - R1 (192.168.1.1 | 10.0.0.1/30) -
      // R2 (10.0.0.2/30 | 172.16.5.1/24) - PC-B 172.16.5.20/24
      RouteEntry conn(NetIface i) => RouteEntry(
          network: i.network,
          prefix: i.prefix,
          iface: i.name,
          origin: RouteOrigin.connected);
      NetDevice dev(
              String n, bool rt, List<NetIface> ifs, List<RouteEntry> x) =>
          NetDevice(n,
              isRouter: rt,
              ifaces: ifs,
              routes: [for (final i in ifs) conn(i), ...x]);
      final a = dev('PC-A', false, [NetIface('eth0', ip('192.168.1.10'), 24)],
          [st('0.0.0.0', 0, '192.168.1.1', 'eth0')]);
      final r1 = dev('R1', true, [
        NetIface('eth0', ip('192.168.1.1'), 24),
        NetIface('eth1', ip('10.0.0.1'), 30)
      ], []);
      final r2 = dev('R2', true, [
        NetIface('eth0', ip('10.0.0.2'), 30),
        NetIface('eth1', ip('172.16.5.1'), 24)
      ], [
        st('192.168.1.0', 24, '10.0.0.1', 'eth0')
      ]);
      final b = dev('PC-B', false, [NetIface('eth0', ip('172.16.5.20'), 24)],
          [st('0.0.0.0', 0, '172.16.5.1', 'eth0')]);
      final ex = MissingRouteExercise(
        devices: [a, r1, r2, b],
        source: a,
        target: b,
        removedRouter: 'R1',
        removedRoute: st('172.16.5.0', 24, '10.0.0.2', 'eth1'),
        neededNetwork: ip('172.16.5.0'),
        neededPrefix: 24,
        schema: '',
      );
      expect(ex.currentPing().ok, isFalse);
      expect(ex.pingOutput(), contains('From 192.168.1.1 icmp_seq=1'));
      expect(ex.solutionCisco, 'ip route 172.16.5.0 255.255.255.0 10.0.0.2');

      bool ok(String rt, String route) =>
          checkMissingRoute(ex, rt, route).check.correct;
      expect(ok('R1', 'ip route add 172.16.5.0/24 via 10.0.0.2'), isTrue);
      expect(ok('r1', 'ip route 172.16.5.0 255.255.255.0 10.0.0.2'), isTrue);
      expect(ok('R1', 'ip route add default via 10.0.0.2'), isTrue);
      expect(ok('R1', 'ip route add 172.16.0.0/16 via 10.0.0.2'), isTrue);
      // Mauvais routeur, passerelle hors réseau connecté, mauvaise adresse réseau.
      expect(ok('R2', 'ip route add 172.16.5.0/24 via 10.0.0.1'), isFalse);
      expect(ok('R1', 'ip route add 172.16.5.0/24 via 172.16.5.1'), isFalse);
      expect(ok('R1', 'ip route add 172.16.5.7/24 via 10.0.0.2'), isFalse);
      expect(ok('R1', 'ip route add 172.16.6.0/24 via 10.0.0.2'), isFalse);
      expect(ok('R1', 'ip route add 192.168.1.0/24 via 10.0.0.2'), isFalse);
      // Bug corrigé : une route plus précise que le LAN (/32, demi-réseau) faisait
      // passer ce ping et était acceptée, alors que le reste du LAN restait injoignable.
      expect(ok('R1', 'ip route add 172.16.5.20/32 via 10.0.0.2'), isFalse);
      expect(ok('R1', 'ip route add 172.16.5.0/25 via 10.0.0.2'), isFalse);
      expect(
          checkMissingRoute(ex, 'R1', 'ip route add 172.16.5.0/25 via 10.0.0.2')
              .check
              .explanation,
          contains('réseau entier'));
      // Bug corrigé : interface de sortie Cisco (avec « / ») prise pour un réseau.
      expect(
          ok('R1',
              'ip route 172.16.5.0 255.255.255.0 GigabitEthernet0/1 10.0.0.2'),
          isTrue);
      final res = checkMissingRoute(ex, 'R1', '172.16.5.0/24 via 10.0.0.2');
      expect(res.check.explanation, contains('Le ping réussit'));
      expect(res.check.explanation, contains('ET'));
    });
  });

  group('200 graines', () {
    for (final mode in [RoutingMode.debutant, RoutingMode.avance]) {
      for (final os in RoutingOs.values) {
        test('table ${mode.name} ${os.name}', () {
          var sansRoute = 0;
          for (var seed = 0; seed < 200; seed++) {
            final ex = generateRoutingTableExercise(TrainingRandom(seed),
                mode: mode, os: os);
            final routes = ex.table.routes;
            expect(ex.table.render(), isNotEmpty);
            expect(ex.destinations.toSet().length, ex.destinations.length);
            if (mode == RoutingMode.debutant) {
              expect(routes.any((r) => r.isDefault), isTrue);
            } else {
              final ps = routes.map((r) => r.prefix).toSet();
              expect(ps.containsAll([16, 24, 26]), isTrue);
            }
            final ifs = <String>[];
            final gws = <String>[];
            for (var i = 0; i < ex.destinations.length; i++) {
              final exp = independentLookup(routes, ex.destinations[i]);
              final got = ex.lookup(i).chosen;
              expect(identical(got, exp), isTrue, reason: 'graine $seed');
              if (exp == null) {
                sansRoute++;
                ifs.add('');
                gws.add('aucune');
              } else {
                ifs.add(ex.table.ifaceLabel(exp.iface));
                gws.add(
                    exp.gateway == null ? 'direct' : ipToString(exp.gateway!));
                // Un candidat doit gagner nettement (pas d'égalité de métrique).
                final ties = ex.lookup(i).matches.where(
                    (r) => r.prefix == exp.prefix && r.metric == exp.metric);
                expect(ties.length, 1, reason: 'graine $seed');
              }
            }
            final good = checkRoutingTable(ex, ifs, gws);
            expect(good.check.correct, isTrue,
                reason: 'graine $seed\n${good.check.explanation}');
            final bad = checkRoutingTable(ex, List.filled(ifs.length, 'eth9'),
                List.filled(ifs.length, '1.2.3.4'));
            expect(bad.check.correct, isFalse);
          }
          if (mode == RoutingMode.avance) expect(sansRoute, greaterThan(0));
        });
      }
    }

    test('route manquante', () {
      for (var seed = 0; seed < 200; seed++) {
        final ex = generateMissingRouteExercise(TrainingRandom(seed));
        expect(ex.routers.length, inInclusiveRange(2, 3));
        final cur = ex.currentPing();
        expect(cur.ok, isFalse, reason: 'graine $seed');
        final failed = cur.reply ?? cur.request;
        expect(failed.failure, 'route');
        expect(failed.failedAt!.name, ex.removedRouter);
        expect(ex.pingOutput(), contains('100% packet loss'));
        for (final sol in [
          ex.solutionLinux,
          ex.solutionCisco,
          ex.solutionWindows
        ]) {
          final res = checkMissingRoute(ex, ex.removedRouter, sol);
          expect(res.check.correct, isTrue,
              reason: 'graine $seed $sol\n${res.check.explanation}');
          expect(res.routerOk && res.routeOk, isTrue);
        }
        // La même route sur un autre routeur est refusée ou ne suffit pas.
        for (final other
            in ex.routers.where((d) => d.name != ex.removedRouter)) {
          expect(
              checkMissingRoute(ex, other.name, ex.solutionLinux).check.correct,
              isFalse,
              reason: 'graine $seed');
        }
        expect(checkMissingRoute(ex, 'R9', ex.solutionLinux).check.correct,
            isFalse);
        // Route vers la seule machine visée : le ping passerait, mais refusée.
        final tip = cur.request.delivered
            ? ex.source.ifaces.first.ip
            : ex.target.ifaces.first.ip;
        final gw = ipToString(ex.removedRoute.gateway!);
        final host = checkMissingRoute(
            ex, ex.removedRouter, 'ip route add ${ipToString(tip)}/32 via $gw');
        expect(host.check.correct, isFalse, reason: 'graine $seed');
        expect(host.routerOk, isTrue);
        expect(
            checkMissingRoute(ex, ex.removedRouter, 'n\'importe quoi')
                .check
                .correct,
            isFalse);
        // L'exercice n'a pas été modifié par les vérifications.
        expect(ex.currentPing().ok, isFalse);
      }
    });
  });

  testWidgets('le widget s\'affiche et compte les tentatives', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: RoutingTrainer())));
    expect(find.text('Tables de routage'), findsOneWidget);
    await tester.ensureVisible(find.text('Vérifier'));
    await tester.tap(find.text('Vérifier'));
    await tester.pump();
    expect(find.text('0 / 1'), findsOneWidget);
    await tester.tap(find.text('Route manquante'));
    await tester.pump();
    expect(find.text('Routeur à corriger'), findsOneWidget);
    await tester.ensureVisible(find.text('Nouvel exercice'));
    await tester.tap(find.text('Nouvel exercice'));
    await tester.pump();
  });
}
