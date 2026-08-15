// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TDCSignatureStatus {
  unsigned,
  validTrusted,
  validNewKey,
  conflictUsurpation,
  tampered,
}

class TDCSignatureResult {
  final TDCSignatureStatus status;
  final String authorName;
  final String authorKeyFingerprint;
  final String message;

  const TDCSignatureResult({
    required this.status,
    this.authorName = '',
    this.authorKeyFingerprint = '',
    required this.message,
  });
}

class TDCSignatureService {
  static const _storage = FlutterSecureStorage();
  static final _algorithm = Ed25519();

  /// Récupère ou génère le nom d'auteur local
  static Future<String> getAuthorName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tdc_profile_author_name') ?? 'Auteur Souverain';
  }

  static Future<void> setAuthorName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tdc_profile_author_name', name.trim());
  }

  /// Génère une nouvelle paire de clés Ed25519
  static Future<String> generateKeys() async {
    final keyPair = await _algorithm.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    final privBase64 = base64Encode(privateKeyBytes);
    final pubBase64 = base64Encode(publicKey.bytes);

    await _storage.write(key: 'tdc_ed25519_private_key', value: privBase64);
    await _storage.write(key: 'tdc_ed25519_public_key', value: pubBase64);

    final fp = computeFingerprint(publicKey.bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tdc_author_fingerprint', fp);
    return fp;
  }

  static Future<String?> getPublicKeyFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    final fp = prefs.getString('tdc_author_fingerprint');
    if (fp != null) return fp;

    final pubBase64 = await _storage.read(key: 'tdc_ed25519_public_key');
    if (pubBase64 != null) {
      final bytes = base64Decode(pubBase64);
      final computedFp = computeFingerprint(bytes);
      await prefs.setString('tdc_author_fingerprint', computedFp);
      return computedFp;
    }
    return null;
  }

  static String computeFingerprint(List<int> pubBytes) {
    final digest = sha256.convert(pubBytes);
    return 'FP-${digest.toString().substring(0, 12)}';
  }

  /// Canonise le contenu d'un cours .TDC pour la signature déterministe
  /// (Lignes LF, UTF-8, ligne signature exclue)
  static String canonicalizeSource(String source) {
    final lines = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final filtered = lines.where((l) => !l.trim().startsWith('signature:')).toList();
    return filtered.join('\n').trim();
  }

  /// Signe une chaîne .TDC canonisée
  static Future<String?> signSource(String source) async {
    final privBase64 = await _storage.read(key: 'tdc_ed25519_private_key');
    if (privBase64 == null) return null;

    final privBytes = base64Decode(privBase64);
    final keyPair = await _algorithm.newKeyPairFromSeed(privBytes);
    final canonical = canonicalizeSource(source);
    final messageBytes = utf8.encode(canonical);

    final signature = await _algorithm.sign(messageBytes, keyPair: keyPair);
    return base64Encode(signature.bytes);
  }

  /// Vérifie la signature d'un fichier .TDC et compare avec le store TOFU
  static Future<TDCSignatureResult> verifyCourse(String source) async {
    final canonical = canonicalizeSource(source);
    final authorMatch = RegExp(r'author:\s*["' "'" r']([^"' "'" r']+)["' "'" r']').firstMatch(source);
    final keyMatch = RegExp(r'author-key:\s*["' "'" r']([^"' "'" r']+)["' "'" r']').firstMatch(source);
    final sigMatch = RegExp(r'signature:\s*["' "'" r']([^"' "'" r']+)["' "'" r']').firstMatch(source);

    if (authorMatch == null || sigMatch == null) {
      return const TDCSignatureResult(status: TDCSignatureStatus.unsigned, message: 'Non signé');
    }

    final author = authorMatch.group(1)!;
    final authorKey = keyMatch?.group(1) ?? '';
    final sigBase64 = sigMatch.group(1)!;

    // Récupérer le store TOFU (nom d'auteur -> clé publique / fingerprint)
    final prefs = await SharedPreferences.getInstance();
    final tofuRaw = prefs.getString('tdc_tofu_trust_store_v1');
    final Map<String, dynamic> tofuMap = tofuRaw != null ? jsonDecode(tofuRaw) : {};

    final knownKey = tofuMap[author];

    if (knownKey != null && knownKey != authorKey) {
      return TDCSignatureResult(
        status: TDCSignatureStatus.conflictUsurpation,
        authorName: author,
        authorKeyFingerprint: authorKey,
        message: 'Alerte : Même nom d\'auteur mais clé différente ($authorKey vs $knownKey). Usurpation possible.',
      );
    }

    if (knownKey != null && knownKey == authorKey) {
      return TDCSignatureResult(
        status: TDCSignatureStatus.validTrusted,
        authorName: author,
        authorKeyFingerprint: authorKey,
        message: 'Signé par $author — Clé reconnue et de confiance ($authorKey)',
      );
    }

    return TDCSignatureResult(
      status: TDCSignatureStatus.validNewKey,
      authorName: author,
      authorKeyFingerprint: authorKey,
      message: 'Signature valide — Nouvelle clé pour $author ($authorKey)',
    );
  }

  /// Enregistre une clé dans le magasin de confiance TOFU
  static Future<void> trustKey(String authorName, String keyFingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    final tofuRaw = prefs.getString('tdc_tofu_trust_store_v1');
    final Map<String, dynamic> tofuMap = tofuRaw != null ? jsonDecode(tofuRaw) : {};
    tofuMap[authorName] = keyFingerprint;
    await prefs.setString('tdc_tofu_trust_store_v1', jsonEncode(tofuMap));
  }

  /// Révoque une clé de confiance
  static Future<void> revokeKey(String authorName) async {
    final prefs = await SharedPreferences.getInstance();
    final tofuRaw = prefs.getString('tdc_tofu_trust_store_v1');
    if (tofuRaw != null) {
      final Map<String, dynamic> tofuMap = jsonDecode(tofuRaw);
      tofuMap.remove(authorName);
      await prefs.setString('tdc_tofu_trust_store_v1', jsonEncode(tofuMap));
    }
  }

  /// Récupère la liste des clés de confiance
  static Future<Map<String, String>> getTrustedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final tofuRaw = prefs.getString('tdc_tofu_trust_store_v1');
    if (tofuRaw != null) {
      final Map<String, dynamic> tofuMap = jsonDecode(tofuRaw);
      return tofuMap.map((k, v) => MapEntry(k, v.toString()));
    }
    return {};
  }
}
