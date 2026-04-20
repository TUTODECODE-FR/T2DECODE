import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/widgets/lab_widgets.dart';

class CtfPrepSimulator extends StatelessWidget {
  const CtfPrepSimulator({super.key});

  static const _dockerComposeTemplate = r'''version: "3.9"
services:
  target:
    # Exemple: image pré-téléchargée (air-gapped friendly)
    # image: bkimminich/juice-shop:latest
    image: YOUR_LOCAL_IMAGE_TAG
    container_name: t2decode_target
    ports:
      - "127.0.0.1:8080:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped

  notes:
    # Un conteneur "notes" purement local pour garder les infos du scénario.
    image: alpine:3.20
    container_name: t2decode_notes
    command: ["sh", "-lc", "printf '%s\n' 'T2DECODE CTF PREP' 'Scénario local — ne pas exposer sur Internet.'; sleep 365d"]
    restart: unless-stopped
''';

  static const _networkChecklist = <String>[
    'Isoler le lab (host-only / VLAN dédié / VMnet) : pas d’accès Internet.',
    'Ne jamais exposer les services vulnérables en WAN (NAT/UPnP désactivés).',
    'Utiliser des snapshots (avant/après) pour rejouer un scénario proprement.',
    'Journaliser localement (Sysmon/Windows Event Logs, journald, Suricata, etc.).',
    'Chiffrer/limiter les exports (USB, ZIP) si environnement sensible.',
  ];

  static const _limitations = <String>[
    'Pas de données temps réel (threat intel, flux live) sans import manuel.',
    'Contenus à préparer et mettre à jour soi‑même (packs, exports, modules).',
    'Moins de “cloud-native” en air‑gapped (mais on peut simuler localement).',
  ];

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copié dans le presse‑papiers.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TdcColors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabGlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, color: TdcColors.warning, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'CTF PREP (OFFLINE)',
                        style: TextStyle(
                          color: TdcColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TdcColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: TdcColors.warning.withOpacity(0.25)),
                        ),
                        child: const Text(
                          'GUIDE LOCAL',
                          style: TextStyle(
                            color: TdcColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const LabNotice(
                    title: 'Objectif',
                    message:
                        'Préparer un environnement d’entraînement totalement local, volontairement vulnérable, mais contrôlé. '
                        'Idéal pour apprendre sérieusement sans risque de fuite.',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 10),
                  const LabNotice(
                    title: 'Sécurité',
                    message:
                        'Tout doit rester isolé : aucune exposition Internet. Utilisez un réseau dédié, des snapshots et des logs locaux.',
                    icon: Icons.shield_outlined,
                    color: TdcColors.security,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'Checklist réseau (recommandé)',
              icon: Icons.router_outlined,
              color: TdcColors.network,
              child: Column(
                children: _networkChecklist
                    .map((t) => _bulletRow(Icons.check, TdcColors.success, t))
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'Template docker-compose (air‑gapped friendly)',
              icon: Icons.layers_outlined,
              color: TdcColors.cloud,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Utilise une image locale (pré‑téléchargée). '
                    'Le port est bindé sur 127.0.0.1 pour éviter toute exposition.',
                    style: TextStyle(
                        color: TdcColors.textMuted.withOpacity(0.95),
                        fontSize: 12,
                        height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TdcColors.border),
                    ),
                    child: SelectableText(
                      _dockerComposeTemplate,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 11,
                        height: 1.35,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _copy(context, _dockerComposeTemplate),
                      icon: const Icon(Icons.copy,
                          size: 16, color: TdcColors.accent),
                      label: const Text(
                        'Copier le template',
                        style: TextStyle(color: TdcColors.accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'Limites & compromis (offline-first)',
              icon: Icons.info_outline,
              color: TdcColors.textMuted,
              child: Column(
                children: _limitations
                    .map((t) =>
                        _bulletRow(Icons.remove, TdcColors.textMuted, t))
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'Idées de scénarios (100% local)',
              icon: Icons.auto_awesome_outlined,
              color: TdcColors.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ScenarioCard(
                    title: 'Web vulnérable (rouge vs bleu)',
                    items: [
                      'Cible: app web vulnérable (conteneur/VM) + logs',
                      'Objectif: XSS/SQLi → détection → remédiation',
                      'Preuve: timeline d’alertes + patch + retest',
                    ],
                  ),
                  SizedBox(height: 10),
                  _ScenarioCard(
                    title: 'Défense & détection (SIEM local)',
                    items: [
                      'Collecte logs Windows/Linux (VMs)',
                      'Règles (Sigma-like) / alertes locales',
                      'Rapport: faux positifs / tuning',
                    ],
                  ),
                  SizedBox(height: 10),
                  _ScenarioCard(
                    title: 'Réseau segmenté (VLAN / host-only)',
                    items: [
                      'Sous-réseaux séparés + filtrage',
                      'Visibilité est‑ouest: SPAN/port mirroring si possible',
                      'Objectif: comprendre flux + segmentation',
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return LabGlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  static Widget _bulletRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: TdcColors.textMuted,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ScenarioCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((t) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          color: TdcColors.textMuted,
                          fontSize: 12,
                          height: 1.25)),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: TdcColors.textMuted,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

