// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class PhantomDiagnosticScreen extends StatefulWidget {
  const PhantomDiagnosticScreen({super.key});

  @override
  State<PhantomDiagnosticScreen> createState() =>
      _PhantomDiagnosticScreenState();
}

class _PhantomDiagnosticScreenState extends State<PhantomDiagnosticScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
            title: 'menu.phantom'.tr(),
            showBackButton: false,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TdcPageWrapper(
        maxWidth: 520,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TdcColors.surfaceAlt,
                borderRadius: TdcRadius.lg,
                border: Border.all(color: TdcColors.border),
              ),
              child: const Icon(Icons.terminal,
                  size: 48, color: TdcColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text(
              'menu.phantom'.tr(),
              style: const TextStyle(
                color: TdcColors.accent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: TdcColors.warningDim,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: TdcColors.warning.withValues(alpha: 0.3)),
              ),
              child: Text(
                'menu.coming_soon'.tr().toUpperCase(),
                style: const TextStyle(
                  color: TdcColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'menu.phantom_coming_soon'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
