import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class BandwidthToolScreen extends StatefulWidget {
  const BandwidthToolScreen({super.key});

  @override
  State<BandwidthToolScreen> createState() => _BandwidthToolScreenState();
}

class _BandwidthToolScreenState extends State<BandwidthToolScreen> {
  final _speedCtrl = TextEditingController(text: '100');
  final _sizeCtrl = TextEditingController(text: '1');
  String _speedUnit = 'Mbps';
  String _sizeUnit = 'GB';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Calculateur de Bande Passante',
        showBackButton: true,
      );
    });
  }

  String _calculateTime() {
    final speed = double.tryParse(_speedCtrl.text) ?? 0;
    final size = double.tryParse(_sizeCtrl.text) ?? 0;
    if (speed <= 0 || size <= 0) return '0s';

    // Convert speed to bits per second
    double bps = 0;
    switch (_speedUnit) {
      case 'Kbps': bps = speed * 1000; break;
      case 'Mbps': bps = speed * 1000 * 1000; break;
      case 'Gbps': bps = speed * 1000 * 1000 * 1000; break;
      case 'KB/s': bps = speed * 8000; break;
      case 'MB/s': bps = speed * 8 * 1000 * 1000; break;
    }

    // Convert size to bits
    double bits = 0;
    switch (_sizeUnit) {
      case 'KB': bits = size * 8 * 1024; break;
      case 'MB': bits = size * 8 * 1024 * 1024; break;
      case 'GB': bits = size * 8 * 1024 * 1024 * 1024; break;
      case 'TB': bits = size * 8 * 1024 * 1024 * 1024 * 1024; break;
    }

    double seconds = bits / bps;
    
    if (seconds < 60) return '${seconds.toStringAsFixed(1)} Seconds';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(1)} Minutes';
    return '${(seconds / 3600).toStringAsFixed(1)} Hours';
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          _buildResultCard(),
          const SizedBox(height: 24),
          _buildInputCard('VITESSE DE CONNEXION', _speedCtrl, _speedUnit, ['Kbps', 'Mbps', 'Gbps', 'KB/s', 'MB/s'], (v) => setState(() => _speedUnit = v!)),
          const SizedBox(height: 16),
          _buildInputCard('TAILLE DU FICHIER', _sizeCtrl, _sizeUnit, ['KB', 'MB', 'GB', 'TB'], (v) => setState(() => _sizeUnit = v!)),
          const SizedBox(height: 32),
          _buildCommonSpeeds(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.indigo.shade700]), borderRadius: TdcRadius.md),
      child: Column(
        children: [
          const Text('TEMPS DE TÉLÉCHARGEMENT ESTIMÉ', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(_calculateTime(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ajustez les paramètres ci-dessous', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildInputCard(String label, TextEditingController ctrl, String unit, List<String> units, Function(String?) onUnitChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: ctrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(filled: true, fillColor: TdcColors.surfaceAlt))),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: unit,
                dropdownColor: TdcColors.surface,
                items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: onUnitChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommonSpeeds() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VITESSES TYPES', style: TextStyle(color: TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _speedRow('ADSL (Moyenne)', '15 Mbps'),
        _speedRow('Fibre (Standard)', '300 Mbps'),
        _speedRow('Fibre (Giga)', '1 Gbps'),
        _speedRow('4G / LTE', '50 Mbps'),
        _speedRow('USB 2.0 (Max)', '480 Mbps'),
      ],
    );
  }

  Widget _speedRow(String label, String speed) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(speed, style: const TextStyle(fontWeight: FontWeight.bold, color: TdcColors.accent, fontSize: 12))]));
}
