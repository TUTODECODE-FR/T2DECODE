import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class SyslogToolScreen extends StatefulWidget {
  const SyslogToolScreen({super.key});

  @override
  State<SyslogToolScreen> createState() => _SyslogToolScreenState();
}

class _SyslogToolScreenState extends State<SyslogToolScreen> {
  final List<SyslogLevel> _levels = [
    SyslogLevel(0, 'Emergency', 'system is unusable', 'Panne totale du noyau, corruption disque critique.', Colors.red.shade900),
    SyslogLevel(1, 'Alert', 'action must be taken immediately', 'Base de données corrompue, perte de connectivité lien principal.', Colors.red.shade700),
    SyslogLevel(2, 'Critical', 'critical conditions', 'Erreur matérielle (RAID dégradé), processus critique arrêté.', Colors.red.shade500),
    SyslogLevel(3, 'Error', 'error conditions', 'Échec d\'écriture fichier, erreur application non critique.', Colors.orange.shade800),
    SyslogLevel(4, 'Warning', 'warning conditions', 'Disque à 90%, utilisation CPU inhabituelle.', Colors.orange.shade500),
    SyslogLevel(5, 'Notice', 'normal but significant condition', 'Redémarrage service, changement de configuration.', Colors.blue.shade600),
    SyslogLevel(6, 'Informational', 'informational messages', 'Tentative de login réussie, transfert de fichier terminé.', Colors.blue.shade400),
    SyslogLevel(7, 'Debug', 'debug-level messages', 'Traces détaillées pour développeurs (très verbeux).', Colors.grey.shade600),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Niveaux Syslog (RFC 5424)',
        showBackButton: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Référence de Sévérité Syslog',
            style: TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comprendre les codes de priorité pour filtrer efficacement vos serveurs de logs.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _levels.length,
              itemBuilder: (context, index) {
                final level = _levels[index];
                return _buildLevelCard(level);
              },
            ),
          ),
          _buildTip(),
        ],
      ),
    );
  }

  Widget _buildLevelCard(SyslogLevel level) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: level.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: level.color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                level.code.toString(),
                style: TextStyle(color: level.color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(color: level.color, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${level.description})',
                      style: const TextStyle(color: TdcColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  level.example,
                  style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: TdcRadius.md,
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Astuce : En production, ne loggez jamais au-dessus du niveau 5 (Notice) pour éviter de saturer vos disques, sauf en phase de debug temporaire.',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class SyslogLevel {
  final int code;
  final String name;
  final String description;
  final String example;
  final Color color;

  SyslogLevel(this.code, this.name, this.description, this.example, this.color);
}
