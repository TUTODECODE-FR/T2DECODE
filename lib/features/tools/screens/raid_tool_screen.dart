import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class RaidToolScreen extends StatefulWidget {
  const RaidToolScreen({super.key});

  @override
  State<RaidToolScreen> createState() => _RaidToolScreenState();
}

class _RaidToolScreenState extends State<RaidToolScreen> {
  String _selectedLevel = 'RAID 5';
  double _diskCount = 3;
  double _diskSize = 1000; // GB

  final List<String> _raidLevels = ['RAID 0', 'RAID 1', 'RAID 5', 'RAID 6', 'RAID 10'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Calculateur RAID',
        showBackButton: true,
      );
    });
  }

  Map<String, double> _calculate() {
    double usable = 0;
    double faultTolerance = 0;
    
    switch (_selectedLevel) {
      case 'RAID 0':
        usable = _diskCount * _diskSize;
        faultTolerance = 0;
        break;
      case 'RAID 1':
        usable = _diskSize;
        faultTolerance = _diskCount - 1;
        break;
      case 'RAID 5':
        if (_diskCount < 3) _diskCount = 3;
        usable = (_diskCount - 1) * _diskSize;
        faultTolerance = 1;
        break;
      case 'RAID 6':
        if (_diskCount < 4) _diskCount = 4;
        usable = (_diskCount - 2) * _diskSize;
        faultTolerance = 2;
        break;
      case 'RAID 10':
        if (_diskCount < 4) _diskCount = 4;
        if (_diskCount % 2 != 0) _diskCount++;
        usable = (_diskCount / 2) * _diskSize;
        faultTolerance = _diskCount / 2;
        break;
    }
    return {'usable': usable, 'faultTolerance': faultTolerance, 'total': _diskCount * _diskSize};
  }

  @override
  Widget build(BuildContext context) {
    final results = _calculate();
    return TdcPageWrapper(
      child: ListView(
        children: [
          _buildResultCard(results),
          const SizedBox(height: 24),
          _buildConfigCard(),
          const SizedBox(height: 24),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, double> res) {
    final usableGB = res['usable']!;
    final totalGB = res['total']!;
    final efficiency = (usableGB / totalGB) * 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('CAPACITÉ UTILE', '${(usableGB / 1000).toStringAsFixed(1)} TB'),
              _buildStat('TOLÉRANCE', '${res['faultTolerance']!.toInt()} Disque(s)'),
              _buildStat('EFFICIENCE', '${efficiency.toInt()}%'),
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: efficiency / 100, backgroundColor: TdcColors.surfaceAlt, color: Colors.blue),
          const SizedBox(height: 8),
          Text('Stockage utilisé pour la redondance : ${((totalGB - usableGB) / 1000).toStringAsFixed(1)} TB', style: const TextStyle(fontSize: 10, color: TdcColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String val) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 10, color: TdcColors.textMuted, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TdcColors.accent)),
  ]);

  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONFIGURATION', style: TextStyle(fontWeight: FontWeight.bold, color: TdcColors.textMuted, fontSize: 10)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedLevel,
            dropdownColor: TdcColors.surface,
            decoration: const InputDecoration(labelText: 'Niveau RAID'),
            items: _raidLevels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => _selectedLevel = v!),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nombre de disques'),
              Text('${_diskCount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: TdcColors.accent)),
            ],
          ),
          Slider(value: _diskCount, min: 2, max: 24, divisions: 22, onChanged: (v) => setState(() => _diskCount = v)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Taille par disque (GB)'),
              Text('${_diskSize.toInt()} GB', style: const TextStyle(fontWeight: FontWeight.bold, color: TdcColors.accent)),
            ],
          ),
          Slider(value: _diskSize, min: 100, max: 20000, divisions: 100, onChanged: (v) => setState(() => _diskSize = v)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    String info = '';
    switch (_selectedLevel) {
      case 'RAID 0': info = 'Performance maximale, AUCUNE sécurité. Si un disque meurt, TOUT est perdu.'; break;
      case 'RAID 1': info = 'Miroir parfait. Très sûr, mais coûteux (50% de perte de stockage).'; break;
      case 'RAID 5': info = 'Le standard. Bon équilibre. Nécessite min. 3 disques. Supporte 1 panne.'; break;
      case 'RAID 6': info = 'Hyper-sécurisé. Supporte la panne de 2 disques simultanément.'; break;
      case 'RAID 10': info = 'Le meilleur des deux mondes. Rapide et sûr. Nécessite min. 4 disques.'; break;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: TdcRadius.md, border: Border.all(color: Colors.blue.withOpacity(0.2))),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(info, style: const TextStyle(fontSize: 12, color: TdcColors.textSecondary))),
        ],
      ),
    );
  }
}
