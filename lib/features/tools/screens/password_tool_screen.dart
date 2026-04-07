import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class PasswordToolScreen extends StatefulWidget {
  const PasswordToolScreen({super.key});

  @override
  State<PasswordToolScreen> createState() => _PasswordToolScreenState();
}

class _PasswordToolScreenState extends State<PasswordToolScreen> {
  double _length = 16;
  bool _useUpper = true;
  bool _useLower = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _generate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Générateur de Mots de Passe',
        showBackButton: true,
      );
    });
  }

  void _generate() {
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String charset = '';
    if (_useLower) charset += lower;
    if (_useUpper) charset += upper;
    if (_useNumbers) charset += numbers;
    if (_useSymbols) charset += symbols;

    if (charset.isEmpty) {
      setState(() => _password = '');
      return;
    }

    final rand = Random.secure();
    final pwd = List.generate(_length.toInt(), (index) => charset[rand.nextInt(charset.length)]).join();
    setState(() => _password = pwd);
  }

  double _calculateEntropy() {
    if (_password.isEmpty) return 0;
    int charsetSize = 0;
    if (_useLower) charsetSize += 26;
    if (_useUpper) charsetSize += 26;
    if (_useNumbers) charsetSize += 10;
    if (_useSymbols) charsetSize += 33;
    return _length * (log(charsetSize) / log(2));
  }

  Color _getStrengthColor(double entropy) {
    if (entropy < 40) return Colors.red;
    if (entropy < 60) return Colors.orange;
    if (entropy < 80) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getStrengthText(double entropy) {
    if (entropy < 40) return 'Très faible';
    if (entropy < 60) return 'Faible';
    if (entropy < 80) return 'Moyen';
    if (entropy < 100) return 'Fort';
    return 'Très fort';
  }

  @override
  Widget build(BuildContext context) {
    final entropy = _calculateEntropy();
    return TdcPageWrapper(
      child: ListView(
        children: [
          _buildResultCard(entropy),
          const SizedBox(height: 24),
          _buildOptionsCard(),
        ],
      ),
    );
  }

  Widget _buildResultCard(double entropy) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(_password, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: TdcColors.textPrimary))),
              IconButton(icon: const Icon(Icons.copy, color: TdcColors.accent), onPressed: () => Clipboard.setData(ClipboardData(text: _password))),
              IconButton(icon: const Icon(Icons.refresh, color: TdcColors.accent), onPressed: _generate),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('FORCE : ', style: TextStyle(fontSize: 10, color: TdcColors.textMuted, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStrengthColor(entropy).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStrengthColor(entropy), width: 0.5),
                ),
                child: Text(_getStrengthText(entropy).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStrengthColor(entropy))),
              ),
              const Spacer(),
              Text('${entropy.toInt()} bits d\'entropie', style: const TextStyle(fontSize: 10, color: TdcColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (entropy / 128).clamp(0, 1), backgroundColor: TdcColors.surfaceAlt, color: _getStrengthColor(entropy)),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LONGUEUR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('${_length.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: TdcColors.accent, fontSize: 18)),
            ],
          ),
          Slider(value: _length, min: 4, max: 64, onChanged: (v) => setState(() { _length = v; _generate(); })),
          const SizedBox(height: 16),
          const Text('CARACTÈRES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 16),
          _buildToggle('Majuscules (A-Z)', _useUpper, (v) => setState(() { _useUpper = v; _generate(); })),
          _buildToggle('Minuscules (a-z)', _useLower, (v) => setState(() { _useLower = v; _generate(); })),
          _buildToggle('Chiffres (0-9)', _useNumbers, (v) => setState(() { _useNumbers = v; _generate(); })),
          _buildToggle('Symboles (!@#\$)', _useSymbols, (v) => setState(() { _useSymbols = v; _generate(); })),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool val, Function(bool) onChanged) {
    return SwitchListTile(title: Text(label, style: const TextStyle(fontSize: 14)), value: val, onChanged: onChanged, contentPadding: EdgeInsets.zero, activeThumbColor: TdcColors.accent);
  }
}
