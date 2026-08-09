// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/utils/ip_helper.dart';

SubnetResult calculateSubnet(String ipStr, int mask) {
  return IpHelper.calculateSubnet(ipStr, mask);
}

String numToIp(int num) {
  return IpHelper.numToIp(num);
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
