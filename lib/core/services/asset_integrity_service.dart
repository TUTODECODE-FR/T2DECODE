import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart' show rootBundle;

class AssetIntegrityService {
  Future<List<String>> verify() async {
    final raw = await rootBundle.loadString('assets/asset_checksums.json');
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];

    final mismatched = <String>[];
    for (final e in decoded.entries) {
      final path = e.key.toString();
      final expected = e.value.toString();
      final bytes = (await rootBundle.load(path)).buffer.asUint8List();
      final hash = await Sha256().hash(bytes);
      final actual = hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      if (actual != expected) mismatched.add(path);
    }
    return mismatched;
  }
}

