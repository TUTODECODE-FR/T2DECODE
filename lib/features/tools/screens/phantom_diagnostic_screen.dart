// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// PhantomDiagnosticScreen — T2c Phantom (coming soon placeholder)
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';

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
      if (!mounted) return;
      context.read<ShellProvider>().updateShell(
            title: 'T2c Phantom',
            showBackButton: false,
            actions: const [],
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TdcColors.bg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: TdcColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: TdcColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.terminal,
                    size: 40,
                    color: TdcColors.accent,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'T2c Phantom',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TdcColors.accent,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: TdcColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: TdcColors.accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Text(
                    'Arrivée prochainement',
                    style: TextStyle(
                      color: TdcColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Synchronisation sécurisée Zero-Trust — bientôt disponible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
