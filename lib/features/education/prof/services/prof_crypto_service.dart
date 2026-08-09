// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Service Cryptographique T2DECODE PROF
/// Gère le hachage des QCM, la génération de jetons de session uniques
/// et le déchiffrement des copies des étudiants (Anti-Triche).
class ProfCryptoService {
  late final String _sessionSalt;
  late final String _serverSecretKey;
  final Map<String, String> _issuedStudentTokens = {};

  ProfCryptoService() {
    _sessionSalt = _generateRandomString(32);
    _serverSecretKey = _generateRandomString(64);
  }

  String get sessionSalt => _sessionSalt;

  /// Génère une chaîne aléatoire sécurisée pour les sels et clés
  static String _generateRandomString(int length) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (i) => rand.nextInt(256));
    return base64Url.encode(values).substring(0, length);
  }

  /// Génère un jeton d'élève unique lié à son nom et son adresse MAC/IP
  String generateStudentToken(String studentName, String clientIp) {
    final raw =
        '$studentName|$clientIp|$_serverSecretKey|${DateTime.now().millisecondsSinceEpoch}';
    final token = sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
    _issuedStudentTokens['$studentName@$clientIp'] = token;
    return token;
  }

  /// Vérifie si le jeton d'un élève est valide
  bool verifyStudentToken(String studentName, String clientIp, String token) {
    final expected = _issuedStudentTokens['$studentName@$clientIp'];
    return expected != null && expected == token;
  }

  /// Hache les réponsés d'un QCM avec le sel dynamique du professeur
  /// afin d'empêcher les élèves de trouver les bonnes réponses dans les fichiers JSON
  String hashAnswer(int questionIndex, int correctIndex) {
    final raw = 'Q$questionIndex:A$correctIndex:$_sessionSalt';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Déchiffre la charge utile sécurisée envoyée par l'élève
  Map<String, dynamic> decryptStudentPayload(String encryptedBase64) {
    try {
      final decodedStr = utf8.decode(base64.decode(encryptedBase64));
      return jsonDecode(decodedStr) as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
          'Payload invalide ou corrompu (Tentative de falsification détectée)');
    }
  }
}
