import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/responsive/responsive.dart';

class SecurityDiagnosticScreen extends StatefulWidget {
  const SecurityDiagnosticScreen({super.key});

  @override
  State<SecurityDiagnosticScreen> createState() => _SecurityDiagnosticScreenState();
}

class _SecurityDiagnosticScreenState extends State<SecurityDiagnosticScreen> {
  List<String> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final storage = StorageService();
    final logs = await storage.getSecurityLogs();
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TdcColors.bg,
      appBar: AppBar(
        title: const Text('Diagnostic Sécurité'),
        backgroundColor: TdcColors.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryHeader(),
              const SizedBox(height: 24),
              const Text('JOURNAUX DE SÉCURITÉ (LOCAUX)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TdcColors.textMuted)),
              const SizedBox(height: 12),
              if (_logs.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Aucun événement suspect détecté.', style: TextStyle(color: TdcColors.success)),
                ))
              else
                ..._logs.map((log) => _buildLogItem(log)),
            ],
          ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.lg,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        children: [
          _buildStatRow('État du Réseau', 'Strict (HTTPS Only)', Icons.verified_user, TdcColors.success),
          const Divider(height: 24),
          _buildStatRow('Hôtes Autorisés', 'GitHub, Ollama (Local)', Icons.language, TdcColors.accent),
          const Divider(height: 24),
          _buildStatRow('Validation Modules', 'Active (Structure + SHA)', Icons.security, TdcColors.success),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Text(value, style: TextStyle(color: TdcColors.textMuted, fontSize: 13)),
      ],
    );
  }

  Widget _buildLogItem(String log) {
    final isError = log.contains('Error') || log.contains('Rejet') || log.contains('Refus');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: TdcRadius.sm,
        border: Border.all(color: isError ? TdcColors.danger.withOpacity(0.3) : TdcColors.border),
      ),
      child: Text(
        log,
        style: TextStyle(
          fontFamily: 'monospace', 
          fontSize: 11, 
          color: isError ? TdcColors.danger : TdcColors.textSecondary
        ),
      ),
    );
  }
}
