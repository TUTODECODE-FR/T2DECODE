import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import './backup_service.dart';
import './storage_service.dart';

class SnapshotService {
  static const String _snapshotsFolder = 'TUTODECODE_Snapshots';

  final BackupService _backup = BackupService();
  final StorageService _storage = StorageService();

  Future<void> maybeCreateDailySnapshot({int keepDays = 14}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final snapshotsDir = Directory('${dir.path}/$_snapshotsFolder');
      if (!await snapshotsDir.exists()) await snapshotsDir.create(recursive: true);

      final today = DateTime.now().toUtc();
      final stamp = '${today.year.toString().padLeft(4, '0')}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      final path = '${snapshotsDir.path}/snapshot_$stamp.tdc';
      final file = File(path);
      if (await file.exists()) {
        await _rotateSnapshots(snapshotsDir, keepDays: keepDays);
        return;
      }

      final keyB64 = await _getOrCreateSnapshotKeyB64();
      final bytes = await _backup.exportEncrypted(password: keyB64);
      await file.writeAsBytes(bytes, flush: true);

      await _rotateSnapshots(snapshotsDir, keepDays: keepDays);
    } catch (e) {
      if (kDebugMode) debugPrint('Snapshot failed: $e');
    }
  }

  Future<String> _getOrCreateSnapshotKeyB64() async {
    final existing = await _storage.getSnapshotKeyB64();
    if (existing != null && existing.isNotEmpty) return existing;
    final bytes = _randomBytes(32);
    final b64 = base64Encode(bytes);
    await _storage.setSnapshotKeyB64(b64);
    return b64;
  }

  Future<void> _rotateSnapshots(Directory snapshotsDir, {required int keepDays}) async {
    final entries = snapshotsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.tdc'))
        .toList();

    final cutoff = DateTime.now().toUtc().subtract(Duration(days: keepDays));
    for (final f in entries) {
      try {
        final stat = f.statSync();
        if (stat.modified.toUtc().isBefore(cutoff)) {
          await f.delete();
        }
      } catch (_) {}
    }
  }

  Uint8List _randomBytes(int n) {
    final r = Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = r.nextInt(256);
    }
    return out;
  }
}
