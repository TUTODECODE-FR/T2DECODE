// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:tutodecode/features/education/student/services/student_exam_service.dart';

class StudentExamScreen extends StatefulWidget {
  const StudentExamScreen({super.key});

  @override
  State<StudentExamScreen> createState() => _StudentExamScreenState();
}

class _StudentExamScreenState extends State<StudentExamScreen> with WidgetsBindingObserver {
  final StudentExamService _examService = StudentExamService();
  final TextEditingController _teacherIpController = TextEditingController(text: '192.168.1.50');
  final TextEditingController _studentNameController = TextEditingController(text: 'Élève_BTS_SIO');
  final TextEditingController _scoreController = TextEditingController(text: '18');

  String _statusMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _examService.dispose();
    _teacherIpController.dispose();
    _studentNameController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _examService.registerFocusLost(
        _studentNameController.text,
        _teacherIpController.text,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MODULE ÉTUDIANT', style: TextStyle(color: TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
                  SizedBox(height: 4),
                  Text('T2DECODE Étudiant', style: TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (_examService.isKioskActive) {
                    _examService.stopKioskExam();
                  } else {
                    _examService.startKioskExam();
                  }
                  setState(() {});
                },
                icon: Icon(_examService.isKioskActive ? Icons.fullscreen_exit : Icons.fullscreen),
                label: Text(_examService.isKioskActive ? 'Quitter Mode Kiosk' : 'Activer Mode Kiosk Examen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _examService.isKioskActive ? TdcColors.danger : TdcColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_examService.focusLostCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TdcColors.danger.withValues(alpha: 0.15),
                borderRadius: TdcRadius.md,
                border: Border.all(color: TdcColors.danger),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: TdcColors.danger, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '⚠️ AVERTISSEMENT TRICHE : Perte de focus détectée (${_focusLostServiceCount()} fois - Alt+Tab/Changement d\'application). Cette alerte sera notifiée à votre Professeur.',
                      style: const TextStyle(color: TdcColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          TdcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Soumettre l\'évaluation au Professeur', style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: _teacherIpController,
                  style: const TextStyle(color: TdcColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Adresse IP du serveur Professeur (ex: 192.168.1.50)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _studentNameController,
                  style: const TextStyle(color: TdcColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Votre Nom & Prénom',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _scoreController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: TdcColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Note de l\'évaluation (sur 20)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() {
                              _isSubmitting = true;
                              _statusMessage = 'Chiffrement et envoi de la copie en cours...';
                            });

                            final res = await StudentExamService.submitEncryptedExamScore(
                              teacherIp: _teacherIpController.text.trim(),
                              studentName: _studentNameController.text.trim(),
                              courseTitle: 'Évaluation Cybersécurité BTS SIO',
                              score: int.tryParse(_scoreController.text.trim()) ?? 18,
                              total: 20,
                              focusLostCount: _examService.focusLostCount,
                            );

                            setState(() {
                              _isSubmitting = false;
                              if (res['success'] == true) {
                                _statusMessage = '✅ Copie transmise avec succès au Professeur !';
                              } else {
                                _statusMessage = '❌ ${res['error']}';
                              }
                            });
                          },
                    icon: const Icon(Icons.lock_clock),
                    label: Text(_isSubmitting ? 'Envoi chiffré en cours...' : 'Envoyer la copie chiffrée au Professeur'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                if (_statusMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.startsWith('✅') ? TdcColors.success : TdcColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _focusLostServiceCount() => _examService.focusLostCount;
}
