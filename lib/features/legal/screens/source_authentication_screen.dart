// ============================================================
// Source Authentication Screen - Interface de vérification du code source
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/security/source_authentication.dart';

class SourceAuthenticationScreen extends StatefulWidget {
  const SourceAuthenticationScreen({super.key});

  @override
  State<SourceAuthenticationScreen> createState() => _SourceAuthenticationScreenState();
}

class _SourceAuthenticationScreenState extends State<SourceAuthenticationScreen>
    with TickerProviderStateMixin {
  SourceAuthResult? _authResult;
  CodeSignature? _codeSignature;
  bool _showTechnicalDetails = false;
  bool _showWatermarkInfo = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Authentification du Code Source',
        showBackButton: true,
        actions: [],
      );
    });
    
    _performSourceAuthentication();
  }

  Future<void> _performSourceAuthentication() async {
    try {
      final result = await SourceAuthService.verifySource();
      final signature = await SourceAuthentication.generateCodeSignature();
      
      setState(() {
        _authResult = result;
        _codeSignature = signature;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _authResult?.isAuthentic == true 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  _authResult?.isAuthentic == true 
                      ? Colors.green.withOpacity(0.05)
                      : Colors.red.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _authResult?.isAuthentic == true 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _authResult?.isAuthentic == true ? Icons.code : Icons.code_off,
                  color: _authResult?.isAuthentic == true ? Colors.green : Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _authResult?.isAuthentic == true 
                      ? 'Code Source Authentifié'
                      : 'Code Source Non Authentifié',
                  style: TextStyle(
                    color: _authResult?.isAuthentic == true ? Colors.green : Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _authResult?.isAuthentic == true 
                      ? 'Ce code source est officiellement développé par l\'Association TUTODECODE'
                      : 'Ce code source n\'est pas reconnu comme officiel',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          if (_authResult != null) ...[
            // Informations du développeur
            _buildDeveloperInfo(),
            
            const SizedBox(height: 24),
            
            // Résultats de l'authentification
            _buildAuthenticationChecks(_authResult!),
            
            if (_authResult!.modifiedFiles.isNotEmpty || 
                _authResult!.suspiciousFiles.isNotEmpty ||
                _authResult!.plagiarizedFiles.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildIssuesSection(_authResult!),
            ],
            
            const SizedBox(height: 24),
            
            // Signature du code source
            _buildCodeSignatureSection(),
            
            const SizedBox(height: 24),
            
            // Watermark information
            _buildWatermarkSection(),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActionsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: TdcColors.accent, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Informations du Développeur',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Nom', SourceAuthentication.OFFICIAL_DEVELOPER['name']),
            _buildInfoRow('Type', SourceAuthentication.OFFICIAL_DEVELOPER['type']),
            _buildInfoRow('SIREN', SourceAuthentication.OFFICIAL_DEVELOPER['siren']),
            _buildInfoRow('Pays', SourceAuthentication.OFFICIAL_DEVELOPER['country']),
            _buildInfoRow('Site Web', SourceAuthentication.OFFICIAL_DEVELOPER['website']),
            _buildInfoRow('Contact', SourceAuthentication.OFFICIAL_DEVELOPER['contact']),
            _buildInfoRow('GitHub', SourceAuthentication.OFFICIAL_DEVELOPER['github']),
            _buildInfoRow('Licence', SourceAuthentication.OFFICIAL_DEVELOPER['license']),
            _buildInfoRow('ID Développeur', SourceAuthentication.OFFICIAL_DEVELOPER['developer_id']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationChecks(SourceAuthResult result) {
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: TdcColors.accent, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Contrôles d\'Authentification',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _showTechnicalDetails = !_showTechnicalDetails),
                  child: Text(_showTechnicalDetails ? 'Masquer' : 'Détails'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...result.checks.entries.map((entry) {
              return _buildCheckRow(entry.key, entry.value);
            }),
            
            if (_showTechnicalDetails) ...[
              const SizedBox(height: 20),
              const Divider(color: TdcColors.border),
              const SizedBox(height: 20),
              const Text(
                'Détails Techniques',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTechnicalDetails(result),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckRow(String checkName, bool passed) {
    final checkInfo = _getCheckInfo(checkName);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.error,
            color: passed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkInfo['name'] ?? 'Inconnu',
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  checkInfo['description'] ?? 'Pas de description',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: passed ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              passed ? 'OK' : 'FAIL',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getCheckInfo(String checkName) {
    switch (checkName) {
      case 'fingerprints':
        return {
          'name': 'Empreintes des Fichiers',
          'description': 'Vérifie que les empreintes digitales correspondent au code officiel',
        };
      case 'signatures':
        return {
          'name': 'Signatures TUTODECODE',
          'description': 'Contrôle la présence des signatures uniques TUTODECODE',
        };
      case 'developer':
        return {
          'name': 'Manifest du Développeur',
          'description': 'Valide les informations du développeur officiel',
        };
      case 'plagiarism':
        return {
          'name': 'Détection de Plagiat',
          'description': 'Recherche les traces de plagiat ou de modification',
        };
      case 'structure':
        return {
          'name': 'Structure du Code',
          'description': 'Vérifie l\'arborescence officielle du projet',
        };
      case 'metadata':
        return {
          'name': 'Métadonnées du Projet',
          'description': 'Valide les informations du projet TUTODECODE',
        };
      case 'suspicious':
        return {
          'name': 'Modifications Suspectes',
          'description': 'Détecte les changements non autorisés',
        };
      case 'sourceSignature':
        return {
          'name': 'Signature du Code Source',
          'description': 'Vérifie la signature numérique du code source',
        };
      default:
        return {
          'name': checkName,
          'description': 'Contrôle de sécurité',
        };
    }
  }

  Widget _buildTechnicalDetails(SourceAuthResult result) {
    return Column(
      children: [
        _buildDetailRow('Total Fichiers Vérifiés', '${result.fileResults.length}'),
        _buildDetailRow('Fichiers Authentiques', '${result.fileResults.values.where((v) => v).length}'),
        if (result.modifiedFiles.isNotEmpty)
          _buildDetailRow('Fichiers Modifiés', '${result.modifiedFiles.length}', isWarning: true),
        if (result.suspiciousFiles.isNotEmpty)
          _buildDetailRow('Fichiers Suspects', '${result.suspiciousFiles.length}', isWarning: true),
        if (result.plagiarizedFiles.isNotEmpty)
          _buildDetailRow('Fichiers Plagiés', '${result.plagiarizedFiles.length}', isWarning: true),
        _buildDetailRow('Date de Vérification', _formatDate(result.verificationDate)),
        _buildDetailRow('Niveau de Risque', result.riskLevel.name.toUpperCase(), 
                       isWarning: result.riskLevel != SourceRiskLevel.low),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? Colors.orange : TdcColors.textPrimary,
              fontSize: 12,
              fontWeight: isWarning ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSection(SourceAuthResult result) {
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
                  'Problèmes de Sécurité Détectés',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (result.modifiedFiles.isNotEmpty) ...[
              _buildIssueSection('Fichiers Modifiés', result.modifiedFiles, Icons.edit),
              const SizedBox(height: 16),
            ],
            
            if (result.suspiciousFiles.isNotEmpty) ...[
              _buildIssueSection('Fichiers Suspects', result.suspiciousFiles, Icons.security),
              const SizedBox(height: 16),
            ],
            
            if (result.plagiarizedFiles.isNotEmpty) ...[
              _buildIssueSection('Fichiers Plagiés', result.plagiarizedFiles, Icons.content_copy),
              const SizedBox(height: 16),
            ],
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce code source présente des problèmes de sécurité. Téléchargez la version officielle depuis le dépôt GitHub officiel.',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
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

  Widget _buildIssueSection(String title, List<String> files, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...files.map((file) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Text(
            file,
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCodeSignatureSection() {
    if (_codeSignature == null) return const SizedBox.shrink();
    
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: TdcColors.accent, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Signature du Code Source',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Informations de la signature
            _buildSignatureRow('ID de Signature', _codeSignature!.signatureId),
            _buildSignatureRow('Validité', _codeSignature!.isOfficial ? 'Officielle' : 'Non officielle'),
            _buildSignatureRow('Date de Vérification', _formatDate(_codeSignature!.verificationDate)),
            _buildSignatureRow('Fichiers Vérifiés', '${_codeSignature!.fileCount}'),
            _buildSignatureRow('Fichiers Authentiques', '${_codeSignature!.authenticFiles}'),
            _buildSignatureRow('Hash de Signature', _codeSignature!.signatureHash),
            
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
                    'QR Code d\'Authentification',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: _codeSignature!.qrCodeData,
                    version: QrVersions.auto,
                    size: 150.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scannez pour vérifier l\'authenticité du code source',
                    style: TextStyle(
                      color: TdcColors.textSecondary,
                      fontSize: 12,
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

  Widget _buildSignatureRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermarkSection() {
    if (_codeSignature == null) return const SizedBox.shrink();
    
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: TdcColors.accent, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Watermark du Code Source',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _showWatermarkInfo = !_showWatermarkInfo),
                  child: Text(_showWatermarkInfo ? 'Masquer' : 'Afficher'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Watermark unique intégré dans le code source',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chaque fichier du code source officiel contient un watermark numérique unique qui prouve son origine. Ce watermark est invisible à l\'exécution mais détectable lors de l\'analyse du code.',
                    style: TextStyle(
                      color: TdcColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (_showWatermarkInfo) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _codeSignature!.watermark,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        // Recommandations
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _authResult?.isAuthentic == true 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _authResult?.isAuthentic == true 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _authResult?.isAuthentic == true ? Icons.check_circle : Icons.warning,
                color: _authResult?.isAuthentic == true ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _authResult?.isAuthentic == true 
                      ? '✅ Code source officiel - Utilisation sécurisée garantie'
                      : '❌ Code source non officiel - Risque de sécurité élevé',
                  style: TextStyle(
                    color: _authResult?.isAuthentic == true ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _copySourceReport,
                icon: const Icon(Icons.copy),
                label: const Text('Copier le Rapport'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exportSignature,
                icon: const Icon(Icons.download),
                label: const Text('Exporter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TdcColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareVerification,
                icon: const Icon(Icons.share),
                label: const Text('Partager'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                ),
              ),
            ),
          ],
        ),
        
        if (_authResult?.isAuthentic != true) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloadOfficialSource,
              icon: const Icon(Icons.code),
              label: const Text('Télécharger le Code Source Officiel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Actions
  void _copySourceReport() {
    final report = _generateTextReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapport de code source copié')),
    );
  }

  void _exportSignature() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export de la signature à implémenter')),
    );
  }

  void _shareVerification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage à implémenter')),
    );
  }

  void _downloadOfficialSource() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirection vers le dépôt GitHub officiel')),
    );
  }

  String _generateTextReport() {
    final result = _authResult!;
    final signature = _codeSignature!;
    
    return '''
RAPPORT D'AUTHENTIFICATION DU CODE SOURCE
==========================================

Application: T2DECODE
Date de vérification: ${_formatDate(result.verificationDate)}

STATUT: ${result.isAuthentic ? 'AUTHENTIFIÉ' : 'NON AUTHENTIFIÉ'}

INFORMATIONS DU DÉVELOPPEUR
---------------------------
Nom: ${SourceAuthentication.OFFICIAL_DEVELOPER['name']}
Type: ${SourceAuthentication.OFFICIAL_DEVELOPER['type']}
SIREN: ${SourceAuthentication.OFFICIAL_DEVELOPER['siren']}
Pays: ${SourceAuthentication.OFFICIAL_DEVELOPER['country']}
Site Web: ${SourceAuthentication.OFFICIAL_DEVELOPER['website']}
Contact: ${SourceAuthentication.OFFICIAL_DEVELOPER['contact']}
GitHub: ${SourceAuthentication.OFFICIAL_DEVELOPER['github']}
Licence: ${SourceAuthentication.OFFICIAL_DEVELOPER['license']}
ID Développeur: ${SourceAuthentication.OFFICIAL_DEVELOPER['developer_id']}

SIGNATURE DU CODE SOURCE
------------------------
ID: ${signature.signatureId}
Validité: ${signature.isOfficial ? 'Officielle' : 'Non officielle'}
Date: ${_formatDate(signature.verificationDate)}
Fichiers vérifiés: ${signature.fileCount}
Fichiers authentiques: ${signature.authenticFiles}
Hash: ${signature.signatureHash}

CONTRÔLES D'AUTHENTIFICATION
---------------------------
${result.checks.entries.map((e) => '- ${e.key}: ${e.value ? 'OK' : 'FAIL'}').join('\n')}

${result.modifiedFiles.isNotEmpty ? 'FICHIERS MODIFIÉS:\n${result.modifiedFiles.map((f) => '- $f').join('\n')}\n' : ''}
${result.suspiciousFiles.isNotEmpty ? 'FICHIERS SUSPECTS:\n${result.suspiciousFiles.map((f) => '- $f').join('\n')}\n' : ''}
${result.plagiarizedFiles.isNotEmpty ? 'FICHIERS PLAGIÉS:\n${result.plagiarizedFiles.map((f) => '- $f').join('\n')}\n' : ''}

WATERMARK
---------
${signature.watermark}

RECOMMANDATION
--------------
${result.isAuthentic ? 'Code source officiel - Utilisation sécurisée' : 'Téléchargez le code source officiel depuis github.com/TUTODECODE-FR/T2DECODE'}

Ce rapport certifie l'authenticité et l'intégrité du code source T2DECODE.
''';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
