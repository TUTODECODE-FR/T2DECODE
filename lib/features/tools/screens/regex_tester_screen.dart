// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class RegexTesterScreen extends StatefulWidget {
  const RegexTesterScreen({super.key});

  @override
  State<RegexTesterScreen> createState() => _RegexTesterScreenState();
}

class _RegexTesterScreenState extends State<RegexTesterScreen> {
  final _regexController = TextEditingController();
  final _textController = TextEditingController();
  
  bool _caseSensitive = true;
  bool _multiLine = true;
  String _error = '';
  List<RegExpMatch> _matches = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Testeur Regex',
        showBackButton: true,
        actions: [],
      );
    });
    
    // Initial values
    _regexController.text = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}';
    _textController.text = "Contactez-nous a support@tutodecode.org ou admin@t2decode.local pour plus d'infos.";
    _evaluateRegex();
  }

  void _evaluateRegex() {
    setState(() {
      _error = '';
      _matches = [];
      if (_regexController.text.isEmpty) return;
      
      try {
        final regex = RegExp(
          _regexController.text,
          caseSensitive: _caseSensitive,
          multiLine: _multiLine,
        );
        _matches = regex.allMatches(_textController.text).toList();
      } catch (e) {
        _error = 'Syntaxe Regex invalide';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          const TdcToolHeader(
            title: 'Testeur Regex',
            description: 'Analysez et testez vos expressions régulières avec coloration syntaxique.',
            howToUse: 'Saisissez votre expression régulière dans le champ du haut. Le texte à analyser se trouve en dessous. Le système extraira automatiquement toutes les correspondances (matches) en temps réel. Vous pouvez activer ou désactiver la sensibilité à la casse (Case Sensitive) et le mode multiligne.',
          ),
          _buildRegexInput(),
          const SizedBox(height: 24),
          SizedBox(
            height: 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildTextInput()),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: _buildMatchesList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegexInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: _error.isNotEmpty ? TdcColors.danger : TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('EXPRESSION RÉGULIÈRE', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: [
                  const Text('Case Sensitive', style: TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
                  Switch(
                    value: _caseSensitive,
                    activeThumbColor: TdcColors.accent,
                    onChanged: (v) { setState(() => _caseSensitive = v); _evaluateRegex(); },
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Text('Multiline', style: TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
                  Switch(
                    value: _multiLine,
                    activeThumbColor: TdcColors.accent,
                    onChanged: (v) { setState(() => _multiLine = v); _evaluateRegex(); },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _regexController,
            onChanged: (_) => _evaluateRegex(),
            style: const TextStyle(color: TdcColors.textPrimary, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: '/',
              suffixText: '/',
              prefixStyle: TextStyle(color: TdcColors.textMuted, fontSize: 18),
              suffixStyle: TextStyle(color: TdcColors.textMuted, fontSize: 18),
              filled: true,
              fillColor: TdcColors.bg,
              border: OutlineInputBorder(borderRadius: TdcRadius.sm, borderSide: BorderSide.none),
            ),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error, style: const TextStyle(color: TdcColors.danger, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
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
          const Text('TEXTE À ANALYSER', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                // Highlighted Text underneath
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: TdcColors.bg,
                    borderRadius: TdcRadius.sm,
                  ),
                  child: SingleChildScrollView(
                    child: RichText(
                      text: _buildHighlightedText(),
                    ),
                  ),
                ),
                // Invisible TextField on top for editing
                TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  onChanged: (_) => _evaluateRegex(),
                  style: const TextStyle(color: Colors.transparent, fontSize: 14, fontFamily: 'monospace', height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  cursorColor: TdcColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildHighlightedText() {
    final text = _textController.text;
    if (_matches.isEmpty || _error.isNotEmpty) {
      return TextSpan(text: text, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 14, fontFamily: 'monospace', height: 1.5));
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (int i = 0; i < _matches.length; i++) {
      final match = _matches[i];
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(color: TdcColors.textPrimary, fontSize: 14, fontFamily: 'monospace', height: 1.5),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(
          color: Colors.black,
          backgroundColor: i % 2 == 0 ? TdcColors.accent : TdcColors.info,
          fontSize: 14,
          fontFamily: 'monospace',
          height: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(color: TdcColors.textPrimary, fontSize: 14, fontFamily: 'monospace', height: 1.5),
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildMatchesList() {
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
          Row(
            children: [
              const Text('RÉSULTATS', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: TdcColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_matches.length} matches', style: const TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _matches.isEmpty 
              ? const Center(child: Text('Aucune correspondance', style: TextStyle(color: TdcColors.textMuted)))
              : ListView.builder(
                  itemCount: _matches.length,
                  itemBuilder: (context, i) {
                    final m = _matches[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TdcColors.bg,
                        border: Border.all(color: TdcColors.border),
                        borderRadius: TdcRadius.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Match #${i+1}', style: const TextStyle(color: TdcColors.textMuted, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(m.group(0) ?? '', style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13, fontFamily: 'monospace')),
                          if (m.groupCount > 0) ...[
                            const SizedBox(height: 8),
                            const Text('Groupes:', style: TextStyle(color: TdcColors.textSecondary, fontSize: 10)),
                            for (int j = 1; j <= m.groupCount; j++)
                              Text(' $j: ${m.group(j)}', style: const TextStyle(color: TdcColors.info, fontSize: 11, fontFamily: 'monospace')),
                          ]
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
