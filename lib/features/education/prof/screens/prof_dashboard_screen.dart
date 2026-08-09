// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:tutodecode/features/education/providers/education_provider.dart';

class ProfDashboardScreen extends StatefulWidget {
  const ProfDashboardScreen({super.key});

  @override
  State<ProfDashboardScreen> createState() => _ProfDashboardScreenState();
}

class _ProfDashboardScreenState extends State<ProfDashboardScreen> {
  String _selectedCurriculum = 'BTS SIO (Bloc 1: Patrimoine Informatique & Sécurité)';
  final TextEditingController _customTopicController = TextEditingController(text: 'Sécurité des accès distants SSH & VPN');

  @override
  void dispose() {
    _customTopicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EducationProvider>(
      builder: (context, edu, _) {
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
                      Text('MODULE ENSEIGNANT', style: TextStyle(color: TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
                      SizedBox(height: 4),
                      Text('T2DECODE Prof (Tableau de bord LMS)', style: TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: edu.submissions.isEmpty
                            ? null
                            : () {
                                final csv = edu.exportSubmissionsCsv();
                                Clipboard.setData(ClipboardData(text: csv));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Export Pronote/ENT copié dans le presse-papier au format CSV !')),
                                );
                              },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Export Pronote / CSV'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => edu.toggleServer(port: edu.port),
                        icon: Icon(edu.isServerRunning ? Icons.stop : Icons.play_arrow),
                        label: Text(edu.isServerRunning ? 'Arrêter Serveur LAN' : 'Lancer Serveur LAN Class'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: edu.isServerRunning ? TdcColors.danger : TdcColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TdcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Générateur Pédagogique (Curriculum BTS SIO / BUT Info)', style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCurriculum,
                      dropdownColor: TdcColors.surfaceAlt,
                      style: const TextStyle(color: TdcColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Référentiel Académique Cible',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'BTS SIO (Bloc 1: Patrimoine Informatique & Sécurité)',
                        'BTS SIO (Bloc 2 SISR: Administration Réseau & Cyber)',
                        'BTS SIO (Bloc 2 SLAM: Développement Sécurisé)',
                        'BUT Informatique (Parcours Déploiement & Cyber)',
                        'Bac Pro NSI / Supérieur Cybersécurité',
                      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCurriculum = v ?? _selectedCurriculum),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customTopicController,
                      style: const TextStyle(color: TdcColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Sujet du TP / Examen à générer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: edu.isGenerating
                            ? null
                            : () {
                                edu.generateCourseWithAI(
                                  topic: '[$_selectedCurriculum] ${_customTopicController.text.trim()}',
                                  level: 'BTS SIO / BUT Info',
                                );
                              },
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(edu.isGenerating ? 'Génération IA du cours...' : 'Générer le cours & QCM basé sur le référentiel'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Tableau des copies et suivi Anti-Triche en direct', style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              if (edu.submissions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md),
                  child: Center(
                    child: Text('Aucune copie reçue. Lancez le serveur LAN et demandez aux étudiants de soumettre leurs TP.', style: TextStyle(color: TdcColors.textMuted)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: edu.submissions.length,
                  itemBuilder: (context, i) {
                    final s = edu.submissions[i];
                    final pct = (s.score / s.total * 100).toInt();
                    final passed = pct >= 50;
                    final hasCheatAlert = s.cheatAlert;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TdcColors.surface,
                        borderRadius: TdcRadius.md,
                        border: Border.all(color: hasCheatAlert ? TdcColors.danger : (passed ? TdcColors.success : TdcColors.warning)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: hasCheatAlert ? TdcColors.danger.withValues(alpha: 0.2) : TdcColors.success.withValues(alpha: 0.2),
                            child: Icon(hasCheatAlert ? Icons.warning_amber : Icons.check, color: hasCheatAlert ? TdcColors.danger : TdcColors.success, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.studentName, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold)),
                                Text('IP: ${s.studentIp} — ${s.courseTitle}', style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
                                if (hasCheatAlert) ...[
                                  const SizedBox(height: 4),
                                  Text('⚠️ ALERTE TRICHE : ${s.cheatReason}', style: const TextStyle(color: TdcColors.danger, fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ],
                            ),
                          ),
                          Text('${s.score} / ${s.total}', style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }
    );
  }
}
