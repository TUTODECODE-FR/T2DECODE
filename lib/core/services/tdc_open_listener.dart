// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/navigation/nav_keys.dart';
import 'package:tutodecode/core/services/tdc_file_open.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';

/// Imports `.tdc` files opened from Finder and shows the course.
///
/// No-op on Android and Linux: the method channel exists only in the macOS runner.
class TdcOpenListener extends StatefulWidget {
  const TdcOpenListener({
    super.key,
    required this.child,
    this.enabled,
    this.bridge,
    this.importer = const TdcFileImporter(),
  });

  final Widget child;

  /// Overrides [TdcFileImporter.handlesOpenEvents]. Tests pass true.
  final bool? enabled;

  final TdcOpenBridge? bridge;
  final TdcFileImporter importer;

  @override
  State<TdcOpenListener> createState() => _TdcOpenListenerState();
}

class _TdcOpenListenerState extends State<TdcOpenListener> {
  late final TdcOpenBridge _bridge = widget.bridge ?? TdcOpenBridge();
  var _started = false;

  bool get _active => widget.enabled ?? TdcFileImporter.handlesOpenEvents;

  @override
  void initState() {
    super.initState();
    if (!_active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) return;
      _started = true;
      unawaited(_bridge.start(onPaths: _openPaths));
    });
  }

  @override
  void dispose() {
    if (_started) {
      _bridge.stop();
    }
    super.dispose();
  }

  Future<void> _openPaths(List<String> paths) async {
    if (!mounted || paths.isEmpty) return;
    final courses = context.read<CoursesProvider>();
    await _waitUntilLoaded(courses);
    if (!mounted) return;

    for (final path in paths) {
      final result = await widget.importer.importPath(path);
      if (!mounted) return;
      final course = result.course;
      if (course == null || course.chapters.isEmpty) {
        final message = result.error ?? 'Impossible d\'ouvrir ce fichier .tdc.';
        final recognized = message.startsWith('Document TDC Studio');
        _snack(
          message,
          background: recognized ? TdcColors.success : TdcColors.danger,
        );
        continue;
      }
      await courses.reload();
      if (!mounted) return;
      courses.selectChapter(course.id, course.chapters.first.id);
      AppNavigator.pushNamed('/chapter');
      _snack('Cours "${course.title}" ouvert.');
    }
  }

  Future<void> _waitUntilLoaded(CoursesProvider courses) async {
    if (courses.loaded) return;
    final ready = Completer<void>();
    void listener() {
      if (courses.loaded && !ready.isCompleted) {
        ready.complete();
      }
    }

    courses.addListener(listener);
    try {
      listener();
      if (!courses.loaded) {
        await ready.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      }
    } finally {
      courses.removeListener(listener);
    }
  }

  void _snack(String message, {Color? background}) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
