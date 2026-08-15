// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Cryptographic Hardening Suite — Constant-Time Execution, Zeroization & Merkle Root.
class ConstantTimeSecurity {
  /// Compares two byte lists in constant time O(1) to prevent Side-Channel Timing Attacks.
  static bool compareBytes(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Compares two strings in constant time using UTF-8 byte representation.
  static bool compareStrings(String a, String b) {
    final bytesA = utf8.encode(a);
    final bytesB = utf8.encode(b);
    return compareBytes(bytesA, bytesB);
  }

  /// Securely overwrites a byte buffer in RAM with zeros (Memory Zeroization / Anti-Dump).
  static void zeroize(TypedData buffer) {
    final byteData = buffer.buffer.asUint8List(buffer.offsetInBytes, buffer.lengthInBytes);
    for (int i = 0; i < byteData.length; i++) {
      byteData[i] = 0;
    }
  }

  /// Computes a Cryptographic Merkle Root Hash for a list of child SHA-256 hashes.
  /// Guarantees that altering any single child hash breaks the root hash.
  static String computeMerkleRoot(List<String> hashes) {
    if (hashes.isEmpty) {
      return sha256.convert(utf8.encode('EMPTY_MERKLE_TREE')).toString();
    }
    if (hashes.length == 1) {
      return hashes.first;
    }

    List<String> currentLevel = List<String>.from(hashes);
    while (currentLevel.length > 1) {
      final nextLevel = <String>[];
      for (int i = 0; i < currentLevel.length; i += 2) {
        final left = currentLevel[i];
        final right = (i + 1 < currentLevel.length) ? currentLevel[i + 1] : left;
        final combined = utf8.encode('$left:$right');
        final parentHash = sha256.convert(combined).toString();
        nextLevel.add(parentHash);
      }
      currentLevel = nextLevel;
    }

    return currentLevel.first;
  }
}
