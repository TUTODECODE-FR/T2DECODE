import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class MiniDnsSandbox extends StatefulWidget {
  const MiniDnsSandbox({super.key});

  @override
  State<MiniDnsSandbox> createState() => _MiniDnsSandboxState();
}

class _MiniDnsSandboxState extends State<MiniDnsSandbox> {
  final TextEditingController _domain = TextEditingController(text: 'example.com');
  int _step = 0;

  @override
  void dispose() {
    _domain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      "Le client demande l'IP de ${_domain.text}",
      "Le résolveur consulte son cache et interroge le DNS (simulation)",
      "Réponse: IP (fictive) → connexion possible",
    ];

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
              const Icon(Icons.dns_outlined, size: 16, color: TdcColors.textMuted),
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
                  color: TdcColors.info.withOpacity(0.12),
                  border: Border.all(color: TdcColors.info.withOpacity(0.25)),
                ),
                child: const Text(
                  'DNS',
                  style: TextStyle(color: TdcColors.info, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _domain,
            style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Domaine',
              labelStyle: TextStyle(color: TdcColors.textMuted),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TdcColors.border)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: TdcColors.accent)),
            ),
            onChanged: (_) => setState(() => _step = 0),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_step + 1) / steps.length,
                  backgroundColor: TdcColors.border,
                  color: TdcColors.info,
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_step + 1}/${steps.length}',
                style: const TextStyle(color: TdcColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              border: Border.all(color: TdcColors.border),
            ),
            child: Text(
              steps[_step],
              style: const TextStyle(color: TdcColors.textPrimary, fontSize: 12, height: 1.35),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: _step == 0 ? null : () => setState(() => _step--),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Précédent'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _step == steps.length - 1 ? null : () => setState(() => _step++),
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Suivant'),
                style: ElevatedButton.styleFrom(backgroundColor: TdcColors.accent),
              ),
            ],
          ),
          const Text(
            'But pédagogique : visualiser la résolution DNS. Aucune requête réseau n’est envoyée ici.',
            style: TextStyle(color: TdcColors.textMuted, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }
}

