// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter_test/flutter_test.dart';

String numToIp(int num) =>
    '${(num >> 24) & 0xFF}.${(num >> 16) & 0xFF}.${(num >> 8) & 0xFF}.${num & 0xFF}';

class SubnetResult {
  final String network, broadcast, firstHost, lastHost, numHosts, netmask;
  SubnetResult({required this.network, required this.broadcast, required this.firstHost,
    required this.lastHost, required this.numHosts, required this.netmask});
}

SubnetResult calculateSubnet(String ipStr, int mask) {
  final ipParts = ipStr.split('.').map(int.parse).toList();
  if (ipParts.length != 4) throw FormatException('Invalid IP');
  if (mask < 0 || mask > 32) throw FormatException('Invalid mask');

  int ipNum = (ipParts[0] << 24) | (ipParts[1] << 16) | (ipParts[2] << 8) | ipParts[3];
  int maskNum = mask == 0 ? 0 : (0xFFFFFFFF << (32 - mask)) & 0xFFFFFFFF;
  int networkNum = ipNum & maskNum;
  int broadcastNum = networkNum | (~maskNum & 0xFFFFFFFF);

  final network = numToIp(networkNum);
  final broadcast = numToIp(broadcastNum);
  final netmask = numToIp(maskNum);
  String firstHost, lastHost, numHosts;

  if (mask < 31) {
    firstHost = numToIp(networkNum + 1);
    lastHost = numToIp(broadcastNum - 1);
    numHosts = (broadcastNum - networkNum - 1).toString();
  } else if (mask == 31) {
    firstHost = numToIp(networkNum);
    lastHost = numToIp(broadcastNum);
    numHosts = '2 (P2P)';
  } else {
    firstHost = numToIp(networkNum);
    lastHost = numToIp(networkNum);
    numHosts = '1';
  }

  return SubnetResult(network: network, broadcast: broadcast, firstHost: firstHost,
    lastHost: lastHost, numHosts: numHosts, netmask: netmask);
}

void main() {
  group('IP Calculator - Standard subnets', () {
    test('/24 class C', () {
      final r = calculateSubnet('192.168.1.100', 24);
      expect(r.network, '192.168.1.0');
      expect(r.broadcast, '192.168.1.255');
      expect(r.firstHost, '192.168.1.1');
      expect(r.lastHost, '192.168.1.254');
      expect(r.numHosts, '254');
      expect(r.netmask, '255.255.255.0');
    });

    test('/16 class B', () {
      final r = calculateSubnet('172.16.5.42', 16);
      expect(r.network, '172.16.0.0');
      expect(r.broadcast, '172.16.255.255');
      expect(r.firstHost, '172.16.0.1');
      expect(r.lastHost, '172.16.255.254');
      expect(r.numHosts, '65534');
      expect(r.netmask, '255.255.0.0');
    });

    test('/8 class A', () {
      final r = calculateSubnet('10.0.0.1', 8);
      expect(r.network, '10.0.0.0');
      expect(r.broadcast, '10.255.255.255');
      expect(r.numHosts, '16777214');
    });
  });

  group('IP Calculator - VLSM subnets', () {
    test('/25 splits /24 in half', () {
      final r = calculateSubnet('192.168.1.200', 25);
      expect(r.network, '192.168.1.128');
      expect(r.broadcast, '192.168.1.255');
      expect(r.numHosts, '126');
    });

    test('/28 small subnet', () {
      final r = calculateSubnet('10.10.10.100', 28);
      expect(r.network, '10.10.10.96');
      expect(r.broadcast, '10.10.10.111');
      expect(r.firstHost, '10.10.10.97');
      expect(r.lastHost, '10.10.10.110');
      expect(r.numHosts, '14');
      expect(r.netmask, '255.255.255.240');
    });

    test('/30 point-to-point link', () {
      final r = calculateSubnet('192.168.1.5', 30);
      expect(r.network, '192.168.1.4');
      expect(r.broadcast, '192.168.1.7');
      expect(r.firstHost, '192.168.1.5');
      expect(r.lastHost, '192.168.1.6');
      expect(r.numHosts, '2');
    });
  });

  group('IP Calculator - Edge cases', () {
    test('/31 point-to-point (RFC 3021)', () {
      final r = calculateSubnet('192.168.1.4', 31);
      expect(r.network, '192.168.1.4');
      expect(r.broadcast, '192.168.1.5');
      expect(r.numHosts, '2 (P2P)');
    });

    test('/32 host route', () {
      final r = calculateSubnet('192.168.1.1', 32);
      expect(r.network, '192.168.1.1');
      expect(r.firstHost, '192.168.1.1');
      expect(r.lastHost, '192.168.1.1');
      expect(r.numHosts, '1');
      expect(r.netmask, '255.255.255.255');
    });

    test('/0 default route', () {
      final r = calculateSubnet('0.0.0.0', 0);
      expect(r.network, '0.0.0.0');
      expect(r.broadcast, '255.255.255.255');
    });

    test('invalid mask throws', () {
      expect(() => calculateSubnet('192.168.1.1', 33), throwsA(isA<FormatException>()));
      expect(() => calculateSubnet('192.168.1.1', -1), throwsA(isA<FormatException>()));
    });

    test('invalid IP throws', () {
      expect(() => calculateSubnet('not.an.ip', 24), throwsA(anything));
    });
  });

  group('numToIp', () {
    test('converts correctly', () {
      expect(numToIp(0), '0.0.0.0');
      expect(numToIp(0xFFFFFFFF), '255.255.255.255');
      expect(numToIp(0xC0A80101), '192.168.1.1');
    });
  });
}
