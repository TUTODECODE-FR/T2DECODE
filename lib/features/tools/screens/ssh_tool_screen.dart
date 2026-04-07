import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class SshToolScreen extends StatefulWidget {
  const SshToolScreen({super.key});

  @override
  State<SshToolScreen> createState() => _SshToolScreenState();
}

class _SshToolScreenState extends State<SshToolScreen> {
  final List<SshTopic> _topics = [
    SshTopic(
      'Fichier Config (~/.ssh/config)',
      'Simplifiez vos connexions en créant des alias pour vos serveurs distants.',
      [
        ConfigParameter('Host', 'Alias de la connexion (ex: srv-prod)'),
        ConfigParameter('HostName', 'Adresse IP ou nom de domaine réel'),
        ConfigParameter('User', 'Nom d\'utilisateur SSH'),
        ConfigParameter('IdentityFile', 'Chemin vers la clé privée (ex: ~/.ssh/id_rsa)'),
        ConfigParameter('Port', 'Port SSH si différent de 22'),
      ],
      'Host prod\n  HostName 1.2.3.4\n  User admin\n  IdentityFile ~/.ssh/prod_key',
    ),
    SshTopic(
      'Best Practices Sécurité',
      'Configuration recommandée pour /etc/ssh/sshd_config sur le serveur.',
      [
        ConfigParameter('PermitRootLogin no', 'Interdire la connexion en root'),
        ConfigParameter('PasswordAuthentication no', 'Désactiver les mots de passe (clés uniquement)'),
        ConfigParameter('PubkeyAuthentication yes', 'Autoriser l\'authentification par clé'),
        ConfigParameter('Port 2222', 'Changer le port par défaut (obscurité)'),
      ],
      '# /etc/ssh/sshd_config\nPermitRootLogin no\nPasswordAuthentication no\nMaxAuthTries 3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Assistant Config SSH',
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
            'Référence SSH & Sécurité',
            style: TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Maîtrisez vos accès distants et sécurisez vos serveurs avec les bons réglages.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ..._topics.map((t) => _buildTopicSection(t)),
          _buildKeyGen(),
        ],
      ),
    );
  }

  Widget _buildTopicSection(SshTopic t) {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TdcColors.accent.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: TdcColors.accent.withValues(alpha: 0.2))),
            ),
            child: Text(t.title, style: const TextStyle(color: TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.desc, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                ...t.params.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Text('• ${p.key} :', style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.desc, style: const TextStyle(color: TdcColors.textMuted, fontSize: 12))),
                  ]),
                )),
                const SizedBox(height: 16),
                const Text('Exemple de syntaxe :', style: TextStyle(color: TdcColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: TdcRadius.sm),
                  child: Row(
                    children: [
                      Expanded(child: Text(t.example, style: const TextStyle(color: TdcColors.success, fontFamily: 'monospace', fontSize: 12))),
                      IconButton(icon: const Icon(Icons.copy, size: 16, color: TdcColors.textTertiary), onPressed: () => Clipboard.setData(ClipboardData(text: t.example))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyGen() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.system.withValues(alpha: 0.05),
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.system.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.vpn_key, color: TdcColors.system, size: 20),
            SizedBox(width: 8),
            Text('Générer une clé sécurisée (Ed25519)', style: TextStyle(color: TdcColors.system, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: TdcRadius.sm),
            child: const Row(children: [
              Expanded(child: Text('ssh-keygen -t ed25519 -C "votre_email@tdc.io"', style: TextStyle(color: TdcColors.success, fontFamily: 'monospace', fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }
}

class SshTopic {
  final String title, desc, example;
  final List<ConfigParameter> params;
  SshTopic(this.title, this.desc, this.params, this.example);
}

class ConfigParameter {
  final String key, desc;
  ConfigParameter(this.key, this.desc);
}
