// ============================================================
// Build Verification Screen - Interface de vérification de build
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/security/build_verification.dart';

class BuildVerificationScreen extends StatefulWidget {
  const BuildVerificationScreen({super.key});

  @override
  State<BuildVerificationScreen> createState() => _BuildVerificationScreenState();
}

class _BuildVerificationScreenState extends State<BuildVerificationScreen>
    with TickerProviderStateMixin {
  BuildVerificationResult? _verificationResult;
  BuildCertificate? _certificate;
  bool _isVerifying = false;
  bool _showTechnicalDetails = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Vérification de Build',
        showBackButton: true,
        actions: [],
      );
    });
    
    _performBuildVerification();
  }

  Future<void> _performBuildVerification() async {
    setState(() => _isVerifying = true);
    
    try {
      final result = await BuildVerificationService.verifyBuild();
      final certificate = await BuildVerification.generateBuildCertificate();
      
      setState(() {
        _verificationResult = result;
        _certificate = certificate;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() => _isVerifying = false);
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _verificationResult?.isOfficial == true 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  _verificationResult?.isOfficial == true 
                      ? Colors.green.withOpacity(0.05)
                      : Colors.orange.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _verificationResult?.isOfficial == true 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _verificationResult?.isOfficial == true ? Icons.verified : Icons.build_circle,
                  color: _verificationResult?.isOfficial == true ? Colors.green : Colors.orange,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _verificationResult?.isOfficial == true 
                      ? 'Build Officiel Vérifié'
                      : 'Build Non Officiel Détecté',
                  style: TextStyle(
                    color: _verificationResult?.isOfficial == true ? Colors.green : Colors.orange,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _verificationResult?.isOfficial == true 
                      ? 'Ce build est authentiquement signé par l\'Association TUTODECODE'
                      : 'Ce build n\'est pas reconnu comme officiel',
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
          
          if (_verificationResult != null) ...[
            // Informations du build
            _buildBuildInfo(_verificationResult!.buildInfo),
            
            const SizedBox(height: 24),
            
            // Résultats des vérifications
            _buildVerificationChecks(_verificationResult!),
            
            if (_verificationResult!.reasons != null) ...[
              const SizedBox(height: 24),
              _buildReasonsSection(_verificationResult!.reasons!),
            ],
            
            const SizedBox(height: 24),
            
            // Certificat de build
            _buildCertificateSection(),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActionsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildBuildInfo(BuildInfo buildInfo) {
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: TdcColors.accent, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Informations du Build',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Version', buildInfo.version),
            _buildInfoRow('Build Number', buildInfo.buildNumber),
            _buildInfoRow('Date de Build', buildInfo.buildDate),
            _buildInfoRow('Plateforme', buildInfo.platform),
            _buildInfoRow('Architecture', buildInfo.architecture),
            _buildInfoRow('Type de Build', buildInfo.buildType),
            _buildInfoRow('Environnement', buildInfo.buildEnvironment),
            if (!buildInfo.isOfficial)
              _buildInfoRow('Statut', 'Non officiel', isWarning: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
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
              style: TextStyle(
                color: isWarning ? Colors.orange : TdcColors.textPrimary,
                fontSize: 14,
                fontWeight: isWarning ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationChecks(BuildVerificationResult result) {
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
                  'Contrôles de Sécurité',
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
                  checkInfo['name'] ?? 'Contrôle inconnu',
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  checkInfo['description'] ?? 'Description indisponible',
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
      case 'signature':
        return {
          'name': 'Signature du Build',
          'description': 'Vérifie que la signature correspond au build officiel',
        };
      case 'checksum':
        return {
          'name': 'Checksum du Build',
          'description': 'Valide l\'intégrité du build via checksum',
        };
      case 'environment':
        return {
          'name': 'Environnement de Build',
          'description': 'Contrôle l\'environnement de compilation officiel',
        };
      case 'manifest':
        return {
          'name': 'Manifest de Build',
          'description': 'Vérifie la présence et validité du manifest',
        };
      case 'metadata':
        return {
          'name': 'Métadonnées',
          'description': 'Valide la cohérence des métadonnées',
        };
      default:
        return {
          'name': checkName,
          'description': 'Contrôle de sécurité',
        };
    }
  }

  Widget _buildReasonsSection(List<String> reasons) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Alertes de Sécurité',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )),
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
            Row(
              children: [
                Icon(Icons.verified, color: TdcColors.accent, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Certificat de Build',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Informations du certificat
            _buildCertRow('ID du Certificat', _certificate!.certificateId),
            _buildCertRow('Validité', _certificate!.isOfficial ? 'Officiel' : 'Non officiel'),
            _buildCertRow('Date de Vérification', _formatDate(_certificate!.verificationDate)),
            _buildCertRow('Hash', _certificate!.certificateHash),
            
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
                    'Code QR de Vérification',
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
                  const SizedBox(height: 12),
                  const Text(
                    'Scannez pour vérifier l\'authenticité',
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

  Widget _buildCertRow(String label, String value) {
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

  Widget _buildActionsSection() {
    return Column(
      children: [
        // Recommandations
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _verificationResult?.isOfficial == true 
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _verificationResult?.isOfficial == true 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _verificationResult?.isOfficial == true ? Icons.check_circle : Icons.info,
                color: _verificationResult?.isOfficial == true ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _verificationResult?.isOfficial == true 
                      ? '✅ Build officiel - Utilisation sécurisée recommandée'
                      : '⚠️ Build non officiel - Téléchargez la version officielle depuis tutodecode.org',
                  style: TextStyle(
                    color: _verificationResult?.isOfficial == true ? Colors.green : Colors.orange,
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
                onPressed: _copyBuildReport,
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
                onPressed: _exportCertificate,
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
        
        if (_verificationResult?.isOfficial != true) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloadOfficialVersion,
              icon: const Icon(Icons.download),
              label: const Text('Télécharger la Version Officielle'),
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
  void _copyBuildReport() {
    final report = _generateTextReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapport de build copié')),
    );
  }

  void _exportCertificate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export du certificat à implémenter')),
    );
  }

  void _shareVerification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage à implémenter')),
    );
  }

  void _downloadOfficialVersion() {
    // Ouvrir le site officiel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirection vers tutodecode.org')),
    );
  }

  String _generateTextReport() {
    final result = _verificationResult!;
    final certificate = _certificate!;
    
    return '''
RAPPORT DE VÉRIFICATION DE BUILD
==================================

Application: TUTODECODE
Date de vérification: ${_formatDate(result.verificationDate)}

STATUT: ${result.isOfficial ? 'OFFICIEL' : 'NON OFFICIEL'}

INFORMATIONS DU BUILD
----------------------
Version: ${result.buildInfo.version}
Build Number: ${result.buildInfo.buildNumber}
Date de Build: ${result.buildInfo.buildDate}
Plateforme: ${result.buildInfo.platform}
Architecture: ${result.buildInfo.architecture}
Type: ${result.buildInfo.buildType}
Environnement: ${result.buildInfo.buildEnvironment}

CERTIFICAT DE BUILD
------------------
ID: ${certificate.certificateId}
Validité: ${certificate.isOfficial ? 'Officiel' : 'Non officiel'}
Date: ${_formatDate(certificate.verificationDate)}
Hash: ${certificate.certificateHash}

CONTRÔLES DE SÉCURITÉ
----------------------
${result.checks.entries.map((e) => '- ${e.key}: ${e.value ? 'OK' : 'FAIL'}').join('\n')}

${result.reasons != null ? 'ALERTES:\n${result.reasons!.map((r) => '- $r').join('\n')}\n' : ''}

RECOMMANDATION
--------------
${result.isOfficial ? 'Build officiel - Utilisation sécurisée' : 'Téléchargez la version officielle depuis tutodecode.org'}

Ce rapport confirme l'authenticité et l'intégrité du build TUTODECODE.
''';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
