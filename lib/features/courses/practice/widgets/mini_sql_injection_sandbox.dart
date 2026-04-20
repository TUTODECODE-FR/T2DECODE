import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class MiniSqlInjectionSandbox extends StatefulWidget {
  const MiniSqlInjectionSandbox({super.key});

  @override
  State<MiniSqlInjectionSandbox> createState() => _MiniSqlInjectionSandboxState();
}

class _MiniSqlInjectionSandboxState extends State<MiniSqlInjectionSandbox> {
  final TextEditingController _input = TextEditingController(text: "admin' OR '1'='1");
  bool _useParam = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool get _looksLikeInjection {
    final s = _input.text.toLowerCase();
    if (_useParam) return false;
    return s.contains("' or") ||
        s.contains("\" or") ||
        s.contains("--") ||
        s.contains("/*") ||
        s.contains("1=1") ||
        s.contains("union select");
  }

  @override
  Widget build(BuildContext context) {
    final query = _useParam
        ? "SELECT * FROM users WHERE username = ?;"
        : "SELECT * FROM users WHERE username = '${_input.text}';";

    final badgeColor = _useParam
        ? TdcColors.success
        : (_looksLikeInjection ? TdcColors.danger : TdcColors.warning);
    final badgeText =
        _useParam ? 'Requête paramétrée' : (_looksLikeInjection ? 'Risque injection' : 'Concaténation fragile');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined, size: 16, color: TdcColors.textMuted),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mini‑sandbox (simulation locale)',
                  style: TextStyle(color: TdcColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  border: Border.all(color: badgeColor.withOpacity(0.25)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _input,
            style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Entrée utilisateur',
              labelStyle: TextStyle(color: TdcColors.textMuted),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TdcColors.border)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: TdcColors.accent)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            value: _useParam,
            onChanged: (v) => setState(() => _useParam = v),
            title: const Text('Utiliser une requête paramétrée',
                style: TextStyle(color: TdcColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            subtitle: const Text('Réduit le risque lié à la concaténation de chaînes.',
                style: TextStyle(color: TdcColors.textMuted, fontSize: 12)),
            contentPadding: EdgeInsets.zero,
            activeColor: TdcColors.accent,
          ),
          const SizedBox(height: 8),
          const Text('Requête générée (simulation):',
              style: TextStyle(color: TdcColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              border: Border.all(color: TdcColors.border),
            ),
            child: SelectableText(
              query,
              style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 11, height: 1.35),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'But pédagogique : comprendre le mécanisme. Aucune base de données, aucune attaque réelle.',
            style: TextStyle(color: TdcColors.textMuted, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }
}

