// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as pkg_crypto;
import 'package:cryptography/cryptography.dart' as pkg_cryptography;

class CryptoEngine {
  // --- Symmetric: AES-GCM (real) ---

  static Future<AesGcmResult> aesGcmEncrypt(String plaintext, String passphrase) async {
    final algo = pkg_cryptography.AesGcm.with256bits();
    final key = await _deriveKey(passphrase);
    final secretKey = pkg_cryptography.SecretKey(key);
    final nonce = algo.newNonce();
    final secretBox = await algo.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    return AesGcmResult(
      ciphertext: base64.encode(secretBox.cipherText),
      nonce: base64.encode(secretBox.nonce),
      mac: base64.encode(secretBox.mac.bytes),
    );
  }

  static Future<String> aesGcmDecrypt(AesGcmResult encrypted, String passphrase) async {
    final algo = pkg_cryptography.AesGcm.with256bits();
    final key = await _deriveKey(passphrase);
    final secretKey = pkg_cryptography.SecretKey(key);
    final secretBox = pkg_cryptography.SecretBox(
      base64.decode(encrypted.ciphertext),
      nonce: base64.decode(encrypted.nonce),
      mac: pkg_cryptography.Mac(base64.decode(encrypted.mac)),
    );
    final decrypted = await algo.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decrypted);
  }

  // --- Symmetric: ChaCha20-Poly1305 ---

  static Future<AesGcmResult> chacha20Encrypt(String plaintext, String passphrase) async {
    final algo = pkg_cryptography.Chacha20.poly1305Aead();
    final key = await _deriveKey(passphrase);
    final secretKey = pkg_cryptography.SecretKey(key);
    final nonce = algo.newNonce();
    final secretBox = await algo.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    return AesGcmResult(
      ciphertext: base64.encode(secretBox.cipherText),
      nonce: base64.encode(secretBox.nonce),
      mac: base64.encode(secretBox.mac.bytes),
    );
  }

  static Future<String> chacha20Decrypt(AesGcmResult encrypted, String passphrase) async {
    final algo = pkg_cryptography.Chacha20.poly1305Aead();
    final key = await _deriveKey(passphrase);
    final secretKey = pkg_cryptography.SecretKey(key);
    final secretBox = pkg_cryptography.SecretBox(
      base64.decode(encrypted.ciphertext),
      nonce: base64.decode(encrypted.nonce),
      mac: pkg_cryptography.Mac(base64.decode(encrypted.mac)),
    );
    final decrypted = await algo.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decrypted);
  }

  // --- Classic ciphers (educational) ---

  static String caesarEncrypt(String text, int shift) {
    return String.fromCharCodes(text.codeUnits.map((c) {
      if (c >= 65 && c <= 90) return (c - 65 + shift) % 26 + 65;
      if (c >= 97 && c <= 122) return (c - 97 + shift) % 26 + 97;
      return c;
    }));
  }

  static String caesarDecrypt(String text, int shift) => caesarEncrypt(text, 26 - (shift % 26));

  static String vigenereEncrypt(String text, String key) {
    if (key.isEmpty) return text;
    final keyUpper = key.toUpperCase();
    final result = StringBuffer();
    int ki = 0;
    for (final c in text.codeUnits) {
      if (c >= 65 && c <= 90) {
        result.writeCharCode((c - 65 + keyUpper.codeUnitAt(ki % keyUpper.length) - 65) % 26 + 65);
        ki++;
      } else if (c >= 97 && c <= 122) {
        result.writeCharCode((c - 97 + keyUpper.codeUnitAt(ki % keyUpper.length) - 65) % 26 + 97);
        ki++;
      } else {
        result.writeCharCode(c);
      }
    }
    return result.toString();
  }

  static String vigenereDecrypt(String text, String key) {
    if (key.isEmpty) return text;
    final keyUpper = key.toUpperCase();
    final result = StringBuffer();
    int ki = 0;
    for (final c in text.codeUnits) {
      if (c >= 65 && c <= 90) {
        result.writeCharCode((c - 65 - (keyUpper.codeUnitAt(ki % keyUpper.length) - 65) + 26) % 26 + 65);
        ki++;
      } else if (c >= 97 && c <= 122) {
        result.writeCharCode((c - 97 - (keyUpper.codeUnitAt(ki % keyUpper.length) - 65) + 26) % 26 + 97);
        ki++;
      } else {
        result.writeCharCode(c);
      }
    }
    return result.toString();
  }

  static String xorEncrypt(String text, String key) {
    if (key.isEmpty) return text;
    final keyBytes = utf8.encode(key);
    final textBytes = utf8.encode(text);
    final result = Uint8List(textBytes.length);
    for (int i = 0; i < textBytes.length; i++) {
      result[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return base64.encode(result);
  }

  static String xorDecrypt(String cipherB64, String key) {
    if (key.isEmpty) return cipherB64;
    final keyBytes = utf8.encode(key);
    final cipherBytes = base64.decode(cipherB64);
    final result = Uint8List(cipherBytes.length);
    for (int i = 0; i < cipherBytes.length; i++) {
      result[i] = cipherBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return utf8.decode(result);
  }

  // --- Hashing ---

  static String hashSha256(String input) => pkg_crypto.sha256.convert(utf8.encode(input)).toString();
  static String hashSha512(String input) => pkg_crypto.sha512.convert(utf8.encode(input)).toString();
  static String hashMd5(String input) => pkg_crypto.md5.convert(utf8.encode(input)).toString(); // NOSONAR - Educational
  static String hashSha1(String input) => pkg_crypto.sha1.convert(utf8.encode(input)).toString(); // NOSONAR - Educational

  static Future<String> hashPbkdf2(String input, {String salt = 't2decode'}) async {
    final algo = pkg_cryptography.Pbkdf2(
      macAlgorithm: pkg_cryptography.Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = pkg_cryptography.SecretKey(utf8.encode(input));
    final derived = await algo.deriveKey(
      secretKey: secretKey,
      nonce: utf8.encode(salt),
    );
    final bytes = await derived.extractBytes();
    return base64.encode(bytes);
  }

  // --- HMAC ---

  static String hmacSha256(String message, String key) {
    final hmacAlgo = pkg_crypto.Hmac(pkg_crypto.sha256, utf8.encode(key));
    final digest = hmacAlgo.convert(utf8.encode(message));
    return digest.toString();
  }

  // --- Asymmetric: Ed25519 (sign/verify) ---

  static Future<Ed25519KeyPairData> generateEd25519KeyPair() async {
    final algo = pkg_cryptography.Ed25519();
    final keyPair = await algo.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    return Ed25519KeyPairData(
      privateKey: base64.encode(privateBytes),
      publicKey: base64.encode(publicKey.bytes),
    );
  }

  static Future<String> ed25519Sign(String message, String privateKeyB64) async {
    final algo = pkg_cryptography.Ed25519();
    final privateBytes = base64.decode(privateKeyB64);
    final keyPair = await algo.newKeyPairFromSeed(privateBytes);
    final signature = await algo.sign(utf8.encode(message), keyPair: keyPair);
    return base64.encode(signature.bytes);
  }

  static Future<bool> ed25519Verify(String message, String signatureB64, String publicKeyB64) async {
    final algo = pkg_cryptography.Ed25519();
    final publicKey = pkg_cryptography.SimplePublicKey(base64.decode(publicKeyB64), type: pkg_cryptography.KeyPairType.ed25519);
    final signature = pkg_cryptography.Signature(base64.decode(signatureB64), publicKey: publicKey);
    return algo.verify(utf8.encode(message), signature: signature);
  }

  // --- Key exchange: X25519 ---

  static Future<X25519KeyPairData> generateX25519KeyPair() async {
    final algo = pkg_cryptography.X25519();
    final keyPair = await algo.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    return X25519KeyPairData(
      privateKey: base64.encode(privateBytes),
      publicKey: base64.encode(publicKey.bytes),
    );
  }

  static Future<String> x25519SharedSecret(String myPrivateKeyB64, String theirPublicKeyB64) async {
    final algo = pkg_cryptography.X25519();
    final myPrivateBytes = base64.decode(myPrivateKeyB64);
    final keyPair = await algo.newKeyPairFromSeed(myPrivateBytes);
    final theirPublicKey = pkg_cryptography.SimplePublicKey(base64.decode(theirPublicKeyB64), type: pkg_cryptography.KeyPairType.x25519);
    final sharedSecret = await algo.sharedSecretKey(keyPair: keyPair, remotePublicKey: theirPublicKey);
    final bytes = await sharedSecret.extractBytes();
    return base64.encode(bytes);
  }

  // --- Key derivation helper ---

  static Future<List<int>> _deriveKey(String passphrase) async {
    final algo = pkg_cryptography.Pbkdf2(
      macAlgorithm: pkg_cryptography.Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = pkg_cryptography.SecretKey(utf8.encode(passphrase));
    final derived = await algo.deriveKey(
      secretKey: secretKey,
      nonce: utf8.encode('t2decode-aes-salt'),
    );
    return derived.extractBytes();
  }
}

class AesGcmResult {
  final String ciphertext;
  final String nonce;
  final String mac;

  const AesGcmResult({required this.ciphertext, required this.nonce, required this.mac});

  String toDisplay() =>
      'Ciphertext: $ciphertext\nNonce: $nonce\nMAC: $mac';
}

class Ed25519KeyPairData {
  final String privateKey;
  final String publicKey;

  const Ed25519KeyPairData({required this.privateKey, required this.publicKey});
}

class X25519KeyPairData {
  final String privateKey;
  final String publicKey;

  const X25519KeyPairData({required this.privateKey, required this.publicKey});
}
