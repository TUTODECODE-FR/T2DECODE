// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'features/education/providers/education_provider.dart';
import 'features/education/prof/screens/prof_dashboard_screen.dart';
import 'core/providers/shell_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      child: const T2DecodeProfApp(),
    ),
  );
}

class T2DecodeProfApp extends StatelessWidget {
  const T2DecodeProfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EducationProvider()),
        ChangeNotifierProvider(create: (_) => ShellProvider()),
      ],
      child: MaterialApp(
        title: 'T2DECODE PROF (Gestion de Classe & LMS)',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        darkTheme: buildAppTheme(),
        home: const Scaffold(
          backgroundColor: TdcColors.bg,
          body: SafeArea(
            child: ProfDashboardScreen(),
          ),
        ),
      ),
    );
  }
}
