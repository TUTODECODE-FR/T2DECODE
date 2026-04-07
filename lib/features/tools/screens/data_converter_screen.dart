import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class DataConverterScreen extends StatefulWidget {
  const DataConverterScreen({super.key});

  @override
  State<DataConverterScreen> createState() => _DataConverterScreenState();
}

class _DataConverterScreenState extends State<DataConverterScreen> {
  final _controller = TextEditingController(text: '1');
  String _fromUnit = 'GB';
  String _toUnit = 'MB';
  String _result = '1024';

  final Map<String, double> _units = {
    'B': 1,
    'KB': 1024,
    'MB': 1024 * 1024,
    'GB': 1024 * 1024 * 1024,
    'TB': 1024 * 1024 * 1024 * 1024,
    'PB': 1024 * 1024 * 1024 * 1024 * 1024,
  };

  @override
  void initState() {
    super.initState();
    _calculate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Convertisseur de Données',
        showBackButton: true,
        actions: [],
      );
    });
  }

  void _calculate() {
    final input = double.tryParse(_controller.text) ?? 0;
    final fromVal = _units[_fromUnit]!;
    final toVal = _units[_toUnit]!;
    final res = (input * fromVal) / toVal;
    
    setState(() {
      if (res == res.toInt()) {
        _result = res.toInt().toString();
      } else {
        _result = res.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          _buildConverterCard(),
          const SizedBox(height: 24),
          _buildQuickReferenceCard(),
        ],
      ),
    );
  }

  Widget _buildConverterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONVERSION UNITAIRE', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _calculate(),
                  style: const TextStyle(color: TdcColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Valeur',
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildUnitDropdown(_fromUnit, (v) => setState(() { _fromUnit = v!; _calculate(); })),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Icon(Icons.swap_vert, color: TdcColors.accent, size: 32)),
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TdcColors.bg,
                    borderRadius: TdcRadius.sm,
                    border: Border.all(color: TdcColors.border),
                  ),
                  child: Text(
                    _result,
                    style: const TextStyle(
                      color: TdcColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildUnitDropdown(_toUnit, (v) => setState(() { _toUnit = v!; _calculate(); })),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown(String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: TdcRadius.sm,
        border: Border.all(color: TdcColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: TdcColors.surface,
          items: _units.keys.map((String unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(unit, style: const TextStyle(color: TdcColors.textPrimary)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildQuickReferenceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RÉFÉRENCE RAPIDE (BASE 1024)', style: TextStyle(color: TdcColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _refRow('1 KB', '1,024 Bytes'),
          _refRow('1 MB', '1,024 KB'),
          _refRow('1 GB', '1,024 MB'),
          _refRow('1 TB', '1,024 GB'),
          _refRow('1 PB', '1,024 TB'),
        ],
      ),
    );
  }

  Widget _refRow(String unit, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(unit, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: TdcColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
