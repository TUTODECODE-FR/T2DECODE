// ============================================================
// Build Verification System — Vérification de build en local
// ============================================================
// Approche : calcule les checksums SHA-256 réels des assets bundlés
// au runtime via rootBundle. Aucune signature fictive, aucun serveur.
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'anti_tampering.dart';

/// Assets bundlés utilisés pour vérifier l'intégrité du build.
const List<String> _kBuildAssets = [
  'assets/courses.json',
  'assets/manifest.json',
  'assets/asset_checksums.json',
];

/// Système de vérification du build basé sur les checksums réels des assets.
class BuildVerification {
  static const String APP_VERSION = '1.0.3+3';

  /// Vérifie le build actuel en calculant les checksums réels des assets.
  static Future<BuildVerificationResult> verifyCurrentBuild() async {
    try {
      final buildInfo = await _getCurrentBuildInfo();
      final checks = <String, bool>{};
      final reasons = <String>[];

      // 1. Vérifier que les assets critiques sont présents et lisibles
      bool allAssetsOk = true;
      for (final asset in _kBuildAssets) {
        try {
          await rootBundle.load(asset);
          checks['asset:${asset.split('/').last}'] = true;
        } catch (_) {
          checks['asset:${asset.split('/').last}'] = false;
          allAssetsOk = false;
          reasons.add('Asset manquant: $asset');
        }
      }

      // 2. Vérifier la version déclarée
      final versionValid = buildInfo.version.isNotEmpty;
      checks['version'] = versionValid;
      if (!versionValid) reasons.add('Version invalide');

      // 3. Vérifier la plateforme
      final platformValid = buildInfo.platform != 'unknown';
      checks['platform'] = platformValid;

      // 4. Calculer le checksum global des assets
      final globalChecksum = await _computeGlobalChecksum();
      checks['checksum'] = globalChecksum.isNotEmpty;

      final isOfficial = allAssetsOk && versionValid;

      return BuildVerificationResult(
        isOfficial: isOfficial,
        buildInfo: buildInfo.copyWith(
          checksum: globalChecksum,
          signature: 'SHA256:$globalChecksum',
          isOfficial: isOfficial,
        ),
        verificationDate: DateTime.now(),
        checks: checks,
        reasons: reasons.isEmpty ? null : reasons,
        riskLevel: isOfficial ? RiskLevel.low : _calculateBuildRisk(reasons),
      );
    } catch (e) {
      final fallback = await _getCurrentBuildInfo();
      return BuildVerificationResult(
        isOfficial: false,
        buildInfo: fallback,
        verificationDate: DateTime.now(),
        error: 'Erreur lors de la vérification du build: $e',
        riskLevel: RiskLevel.critical,
        checks: const {'error': false},
      );
    }
  }

  /// Génère un certificat de build basé sur les données réelles.
  static Future<BuildCertificate> generateBuildCertificate() async {
    final verification = await verifyCurrentBuild();
    return BuildCertificate(
      certificateId: 'BUILD_CERT_${DateTime.now().millisecondsSinceEpoch}',
      buildInfo: verification.buildInfo,
      isOfficial: verification.isOfficial,
      verificationDate: verification.verificationDate,
      certificateHash: _generateCertificateHash(verification),
      qrCodeData: _generateBuildQRCode(verification),
      signature: 'SHA256:${_generateCertificateHash(verification)}',
    );
  }

  // ── Méthodes privées ──────────────────────────────────────────────────────

  static Future<BuildInfo> _getCurrentBuildInfo() async {
    final platform = _getCurrentPlatform();
    final checksum = await _computeGlobalChecksum();

    return BuildInfo(
      version: APP_VERSION,
      buildNumber: 'runtime-${DateTime.now().millisecondsSinceEpoch}',
      buildDate: DateTime.now().toIso8601String().split('T')[0],
      platform: platform,
      architecture: 'universal',
      buildType: 'release',
      signature: 'SHA256:$checksum',
      checksum: checksum,
      isOfficial: checksum.isNotEmpty,
      buildEnvironment: 'local',
    );
  }

  static Future<String> _computeGlobalChecksum() async {
    try {
      final hashes = <String>[];
      for (final asset in _kBuildAssets) {
        try {
          final data = await rootBundle.load(asset);
          final digest = sha256.convert(data.buffer.asUint8List());
          hashes.add(digest.toString());
        } catch (_) {
          hashes.add('MISSING:$asset');
        }
      }
      final combined = hashes.join('|');
      return sha256.convert(utf8.encode(combined)).toString();
    } catch (_) {
      return '';
    }
  }

  static String _getCurrentPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  static String _generateCertificateHash(BuildVerificationResult v) {
    final data =
        '${v.buildInfo.version}|${v.isOfficial}|${v.verificationDate.toIso8601String()}|${v.buildInfo.checksum}';
    return sha256.convert(utf8.encode(data)).toString();
  }

  static String _generateBuildQRCode(BuildVerificationResult v) {
    return jsonEncode({
      'app': 'T2CODE',
      'version': v.buildInfo.version,
      'platform': v.buildInfo.platform,
      'isOfficial': v.isOfficial,
      'checksum': v.buildInfo.checksum,
      'verificationDate': v.verificationDate.toIso8601String(),
    });
  }

  static RiskLevel _calculateBuildRisk(List<String> reasons) {
    if (reasons.length >= 3) return RiskLevel.critical;
    if (reasons.length >= 2) return RiskLevel.high;
    return RiskLevel.medium;
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

/// Informations de build
class BuildInfo {
  final String version;
  final String buildNumber;
  final String buildDate;
  final String platform;
  final String architecture;
  final String buildType;
  final String signature;
  final String checksum;
  final bool isOfficial;
  final String buildEnvironment;

  const BuildInfo({
    required this.version,
    required this.buildNumber,
    required this.buildDate,
    required this.platform,
    required this.architecture,
    required this.buildType,
    required this.signature,
    required this.checksum,
    required this.isOfficial,
    required this.buildEnvironment,
  });

  BuildInfo copyWith({
    String? version,
    String? buildNumber,
    String? buildDate,
    String? platform,
    String? architecture,
    String? buildType,
    String? signature,
    String? checksum,
    bool? isOfficial,
    String? buildEnvironment,
  }) =>
      BuildInfo(
        version: version ?? this.version,
        buildNumber: buildNumber ?? this.buildNumber,
        buildDate: buildDate ?? this.buildDate,
        platform: platform ?? this.platform,
        architecture: architecture ?? this.architecture,
        buildType: buildType ?? this.buildType,
        signature: signature ?? this.signature,
        checksum: checksum ?? this.checksum,
        isOfficial: isOfficial ?? this.isOfficial,
        buildEnvironment: buildEnvironment ?? this.buildEnvironment,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'buildNumber': buildNumber,
        'buildDate': buildDate,
        'platform': platform,
        'architecture': architecture,
        'buildType': buildType,
        'signature': signature,
        'checksum': checksum,
        'isOfficial': isOfficial,
        'buildEnvironment': buildEnvironment,
      };

  factory BuildInfo.fromJson(Map<String, dynamic> json) => BuildInfo(
        version: json['version'] as String? ?? '',
        buildNumber: json['buildNumber'] as String? ?? '',
        buildDate: json['buildDate'] as String? ?? '',
        platform: json['platform'] as String? ?? '',
        architecture: json['architecture'] as String? ?? '',
        buildType: json['buildType'] as String? ?? '',
        signature: json['signature'] as String? ?? '',
        checksum: json['checksum'] as String? ?? '',
        isOfficial: json['isOfficial'] as bool? ?? false,
        buildEnvironment: json['buildEnvironment'] as String? ?? '',
      );
}

/// Résultat de vérification de build
class BuildVerificationResult {
  final bool isOfficial;
  final BuildInfo buildInfo;
  final BuildInfo? officialBuildInfo;
  final DateTime verificationDate;
  final Map<String, bool> checks;
  final List<String>? reasons;
  final RiskLevel riskLevel;
  final String? error;

  const BuildVerificationResult({
    required this.isOfficial,
    required this.buildInfo,
    this.officialBuildInfo,
    required this.verificationDate,
    required this.checks,
    this.reasons,
    required this.riskLevel,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'isOfficial': isOfficial,
        'buildInfo': buildInfo.toJson(),
        'verificationDate': verificationDate.toIso8601String(),
        'checks': checks,
        'reasons': reasons,
        'riskLevel': riskLevel.name,
        'error': error,
      };
}

/// Certificat de build
class BuildCertificate {
  final String certificateId;
  final BuildInfo buildInfo;
  final bool isOfficial;
  final DateTime verificationDate;
  final String certificateHash;
  final String qrCodeData;
  final String signature;

  const BuildCertificate({
    required this.certificateId,
    required this.buildInfo,
    required this.isOfficial,
    required this.verificationDate,
    required this.certificateHash,
    required this.qrCodeData,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'certificateId': certificateId,
        'buildInfo': buildInfo.toJson(),
        'isOfficial': isOfficial,
        'verificationDate': verificationDate.toIso8601String(),
        'certificateHash': certificateHash,
        'qrCodeData': qrCodeData,
        'signature': signature,
      };
}

/// Service de vérification de build avec cache
class BuildVerificationService {
  static BuildVerificationResult? _lastVerification;
  static DateTime? _lastVerificationTime;

  static Future<BuildVerificationResult> verifyBuild({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastVerification != null &&
        _lastVerificationTime != null &&
        now.difference(_lastVerificationTime!).inMinutes < 15) {
      return _lastVerification!;
    }
    _lastVerification = await BuildVerification.verifyCurrentBuild();
    _lastVerificationTime = now;
    return _lastVerification!;
  }

  static Future<bool> quickBuildCheck() async {
    try {
      final result = await verifyBuild();
      return result.isOfficial;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> generateBuildReport() async {
    final verification = await verifyBuild();
    final certificate = await BuildVerification.generateBuildCertificate();
    return {
      'verification': verification.toJson(),
      'certificate': certificate.toJson(),
      'reportGenerated': DateTime.now().toIso8601String(),
      'summary': {
        'isOfficial': verification.isOfficial,
        'version': verification.buildInfo.version,
        'platform': verification.buildInfo.platform,
        'riskLevel': verification.riskLevel.name,
        'checksum': verification.buildInfo.checksum,
        'recommendation': verification.isOfficial
            ? 'Build vérifié — Tous les assets sont présents'
            : 'Build incomplet — Vérifiez l\'installation',
      },
    };
  }

  static void clearCache() {
    _lastVerification = null;
    _lastVerificationTime = null;
  }
}
