import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:provider/provider.dart';

class MentionsLegalesScreen extends StatefulWidget {
  const MentionsLegalesScreen({super.key});

  @override
  State<MentionsLegalesScreen> createState() => _MentionsLegalesScreenState();
}

class _MentionsLegalesScreenState extends State<MentionsLegalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Mentions Légales & Identité',
        showBackButton: true,
        actions: [],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegalCard(
            title: 'Éditeur de l\'Application',
            icon: Icons.business,
            content: [
              _buildRow('Association', 'TUTO DECODE'),
              _buildRow('Statut Juridique', 'Association Loi 1901 à but non lucratif'),
              _buildRow('Objet', 'Éducation Numérique, Sensibilisation à la Cybersécurité et à la Liberté Technologique'),
              _buildRow('Président / Directeur de publication', 'Maxime MARTIN CIVET'),
            ],
          ),
          const SizedBox(height: 24),
          _buildLegalCard(
            title: 'Enregistrement & Preuves Légales',
            icon: Icons.gavel,
            content: [
              _buildRow('Numéro RNA', '[VOTRE NUMÉRO RNA ICI]'),
              _buildRow('Numéro SIREN', '[VOTRE SIREN ICI (si applicable)]'),
              _buildRow('Déclaration Officielle', 'Publiée au Journal Officiel de la République Française (JOAFE)'),
              const SizedBox(height: 16),
              const Text('Lien du Journal Officiel :', style: TextStyle(color: TdcColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TdcColors.bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: TdcColors.border),
                ),
                child: const SelectableText(
                  '[VOTRE LIEN VERS LE JOURNAL OFFICIEL ICI]',
                  style: TextStyle(color: TdcColors.accent, fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLegalCard(
            title: 'Hébergement & Données (RGPD)',
            icon: Icons.security,
            content: [
              const Text('Application 100% "Air-Gapped" / Local-First.', style: TextStyle(color: TdcColors.textSecondary, height: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('L\'association TUTO DECODE ne collecte, ne transmet et ne stocke aucune donnée personnelle sur des serveurs distants. L\'application fonctionne de manière autonome en local sur la machine de l\'utilisateur, garantissant un respect absolu du RGPD "Privacy by Design".\n\nLe code source est public (AGPL-3.0) et auditable par tous sur GitHub.', style: TextStyle(color: TdcColors.textSecondary, height: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard({required String title, required IconData icon, required List<Widget> content}) {
    return Card(
      color: TdcColors.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: TdcColors.accent, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TdcColors.textPrimary))),
              ],
            ),
            const SizedBox(height: 16),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: TdcColors.textMuted, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(value, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
