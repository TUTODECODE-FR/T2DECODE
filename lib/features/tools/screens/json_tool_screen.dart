import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class JsonToolScreen extends StatefulWidget {
  const JsonToolScreen({super.key});

  @override
  State<JsonToolScreen> createState() => _JsonToolScreenState();
}

class _JsonToolScreenState extends State<JsonToolScreen> {
  final _inputCtrl = TextEditingController();
  final _outputCtrl = TextEditingController();
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Formateur JSON',
        showBackButton: true,
      );
    });
  }

  void _format() {
    setState(() { _error = ''; });
    final input = _inputCtrl.text.trim();
    if (input.isEmpty) return;

    try {
      final decoded = json.decode(input);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(decoded);
      setState(() => _outputCtrl.text = formatted);
    } catch (e) {
      setState(() => _error = 'JSON Invalide : ${e.toString()}');
    }
  }

  void _minify() {
    setState(() { _error = ''; });
    final input = _inputCtrl.text.trim();
    if (input.isEmpty) return;

    try {
      final decoded = json.decode(input);
      final minified = json.encode(decoded);
      setState(() => _outputCtrl.text = minified);
    } catch (e) {
      setState(() => _error = 'JSON Invalide : ${e.toString()}');
    }
  }

  @override
  void dispose() { _inputCtrl.dispose(); _outputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: Column(
        children: [
          _buildInputCard(),
          const SizedBox(height: 24),
          if (_error.isNotEmpty) _buildError(),
          Expanded(child: _buildOutputCard()),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        children: [
          TextField(
            controller: _inputCtrl,
            maxLines: 6,
            style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(labelText: 'Entrée JSON', filled: true, fillColor: TdcColors.surfaceAlt),
          ),
          const SizedBox(height: 16),
          Row(
             children: [
               Expanded(child: ElevatedButton.icon(onPressed: _format, icon: const Icon(Icons.format_indent_increase, size: 16), label: const Text('FORMATTER'), style: ElevatedButton.styleFrom(backgroundColor: TdcColors.accent))),
               const SizedBox(width: 8),
               Expanded(child: ElevatedButton.icon(onPressed: _minify, icon: const Icon(Icons.compress, size: 16), label: const Text('MINIFIER'), style: ElevatedButton.styleFrom(backgroundColor: TdcColors.surfaceAlt))),
             ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: TdcRadius.sm, border: Border.all(color: Colors.red)),
    child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 12)),
  );

  Widget _buildOutputCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RÉSULTAT', style: TextStyle(color: TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.copy, size: 16, color: TdcColors.accent), onPressed: () => Clipboard.setData(ClipboardData(text: _outputCtrl.text))),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _outputCtrl,
              readOnly: true,
              maxLines: null,
              style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
