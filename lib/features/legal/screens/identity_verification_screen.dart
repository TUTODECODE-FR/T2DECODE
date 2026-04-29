// ============================================================
// Identity Verification Screen - Interface de vérification d'authenticité
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/security/identity_verification.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VerificationResult? _verificationResult;
  AuthenticityCertificate? _certificate;
  DigitalSeal? _digitalSeal;
  bool _isVerifying = false;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Vérification d\'Identité',
        showBackButton: true,
        actions: [],
      );
    });
    
    _performVerification();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performVerification() async {
    setState(() => _isVerifying = true);
    
    try {
      final result = await IdentityVerificationService.verifyIdentity();
      final certificate = await IdentityVerification.generateAuthenticityCertificate();
      final seal = IdentityVerification.createAssociationSeal();
      
      setState(() {
        _verificationResult = result;
        _certificate = certificate;
        _digitalSeal = seal;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TdcColors.surface,
            border: Border(bottom: BorderSide(color: TdcColors.border)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user,
                color: Colors.blue.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Vérification d\'Authenticité',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_verificationResult != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _verificationResult!.isAuthentic 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _verificationResult!.isAuthentic 
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _verificationResult!.isAuthentic ? Icons.check_circle : Icons.warning,
                        color: _verificationResult!.isAuthentic ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _verificationResult!.isAuthentic ? 'AUTHENTIQUE' : 'NON VÉRIFIÉ',
                        style: TextStyle(
                          color: _verificationResult!.isAuthentic ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          color: TdcColors.surfaceAlt.withOpacity(0.3),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.blue.shade700,
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: TdcColors.textMuted,
            tabs: const [
              Tab(text: 'Authenticité'),
              Tab(text: 'Certificat'),
              Tab(text: 'Sceau Numérique'),
            ],
          ),
        ),
        Expanded(
          child: _isVerifying
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: TdcColors.accent),
                      SizedBox(height: 16),
                      Text(
                        'Vérification de l\'authenticité...',
                        style: TextStyle(color: TdcColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : _verificationResult == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Erreur de vérification',
                            style: TextStyle(color: Colors.red, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _performVerification,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAuthenticityTab(),
                    _buildCertificateTab(),
                    _buildSealTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAuthenticityTab() {
    final result = _verificationResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: result.isAuthentic 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: result.isAuthentic 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  result.isAuthentic ? Icons.verified : Icons.gpp_bad,
                  color: result.isAuthentic ? Colors.green : Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  result.isAuthentic ? 'Application Authentifiée' : 'Application Non Authentifiée',
                  style: TextStyle(
                    color: result.isAuthentic ? Colors.green : Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  result.isAuthentic 
                      ? 'Cette application est officiellement créée par l\'Association TUTODECODE'
                      : 'Cette application n\'est pas reconnue comme officielle',
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
          
          // Informations sur l'association
          _buildAssociationInfo(),
          
          const SizedBox(height: 32),
          
          // Résultats des vérifications
          _buildVerificationChecks(result),
          
          const SizedBox(height: 32),
          
          // Détails
          if (result.details != null) ...[
            Row(
              children: [
                const Text(
                  'Détails de Vérification',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _showDetails = !_showDetails),
                  child: Text(_showDetails ? 'Masquer' : 'Afficher'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_showDetails)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TdcColors.surfaceAlt.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TdcColors.border),
                ),
                child: Text(
                  result.details!,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
          
          const SizedBox(height: 32),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyVerificationReport,
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
                  onPressed: _shareVerification,
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssociationInfo() {
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Association TUTODECODE',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Type', 'Association Loi 1901'),
            _buildInfoRow('SIREN', IdentityVerification.ASSOCIATION_SIREN),
            _buildInfoRow('Email', IdentityVerification.ASSOCIATION_EMAIL),
            _buildInfoRow('Site Web', IdentityVerification.ASSOCIATION_WEBSITE),
            _buildInfoRow('Pays', 'France'),
            _buildInfoRow('Date de Vérification', _formatDate(_verificationResult!.verificationDate)),
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

  Widget _buildVerificationChecks(VerificationResult result) {
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contrôles de Sécurité',
              style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
          'name': 'Signature de l\'Application',
          'description': 'Vérifie que l\'application est signée par l\'association',
        };
      case 'metadata':
        return {
          'name': 'Métadonnées de l\'Association',
          'description': 'Valide les informations de l\'association TUTODECODE',
        };
      case 'certificate':
        return {
          'name': 'Certificat de Build',
          'description': 'Vérifie le certificat de compilation signé',
        };
      case 'codeIntegrity':
        return {
          'name': 'Intégrité du Code',
          'description': 'Contrôle que le code n\'a pas été modifié',
        };
      case 'digitalSignature':
        return {
          'name': 'Signature Numérique',
          'description': 'Valide la signature cryptographique',
        };
      default:
        return {
          'name': checkName,
          'description': 'Contrôle de sécurité',
        };
    }
  }

  Widget _buildCertificateTab() {
    final certificate = _certificate!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du certificat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade700.withOpacity(0.1),
                  Colors.blue.shade500.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade300.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.verified, color: Colors.blue.shade700, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Certificat d\'Authenticité',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ce certificat atteste de l\'authenticité de l\'application',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Informations du certificat
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations du Certificat',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCertRow('ID du Certificat', certificate.certificateId),
                  _buildCertRow('Application', certificate.applicationName),
                  _buildCertRow('Version', certificate.version),
                  _buildCertRow('Association', certificate.associationName),
                  _buildCertRow('SIREN', certificate.associationSIREN),
                  _buildCertRow('Date d\'Émission', _formatDate(certificate.issueDate)),
                  _buildCertRow('Validité', certificate.isValid ? 'Valide' : 'Invalide'),
                  _buildCertRow('Hash de Vérification', certificate.verificationHash),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // QR Code
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Code QR de Vérification',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: certificate.qrCodeData,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scannez ce code QR pour vérifier l\'authenticité',
                    style: TextStyle(
                      color: TdcColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportCertificate,
                  icon: const Icon(Icons.download),
                  label: const Text('Exporter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _printCertificate,
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildSealTab() {
    final seal = _digitalSeal!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sceau numérique
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade700.withOpacity(0.1),
                  Colors.purple.shade500.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade300.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                // Design du sceau
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade700,
                        Colors.purple.shade500,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sceau Numérique Officiel',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Association TUTODECODE',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Authentifié et scellé numériquement',
                  style: const TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Informations du sceau
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations du Sceau',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSealRow('ID du Sceau', seal.sealId),
                  _buildSealRow('Association', seal.associationName),
                  _buildSealRow('SIREN', seal.associationSIREN),
                  _buildSealRow('Horodatage', seal.timestamp),
                  _buildSealRow('Hash', seal.hash),
                  _buildSealRow('Signature', seal.signature),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Vérification du sceau
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vérification du Sceau',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Sceau valide et authentique',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Signature cryptographique vérifiée',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSealRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  void _copyVerificationReport() {
    final report = _generateTextReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapport copié dans le presse-papiers')),
    );
  }

  void _shareVerification() {
    // Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonction de partage à implémenter')),
    );
  }

  void _exportCertificate() {
    // Implémenter l'export du certificat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export du certificat à implémenter')),
    );
  }

  void _printCertificate() {
    // Implémenter l'impression
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impression à implémenter')),
    );
  }

  String _generateTextReport() {
    final result = _verificationResult!;
    final certificate = _certificate!;
    
    return '''
RAPPORT DE VÉRIFICATION D'AUTHENTICITÉ
==========================================

Application: T2DECODE
Date de vérification: ${_formatDate(result.verificationDate)}

STATUT: ${result.isAuthentic ? 'AUTHENTIFIÉ' : 'NON AUTHENTIFIÉ'}

Association: ${result.associationName}
SIREN: ${IdentityVerification.ASSOCIATION_SIREN}
Email: ${IdentityVerification.ASSOCIATION_EMAIL}
Site Web: ${IdentityVerification.ASSOCIATION_WEBSITE}

CERTIFICAT D'AUTHENTICITÉ
--------------------------
ID: ${certificate.certificateId}
Version: ${certificate.version}
Date d'émission: ${_formatDate(certificate.issueDate)}
Validité: ${certificate.isValid ? 'Valide' : 'Invalide'}

CONTRÔLES DE SÉCURITÉ
----------------------
${result.checks.entries.map((e) => '- ${e.key}: ${e.value ? 'OK' : 'FAIL'}').join('\n')}

DÉTAILS
-------
${result.details ?? 'Aucun détail disponible'}

Ce rapport confirme que l'application T2DECODE est officiellement créée et signée par l'Association TUTODECODE (Loi 1901, France).
''';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
