// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:tutodecode/features/courses/screens/tdc_studio_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TDCStudioApp());
}

class TDCStudioApp extends StatelessWidget {
  const TDCStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TDC Studio IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5EBDA),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF141414),
        ),
      ),
      home: const TDCStudioScreen(),
    );
  }
}
