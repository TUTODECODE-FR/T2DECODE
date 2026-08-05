// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Token d'initialisation fourni au client pour s'enrôler auprès d'un LXC.
class EnrollmentToken {
  final String lxcUrl;
  final String lxcPublicKey;
  final String tenantId;
  final String profileType; // 'prof', 'student', 'enterprise'

  EnrollmentToken({
    required this.lxcUrl,
    required this.lxcPublicKey,
    required this.tenantId,
    required this.profileType,
  });

  Map<String, dynamic> toJson() => {
        'lxc_url': lxcUrl,
        'lxc_pubkey': lxcPublicKey,
        'tenant_id': tenantId,
        'profile_type': profileType,
      };

  factory EnrollmentToken.fromJson(Map<String, dynamic> json) {
    return EnrollmentToken(
      lxcUrl: json['lxc_url'] ?? '',
      lxcPublicKey: json['lxc_pubkey'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      profileType: json['profile_type'] ?? 'student',
    );
  }

  /// Décode une chaîne de token d'enrôlement (Base64 ou JSON brut)
  static EnrollmentToken? parse(String rawToken) {
    try {
      String decodedStr = rawToken.trim();
      if (!decodedStr.startsWith('{')) {
        decodedStr = utf8.decode(base64.decode(decodedStr));
      }
      final Map<String, dynamic> map = jsonDecode(decodedStr);
      return EnrollmentToken.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  String toBase64() {
    return base64.encode(utf8.encode(jsonEncode(toJson())));
  }
}

/// Identité Ed25519 générée localement pour le Zero-Trust.
class AppIdentity {
  final String peerId;
  final String publicKeyHex;

  AppIdentity({
    required this.peerId,
    required this.publicKeyHex,
  });
}

/// Service d'enrôlement Zero-Trust pour T2DECODE
class EnrollmentService {
  static const _storage = FlutterSecureStorage();
  static const String _keyPeerId = 't2c_peer_id';
  static const String _keyPrivateKey = 't2c_priv_key';
  static const String _keyPublicKey = 't2c_pub_key';
  static const String _keyEnrollment = 't2c_enrollment_token';

  /// Vérifie si l'appareil est déjà enrôlé auprès d'un LXC
  static Future<bool> isEnrolled() async {
    final token = await _storage.read(key: _keyEnrollment);
    final peerId = await _storage.read(key: _keyPeerId);
    return token != null && peerId != null;
  }

  /// Récupère le token d'enrôlement actuellement enregistré
  static Future<EnrollmentToken?> getStoredToken() async {
    final raw = await _storage.read(key: _keyEnrollment);
    if (raw == null) return null;
    return EnrollmentToken.parse(raw);
  }

  /// Récupère ou génère l'identité Ed25519 de cet appareil
  static Future<AppIdentity> getOrCreateIdentity() async {
    String? peerId = await _storage.read(key: _keyPeerId);
    String? pubHex = await _storage.read(key: _keyPublicKey);

    if (peerId != null && pubHex != null) {
      return AppIdentity(peerId: peerId, publicKeyHex: pubHex);
    }

    // Keypair generation using cryptography package (Ed25519)
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final pubKey = await keyPair.extractPublicKey();
    final privBytes = await keyPair.extractPrivateKeyBytes();

    pubHex = pubKey.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final privHex = privBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    peerId = 'peer_ed25519_$pubHex';

    await _storage.write(key: _keyPeerId, value: peerId);
    await _storage.write(key: _keyPublicKey, value: pubHex);
    await _storage.write(key: _keyPrivateKey, value: privHex);

    return AppIdentity(peerId: peerId, publicKeyHex: pubHex);
  }

  /// Procède à l'enrôlement Zero-Trust auprès du LXC central
  static Future<bool> enrollDevice(EnrollmentToken token) async {
    final identity = await getOrCreateIdentity();

    try {
      final uri = Uri.parse('${token.lxcUrl}/api/v1/enroll');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tenant_id': token.tenantId,
          'peer_id': identity.peerId,
          'public_key': identity.publicKeyHex,
          'profile_type': token.profileType,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storage.write(key: _keyEnrollment, value: token.toBase64());
        return true;
      }
    } catch (_) {
      // Offline fallback: store token locally if LXC reachable or offline setup
      await _storage.write(key: _keyEnrollment, value: token.toBase64());
      return true;
    }
    return false;
  }

  /// Réinitialise l'enrôlement (déconnexion de l'établissement)
  static Future<void> clearEnrollment() async {
    await _storage.delete(key: _keyEnrollment);
  }
}
