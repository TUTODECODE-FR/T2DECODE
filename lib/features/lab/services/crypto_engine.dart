// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as pkg_crypto;
import 'package:cryptography/cryptography.dart' as pkg_cryptography;

class CryptoEngine {
  static const String _errPassphrase = 'Passphrase cannot be null or empty';
  static const String _errKey = 'Key cannot be null or empty';
  static const String _errMessage = 'Message cannot be null or empty';
  static const String _errText = 'Text cannot be null or empty';
  static const String _errPlaintext = 'Plaintext cannot be null or empty';
  static const String _errEncrypted = 'Encrypted data cannot be null or empty';

  // --- Symmetric: AES-GCM (real) ---

  static Future<AesGcmResult> aesGcmEncrypt(String plaintext, String passphrase) =>
      _symmetricEncrypt(pkg_cryptography.AesGcm.with256bits(), plaintext, passphrase);

  static Future<String> aesGcmDecrypt(AesGcmResult encrypted, String passphrase) =>
      _symmetricDecrypt(pkg_cryptography.AesGcm.with256bits(), encrypted, passphrase);

  // --- Symmetric: ChaCha20-Poly1305 ---

  static Future<AesGcmResult> chacha20Encrypt(String plaintext, String passphrase) =>
      _symmetricEncrypt(pkg_cryptography.Chacha20.poly1305Aead(), plaintext, passphrase);

  static Future<String> chacha20Decrypt(AesGcmResult encrypted, String passphrase) =>
      _symmetricDecrypt(pkg_cryptography.Chacha20.poly1305Aead(), encrypted, passphrase);

  static Future<AesGcmResult> _symmetricEncrypt(pkg_cryptography.Cipher algo, String plaintext, String passphrase) async {
    if (plaintext == null || plaintext.isEmpty) {
      throw ArgumentError(_errPlaintext);
    }
    if (passphrase == null || passphrase.isEmpty) {
      throw ArgumentError(_errPassphrase);
    }

    final salt = _generateRandomBytes(16);
    final key = await _deriveKey(passphrase, salt);
    final secretKey = pkg_cryptography.SecretKey(key);
    final nonce = algo.newNonce();
    final secretBox = await algo.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    final combinedCiphertext = Uint8List.fromList(salt + secretBox.cipherText);
    return AesGcmResult(
      ciphertext: base64.encode(combinedCiphertext),
      nonce: base64.encode(secretBox.nonce),
      mac: base64.encode(secretBox.mac.bytes),
    );
  }

  static Future<String> _symmetricDecrypt(pkg_cryptography.Cipher algo, AesGcmResult encrypted, String passphrase) async {
    if (encrypted == null || encrypted.ciphertext.isEmpty || encrypted.nonce.isEmpty || encrypted.mac.isEmpty) {
      throw ArgumentError(_errEncrypted);
    }
    if (passphrase == null || passphrase.isEmpty) {
      throw ArgumentError(_errPassphrase);
    }

    final decodedCiphertext = base64.decode(encrypted.ciphertext);
    if (decodedCiphertext.length < 16) {
      throw ArgumentError('Invalid ciphertext length');
    }
    final salt = decodedCiphertext.sublist(0, 16);
    final ciphertextBytes = decodedCiphertext.sublist(16);
    final key = await _deriveKey(passphrase, salt);
    final secretKey = pkg_cryptography.SecretKey(key);
    final secretBox = pkg_cryptography.SecretBox(
      ciphertextBytes,
      nonce: base64.decode(encrypted.nonce),
      mac: pkg_cryptography.Mac(base64.decode(encrypted.mac)),
    );
    final decrypted = await algo.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decrypted);
  }

  // --- Classic ciphers (educational) ---

  static String caesarEncrypt(String text, int shift) {
    if (text == null || text.isEmpty) {
      throw ArgumentError(_errText);
    }
    if (shift < 0) {
      throw ArgumentError('Shift must be a non-negative integer');
    }

    return String.fromCharCodes(text.codeUnits.map((c) {
      if (c >= 65 && c <= 90) return (c - 65 + shift) % 26 + 65;
      if (c >= 97 && c <= 122) return (c - 97 + shift) % 26 + 97;
      return c;
    }));
  }

  static String caesarDecrypt(String text, int shift) {
    if (text == null || text.isEmpty) {
      throw ArgumentError(_errText);
    }
    if (shift < 0) {
      throw ArgumentError('Shift must be a non-negative integer');
    }

    return caesarEncrypt(text, 26 - (shift % 26));
  }

  static String vigenereEncrypt(String text, String key) {
    if (text == null || text.isEmpty) {
      throw ArgumentError(_errText);
    }
    if (key == null) {
      throw ArgumentError('Key cannot be null');
    }
    if (key.isEmpty) {
      return text;
    }

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
    if (text == null || text.isEmpty) {
      throw ArgumentError(_errText);
    }
    if (key == null) {
      throw ArgumentError('Key cannot be null');
    }
    if (key.isEmpty) {
      return text;
    }

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
    if (text == null || text.isEmpty) {
      throw ArgumentError(_errText);
    }
    if (key == null || key.isEmpty) {
      throw ArgumentError(_errKey);
    }

    final keyBytes = utf8.encode(key);
    final textBytes = utf8.encode(text);
    final result = Uint8List(textBytes.length);
    for (int i = 0; i < textBytes.length; i++) {
      result[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return base64.encode(result);
  }

  static String xorDecrypt(String cipherB64, String key) {
    if (cipherB64 == null || cipherB64.isEmpty) {
      throw ArgumentError('Cipher cannot be null or empty');
    }
    if (key == null || key.isEmpty) {
      throw ArgumentError(_errKey);
    }

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
  static String hashMd5(String input) => _CustomMd5.hash(input);
  static String hashSha1(String input) => _CustomSha1.hash(input);

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
    if (message == null || message.isEmpty) {
      throw ArgumentError(_errMessage);
    }
    if (key == null || key.isEmpty) {
      throw ArgumentError(_errKey);
    }

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
    if (message == null || message.isEmpty) {
      throw ArgumentError(_errMessage);
    }
    if (privateKeyB64 == null || privateKeyB64.isEmpty) {
      throw ArgumentError('Private key cannot be null or empty');
    }

    final algo = pkg_cryptography.Ed25519();
    final privateBytes = base64.decode(privateKeyB64);
    final keyPair = await algo.newKeyPairFromSeed(privateBytes);
    final signature = await algo.sign(utf8.encode(message), keyPair: keyPair);
    return base64.encode(signature.bytes);
  }

  static Future<bool> ed25519Verify(String message, String signatureB64, String publicKeyB64) async {
    if (message == null || message.isEmpty) {
      throw ArgumentError(_errMessage);
    }
    if (signatureB64 == null || signatureB64.isEmpty) {
      throw ArgumentError('Signature cannot be null or empty');
    }
    if (publicKeyB64 == null || publicKeyB64.isEmpty) {
      throw ArgumentError('Public key cannot be null or empty');
    }

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
    if (myPrivateKeyB64 == null || myPrivateKeyB64.isEmpty) {
      throw ArgumentError('My private key cannot be null or empty');
    }
    if (theirPublicKeyB64 == null || theirPublicKeyB64.isEmpty) {
      throw ArgumentError('Their public key cannot be null or empty');
    }

    final algo = pkg_cryptography.X25519();
    final myPrivateBytes = base64.decode(myPrivateKeyB64);
    final keyPair = await algo.newKeyPairFromSeed(myPrivateBytes);
    final theirPublicKey = pkg_cryptography.SimplePublicKey(base64.decode(theirPublicKeyB64), type: pkg_cryptography.KeyPairType.x25519);
    final sharedSecret = await algo.sharedSecretKey(keyPair: keyPair, remotePublicKey: theirPublicKey);
    final bytes = await sharedSecret.extractBytes();
    return base64.encode(bytes);
  }

  static List<int> _generateRandomBytes(int length) {
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }

  // --- Key derivation helper ---

  static Future<List<int>> _deriveKey(String passphrase, List<int> salt) async {
    if (passphrase == null || passphrase.isEmpty) {
      throw ArgumentError(_errPassphrase);
    }

    final algo = pkg_cryptography.Pbkdf2(
      macAlgorithm: pkg_cryptography.Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = pkg_cryptography.SecretKey(utf8.encode(passphrase));
    final derived = await algo.deriveKey(
      secretKey: secretKey,
      nonce: salt,
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

// SECURITY NOTE: Educational implementation for simulation purposes only. DO NOT use for actual cryptographic operations.
class _CustomMd5 {
  static String hash(String input) {
    final bytes = Uint8List.fromList(utf8.encode(input));
    final hashBytes = _compute(bytes);
    return hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Uint8List _compute(Uint8List message) {
    final originalLengthInBits = message.length * 8;
    final paddingLength = (56 - (message.length + 1) % 64) % 64;
    final padded = Uint8List(message.length + 1 + paddingLength + 8);
    padded.setRange(0, message.length, message);
    padded[message.length] = 0x80;
    
    final lengthData = ByteData(8);
    lengthData.setUint64(0, originalLengthInBits, Endian.little);
    padded.setRange(padded.length - 8, padded.length, lengthData.buffer.asUint8List());

    int a0 = 0x67452301;
    int b0 = 0xefcdab89;
    int c0 = 0x98badcfe;
    int d0 = 0x10325476;

    final s = [
      7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
      5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
      4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
      6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
    ];

    final k = [
      0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
      0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
      0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
      0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
      0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
      0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
      0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
      0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
      0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
      0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
      0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
      0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
      0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
      0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
      0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
      0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
    ];

    final byteData = ByteData.sublistView(padded);
    for (int offset = 0; offset < padded.length; offset += 64) {
      final w = List<int>.generate(16, (i) => byteData.getUint32(offset + i * 4, Endian.little));

      int a = a0;
      int b = b0;
      int c = c0;
      int d = d0;

      for (int i = 0; i < 64; i++) {
        int f, g;
        if (i < 16) {
          f = (b & c) | (~b & d);
          g = i;
        } else if (i < 32) {
          f = (d & b) | (~d & c);
          g = (5 * i + 1) % 16;
        } else if (i < 48) {
          f = b ^ c ^ d;
          g = (3 * i + 5) % 16;
        } else {
          f = c ^ (b | ~d);
          g = (7 * i) % 16;
        }

        f = (f + a + k[i] + w[g]) & 0xFFFFFFFF;
        a = d;
        d = c;
        c = b;
        final rotate = s[i];
        b = (b + ((f << rotate) | (f >>> (32 - rotate)))) & 0xFFFFFFFF;
      }

      a0 = (a0 + a) & 0xFFFFFFFF;
      b0 = (b0 + b) & 0xFFFFFFFF;
      c0 = (c0 + c) & 0xFFFFFFFF;
      d0 = (d0 + d) & 0xFFFFFFFF;
    }

    final result = Uint8List(16);
    final outData = ByteData.sublistView(result);
    outData.setUint32(0, a0, Endian.little);
    outData.setUint32(4, b0, Endian.little);
    outData.setUint32(8, c0, Endian.little);
    outData.setUint32(12, d0, Endian.little);
    return result;
  }
}

// SECURITY NOTE: Educational implementation for simulation purposes only. DO NOT use for actual cryptographic operations.
class _CustomSha1 {
  static String hash(String input) {
    final bytes = Uint8List.fromList(utf8.encode(input));
    final hashBytes = _compute(bytes);
    return hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Uint8List _compute(Uint8List message) {
    final originalLengthInBits = message.length * 8;
    final paddingLength = (56 - (message.length + 1) % 64) % 64;
    final padded = Uint8List(message.length + 1 + paddingLength + 8);
    padded.setRange(0, message.length, message);
    padded[message.length] = 0x80;
    
    final lengthData = ByteData(8);
    lengthData.setUint64(0, originalLengthInBits, Endian.big);
    padded.setRange(padded.length - 8, padded.length, lengthData.buffer.asUint8List());

    int h0 = 0x67452301;
    int h1 = 0xEFCDAB89;
    int h2 = 0x98BADCFE;
    int h3 = 0x10325476;
    int h4 = 0xC3D2E1F0;

    final byteData = ByteData.sublistView(padded);
    final w = Uint32List(80);

    for (int offset = 0; offset < padded.length; offset += 64) {
      for (int i = 0; i < 16; i++) {
        w[i] = byteData.getUint32(offset + i * 4, Endian.big);
      }
      for (int i = 16; i < 80; i++) {
        final val = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
        w[i] = ((val << 1) | (val >>> 31)) & 0xFFFFFFFF;
      }

      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;

      for (int i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) {
          f = (b & c) | (~b & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp = (((a << 5) | (a >>> 27)) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = ((b << 30) | (b >>> 2)) & 0xFFFFFFFF;
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    final result = Uint8List(20);
    final outData = ByteData.sublistView(result);
    outData.setUint32(0, h0, Endian.big);
    outData.setUint32(4, h1, Endian.big);
    outData.setUint32(8, h2, Endian.big);
    outData.setUint32(12, h3, Endian.big);
    outData.setUint32(16, h4, Endian.big);
    return result;
  }
}
