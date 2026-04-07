import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class IPCalcScreen extends StatefulWidget {
  const IPCalcScreen({super.key});
  @override State<IPCalcScreen> createState() => _IPCalcScreenState();
}

class _IPCalcScreenState extends State<IPCalcScreen> {
  final _ipController = TextEditingController(text: '192.168.1.1');
  final _maskController = TextEditingController(text: '24');

  String _network = '-';
  String _broadcast = '-';
  String _firstHost = '-';
  String _lastHost = '-';
  String _numHosts = '-';
  String _netmask = '-';
  final List<String> _history = [];

  void _calculate() {
    try {
      final ipStr = _ipController.text.trim();
      final maskStr = _maskController.text.trim();
      final ipParts = ipStr.split('.').map(int.parse).toList();
      if (ipParts.length != 4) throw Exception();
      final mask = int.parse(maskStr);
      if (mask < 0 || mask > 32) throw Exception();

      int ipNum = (ipParts[0] << 24) | (ipParts[1] << 16) | (ipParts[2] << 8) | ipParts[3];
      int maskNum = mask == 0 ? 0 : (0xFFFFFFFF << (32 - mask)) & 0xFFFFFFFF;
      int networkNum = ipNum & maskNum;
      int broadcastNum = networkNum | (~maskNum & 0xFFFFFFFF);
      
      final network = _numToIp(networkNum);
      final broadcast = _numToIp(broadcastNum);
      final netmask = _numToIp(maskNum);
      String firstHost, lastHost, numHosts;
      if (mask < 31) {
        firstHost = _numToIp(networkNum + 1);
        lastHost = _numToIp(broadcastNum - 1);
        numHosts = (broadcastNum - networkNum - 1).toString();
      } else if (mask == 31) {
        firstHost = _numToIp(networkNum);
        lastHost = _numToIp(broadcastNum);
        numHosts = '2 (P2P)';
      } else {
        firstHost = _numToIp(networkNum);
        lastHost = _numToIp(networkNum);
        numHosts = '1';
      }
      final entry = '$ipStr/$mask → $network';
      setState(() {
        _network = network;
        _broadcast = broadcast;
        _netmask = netmask;
        _firstHost = firstHost;
        _lastHost = lastHost;
        _numHosts = numHosts;
        if (_history.isEmpty || _history.first != entry) {
          _history.insert(0, entry);
          if (_history.length > 8) _history.removeLast();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Format IP ou Masque invalide'), behavior: SnackBarBehavior.floating));
    }
  }

  String _numToIp(int num) => '${(num >> 24) & 0xFF}.${(num >> 16) & 0xFF}.${(num >> 8) & 0xFF}.${num & 0xFF}';

  @override
  void initState() {
    super.initState();
    _calculate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Calculateur IP',
        showBackButton: true,
        actions: [],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          _buildCard('CONFIGURATION RÉSEAU', [
            Row(children: [
              Expanded(flex: 3, child: TextField(controller: _ipController, decoration: const InputDecoration(labelText: 'IP', hintText: '192.168.1.1'))),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: TextField(controller: _maskController, decoration: const InputDecoration(labelText: 'CIDR', hintText: '24'))),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: TdcColors.accent), child: const Text('CALCULER'))),
          ]),
          const SizedBox(height: 24),
          _buildCard('RÉSULTATS', [
            _row('Masque', _netmask),
            _row('Réseau', _network),
            _row('Broadcast', _broadcast),
            const Divider(height: 24),
            _row('Premier hôte', _firstHost),
            _row('Dernier hôte', _lastHost),
            _row('Hôtes valides', _numHosts),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: '${_ipController.text.trim()}/${_maskController.text.trim()} — Réseau: $_network | Masque: $_netmask | Premier: $_firstHost | Dernier: $_lastHost | Hôtes: $_numHosts')),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copier les résultats'),
                style: OutlinedButton.styleFrom(foregroundColor: TdcColors.accent),
              ),
            ),
          ]),
          if (_history.length > 1) ...[
            const SizedBox(height: 24),
            _buildCard('HISTORIQUE', [
              ..._history.skip(1).map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    final parts = h.split('/');
                    if (parts.length >= 2) {
                      _ipController.text = parts[0];
                      _maskController.text = parts[1].split(' ').first;
                      _calculate();
                    }
                  },
                  child: Row(children: [
                    const Icon(Icons.history, size: 12, color: TdcColors.textMuted),
                    const SizedBox(width: 8),
                    Text(h, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12, fontFamily: 'monospace')),
                  ]),
                ),
              )),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13)),
      Text(value, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
    ]));
  }
}
