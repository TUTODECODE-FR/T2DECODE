import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class SurvivalScreen extends StatefulWidget {
  const SurvivalScreen({super.key});
  @override State<SurvivalScreen> createState() => _SurvivalScreenState();
}

class _SurvivalScreenState extends State<SurvivalScreen> {
  int _selectedOS = 0;

  final List<Map<String, dynamic>> _guides = [
    {
      'category': 'SYSTÈME & BOOT',
      'icon': Icons.settings_power,
      'color': const Color(0xFF0078D4),
      'scenarios': [
        {
          'title': 'Boucle de démarrage (Boot Loop)',
          'content': '1. Éteindre/Allumer 3 fois brusquement pour forcer la Récupération.\n2. Dépannage > Options avancées > Paramètres > Redémarrer.\n3. Appuyer sur 4 ou F4 pour le Mode Sans Échec.',
          'severity': 'critical',
          'prevention': 'Vérifier les mises à jour de pilotes récentes ou les nouveaux matériels.',
        },
        {
          'title': 'OS Corrompu / Écran Bleu (BSOD)',
          'content': '1. Ouvrir CMD en admin.\n2. Lancer "sfc /scannow" pour les fichiers système.\n3. Lancer "DISM /Online /Cleanup-Image /RestoreHealth" si SFC échoue.',
          'severity': 'critical',
          'prevention': 'Maintenir 20% d\'espace disque libre et éviter les logiciels de "nettoyage" tiers.',
        },
      ],
    },
    {
      'category': 'SÉCURITÉ INFECTIEUSE',
      'icon': Icons.bug_report,
      'color': const Color(0xFFE81123),
      'scenarios': [
        {
          'title': 'Infection Ransomware active',
          'content': 'URGENT : Débranchez le câble réseau et coupez le Wi-Fi IMMÉDIATEMENT.\nNe redémarrez pas (certains ransomwares s\'activent au reboot).\nIsolez le poste et utilisez un autre PC pour identifier l\'extension des fichiers.',
          'severity': 'critical',
          'prevention': 'Sauvegardes hors-ligne régulières (Règle du 3-2-1).',
        },
        {
          'title': 'Malware / Publicités intempestives',
          'content': '1. Utiliser Malawarebytes en mode sans échec.\n2. Vérifier les extensions de navigateur suspectes.\n3. Réinitialiser le fichier "hosts" de Windows.',
          'severity': 'risk',
          'prevention': 'Activer la protection contre les ransomwares de Windows Defender.',
        },
      ],
    },
    {
      'category': 'MATÉRIEL & STOCKAGE',
      'icon': Icons.memory,
      'color': const Color(0xFFFCC624),
      'scenarios': [
        {
          'title': 'Bruit anormal / Claquement disque',
          'content': 'SIGNE DE PANNE MÉCANIQUE IMMINENTE.\nCopiez les données vitalES immédiatement sans redémarrer.\nCessez toute activité intensive sur le disque.',
          'severity': 'critical',
          'prevention': 'Surveiller les rapports S.M.A.R.T avec CrystalDiskInfo.',
        },
        {
          'title': 'Surchauffe / Coupure brutale',
          'content': '1. Nettoyer les ventilateurs et bouches d\'air.\n2. Vérifier si un processus sature le CPU via le Gestionnaire des tâches.\n3. Remplacer la pâte thermique si le PC a + de 3 ans.',
          'severity': 'risk',
          'prevention': 'Éviter d\'utiliser un PC portable sur des surfaces molles (lit, couette).',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'SOS Dépannage',
        showBackButton: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          const Text('PROTOCOLES D\'URGENCE', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Text('SOS Secours Technique', style: TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ..._guides.map((g) => _buildCategorySection(g)).toList(),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(g['icon'], color: g['color'], size: 20),
              const SizedBox(width: 12),
              Text(g['category'], style: TextStyle(color: g['color'], fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: g['color'].withOpacity(0.2))),
            ],
          ),
        ),
        ...g['scenarios'].map<Widget>((s) => _buildScenarioCard(s, g['color'])).toList(),
      ],
    );
  }

  Widget _buildScenarioCard(Map<String, dynamic> s, Color catColor) {
    final isCrit = s['severity'] == 'critical';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: isCrit ? TdcColors.danger.withOpacity(0.3) : TdcColors.border),
        boxShadow: isCrit ? [BoxShadow(color: TdcColors.danger.withOpacity(0.05), blurRadius: 10)] : null,
      ),
      child: ClipRRect(
        borderRadius: TdcRadius.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isCrit ? TdcColors.danger.withOpacity(0.1) : TdcColors.surfaceAlt,
              child: Row(
                children: [
                  Icon(isCrit ? Icons.warning_amber_rounded : Icons.info_outline, color: isCrit ? TdcColors.danger : catColor, size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s['title'], style: TextStyle(color: isCrit ? TdcColors.danger : TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15))),
                  _severityBadge(s['severity']),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ACTIONS À MENER :', style: TextStyle(color: TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(s['content'], style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13, height: 1.6)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: TdcColors.bg.withOpacity(0.5), borderRadius: TdcRadius.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: TdcColors.success, size: 14),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Prévention : ${s['prevention']}', style: const TextStyle(color: TdcColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityBadge(String level) {
    final color = level == 'critical' ? TdcColors.danger : TdcColors.warning;
    final label = level == 'critical' ? 'CRITIQUE' : 'RISQUE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
