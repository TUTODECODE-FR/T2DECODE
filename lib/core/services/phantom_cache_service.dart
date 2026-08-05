import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:tutodecode/core/security/phantom_trust_validator.dart';

class PhantomCacheService {
  final PhantomTrustValidator _trustValidator;

  PhantomCacheService(this._trustValidator);

  /// Retourne le chemin par défaut du cache de T2C-Phantom.
  String get defaultCachePath {
    if (Platform.isWindows) {
      return p.join(Platform.environment['APPDATA'] ?? '', 'T2C-Phantom', 'cache');
    } else if (Platform.isMacOS) {
      return p.join(Platform.environment['HOME'] ?? '', 'Library', 'Caches', 'T2C-Phantom');
    } else {
      return p.join(Platform.environment['HOME'] ?? '', '.cache', 't2c-phantom');
    }
  }

  /// Dérive la clé de déchiffrement depuis une passphrase (PBKDF2 / SHA-256)
  Future<SecretKey> _deriveKey(String passphrase) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    return await pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: utf8.encode('t2c-phantom-salt'),
    );
  }

  /// Lit et déchiffre un fichier depuis le cache T2C-Phantom.
  Future<List<int>?> readDecryptedFile(String relativePath, String passphrase) async {
    final cacheDir = Directory(defaultCachePath);
    if (!await cacheDir.exists()) return null;

    final file = File(p.join(cacheDir.path, relativePath));
    if (!await file.exists()) return null;

    final encryptedBytes = await file.readAsBytes();
    if (encryptedBytes.length < 28) return null; // 12 bytes nonce + 16 bytes mac + data

    final nonce = encryptedBytes.sublist(0, 12);
    final ciphertext = encryptedBytes.sublist(12, encryptedBytes.length - 16);
    final mac = encryptedBytes.sublist(encryptedBytes.length - 16);

    final key = await _deriveKey(passphrase);
    final aesGcm = AesGcm.with256bits();

    try {
      final decrypted = await aesGcm.decrypt(
        SecretBox(
          ciphertext,
          nonce: nonce,
          mac: Mac(mac),
        ),
        secretKey: key,
      );
      
      // Validation Zero-Trust
      if (!await _trustValidator.verifyIntegrity(relativePath, decrypted)) {
        throw Exception("Intégrité compromise pour le fichier $relativePath.");
      }
      return decrypted;
    } catch (e) {
      print("Erreur de déchiffrement Phantom: $e");
      return null;
    }
  }

  /// Décode un fichier en String UTF-8.
  Future<String?> readDecryptedString(String relativePath, String passphrase) async {
    final bytes = await readDecryptedFile(relativePath, passphrase);
    if (bytes == null) return null;
    return utf8.decode(bytes);
  }
}
