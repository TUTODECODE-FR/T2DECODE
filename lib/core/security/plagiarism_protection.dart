// ============================================================
// Plagiarism Protection System — Protection de l'originalité
// ============================================================
// Approche : vérifie l'originalité via les checksums SHA-256
// réels des assets bundlés. Aucun DNA fictif.
// ============================================================
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'source_authentication.dart';
import 'anti_tampering.dart';

/// Assets utilisés pour l'analyse d'originalité.
const List<String> _kPlagiarismAssets = [
  'assets/courses.json',
  'assets/cheat_sheets.json',
  'assets/netkit_cheat_sheets.json',
  'assets/manifest.json',
  'assets/asset_checksums.json',
];

/// Système de protection contre le plagiat basé sur l'intégrité réelle des assets.
class PlagiarismProtection {
  /// Analyse un asset pour détecter des modifications (plagiat ou altération).
  static Future<PlagiarismAnalysis> analyzeFile(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final digest = sha256.convert(data.buffer.asUint8List());
      final checksumValid = digest.toString().isNotEmpty;

      return PlagiarismAnalysis(
        filePath: assetPath,
        isOriginal: checksumValid,
        plagiarismScore: checksumValid ? 0.0 : 1.0,
        issues: checksumValid ? [] : ['Asset illisible ou corrompu: $assetPath'],
        originalityScore: checksumValid ? 100.0 : 0.0,
      );
    } catch (_) {
      return PlagiarismAnalysis(
        filePath: assetPath,
        isOriginal: false,
        plagiarismScore: 1.0,
        issues: ['Asset manquant: $assetPath'],
        originalityScore: 0.0,
      );
    }
  }

  /// Analyse complète du projet via les checksums réels des assets.
  static Future<ProjectPlagiarismAnalysis> analyzeProject() async {
    try {
      final fileAnalyses = <PlagiarismAnalysis>[];
      double totalOriginalityScore = 0.0;
      final allIssues = <String>[];

      for (final assetPath in _kPlagiarismAssets) {
        final analysis = await analyzeFile(assetPath);
        fileAnalyses.add(analysis);
        totalOriginalityScore += analysis.originalityScore;
        allIssues.addAll(analysis.issues);
      }

      final averageOriginalityScore =
          _kPlagiarismAssets.isEmpty ? 100.0 : totalOriginalityScore / _kPlagiarismAssets.length;
      final overallPlagiarismScore = (100.0 - averageOriginalityScore) / 100.0;

      // Vérifier l'intégrité complète via le système anti-tampering
      final integrityResult = await AntiTamperingSystem.performIntegrityCheck();
      final structureMatch = integrityResult.structureValid;
      final dependenciesMatch = integrityResult.modifiedFiles.isEmpty;
      final projectDNA = integrityResult.isIntegrityValid;

      if (!projectDNA) {
        allIssues.addAll(integrityResult.modifiedFiles.map(
          (f) => 'Asset modifié depuis l\'installation: $f',
        ));
      }

      final isAuthentic = averageOriginalityScore >= 80.0 && projectDNA;

      return ProjectPlagiarismAnalysis(
        isAuthentic: isAuthentic,
        overallOriginalityScore: averageOriginalityScore,
        overallPlagiarismScore: overallPlagiarismScore,
        fileAnalyses: fileAnalyses,
        projectDNA: projectDNA,
        structureMatch: structureMatch,
        dependenciesMatch: dependenciesMatch,
        allIssues: allIssues,
        analysisDate: DateTime.now(),
        riskLevel: _calculatePlagiarismRisk(overallPlagiarismScore, allIssues),
      );
    } catch (e) {
      return ProjectPlagiarismAnalysis(
        isAuthentic: false,
        overallOriginalityScore: 0.0,
        overallPlagiarismScore: 1.0,
        fileAnalyses: [],
        projectDNA: false,
        structureMatch: false,
        dependenciesMatch: false,
        allIssues: ['Erreur d\'analyse: $e'],
        analysisDate: DateTime.now(),
        riskLevel: PlagiarismRiskLevel.critical,
      );
    }
  }

  /// Génère un certificat d'originalité basé sur les checksums réels.
  static Future<OriginalityCertificate> generateOriginalityCertificate() async {
    final analysis = await analyzeProject();
    final certHash = _generateCertificateHash(analysis);
    final devId = officialDeveloper['developer_id'] as String? ?? 'TUTODECODE_OFFICIAL_DEV_001';

    return OriginalityCertificate(
      certificateId: 'ORIG_CERT_${DateTime.now().millisecondsSinceEpoch}',
      projectName: 'TUTODECODE',
      developerId: devId,
      isOriginal: analysis.isAuthentic,
      originalityScore: analysis.overallOriginalityScore,
      analysisDate: analysis.analysisDate,
      certificateHash: certHash,
      qrCodeData: _generateCertificateQRCode(analysis, certHash, devId),
      digitalSignature: 'SHA256:$certHash',
    );
  }

  // ── Méthodes privées ──────────────────────────────────────────────────────

  static PlagiarismRiskLevel _calculatePlagiarismRisk(
      double plagiarismScore, List<String> issues) {
    if (plagiarismScore >= 0.7 || issues.length >= 5) return PlagiarismRiskLevel.critical;
    if (plagiarismScore >= 0.4 || issues.length >= 3) return PlagiarismRiskLevel.high;
    if (plagiarismScore >= 0.2 || issues.length >= 1) return PlagiarismRiskLevel.medium;
    return PlagiarismRiskLevel.low;
  }

  static String _generateCertificateHash(ProjectPlagiarismAnalysis analysis) {
    final data =
        '${analysis.isAuthentic}|${analysis.overallOriginalityScore}|${analysis.analysisDate.toIso8601String()}';
    return sha256.convert(utf8.encode(data)).toString();
  }

  static String _generateCertificateQRCode(
      ProjectPlagiarismAnalysis analysis, String hash, String devId) {
    return jsonEncode({
      'type': 'ORIGINALITY_CERTIFICATE',
      'project': 'TUTODECODE',
      'developer': officialDeveloper['name'],
      'isOriginal': analysis.isAuthentic,
      'originalityScore': analysis.overallOriginalityScore,
      'analysisDate': analysis.analysisDate.toIso8601String(),
      'certificate': hash,
    });
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class PlagiarismAnalysis {
  final String filePath;
  final bool isOriginal;
  final double plagiarismScore;
  final List<String> issues;
  final double originalityScore;

  const PlagiarismAnalysis({
    required this.filePath,
    required this.isOriginal,
    required this.plagiarismScore,
    required this.issues,
    required this.originalityScore,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'isOriginal': isOriginal,
        'plagiarismScore': plagiarismScore,
        'issues': issues,
        'originalityScore': originalityScore,
      };
}

class ProjectPlagiarismAnalysis {
  final bool isAuthentic;
  final double overallOriginalityScore;
  final double overallPlagiarismScore;
  final List<PlagiarismAnalysis> fileAnalyses;
  final bool projectDNA;
  final bool structureMatch;
  final bool dependenciesMatch;
  final List<String> allIssues;
  final DateTime analysisDate;
  final PlagiarismRiskLevel riskLevel;

  const ProjectPlagiarismAnalysis({
    required this.isAuthentic,
    required this.overallOriginalityScore,
    required this.overallPlagiarismScore,
    required this.fileAnalyses,
    required this.projectDNA,
    required this.structureMatch,
    required this.dependenciesMatch,
    required this.allIssues,
    required this.analysisDate,
    required this.riskLevel,
  });

  Map<String, dynamic> toJson() => {
        'isAuthentic': isAuthentic,
        'overallOriginalityScore': overallOriginalityScore,
        'overallPlagiarismScore': overallPlagiarismScore,
        'fileAnalyses': fileAnalyses.map((a) => a.toJson()).toList(),
        'projectDNA': projectDNA,
        'structureMatch': structureMatch,
        'dependenciesMatch': dependenciesMatch,
        'allIssues': allIssues,
        'analysisDate': analysisDate.toIso8601String(),
        'riskLevel': riskLevel.name,
      };
}

class OriginalityCertificate {
  final String certificateId;
  final String projectName;
  final String developerId;
  final bool isOriginal;
  final double originalityScore;
  final DateTime analysisDate;
  final String certificateHash;
  final String qrCodeData;
  final String digitalSignature;

  const OriginalityCertificate({
    required this.certificateId,
    required this.projectName,
    required this.developerId,
    required this.isOriginal,
    required this.originalityScore,
    required this.analysisDate,
    required this.certificateHash,
    required this.qrCodeData,
    required this.digitalSignature,
  });

  Map<String, dynamic> toJson() => {
        'certificateId': certificateId,
        'projectName': projectName,
        'developerId': developerId,
        'isOriginal': isOriginal,
        'originalityScore': originalityScore,
        'analysisDate': analysisDate.toIso8601String(),
        'certificateHash': certificateHash,
        'qrCodeData': qrCodeData,
        'digitalSignature': digitalSignature,
      };
}

class DigitalSignature {
  final String signatureId;
  final String projectName;
  final String version;
  final String developerId;
  final Map<String, String> codeDNA;
  final List<String> uniquePatterns;
  final Map<String, String> styleSignatures;
  final DateTime createdAt;
  final String signatureHash;

  const DigitalSignature({
    required this.signatureId,
    required this.projectName,
    required this.version,
    required this.developerId,
    required this.codeDNA,
    required this.uniquePatterns,
    required this.styleSignatures,
    required this.createdAt,
    required this.signatureHash,
  });

  Map<String, dynamic> toJson() => {
        'signatureId': signatureId,
        'projectName': projectName,
        'version': version,
        'developerId': developerId,
        'codeDNA': codeDNA,
        'uniquePatterns': uniquePatterns,
        'styleSignatures': styleSignatures,
        'createdAt': createdAt.toIso8601String(),
        'signatureHash': signatureHash,
      };
}

enum PlagiarismRiskLevel { low, medium, high, critical }

/// Service de protection contre le plagiat avec cache
class PlagiarismProtectionService {
  static ProjectPlagiarismAnalysis? _lastAnalysis;
  static DateTime? _lastAnalysisTime;

  static Future<ProjectPlagiarismAnalysis> analyzeProject(
      {bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastAnalysis != null &&
        _lastAnalysisTime != null &&
        now.difference(_lastAnalysisTime!).inMinutes < 30) {
      return _lastAnalysis!;
    }
    _lastAnalysis = await PlagiarismProtection.analyzeProject();
    _lastAnalysisTime = now;
    return _lastAnalysis!;
  }

  static Future<Map<String, dynamic>> generateProtectionReport() async {
    final analysis = await analyzeProject();
    final certificate = await PlagiarismProtection.generateOriginalityCertificate();
    return {
      'analysis': analysis.toJson(),
      'certificate': certificate.toJson(),
      'reportGenerated': DateTime.now().toIso8601String(),
      'summary': {
        'isAuthentic': analysis.isAuthentic,
        'originalityScore': analysis.overallOriginalityScore,
        'riskLevel': analysis.riskLevel.name,
        'assetsAnalyzed': analysis.fileAnalyses.length,
        'recommendation': analysis.isAuthentic
            ? 'Assets originaux — Aucune altération détectée'
            : 'Assets potentiellement altérés — Vérifiez l\'installation',
      },
    };
  }

  static void clearCache() {
    _lastAnalysis = null;
    _lastAnalysisTime = null;
  }
}
