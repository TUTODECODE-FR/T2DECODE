import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class HashToolScreen extends StatefulWidget {
  const HashToolScreen({super.key});

  @override
  State<HashToolScreen> createState() => _HashToolScreenState();
}

class _HashToolScreenState extends State<HashToolScreen> {
  final _inputCtrl = TextEditingController();
  String _algo = 'SHA-256';
  String _output = '';
  final List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Générateur de Hash',
        showBackButton: true,
        actions: [],
      );
    });
  }

  void _generate() {
    final input = _inputCtrl.text;
    final bytes = utf8.encode(input);
    Digest digest;
    
    switch (_algo) {
      case 'MD5': digest = md5.convert(bytes); break;
      case 'SHA-1': digest = sha1.convert(bytes); break;
      case 'SHA-256': digest = sha256.convert(bytes); break;
      default: digest = sha256.convert(bytes);
    }
    
    final result = digest.toString();
    setState(() {
      _output = result;
      if (input.isNotEmpty) {
        _history.insert(0, {'algo': _algo, 'input': input.length > 40 ? '${input.substring(0, 40)}…' : input, 'hash': result});
        if (_history.length > 10) _history.removeLast();
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
          if (_output.isNotEmpty) _buildResultCard(),
          if (_history.length > 1) ...[
            const SizedBox(height: 24),
            _buildHistoryCard(),
          ],
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
          const Text('CONFIGURATION', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildAlgoPicker(),
          const SizedBox(height: 24),
          TextField(
            controller: _inputCtrl,
            maxLines: 4,
            style: const TextStyle(color: TdcColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Texte à hasher',
              filled: true,
              fillColor: TdcColors.surfaceAlt,
            ),
            onChanged: (v) => _generate(),
          ),
        ],
      ),
    );
  }

  static const _deprecatedAlgos = {'MD5', 'SHA-1'};

  Widget _buildAlgoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['MD5', 'SHA-1', 'SHA-256'].map((a) {
            final active = _algo == a;
            final deprecated = _deprecatedAlgos.contains(a);
            return InkWell(
              onTap: () => setState(() { _algo = a; _generate(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? TdcColors.accent.withOpacity(0.1) : Colors.transparent,
                  borderRadius: TdcRadius.sm,
                  border: Border.all(color: active ? TdcColors.accent : TdcColors.border),
                ),
                child: Column(
                  children: [
                    Text(a, style: TextStyle(color: active ? TdcColors.accent : TdcColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                    if (deprecated)
                      const Text('⚠ obsolète', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_deprecatedAlgos.contains(_algo)) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: TdcRadius.sm,
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _algo == 'MD5'
                        ? 'MD5 est cryptographiquement cassé. Ne pas utiliser pour la sécurité — collisions triviales connues depuis 2004.'
                        : 'SHA-1 est cryptographiquement cassé. Attaque SHAttered démontrée en 2017. Utiliser SHA-256 ou supérieur.',
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HISTORIQUE', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              InkWell(onTap: () => setState(() => _history.clear()), child: const Text('Effacer', style: TextStyle(color: TdcColors.textMuted, fontSize: 11))),
            ],
          ),
          const SizedBox(height: 16),
          ..._history.skip(1).map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: TdcColors.surfaceAlt, borderRadius: TdcRadius.sm),
                  child: Text(h['algo']!, style: const TextStyle(color: TdcColors.textMuted, fontSize: 10, fontFamily: 'monospace')),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(h['input']!, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: h['hash']!)),
                  child: Text(
                    '${h['hash']!.substring(0, 12)}…',
                    style: const TextStyle(color: TdcColors.accent, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          )),
        ],
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
              Text('HASH $_algo', style: const TextStyle(color: TdcColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.copy, size: 16, color: TdcColors.accent), onPressed: () => Clipboard.setData(ClipboardData(text: _output)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 16),
          Text(_output, style: const TextStyle(color: TdcColors.accent, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
