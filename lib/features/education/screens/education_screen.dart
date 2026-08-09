// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:tutodecode/features/education/providers/education_provider.dart';
import 'package:tutodecode/features/education/services/education_server_service.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _topicController =
      TextEditingController(text: 'Securite des reseaux Wi-Fi & WPA3');
  final TextEditingController _teacherIpController = TextEditingController();
  final TextEditingController _studentNameController =
      TextEditingController(text: 'Eleve_01');
  final TextEditingController _studentScoreController =
      TextEditingController(text: '8');
  final TextEditingController _studentTotalController =
      TextEditingController(text: '10');

  String _selectedLevel = 'Intermédiaire';
  String _studentStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
            title: 'T2DECODE Éducation (Prof & Élèves)',
            showBackButton: true,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    _teacherIpController.dispose();
    _studentNameController.dispose();
    _studentScoreController.dispose();
    _studentTotalController.dispose();
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
              _buildHeader(),
              const SizedBox(height: 20),
              _buildTabBar(),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAiGeneratorTab(edu),
                    _buildTeacherDashboardTab(edu),
                    _buildStudentModeTab(edu),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ESPACE ENSEIGNANTS & EXPÉRIMENTATION CLASSE',
          style: TextStyle(
            color: TdcColors.accent,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'T2DECODE Éducation',
          style: TextStyle(
            color: TdcColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Générez des cours et QCM avec Ghost AI local et collectez en direct les notes des élèves sur réseau local LAN (100% Hors-Ligne / Air-Gapped).',
          style: TextStyle(color: TdcColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: TdcColors.accent,
        labelColor: TdcColors.accent,
        unselectedLabelColor: TdcColors.textMuted,
        tabs: const [
          Tab(
              icon: Icon(Icons.smart_toy, size: 18),
              text: 'Ghost AI Prof (Générateur)'),
          Tab(
              icon: Icon(Icons.dashboard_customize, size: 18),
              text: 'Tableau de Bord Prof (Notes LAN)'),
          Tab(
              icon: Icon(Icons.school, size: 18),
              text: 'Mode Étudiant (Envoyer Note)'),
        ],
      ),
    );
  }

  // ─── ONGLET 1 : Générateur IA de cours & QCM ─────────────────────────────
  Widget _buildAiGeneratorTab(EducationProvider edu) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TdcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Générer un cours et un QCM personnalisés',
                  style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _topicController,
                  style: const TextStyle(color: TdcColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Sujet du cours à créer par Ghost AI',
                    hintText:
                        'ex: Cryptographie RSA, Configuration des VLANs, Sockets POSIX...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        dropdownColor: TdcColors.surfaceAlt,
                        style: const TextStyle(color: TdcColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Niveau cible',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Débutant', 'Intermédiaire', 'Avancé']
                            .map((l) =>
                                DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _selectedLevel = v ?? 'Intermédiaire'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: edu.selectedModel,
                        dropdownColor: TdcColors.surfaceAlt,
                        style: const TextStyle(color: TdcColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Modèle IA (Ollama)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'phi3',
                          'llama3.2',
                          'qwen3:4b',
                          'mistral',
                          'codellama'
                        ]
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) edu.setSelectedModel(v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: edu.isGenerating
                        ? null
                        : () {
                            if (_topicController.text.trim().isEmpty) return;
                            edu.generateCourseWithAI(
                              topic: _topicController.text.trim(),
                              level: _selectedLevel,
                            );
                          },
                    icon: edu.isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome),
                    label: Text(edu.isGenerating
                        ? 'Génération en cours avec Ghost AI...'
                        : 'Générer le cours & le QCM avec Ghost AI'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (edu.generationStatus.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    edu.generationStatus,
                    style: TextStyle(
                      color: edu.generationStatus.startsWith('Erreur')
                          ? TdcColors.danger
                          : TdcColors.info,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (edu.lastGeneratedCourse != null) ...[
            const Text(
              'Aperçu du cours généré pour la classe :',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),
            TdcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        edu.lastGeneratedCourse!['title']?.toString() ??
                            'Cours',
                        style: const TextStyle(
                            color: TdcColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      const Chip(
                        label: Text('Publié sur le LAN Prof',
                            style:
                                TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: TdcColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    edu.lastGeneratedCourse!['description']?.toString() ?? '',
                    style: const TextStyle(
                        color: TdcColors.textSecondary, fontSize: 13),
                  ),
                  const Divider(height: 24, color: TdcColors.border),
                  Text(
                    edu.lastGeneratedCourse!['content']?.toString() ?? '',
                    style: const TextStyle(
                        color: TdcColors.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (edu.lastGeneratedQuiz.isNotEmpty) ...[
            const Text(
              'QCM d\'évaluation associé :',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...edu.lastGeneratedQuiz.asMap().entries.map((e) {
              final q = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TdcColors.surface,
                  borderRadius: TdcRadius.md,
                  border: Border.all(color: TdcColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question ${e.key + 1}: ${q.question}',
                        style: const TextStyle(
                            color: TdcColors.textPrimary,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...q.choices.asMap().entries.map((c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '  ${c.key == q.correctIndex ? "✅" : "⚪"} ${c.value}',
                            style: TextStyle(
                              color: c.key == q.correctIndex
                                  ? TdcColors.success
                                  : TdcColors.textSecondary,
                            ),
                          ),
                        )),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── ONGLET 2 : Tableau de bord Prof (Serveur & Notes) ─────────────────────
  Widget _buildTeacherDashboardTab(EducationProvider edu) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TdcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Serveur de Classe LAN (Collecte des notes)',
                          style: TextStyle(
                              color: TdcColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          edu.isServerRunning
                              ? 'Le serveur écoute les soumissions d\'élèves sur le réseau local.'
                              : 'Serveur actuellement arrêté.',
                          style: const TextStyle(
                              color: TdcColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    Switch(
                      value: edu.isServerRunning,
                      activeColor: TdcColors.accent,
                      onChanged: (v) => edu.toggleServer(port: edu.port),
                    ),
                  ],
                ),
                if (edu.isServerRunning && edu.localIps.isNotEmpty) ...[
                  const Divider(height: 24, color: TdcColors.border),
                  const Text(
                    'Adresses IP à transmettre à vos élèves :',
                    style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: edu.localIps.map((ip) {
                      final url = 'http://$ip:${edu.port}';
                      return InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('URL copiée : $url')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: TdcColors.accent.withValues(alpha: 0.1),
                            borderRadius: TdcRadius.sm,
                            border: Border.all(color: TdcColors.accent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi,
                                  size: 14, color: TdcColors.accent),
                              const SizedBox(width: 6),
                              Text(url,
                                  style: const TextStyle(
                                      color: TdcColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy,
                                  size: 12, color: TdcColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notes des élèves (${edu.submissions.length})',
                style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
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
                              const SnackBar(
                                  content: Text(
                                      'Notes exportées au format CSV (copiées dans le presse-papier)')),
                            );
                          },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Exporter CSV'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: edu.submissions.isEmpty
                        ? null
                        : () => edu.clearSubmissions(),
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: TdcColors.danger),
                    label: const Text('Réinitialiser',
                        style: TextStyle(color: TdcColors.danger)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (edu.submissions.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: TdcColors.surface,
                borderRadius: TdcRadius.md,
              ),
              child: Center(
                child: Text(
                  'Aucune note soumise pour l\'instant. Lancez le serveur et demandez à vos élèves de vous envoyer leurs résultats !',
                  style: TextStyle(color: TdcColors.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
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
                final passed = pct >= 60;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TdcColors.surface,
                    borderRadius: TdcRadius.md,
                    border: Border.all(
                        color: passed
                            ? TdcColors.success.withValues(alpha: 0.3)
                            : TdcColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: passed
                            ? TdcColors.success.withValues(alpha: 0.2)
                            : TdcColors.danger.withValues(alpha: 0.2),
                        child: Text(
                          '$pct%',
                          style: TextStyle(
                            color:
                                passed ? TdcColors.success : TdcColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.studentName,
                                style: const TextStyle(
                                    color: TdcColors.textPrimary,
                                    fontWeight: FontWeight.bold)),
                            Text('IP: ${s.studentIp} — Cours: ${s.courseTitle}',
                                style: const TextStyle(
                                    color: TdcColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${s.score} / ${s.total}',
                        style: const TextStyle(
                            color: TdcColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── ONGLET 3 : Mode Étudiant (Soumettre ma note au Prof) ──────────────────
  Widget _buildStudentModeTab(EducationProvider edu) {
    if (_teacherIpController.text.isEmpty && edu.localIps.isNotEmpty) {
      _teacherIpController.text = edu.localIps.first;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TdcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transmettre mes résultats au Professeur',
                  style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Renseignez l\'adresse IP affichée sur l\'écran de votre Professeur pour lui envoyer votre note en direct sur le réseau local.',
                  style:
                      TextStyle(color: TdcColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _teacherIpController,
                  style: const TextStyle(color: TdcColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Adresse IP du Professeur',
                    hintText: 'ex: 192.168.1.50',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _studentNameController,
                  style: const TextStyle(color: TdcColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Votre Nom / Prénom (Élève)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _studentScoreController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: TdcColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Votre Note',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _studentTotalController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: TdcColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Note Maximale',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final teacherIp = _teacherIpController.text.trim();
                      final studentName = _studentNameController.text.trim();
                      final score =
                          int.tryParse(_studentScoreController.text.trim()) ??
                              0;
                      final total =
                          int.tryParse(_studentTotalController.text.trim()) ??
                              10;

                      if (teacherIp.isEmpty || studentName.isEmpty) return;

                      setState(() => _studentStatusMessage =
                          'Envoi au serveur du professeur...');

                      final res =
                          await EducationServerService.sendScoreToTeacher(
                        teacherIp: teacherIp,
                        studentName: studentName,
                        courseTitle: _topicController.text.trim(),
                        score: score,
                        total: total,
                      );

                      setState(() {
                        if (res['success'] == true) {
                          _studentStatusMessage =
                              '✅ Note transmise avec succès au Professeur !';
                        } else {
                          _studentStatusMessage = '❌ ${res['error']}';
                        }
                      });
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Envoyer mes résultats au Professeur'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_studentStatusMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _studentStatusMessage,
                    style: TextStyle(
                      color: _studentStatusMessage.startsWith('✅')
                          ? TdcColors.success
                          : TdcColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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
}
