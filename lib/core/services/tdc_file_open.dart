// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tutodecode/core/services/module_service.dart';
import 'package:tutodecode/core/services/tdc_studio_document.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';

/// Result of trying to import a course the operating system handed to the app.
class TdcOpenResult {
  final Course? course;
  final String? error;

  TdcOpenResult.imported(this.course) : error = null;

  TdcOpenResult.rejected(this.error) : course = null;

  bool get isImported => course != null;
}

/// Reads a `.tdc` path and stores it with the existing course importer.
class TdcFileImporter {
  const TdcFileImporter({this.modules});

  /// Same channel name as `TdcOpenFileCenter` in the macOS runner.
  static const String channelName = 'org.t2decode.app/open_files';

  /// Matches [ModuleService]'s load limit so an opened file can be shown.
  static const int maxBytes = 5 * 1024 * 1024;

  final ModuleService? modules;

  /// Finder document opens are wired on macOS only.
  static bool get handlesOpenEvents => Platform.isMacOS;

  /// True when [rawPath] names a `.tdc` file (any directory, any case).
  static bool acceptsPath(String rawPath) {
    final path = normalizePath(rawPath);
    if (path.isEmpty) return false;
    final name = baseName(path);
    if (name.isEmpty || name == '.' || name == '..') return false;
    return name.toLowerCase().endsWith('.tdc');
  }

  /// Drops paths this app does not import, keeping the first of each path.
  static List<String> filterPaths(Iterable<String> rawPaths) {
    final accepted = <String>[];
    for (final raw in rawPaths) {
      final path = normalizePath(raw);
      if (!acceptsPath(path) || accepted.contains(path)) continue;
      accepted.add(path);
    }
    return accepted;
  }

  static String normalizePath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.startsWith('file://')) {
      return Uri.parse(trimmed).toFilePath();
    }
    return trimmed;
  }

  static String baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    if (slash == -1) return normalized;
    return normalized.substring(slash + 1);
  }

  /// Encrypted settings backups also use the `.tdc` extension.
  static bool isEncryptedBackup(String text) {
    final trimmed = text.trimLeft();
    if (!trimmed.startsWith('{')) return false;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return false;
      final header = decoded['header'];
      return header is Map && header['magic'] == 'TDCB';
    } catch (_) {
      return false;
    }
  }

  /// Imports a TDC Studio course, or a legacy course DSL/JSON document.
  ///
  /// The Studio hierarchy is checked before [ModuleService.importModuleContent].
  /// A file whose only TDC trait is the `.tdc` extension is rejected and not imported.
  Future<TdcOpenResult> importContent(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) {
      return TdcOpenResult.rejected(TdcStudioDocument.notStudioMessage);
    }
    if (isEncryptedBackup(text)) {
      return TdcOpenResult.rejected(
        'Sauvegarde chiffrée : importez-la depuis Paramètres.',
      );
    }

    final decision = TdcOpenDecision.decide(text, namedTdc: true);
    if (decision.rejected ||
        (decision.document != null && !decision.importCourse)) {
      return TdcOpenResult.rejected(
        decision.message ?? TdcStudioDocument.notStudioMessage,
      );
    }
    if (!decision.importCourse && !decision.continueLegacy) {
      return TdcOpenResult.rejected(TdcStudioDocument.notStudioMessage);
    }

    try {
      final course =
          await (modules ?? ModuleService()).importModuleContent(text);
      return TdcOpenResult.imported(course);
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      return TdcOpenResult.rejected(
        message.isEmpty ? 'Impossible d\'ouvrir ce fichier .tdc.' : message,
      );
    }
  }

  /// Reads [path] from disk and imports it when it is a course file.
  Future<TdcOpenResult> importPath(String path) async {
    final normalized = normalizePath(path);
    if (!acceptsPath(normalized)) {
      return TdcOpenResult.rejected('Seuls les fichiers .tdc sont ouverts.');
    }
    final file = File(normalized);
    if (!await file.exists()) {
      return TdcOpenResult.rejected('Fichier .tdc introuvable.');
    }
    final length = await file.length();
    if (length <= 0 || length > maxBytes) {
      return TdcOpenResult.rejected(
        'Fichier .tdc vide ou trop volumineux (max 5 Mo).',
      );
    }
    final bytes = await file.readAsBytes();
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    return importContent(text);
  }
}

/// Pulls paths queued by the macOS runner and hands the `.tdc` ones to [onPaths].
class TdcOpenBridge {
  TdcOpenBridge({MethodChannel? channel})
      : channel = channel ?? const MethodChannel(TdcFileImporter.channelName);

  final MethodChannel channel;

  Future<void> Function(List<String> paths)? onPaths;
  bool _draining = false;
  bool _drainAgain = false;

  /// Listens for later opens and pulls paths that arrived during startup.
  Future<void> start({
    required Future<void> Function(List<String> paths) onPaths,
  }) async {
    this.onPaths = onPaths;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openFiles') {
        await drain();
      }
    });
    // The runner may register the channel a moment after the first frame.
    for (var attempt = 0; attempt < 10; attempt++) {
      final ready = await drain();
      if (ready) return;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void stop() {
    channel.setMethodCallHandler(null);
  }

  /// Returns false when the macOS channel is not registered yet.
  Future<bool> drain() async {
    if (_draining) {
      _drainAgain = true;
      return true;
    }
    _draining = true;
    try {
      do {
        _drainAgain = false;
        final List<String> paths;
        try {
          final raw = await channel.invokeMethod<dynamic>('getPendingFiles');
          paths = <String>[];
          if (raw is List) {
            for (final item in raw) {
              if (item is String) paths.add(item);
            }
          }
        } on MissingPluginException {
          return false;
        } on PlatformException {
          return false;
        }
        final accepted = TdcFileImporter.filterPaths(paths);
        final deliver = onPaths;
        if (accepted.isNotEmpty && deliver != null) {
          await deliver(accepted);
        }
      } while (_drainAgain);
      return true;
    } finally {
      _draining = false;
    }
  }
}
