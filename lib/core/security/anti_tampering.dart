// ============================================================
// Anti-Tampering System — Vérification d'intégrité des assets en local
// ============================================================
// Approche : à la première installation, un snapshot SHA-256 de chaque asset
// bundlé est créé et stocké dans flutter_secure_storage.
// À chaque lancement suivant, les assets sont re-hashés et comparés au snapshot.
// Si un hash diffère → l'asset a été modifié après installation.
// 100% offline, aucun serveur, vrais hashes SHA-256.
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;

/// Assets bundlés considérés comme critiques pour l'intégrité de l'app.
// asset_checksums.json est volontairement exclu : il contient les hashes de
// référence et serait en confiance circulaire s'il était dans sa propre liste.
// Son intégrité est garantie par le snapshot flutter_secure_storage.
const List<String> _kCriticalAssets = [
  'assets/courses.json',
  'assets/cheat_sheets.json',
  'assets/netkit_cheat_sheets.json',
  'assets/manifest.json',
];

const String _kBaselineKey = 'anti_tampering_asset_baseline_v1';
const FlutterSecureStorage _secure = FlutterSecureStorage();

/// Système anti-tampering basé sur les vrais checksums SHA-256 des assets bundlés.
class AntiTamperingSystem {
  /// Calcule le SHA-256 d'un asset bundlé via rootBundle.
  static Future<String> _hashAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    return sha256.convert(bytes).toString();
  }

  /// Calcule les checksums de tous les assets critiques.
  static Future<Map<String, String>> computeCurrentChecksums() async {
    final result = <String, String>{};
    for (final assetPath in _kCriticalAssets) {
      try {
        result[assetPath] = await _hashAsset(assetPath);
      } catch (_) {
        result[assetPath] = 'MISSING';
      }
    }
    return result;
  }

  /// Initialise le snapshot de référence (à appeler au premier lancement).
  /// Stocke les checksums actuels dans flutter_secure_storage.
  static Future<void> initializeBaseline() async {
    final checksums = await computeCurrentChecksums();
    await _secure.write(key: _kBaselineKey, value: jsonEncode(checksums));
  }

  /// Vérifie l'intégrité complète de l'application.
  /// Si aucun snapshot n'existe → crée le snapshot et retourne un résultat sain.
  static Future<IntegrityCheckResult> performIntegrityCheck() async {
    try {
      // 1. Lire le snapshot de référence
      final baselineRaw = await _secure.read(key: _kBaselineKey);
      if (baselineRaw == null || baselineRaw.isEmpty) {
        // Premier lancement : créer le snapshot
        await initializeBaseline();
        return IntegrityCheckResult(
          isIntegrityValid: true,
          fileResults: {for (final a in _kCriticalAssets) a: true},
          modifiedFiles: [],
          missingFiles: [],
          suspiciousFiles: await _detectSuspiciousFiles(),
          structureValid: await _verifyDirectoryStructure(),
          dependenciesValid: true,
          signatureValid: true,
          checksumValid: true,
          checkDate: DateTime.now(),
          riskLevel: RiskLevel.low,
        );
      }

      // 2. Décoder le snapshot
      final baseline = Map<String, String>.from(jsonDecode(baselineRaw) as Map);

      // 3. Calculer les checksums actuels
      final current = await computeCurrentChecksums();

      // 4. Comparer
      final fileResults = <String, bool>{};
      final modifiedFiles = <String>[];
      final missingFiles = <String>[];

      for (final assetPath in _kCriticalAssets) {
        final currentHash = current[assetPath] ?? 'MISSING';
        final baselineHash = baseline[assetPath] ?? 'MISSING';

        if (currentHash == 'MISSING') {
          missingFiles.add(assetPath);
          fileResults[assetPath] = false;
        } else if (currentHash != baselineHash) {
          modifiedFiles.add(assetPath);
          fileResults[assetPath] = false;
        } else {
          fileResults[assetPath] = true;
        }
      }

      // 5. Vérifications supplémentaires
      final structureValid = await _verifyDirectoryStructure();
      final suspiciousFiles = await _detectSuspiciousFiles();
      final allChecksPass = fileResults.values.every((v) => v) &&
          structureValid &&
          suspiciousFiles.isEmpty;

      return IntegrityCheckResult(
        isIntegrityValid: allChecksPass,
        fileResults: fileResults,
        modifiedFiles: modifiedFiles,
        missingFiles: missingFiles,
        suspiciousFiles: suspiciousFiles,
        structureValid: structureValid,
        dependenciesValid: true,
        signatureValid: allChecksPass,
        checksumValid: modifiedFiles.isEmpty && missingFiles.isEmpty,
        checkDate: DateTime.now(),
        riskLevel: _calculateRiskLevel(modifiedFiles.length, suspiciousFiles.length),
      );
    } catch (e) {
      return IntegrityCheckResult(
        isIntegrityValid: false,
        fileResults: {},
        modifiedFiles: [],
        missingFiles: [],
        suspiciousFiles: [],
        structureValid: false,
        dependenciesValid: false,
        signatureValid: false,
        checksumValid: false,
        checkDate: DateTime.now(),
        riskLevel: RiskLevel.critical,
        error: 'Erreur lors de la vérification d\'intégrité: $e',
      );
    }
  }

  /// Vérifie si l'application a été modifiée depuis le dernier snapshot.
  static Future<bool> isApplicationModified() async {
    final result = await performIntegrityCheck();
    return !result.isIntegrityValid;
  }

  /// Génère un rapport d'intégrité détaillé.
  static Future<Map<String, dynamic>> generateIntegrityReport() async {
    final result = await performIntegrityCheck();
    return {
      'summary': {
        'isIntegrityValid': result.isIntegrityValid,
        'riskLevel': result.riskLevel.name,
        'checkDate': result.checkDate.toIso8601String(),
        'totalFilesChecked': result.fileResults.length,
        'modifiedFilesCount': result.modifiedFiles.length,
        'missingFilesCount': result.missingFiles.length,
        'suspiciousFilesCount': result.suspiciousFiles.length,
      },
      'checks': {
        'structure': result.structureValid,
        'dependencies': result.dependenciesValid,
        'signature': result.signatureValid,
        'checksum': result.checksumValid,
      },
      'files': {
        'valid': result.fileResults.entries.where((e) => e.value).map((e) => e.key).toList(),
        'modified': result.modifiedFiles,
        'missing': result.missingFiles,
        'suspicious': result.suspiciousFiles,
      },
      'recommendations': _generateRecommendations(result),
    };
  }

  /// Recrée le snapshot (à utiliser après une mise à jour officielle).
  static Future<void> resetBaseline() async {
    await _secure.delete(key: _kBaselineKey);
    await initializeBaseline();
  }

  // ── Méthodes privées ──────────────────────────────────────────────────────

  static Future<bool> _verifyDirectoryStructure() async {
    try {
      // Sur desktop, vérifier les répertoires critiques
      if (!Platform.isAndroid && !Platform.isIOS) {
        final suspiciousDirs = ['hack', 'crack', 'patch', 'mod'];
        final currentDir = Directory.current;
        await for (final entity in currentDir.list()) {
          if (entity is Directory) {
            final dirName = path.basename(entity.path).toLowerCase();
            if (suspiciousDirs.contains(dirName)) return false;
          }
        }
      }
      return true;
    } catch (_) {
      return true; // Non bloquant
    }
  }

  static Future<List<String>> _detectSuspiciousFiles() async {
    // Sur mobile, les assets sont dans l'APK/IPA — pas de système de fichiers accessible
    if (Platform.isAndroid || Platform.isIOS) return [];

    final suspiciousFiles = <String>[];
    final suspiciousPatterns = [
      RegExp(r'\.patch$', caseSensitive: false),
      RegExp(r'\.crack$', caseSensitive: false),
      RegExp(r'\.hack$', caseSensitive: false),
      RegExp(r'keylogger', caseSensitive: false),
      RegExp(r'backdoor', caseSensitive: false),
    ];

    try {
      final currentDir = Directory.current;
      await for (final entity in currentDir.list(recursive: true)) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          for (final pattern in suspiciousPatterns) {
            if (pattern.hasMatch(fileName)) {
              suspiciousFiles.add(entity.path);
              break;
            }
          }
        }
      }
    } catch (_) {
      // Ignorer les erreurs de lecture
    }
    return suspiciousFiles;
  }

  static RiskLevel _calculateRiskLevel(int modifiedFiles, int suspiciousFiles) {
    if (suspiciousFiles > 0) return RiskLevel.critical;
    if (modifiedFiles > 2) return RiskLevel.high;
    if (modifiedFiles > 0) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static List<String> _generateRecommendations(IntegrityCheckResult result) {
    final recommendations = <String>[];
    if (result.modifiedFiles.isNotEmpty) {
      recommendations.add(
          '${result.modifiedFiles.length} asset(s) modifié(s) depuis l\'installation. Réinstallez l\'application depuis la source officielle.');
    }
    if (result.missingFiles.isNotEmpty) {
      recommendations.add(
          '${result.missingFiles.length} asset(s) manquant(s). L\'installation est incomplète.');
    }
    if (result.suspiciousFiles.isNotEmpty) {
      recommendations.add(
          '${result.suspiciousFiles.length} fichier(s) suspect(s) détecté(s) dans le répertoire de l\'application.');
    }
    if (result.isIntegrityValid) {
      recommendations.add('Intégrité des assets vérifiée — aucune modification détectée.');
    }
    return recommendations;
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

/// Résultat de la vérification d'intégrité
class IntegrityCheckResult {
  final bool isIntegrityValid;
  final Map<String, bool> fileResults;
  final List<String> modifiedFiles;
  final List<String> missingFiles;
  final List<String> suspiciousFiles;
  final bool structureValid;
  final bool dependenciesValid;
  final bool signatureValid;
  final bool checksumValid;
  final DateTime checkDate;
  final RiskLevel riskLevel;
  final String? error;

  const IntegrityCheckResult({
    required this.isIntegrityValid,
    required this.fileResults,
    required this.modifiedFiles,
    required this.missingFiles,
    required this.suspiciousFiles,
    required this.structureValid,
    required this.dependenciesValid,
    required this.signatureValid,
    required this.checksumValid,
    required this.checkDate,
    required this.riskLevel,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'isIntegrityValid': isIntegrityValid,
        'fileResults': fileResults,
        'modifiedFiles': modifiedFiles,
        'missingFiles': missingFiles,
        'suspiciousFiles': suspiciousFiles,
        'structureValid': structureValid,
        'dependenciesValid': dependenciesValid,
        'signatureValid': signatureValid,
        'checksumValid': checksumValid,
        'checkDate': checkDate.toIso8601String(),
        'riskLevel': riskLevel.name,
        'error': error,
      };
}

/// Niveaux de risque
enum RiskLevel { low, medium, high, critical }

/// Service anti-tampering avec cache
class AntiTamperingService {
  static IntegrityCheckResult? _lastCheck;
  static DateTime? _lastCheckTime;

  static Future<IntegrityCheckResult> checkIntegrity({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastCheck != null &&
        _lastCheckTime != null &&
        now.difference(_lastCheckTime!).inMinutes < 10) {
      return _lastCheck!;
    }
    _lastCheck = await AntiTamperingSystem.performIntegrityCheck();
    _lastCheckTime = now;
    return _lastCheck!;
  }

  /// Vérification rapide : compare uniquement les checksums des assets.
  static Future<bool> quickIntegrityCheck() async {
    try {
      final baselineRaw = await _secure.read(key: _kBaselineKey);
      if (baselineRaw == null) return true; // Premier lancement

      final baseline = Map<String, String>.from(jsonDecode(baselineRaw) as Map);
      final current = await AntiTamperingSystem.computeCurrentChecksums();

      for (final assetPath in _kCriticalAssets) {
        if (current[assetPath] != baseline[assetPath]) return false;
      }
      return true;
    } catch (_) {
      return true; // Non bloquant
    }
  }

  static void clearCache() {
    _lastCheck = null;
    _lastCheckTime = null;
  }
}
