// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/lab/services/crypto_engine.dart';

void main() {
  group('AES-GCM', () {
    test('encrypt then decrypt returns original', () async {
      const plaintext = 'Hello, T2DECODE!';
      const passphrase = 'SuperSecretKey42';

      final encrypted = await CryptoEngine.aesGcmEncrypt(plaintext, passphrase);
      expect(encrypted.ciphertext, isNotEmpty);
      expect(encrypted.nonce, isNotEmpty);
      expect(encrypted.mac, isNotEmpty);
      expect(encrypted.ciphertext, isNot(equals(plaintext)));

      final decrypted = await CryptoEngine.aesGcmDecrypt(encrypted, passphrase);
      expect(decrypted, plaintext);
    });

    test('wrong passphrase fails to decrypt', () async {
      const plaintext = 'Secret message';
      final encrypted = await CryptoEngine.aesGcmEncrypt(plaintext, 'rightkey');
      expect(
        () => CryptoEngine.aesGcmDecrypt(encrypted, 'wrongkey'),
        throwsA(anything),
      );
    });

    test('different encryptions produce different nonces', () async {
      const plaintext = 'Same text';
      const passphrase = 'key';
      final r1 = await CryptoEngine.aesGcmEncrypt(plaintext, passphrase);
      final r2 = await CryptoEngine.aesGcmEncrypt(plaintext, passphrase);
      expect(r1.nonce, isNot(equals(r2.nonce)));
    });
  });

  group('ChaCha20-Poly1305', () {
    test('encrypt then decrypt returns original', () async {
      const plaintext = 'ChaCha20 test data';
      const passphrase = 'MyPass123';

      final encrypted = await CryptoEngine.chacha20Encrypt(plaintext, passphrase);
      final decrypted = await CryptoEngine.chacha20Decrypt(encrypted, passphrase);
      expect(decrypted, plaintext);
    });
  });

  group('Caesar cipher', () {
    test('encrypt and decrypt are inverse', () {
      const text = 'Hello World';
      const shift = 3;
      final encrypted = CryptoEngine.caesarEncrypt(text, shift);
      expect(encrypted, 'Khoor Zruog');
      expect(CryptoEngine.caesarDecrypt(encrypted, shift), text);
    });

    test('preserves non-alpha characters', () {
      expect(CryptoEngine.caesarEncrypt('123!', 5), '123!');
    });

    test('handles full rotation', () {
      expect(CryptoEngine.caesarEncrypt('Z', 1), 'A');
      expect(CryptoEngine.caesarEncrypt('z', 1), 'a');
    });
  });

  group('Vigenère cipher', () {
    test('encrypt and decrypt are inverse', () {
      const text = 'ATTACKATDAWN';
      const key = 'LEMON';
      final encrypted = CryptoEngine.vigenereEncrypt(text, key);
      expect(encrypted, 'LXFOPVEFRNHR');
      expect(CryptoEngine.vigenereDecrypt(encrypted, key), text);
    });

    test('handles mixed case', () {
      const text = 'Hello World';
      const key = 'KEY';
      final encrypted = CryptoEngine.vigenereEncrypt(text, key);
      final decrypted = CryptoEngine.vigenereDecrypt(encrypted, key);
      expect(decrypted, text);
    });

    test('empty key returns original', () {
      expect(CryptoEngine.vigenereEncrypt('test', ''), 'test');
    });
  });

  group('XOR cipher', () {
    test('encrypt and decrypt are inverse', () {
      const text = 'XOR test';
      const key = 'secret';
      final encrypted = CryptoEngine.xorEncrypt(text, key);
      expect(encrypted, isNot(equals(text)));
      expect(CryptoEngine.xorDecrypt(encrypted, key), text);
    });
  });

  group('Hashing', () {
    test('SHA-256 produces 64 hex chars', () {
      final hash = CryptoEngine.hashSha256('hello');
      expect(hash.length, 64);
      expect(hash, matches(RegExp(r'^[a-f0-9]{64}$')));
    });

    test('SHA-256 is deterministic', () {
      expect(
        CryptoEngine.hashSha256('test'),
        CryptoEngine.hashSha256('test'),
      );
    });

    test('SHA-256 known vector', () {
      expect(
        CryptoEngine.hashSha256(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('SHA-512 produces 128 hex chars', () {
      final hash = CryptoEngine.hashSha512('hello');
      expect(hash.length, 128);
    });

    test('MD5 produces 32 hex chars', () {
      final hash = CryptoEngine.hashMd5('hello');
      expect(hash.length, 32);
    });

    test('SHA-1 produces 40 hex chars', () {
      final hash = CryptoEngine.hashSha1('hello');
      expect(hash.length, 40);
    });

    test('PBKDF2 produces base64 output', () async {
      final hash = await CryptoEngine.hashPbkdf2('password');
      expect(hash, isNotEmpty);
      expect(hash, isNot(equals('password')));
    });

    test('PBKDF2 is deterministic with same salt', () async {
      final h1 = await CryptoEngine.hashPbkdf2('pass', salt: 'salt');
      final h2 = await CryptoEngine.hashPbkdf2('pass', salt: 'salt');
      expect(h1, h2);
    });
  });

  group('HMAC', () {
    test('HMAC-SHA256 is deterministic', () {
      final h1 = CryptoEngine.hmacSha256('message', 'key');
      final h2 = CryptoEngine.hmacSha256('message', 'key');
      expect(h1, h2);
    });

    test('different keys produce different HMACs', () {
      final h1 = CryptoEngine.hmacSha256('message', 'key1');
      final h2 = CryptoEngine.hmacSha256('message', 'key2');
      expect(h1, isNot(equals(h2)));
    });
  });

  group('Ed25519 signatures', () {
    test('sign and verify roundtrip', () async {
      final keyPair = await CryptoEngine.generateEd25519KeyPair();
      const message = 'Sign this message';

      final signature = await CryptoEngine.ed25519Sign(message, keyPair.privateKey);
      expect(signature, isNotEmpty);

      final valid = await CryptoEngine.ed25519Verify(message, signature, keyPair.publicKey);
      expect(valid, true);
    });

    test('wrong message fails verification', () async {
      final keyPair = await CryptoEngine.generateEd25519KeyPair();
      final signature = await CryptoEngine.ed25519Sign('original', keyPair.privateKey);
      final valid = await CryptoEngine.ed25519Verify('tampered', signature, keyPair.publicKey);
      expect(valid, false);
    });

    test('wrong key fails verification', () async {
      final kp1 = await CryptoEngine.generateEd25519KeyPair();
      final kp2 = await CryptoEngine.generateEd25519KeyPair();
      final signature = await CryptoEngine.ed25519Sign('message', kp1.privateKey);
      final valid = await CryptoEngine.ed25519Verify('message', signature, kp2.publicKey);
      expect(valid, false);
    });
  });

  group('X25519 key exchange', () {
    test('shared secret is symmetric', () async {
      final alice = await CryptoEngine.generateX25519KeyPair();
      final bob = await CryptoEngine.generateX25519KeyPair();

      final secretA = await CryptoEngine.x25519SharedSecret(alice.privateKey, bob.publicKey);
      final secretB = await CryptoEngine.x25519SharedSecret(bob.privateKey, alice.publicKey);

      expect(secretA, secretB);
    });
  });
}
