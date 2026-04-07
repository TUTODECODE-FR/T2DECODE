// ============================================================
// Plagiarism Protection Screen - Interface de protection contre le plagiat
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/security/plagiarism_protection.dart';

class PlagiarismProtectionScreen extends StatefulWidget {
  const PlagiarismProtectionScreen({super.key});

  @override
  State<PlagiarismProtectionScreen> createState() => _PlagiarismProtectionScreenState();
}

class _PlagiarismProtectionScreenState extends State<PlagiarismProtectionScreen>
    with TickerProviderStateMixin {
  ProjectPlagiarismAnalysis? _analysis;
  OriginalityCertificate? _certificate;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Protection Anti-Plagiat',
        showBackButton: true,
        actions: [],
      );
    });
    
    _performAnalysis();
  }

  Future<void> _performAnalysis() async {
    setState(() => _isAnalyzing = true);
    
    try {
      final analysis = await PlagiarismProtectionService.analyzeProject();
      final certificate = await PlagiarismProtection.generateOriginalityCertificate();
      
      setState(() {
        _analysis = analysis;
        _certificate = certificate;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _analysis?.isAuthentic == true 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  _analysis?.isAuthentic == true 
                      ? Colors.green.withOpacity(0.05)
                      : Colors.red.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _analysis?.isAuthentic == true 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _analysis?.isAuthentic == true ? Icons.plagiarism : Icons.plagiarism_outlined,
                  color: _analysis?.isAuthentic == true ? Colors.green : Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _analysis?.isAuthentic == true 
                      ? 'Code Original Authentifié'
                      : 'Plagiat Détecté',
                  style: TextStyle(
                    color: _analysis?.isAuthentic == true ? Colors.green : Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _analysis?.isAuthentic == true 
                      ? 'Ce code est 100% original et développé par TUTODECODE'
                      : 'Ce code présente des traces de plagiat',
                  style: const TextStyle(color: TdcColors.textSecondary),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          if (_analysis != null) ...[
            // Score d'originalité
            _buildOriginalityScore(_analysis!),
            
            const SizedBox(height: 24),
            
            // Analyse des fichiers
            _buildFileAnalysis(_analysis!),
            
            if (_analysis!.allIssues.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildIssuesSection(_analysis!),
            ],
            
            const SizedBox(height: 24),
            
            // Certificat d'originalité
            _buildCertificateSection(),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActionsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildOriginalityScore(ProjectPlagiarismAnalysis analysis) {
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score d\'Originalité',
              style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Score principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getScoreColor(analysis.overallOriginalityScore).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getScoreColor(analysis.overallOriginalityScore).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${analysis.overallOriginalityScore.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _getScoreColor(analysis.overallOriginalityScore),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getScoreLabel(analysis.overallOriginalityScore),
                    style: TextStyle(
                      color: _getScoreColor(analysis.overallOriginalityScore),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Métriques détaillées
            _buildMetricRow('Fichiers Analysés', '${analysis.fileAnalyses.length}'),
            _buildMetricRow('Score de Plagiat', '${(analysis.overallPlagiarismScore * 100).toStringAsFixed(1)}%'),
            _buildMetricRow('Niveau de Risque', analysis.riskLevel.name.toUpperCase()),
            _buildMetricRow('Date d\'Analyse', _formatDate(analysis.analysisDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: TdcColors.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileAnalysis(ProjectPlagiarismAnalysis analysis) {
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analyse des Fichiers',
              style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            ...analysis.fileAnalyses.map((fileAnalysis) {
              return _buildFileCard(fileAnalysis);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(PlagiarismAnalysis analysis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: analysis.isOriginal 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: analysis.isOriginal 
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                analysis.isOriginal ? Icons.check_circle : Icons.error,
                color: analysis.isOriginal ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  analysis.filePath.split('/').last,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${analysis.originalityScore.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: analysis.isOriginal ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (analysis.issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...analysis.issues.take(3).map((issue) => Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(
                issue,
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildIssuesSection(ProjectPlagiarismAnalysis analysis) {
    return Card(
      color: Colors.red.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Problèmes Détectés',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...analysis.allIssues.take(10).map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue,
                      style: const TextStyle(color: TdcColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
            
            if (analysis.allIssues.length > 10) ...[
              const SizedBox(height: 8),
              Text(
                '... et ${analysis.allIssues.length - 10} autres problèmes',
                style: const TextStyle(color: TdcColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateSection() {
    if (_certificate == null) return const SizedBox.shrink();
    
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Certificat d\'Originalité',
              style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildCertRow('ID du Certificat', _certificate!.certificateId),
            _buildCertRow('Validité', _certificate!.isOriginal ? 'Original' : 'Non original'),
            _buildCertRow('Score d\'Originalité', '${_certificate!.originalityScore.toStringAsFixed(1)}%'),
            _buildCertRow('Date d\'Analyse', _formatDate(_certificate!.analysisDate)),
            
            const SizedBox(height: 20),
            
            // QR Code
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'QR Code d\'Originalité',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: _certificate!.qrCodeData,
                    version: QrVersions.auto,
                    size: 150.0,
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: TdcColors.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: TdcColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _analysis?.isAuthentic == true 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _analysis?.isAuthentic == true 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _analysis?.isAuthentic == true ? Icons.check_circle : Icons.warning,
                color: _analysis?.isAuthentic == true ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _analysis?.isAuthentic == true 
                      ? '✅ Code original protégé - Utilisation sécurisée'
                      : '❌ Plagiat détecté - Risque légal et de sécurité',
                  style: TextStyle(
                    color: _analysis?.isAuthentic == true ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _copyReport,
                icon: const Icon(Icons.copy),
                label: const Text('Copier le Rapport'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exportCertificate,
                icon: const Icon(Icons.download),
                label: const Text('Exporter'),
                style: ElevatedButton.styleFrom(backgroundColor: TdcColors.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareAnalysis,
                icon: const Icon(Icons.share),
                label: const Text('Partager'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Original';
    if (score >= 60) return 'Similaire';
    if (score >= 40) return 'Inspiré';
    return 'Plagié';
  }

  void _copyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapport copié')),
    );
  }

  void _exportCertificate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export à implémenter')),
    );
  }

  void _shareAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage à implémenter')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
