import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class AsciiToolScreen extends StatefulWidget {
  const AsciiToolScreen({super.key});

  @override
  State<AsciiToolScreen> createState() => _AsciiToolScreenState();
}

class _AsciiToolScreenState extends State<AsciiToolScreen> {
  final _textCtrl = TextEditingController();
  final _hexCtrl = TextEditingController();
  final _binCtrl = TextEditingController();
  final _decCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Convertisseur ASCII',
        showBackButton: true,
      );
    });
  }

  void _onTextChange(String s) {
    if (s.isEmpty) { _clearAll(); return; }
    final bytes = s.codeUnits;
    _hexCtrl.text = bytes.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ');
    _binCtrl.text = bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join(' ');
    _decCtrl.text = bytes.map((b) => b.toString()).join(' ');
  }

  void _onHexChange(String s) {
    try {
      final bytes = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).map((e) => int.parse(e, radix: 16)).toList();
      _textCtrl.text = String.fromCharCodes(bytes);
      _binCtrl.text = bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join(' ');
      _decCtrl.text = bytes.map((b) => b.toString()).join(' ');
    } catch (_) {}
  }

  void _clearAll() {
    _textCtrl.clear(); _hexCtrl.clear(); _binCtrl.clear(); _decCtrl.clear();
  }

  @override
  void dispose() { _textCtrl.dispose(); _hexCtrl.dispose(); _binCtrl.dispose(); _decCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          _buildCard('TEXTE (String)', _textCtrl, (s) => _onTextChange(s), maxLines: 2),
          const SizedBox(height: 16),
          _buildCard('HEXADÉCIMAL', _hexCtrl, (s) => _onHexChange(s), maxLines: 2),
          const SizedBox(height: 16),
          _buildCard('BINAIRE', _binCtrl, (s) => {}, maxLines: 4, readOnly: true),
          const SizedBox(height: 16),
          _buildCard('DÉCIMAL', _decCtrl, (s) => {}, maxLines: 2, readOnly: true),
        ],
      ),
    );
  }

  Widget _buildCard(String label, TextEditingController ctrl, Function(String) onChanged, {int maxLines = 1, bool readOnly = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            readOnly: readOnly,
            onChanged: onChanged,
            style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 14),
            decoration: const InputDecoration(border: InputBorder.none, filled: true, fillColor: TdcColors.surfaceAlt),
          ),
        ],
      ),
    );
  }
}
