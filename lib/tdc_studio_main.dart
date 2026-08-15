// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// TDC Studio Desktop IDE — Entry Point (macOS, Windows, Linux)
// ============================================================
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/courses/screens/tdc_studio_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TDCStudioDesktopApp());
}

/// Standalone TDC Studio IDE Application for Desktop platforms.
class TDCStudioDesktopApp extends StatelessWidget {
  const TDCStudioDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TDC Studio IDE — Environnement de Création .TDC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const TDCStudioScreen(),
    );
  }
}
