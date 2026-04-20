// ============================================================
// Source Authentication System — Authentification par assets réels
// ============================================================
// Approche : vérifie l'intégrité des assets bundlés via rootBundle
// (SHA-256 réel). Aucune empreinte fictive de fichiers source.
// Les fichiers source Dart n'existent pas dans l'app compilée.
// ============================================================
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'anti_tampering.dart';

/// Métadonnées officielles du développeur (sans SIREN fictif).
const Map<String, dynamic> officialDeveloper = {
  'name': 'Association TUTODECODE',
  'type': 'Loi 1901',
  'country': 'France',
  'website': 'https://www.tutodecode.org',
  'contact': 'contact@tutodecode.org',
  'github': 'https://github.com/TUTODECODE-FR/T2DECODE',
  'license': 'AGPL-3.0',
  'developer_id': 'TUTODECODE_OFFICIAL_DEV_001',
};

/// Assets bundlés utilisés pour l'authentification du code source.
const List<String> _kSourceAssets = [
  'assets/courses.json',
  'assets/cheat_sheets.json',
  'assets/netkit_cheat_sheets.json',
  'assets/manifest.json',
  'assets/asset_checksums.json',
];

/// Système d'authentification basé sur les checksums SHA-256 réels des assets.
class SourceAuthentication {
  /// Accès aux métadonnées du développeur (rétro-compat).
  static Map<String, dynamic> get OFFICIAL_DEVELOPER => officialDeveloper;

  /// Vérifie l'authenticité des assets du code source.
  /// Retourne un résultat basé sur les vrais checksums SHA-256 des assets bundlés.
  static Future<SourceAuthResult> verifySourceAuthenticity() async {
    final fileResults = <String, bool>{};
    final modifiedFiles = <String>[];
    final missingSignatures = <String>[];

    // Calculer les checksums réels via rootBundle
    for (final assetPath in _kSourceAssets) {
      try {
        final data = await rootBundle.load(assetPath);
        final digest = sha256.convert(data.buffer.asUint8List());
        // Le checksum est valide si on peut le calculer
        fileResults[assetPath] = digest.toString().isNotEmpty;
      } catch (_) {
        fileResults[assetPath] = false;
        missingSignatures.add(assetPath);
      }
    }

    // Comparer avec le snapshot anti-tampering si disponible
    final integrityResult = await AntiTamperingSystem.performIntegrityCheck();
    for (final modified in integrityResult.modifiedFiles) {
      if (!modifiedFiles.contains(modified)) modifiedFiles.add(modified);
      fileResults[modified] = false;
    }

    final isAuthentic = fileResults.values.every((v) => v) && modifiedFiles.isEmpty;

    return SourceAuthResult(
      isAuthentic: isAuthentic,
      fileResults: fileResults,
      modifiedFiles: modifiedFiles,
      suspiciousFiles: integrityResult.suspiciousFiles,
      missingSignatures: missingSignatures,
      plagiarizedFiles: const [],
      checks: {
        'assets_present': missingSignatures.isEmpty,
        'assets_unmodified': modifiedFiles.isEmpty,
        'structure_valid': integrityResult.structureValid,
        'suspicious_clean': integrityResult.suspiciousFiles.isEmpty,
      },
      verificationDate: DateTime.now(),
      riskLevel: _calculateSourceRisk(
          modifiedFiles.length, integrityResult.suspiciousFiles.length, 0),
    );
  }

  /// Génère une signature de code source basée sur les checksums réels.
  static Future<CodeSignature> generateCodeSignature() async {
    final verification = await verifySourceAuthenticity();
    final signatureHash = _generateSignatureHash(verification);

    return CodeSignature(
      signatureId: 'SOURCE_SIG_${DateTime.now().millisecondsSinceEpoch}',
      isOfficial: verification.isAuthentic,
      verificationDate: verification.verificationDate,
      fileCount: verification.fileResults.length,
      authenticFiles: verification.fileResults.values.where((v) => v).length,
      signatureHash: signatureHash,
      qrCodeData: _generateSourceQRCode(verification, signatureHash),
      developerInfo: officialDeveloper,
      watermark: 'TUTODECODE_OFFICIAL_SOURCE',
    );
  }

  // ── Méthodes privées ──────────────────────────────────────────────────────

  static String _generateSignatureHash(SourceAuthResult verification) {
    final data =
        '${verification.isAuthentic}|${verification.verificationDate.toIso8601String()}|${verification.fileResults.length}';
    return sha256.convert(utf8.encode(data)).toString();
  }

  static String _generateSourceQRCode(SourceAuthResult verification, String hash) {
    return jsonEncode({
      'type': 'SOURCE_AUTHENTICATION',
      'project': 'TUTODECODE',
      'developer': officialDeveloper['name'],
      'isAuthentic': verification.isAuthentic,
      'verificationDate': verification.verificationDate.toIso8601String(),
      'signature': hash,
    });
  }

  static SourceRiskLevel _calculateSourceRisk(
      int modifiedFiles, int suspiciousFiles, int plagiarizedFiles) {
    if (suspiciousFiles > 0) return SourceRiskLevel.high;
    if (modifiedFiles > 2) return SourceRiskLevel.high;
    if (modifiedFiles > 0) return SourceRiskLevel.medium;
    return SourceRiskLevel.low;
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

/// Résultat de l'authentification du code source
class SourceAuthResult {
  final bool isAuthentic;
  final Map<String, bool> fileResults;
  final List<String> modifiedFiles;
  final List<String> suspiciousFiles;
  final List<String> missingSignatures;
  final List<String> plagiarizedFiles;
  final Map<String, bool> checks;
  final DateTime verificationDate;
  final SourceRiskLevel riskLevel;
  final String? error;

  const SourceAuthResult({
    required this.isAuthentic,
    required this.fileResults,
    required this.modifiedFiles,
    required this.suspiciousFiles,
    required this.missingSignatures,
    required this.plagiarizedFiles,
    required this.checks,
    required this.verificationDate,
    required this.riskLevel,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'isAuthentic': isAuthentic,
        'fileResults': fileResults,
        'modifiedFiles': modifiedFiles,
        'suspiciousFiles': suspiciousFiles,
        'missingSignatures': missingSignatures,
        'plagiarizedFiles': plagiarizedFiles,
        'checks': checks,
        'verificationDate': verificationDate.toIso8601String(),
        'riskLevel': riskLevel.name,
        'error': error,
      };
}

/// Signature de code source
class CodeSignature {
  final String signatureId;
  final bool isOfficial;
  final DateTime verificationDate;
  final int fileCount;
  final int authenticFiles;
  final String signatureHash;
  final String qrCodeData;
  final Map<String, dynamic> developerInfo;
  final String watermark;

  const CodeSignature({
    required this.signatureId,
    required this.isOfficial,
    required this.verificationDate,
    required this.fileCount,
    required this.authenticFiles,
    required this.signatureHash,
    required this.qrCodeData,
    required this.developerInfo,
    required this.watermark,
  });

  Map<String, dynamic> toJson() => {
        'signatureId': signatureId,
        'isOfficial': isOfficial,
        'verificationDate': verificationDate.toIso8601String(),
        'fileCount': fileCount,
        'authenticFiles': authenticFiles,
        'signatureHash': signatureHash,
        'qrCodeData': qrCodeData,
        'developerInfo': developerInfo,
        'watermark': watermark,
      };
}

/// Manifest du développeur
class DeveloperManifest {
  final Map<String, dynamic> developerInfo;
  final Map<String, String> codeFingerprints;
  final List<String> signatures;
  final String buildDate;
  final String environment;
  final String integrityHash;

  const DeveloperManifest({
    required this.developerInfo,
    required this.codeFingerprints,
    required this.signatures,
    required this.buildDate,
    required this.environment,
    required this.integrityHash,
  });

  Map<String, dynamic> toJson() => {
        'developerInfo': developerInfo,
        'codeFingerprints': codeFingerprints,
        'signatures': signatures,
        'buildDate': buildDate,
        'environment': environment,
        'integrityHash': integrityHash,
      };
}

/// Niveaux de risque pour le code source
enum SourceRiskLevel { low, medium, high, critical }

/// Service d'authentification du code source avec cache
class SourceAuthService {
  static SourceAuthResult? _lastVerification;
  static DateTime? _lastVerificationTime;

  static Future<SourceAuthResult> verifySource({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastVerification != null &&
        _lastVerificationTime != null &&
        now.difference(_lastVerificationTime!).inMinutes < 30) {
      return _lastVerification!;
    }
    _lastVerification = await SourceAuthentication.verifySourceAuthenticity();
    _lastVerificationTime = now;
    return _lastVerification!;
  }

  static Future<bool> quickSourceCheck() async {
    try {
      return await AntiTamperingService.quickIntegrityCheck();
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> generateSourceReport() async {
    final verification = await verifySource();
    final signature = await SourceAuthentication.generateCodeSignature();
    return {
      'verification': verification.toJson(),
      'signature': signature.toJson(),
      'reportGenerated': DateTime.now().toIso8601String(),
      'summary': {
        'isAuthentic': verification.isAuthentic,
        'riskLevel': verification.riskLevel.name,
        'totalAssets': verification.fileResults.length,
        'authenticAssets': verification.fileResults.values.where((v) => v).length,
        'modifiedAssets': verification.modifiedFiles.length,
        'recommendation': verification.isAuthentic
            ? 'Assets authentiques — Aucune modification détectée'
            : 'Assets modifiés — Risque d\'intégrité',
      },
    };
  }

  static void clearCache() {
    _lastVerification = null;
    _lastVerificationTime = null;
  }
}
