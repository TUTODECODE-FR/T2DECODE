import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'cheat_sheet_screen.dart';

class CheatSheetDetailScreen extends StatefulWidget {
  final CheatSheetEntry entry;
  const CheatSheetDetailScreen({super.key, required this.entry});
  @override State<CheatSheetDetailScreen> createState() => _CheatSheetDetailScreenState();
}

class _CheatSheetDetailScreenState extends State<CheatSheetDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Détails Commande',
        showBackButton: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Scaffold(
      backgroundColor: TdcColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: TdcPageWrapper(
          maxWidth: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(e),
              const SizedBox(height: 32),
              _buildTerminalBlock(e),
              const SizedBox(height: 32),
              if (e.detailedExplanation != null) ...[
                const TdcSectionTitle('DESCRIPTION'),
                const SizedBox(height: 12),
                Text(e.detailedExplanation!, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 15, height: 1.5)),
                const SizedBox(height: 32),
              ],
              if (e.options != null && e.options!.isNotEmpty) ...[
                const TdcSectionTitle('OPTIONS COMMUNES'),
                const SizedBox(height: 12),
                _buildList(e.options!),
                const SizedBox(height: 32),
              ],
              if (e.examples != null && e.examples!.isNotEmpty) ...[
                const TdcSectionTitle('EXEMPLES D\'USAGE'),
                const SizedBox(height: 12),
                _buildExamples(e.examples!),
                const SizedBox(height: 32),
              ],
              if (e.tableData != null) ...[
                const TdcSectionTitle('RÉFÉRENCE TECHNIQUE'),
                const SizedBox(height: 16),
                _buildTable(e),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CheatSheetEntry e) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _getColor(e).withOpacity(0.1), borderRadius: TdcRadius.md),
          child: Icon(_getIcon(e), color: _getColor(e), size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.category, style: const TextStyle(color: TdcColors.textMuted, fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                  _buildDangerLevel(e.dangerLevel),
                ],
              ),
              const SizedBox(height: 8),
              Text(e.description, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalBlock(CheatSheetEntry e) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _dot(Colors.red), const SizedBox(width: 6),
                _dot(Colors.amber), const SizedBox(width: 6),
                _dot(Colors.green),
                const Spacer(),
                const Text('terminal — bash', style: TextStyle(color: TdcColors.textMuted, fontSize: 11, fontFamily: 'monospace')),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: TdcColors.textMuted),
                  onPressed: () => Clipboard.setData(ClipboardData(text: e.command)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('\$ ', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(e.command, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'monospace', height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 10, height: 10, decoration: BoxDecoration(color: c.withOpacity(0.5), shape: BoxShape.circle));

  Widget _buildList(List<String> items) {
    return Column(
      children: items.map((opt) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: TdcColors.accent)),
            const SizedBox(width: 12),
            Expanded(child: Text(opt, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 14))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildExamples(List<String> items) {
    return Column(
      children: items.map((ex) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: TdcColors.surfaceAlt, borderRadius: TdcRadius.sm, border: Border.all(color: TdcColors.border)),
        child: Text(ex, style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 13)),
      )).toList(),
    );
  }

  Widget _buildTable(CheatSheetEntry e) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
        children: [
          TableRow(
            decoration: BoxDecoration(color: TdcColors.surfaceAlt, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
            children: (e.tableHeaders ?? ['Argument', 'Description']).map((h) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TdcColors.accent)),
            )).toList(),
          ),
          ...e.tableData!.map((row) => TableRow(
            children: row.map((cell) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(cell, style: const TextStyle(fontSize: 13, color: TdcColors.textPrimary)),
            )).toList(),
          )),
        ],
      ),
    );
  }

  Color _getColor(CheatSheetEntry e) {
    if (e.colorHex != null && e.colorHex!.isNotEmpty) {
      final hex = e.colorHex!.replaceAll('#', '');
      try {
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    switch (e.category) {
      case 'WINDOWS': return const Color(0xFF00A4EF);
      case 'MAC': return const Color(0xFF999999);
      case 'LINUX': return const Color(0xFFFCC624);
      case 'DOCKER': return const Color(0xFF2496ED);
      case 'RÉSEAU': return const Color(0xFF10B981);
      case 'GIT': return const Color(0xFFF05032);
      case 'SÉCURITÉ': return const Color(0xFFEF4444);
      default: return TdcColors.accent;
    }
  }

  IconData _getIcon(CheatSheetEntry e) {
    if (e.iconName != null && e.iconName!.isNotEmpty) {
      switch (e.iconName) {
        case 'security': return Icons.security;
        case 'terminal': return Icons.terminal;
        case 'cloud': return Icons.cloud;
        case 'dns': return Icons.dns;
        case 'lock': return Icons.lock;
        case 'api': return Icons.api;
        case 'bug_report': return Icons.bug_report;
        case 'admin_panel_settings': return Icons.admin_panel_settings;
        case 'storage': return Icons.storage;
        case 'network': return Icons.network_check;
        case 'search': return Icons.search;
      }
    }
    switch (e.category) {
      case 'WINDOWS': return Icons.window;
      case 'MAC': return Icons.apple;
      case 'LINUX': return Icons.terminal;
      case 'DOCKER': return Icons.directions_boat;
      case 'RÉSEAU': return Icons.lan;
      case 'GIT': return Icons.merge_type;
      case 'SÉCURITÉ': return Icons.security;
      default: return Icons.code;
    }
  }

  Widget _buildDangerLevel(int level) {
    Color color = Colors.green;
    String label = 'SÉCURISÉ';
    if (level == 2) { color = Colors.orange; label = 'PRUDENCE'; }
    else if (level >= 3) { color = Colors.red; label = 'CRITIQUE'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
