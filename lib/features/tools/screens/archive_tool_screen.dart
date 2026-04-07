import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class ArchiveToolScreen extends StatefulWidget {
  const ArchiveToolScreen({super.key});

  @override
  State<ArchiveToolScreen> createState() => _ArchiveToolScreenState();
}

class _ArchiveToolScreenState extends State<ArchiveToolScreen> {
  final List<ArchiveCommand> _commands = [
    ArchiveCommand(
      'TAR (Tape Archive)',
      'L\'outil standard pour créer des archives compressées sous Linux.',
      [
        CommandExample('Créer une archive compressée (gzip)', 'tar -cvzf archive.tar.gz dossier/'),
        CommandExample('Extraire une archive (gzip)', 'tar -xvzf archive.tar.gz'),
        CommandExample('Lister le contenu d\'une archive', 'tar -tvf archive.tar.gz'),
        CommandExample('Extraire un fichier spécifique', 'tar -xvf archive.tar.gz chemin/vers/fichier'),
      ],
      Colors.orange,
    ),
    ArchiveCommand(
      'RSYNC',
      'Synchronisation de fichiers locale ou distante avec delta-transfert.',
      [
        CommandExample('Copie locale récursive avec droits preservés', 'rsync -av source/ destination/'),
        CommandExample('Synchronisation distante (SSH)', 'rsync -avz -e ssh user@remote:/path/ /local/path/'),
        CommandExample('Mode "Dry Run" (Simulation)', 'rsync -avn source/ destination/'),
        CommandExample('Supprimer fichiers absents de la source', 'rsync -av --delete source/ destination/'),
      ],
      Colors.blue,
    ),
    ArchiveCommand(
      'ZIP / UNZIP',
      'Format d\'archivage universel compatible Windows/Linux.',
      [
        CommandExample('Compresser un dossier récursivement', 'zip -r archive.zip dossier/'),
        CommandExample('Extraire une archive zip', 'unzip archive.zip'),
        CommandExample('Extraire dans un dossier spécifique', 'unzip archive.zip -d /target/dir'),
      ],
      Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Archivage & Transfert',
        showBackButton: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          const Text(
            'Aide-mémoire Archivage',
            style: TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commandes essentielles pour la sauvegarde et le transfert de données.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ..._commands.map((cmd) => _buildSection(cmd)),
          _buildInfo(),
        ],
      ),
    );
  }

  Widget _buildSection(ArchiveCommand cmd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cmd.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: cmd.color.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_zip, color: cmd.color, size: 20),
                const SizedBox(width: 12),
                Text(
                  cmd.title,
                  style: TextStyle(color: cmd.color, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cmd.desc, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                ...cmd.examples.map((ex) => _buildExample(ex)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(CommandExample ex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ex.label, style: const TextStyle(color: TdcColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: TdcRadius.sm,
              border: Border.all(color: TdcColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ex.code,
                    style: const TextStyle(color: TdcColors.success, fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: TdcColors.textTertiary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ex.code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copié !'), duration: Duration(seconds: 1)));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Rappel des Flags TAR :', style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 8),
          Text('• c : Create (Créer)\n• x : Extract (Extraire)\n• v : Verbose (Détail)\n• f : File (Fichier)\n• z : Gzip (Compression rapide)\n• j : Bzip2 (Meilleure compression)', 
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}

class ArchiveCommand {
  final String title, desc;
  final List<CommandExample> examples;
  final Color color;
  ArchiveCommand(this.title, this.desc, this.examples, this.color);
}

class CommandExample {
  final String label, code;
  CommandExample(this.label, this.code);
}
