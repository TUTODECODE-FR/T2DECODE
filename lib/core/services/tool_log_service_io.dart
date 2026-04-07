import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ToolLogService {
  static const String _folder = 'TUTODECODE_ToolLogs';
  static const String _fileName = 'tool_logs.jsonl';

  Future<File> _file() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$_fileName');
  }

  Future<void> log({
    required String toolId,
    required String action,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final f = await _file();
      final entry = {
        'ts': DateTime.now().toUtc().toIso8601String(),
        'toolId': toolId,
        'action': action,
        if (meta != null) 'meta': meta,
      };
      await f.writeAsString('${jsonEncode(entry)}\n', mode: FileMode.append, flush: true);
    } catch (e) {
      if (kDebugMode) debugPrint('Tool log failed: $e');
    }
  }

  Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}

