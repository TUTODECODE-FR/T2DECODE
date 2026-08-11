// ignore_for_file: unused_element, deprecated_member_use
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Linux Simulator - Bac à Sable Terminal VM Sécurisé
// ============================================================
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/widgets/interactive_terminal.dart';
import 'package:tutodecode/features/lab/services/virtual_shell.dart';

class LinuxSimulator extends StatefulWidget {
  const LinuxSimulator({super.key});

  @override
  State<LinuxSimulator> createState() => _LinuxSimulatorState();
}

class _LinuxSimulatorState extends State<LinuxSimulator> {
  Key _terminalKey = UniqueKey();

  void _resetVM() {
    setState(() {
      _terminalKey = UniqueKey();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: TdcColors.accent,
        content: Text('🔄 Machine Virtuelle réinitialisée à son état d\'origine !', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TdcColors.bg,
      child: Column(
        children: [
          // En-tête de la VM Sécurisée
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: TdcColors.surface,
              border: Border(bottom: BorderSide(color: TdcColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TdcColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.terminal, color: TdcColors.accent, size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TERMINAL VM LINUX (BAC À SABLE SÉCURISÉ)',
                      style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Système isolé — Entraînez-vous sans aucun risque pour votre PC',
                      style: TextStyle(color: TdcColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _resetVM,
                  icon: const Icon(Icons.refresh, size: 14, color: TdcColors.accent),
                  label: const Text('RÉINITIALISER LA VM', style: TextStyle(fontSize: 10, color: TdcColors.accent, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: TdcColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Presets d'exercices rapides
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF09090D),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('EXERCICES RÉFLEXES : ', style: TextStyle(color: TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  _buildExerciseChip('ls -lah /var/log', 'Inspecter les logs'),
                  _buildExerciseChip('whoami && pwd', 'Diagnostic identité'),
                  _buildExerciseChip('chmod 755 script.sh', 'Permissions binaire'),
                  _buildExerciseChip('grep -rn "ERROR" /var/log', 'Recherche de pannes'),
                  _buildExerciseChip('rm -rf /tmp/demo', 'Nettoyage récursif'),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: TdcColors.border),

          // Terminal Interactif Vrai Sandbox
          Expanded(
            child: InteractiveTerminal(
              key: _terminalKey,
              hostname: 't2decode-vm',
              username: 'student',
              initialPath: '~',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseChip(String command, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: const Icon(Icons.code, size: 12, color: TdcColors.accent),
        label: Text('$label ($command)', style: const TextStyle(fontSize: 10, color: TdcColors.textPrimary)),
        backgroundColor: TdcColors.surface,
        side: const BorderSide(color: TdcColors.border),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: TdcColors.surfaceAlt,
              content: Text('💡 Tapez "$command" dans le terminal ci-dessous pour tester !', style: const TextStyle(color: TdcColors.accent, fontFamily: 'monospace')),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
