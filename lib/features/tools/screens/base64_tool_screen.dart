import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class Base64ToolScreen extends StatefulWidget {
  const Base64ToolScreen({super.key});

  @override
  State<Base64ToolScreen> createState() => _Base64ToolScreenState();
}

class _Base64ToolScreenState extends State<Base64ToolScreen> {
  final _inputCtrl = TextEditingController();
  String _output = '';
  bool _encodeMode = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Encodeur / Décodeur Base64',
        showBackButton: true,
        actions: [],
      );
    });
  }

  void _process() {
    final input = _inputCtrl.text.trim();
    if (input.isEmpty) { setState(() { _output = ''; _error = null; }); return; }
    setState(() {
      _error = null;
      try {
        if (_encodeMode) {
          _output = base64.encode(utf8.encode(input));
        } else {
          _output = utf8.decode(base64.decode(input));
        }
      } catch (_) {
        _error = 'Entrée invalide pour le décodage Base64.';
        _output = '';
      }
    });
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          _buildInputCard(),
          const SizedBox(height: 24),
          if (_error != null || _output.isNotEmpty) _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _modeButton('ENCODER', true),
              const SizedBox(width: 8),
              _modeButton('DÉCODER', false),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _inputCtrl,
            maxLines: 6,
            style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              labelText: _encodeMode ? 'Texte à encoder' : 'Base64 à décoder',
              filled: true,
              fillColor: TdcColors.surfaceAlt,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _process,
              icon: Icon(_encodeMode ? Icons.arrow_forward : Icons.arrow_back),
              label: Text(_encodeMode ? 'ENCODER MAINTENANT' : 'DÉCODER MAINTENANT'),
              style: ElevatedButton.styleFrom(backgroundColor: TdcColors.accent, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool mode) {
    final active = _encodeMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() { _encodeMode = mode; _output = ''; _error = null; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? TdcColors.accent.withOpacity(0.1) : Colors.transparent,
            borderRadius: TdcRadius.sm,
            border: Border.all(color: active ? TdcColors.accent : TdcColors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: active ? TdcColors.accent : TdcColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RÉSULTAT', style: TextStyle(color: TdcColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              if (_output.isNotEmpty) IconButton(icon: const Icon(Icons.copy, size: 16, color: TdcColors.accent), onPressed: () => Clipboard.setData(ClipboardData(text: _output)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: TdcColors.danger, fontSize: 13))
          else
            Text(_output, style: const TextStyle(color: TdcColors.accent, fontFamily: 'monospace', fontSize: 14)),
        ],
      ),
    );
  }
}
