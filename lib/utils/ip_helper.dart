// SPDX-License-Identifier: GPL-3.0-only

class SubnetResult {
  final String network;
  final String broadcast;
  final String firstHost;
  final String lastHost;
  final String numHosts;
  final String netmask;

  SubnetResult({
    required this.network,
    required this.broadcast,
    required this.firstHost,
    required this.lastHost,
    required this.numHosts,
    required this.netmask,
  });
}

class IpHelper {
  static String numToIp(int num) =>
      '${(num >> 24) & 0xFF}.${(num >> 16) & 0xFF}.${(num >> 8) & 0xFF}.${num & 0xFF}';

  static SubnetResult calculateSubnet(String ipStr, int mask) {
    final ipParts = ipStr.split('.').map(int.parse).toList();
    if (ipParts.length != 4) throw const FormatException('Invalid IP address format');
    for (final part in ipParts) {
      if (part < 0 || part > 255) throw const FormatException('IP segments must be between 0 and 255');
    }
    if (mask < 0 || mask > 32) throw const FormatException('CIDR mask must be between 0 and 32');

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

    return SubnetResult(
      network: network,
      broadcast: broadcast,
      firstHost: firstHost,
      lastHost: lastHost,
      numHosts: numHosts,
      netmask: netmask,
    );
  }
}
