// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Roadmap — 4 parcours d'apprentissage avec progression riche
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

// ── Modèle de parcours ─────────────────────────────────────────

class _Path {
  final String id;
  final String title;
  final String subtitle;
  final String targetAudience;
  final String duration;
  final IconData icon;
  final Color color;
  final List<String> courseIds;
  final List<String> skills;

  const _Path({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetAudience,
    required this.duration,
    required this.icon,
    required this.color,
    required this.courseIds,
    required this.skills,
  });
}

const _kPaths = [
  _Path(
    id: 'beginner',
    title: 'Débutant',
    subtitle: 'Cybersécurité & Réseaux',
    targetAudience:
        'Vous n\'avez aucune base. Vous voulez comprendre comment fonctionne Internet, Linux et la sécurité informatique en partant de zéro.',
    duration: '4 à 6 semaines',
    icon: Icons.school,
    color: Color(0xFF10B981),
    courseIds: [
      'networking-fundamentals',
      'linux-basics',
      'cybersecurity-basics'
    ],
    skills: [
      'OSI & TCP/IP',
      'Commandes Linux essentielles',
      'Menaces & bonnes pratiques',
      'Bases de la cryptographie'
    ],
  ),
  _Path(
    id: 'pentester',
    title: 'Red Team',
    subtitle: 'Pentest & Offensive Security',
    targetAudience:
        'Vous avez des bases en réseaux/Linux. Vous voulez apprendre à penser comme un attaquant pour mieux défendre.',
    duration: '6 à 10 semaines',
    icon: Icons.bug_report,
    color: Color(0xFFEF4444),
    courseIds: ['bash-scripting', 'python-basics', 'sql-basics'],
    skills: [
      'Scripting Bash & Python',
      'Reconnaissance & OSINT',
      'Injection SQL',
      'Exploitation basique'
    ],
  ),
  _Path(
    id: 'forensic',
    title: 'Blue Team',
    subtitle: 'Forensic & Défense',
    targetAudience:
        'Vous maîtrisez Linux et la sécurité de base. Vous voulez analyser des incidents, investiguer des compromissions et durcir des systèmes.',
    duration: '8 à 12 semaines',
    icon: Icons.search,
    color: Color(0xFF3B82F6),
    courseIds: ['cryptography-applied', 'regex-mastery', 'python-advanced'],
    skills: [
      'Cryptographie appliquée',
      'Analyse de logs & Regex',
      'Python avancé',
      'Réponse sur incident'
    ],
  ),
  _Path(
    id: 'sysadmin',
    title: 'Sysadmin & DevOps',
    subtitle: 'Infrastructure & Automatisation',
    targetAudience:
        'Vous gérez ou souhaitez gérer des serveurs. Vous voulez automatiser, conteneuriser et industrialiser votre infrastructure.',
    duration: '8 à 14 semaines',
    icon: Icons.dns,
    color: Color(0xFF8B5CF6),
    courseIds: [
      'bash-scripting',
      'networking-fundamentals',
      'cybersecurity-basics'
    ],
    skills: [
      'Administration Linux',
      'Docker & Conteneurs',
      'CI/CD & Automatisation',
      'Durcissement système'
    ],
  ),
];

// ── Screen ─────────────────────────────────────────────────────

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});
  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen>
    with SingleTickerProviderStateMixin {
  int _selected = 0;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _kPaths.length, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() => _selected = _tab.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
            title: 'Roadmap',
            showBackButton: true,
          );
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<CoursesProvider>(context);
    final path = _kPaths[_selected];
    return Column(
      children: [
        _buildTabs(),
        Expanded(child: _buildContent(path, prov)),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      color: TdcColors.surface,
      child: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: _kPaths[_selected].color,
        labelColor: _kPaths[_selected].color,
        unselectedLabelColor: TdcColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: _kPaths
            .map((p) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(p.icon, size: 15),
                      const SizedBox(width: 7),
                      Text(p.title),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildContent(_Path path, CoursesProvider prov) {
    final courses =
        prov.courses.where((c) => path.courseIds.contains(c.id)).toList();

    final done = courses.fold<int>(
      0,
      (s, c) =>
          s + (prov.courseCompletedCount(c.id) == c.chapters.length ? 1 : 0),
    );
    final total = courses.length;
    final percent = total == 0 ? 0.0 : done / total;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Hero card du parcours ─────────────────────────────
        _buildHeroCard(path, done, total, percent),
        const SizedBox(height: 28),

        // ── Compétences acquises ──────────────────────────────
        _buildSkillsSection(path),
        const SizedBox(height: 28),

        // ── Titre section modules ─────────────────────────────
        Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: path.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Modules du parcours (${courses.length})',
              style: const TextStyle(
                color: TdcColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Nœuds de progression ──────────────────────────────
        if (courses.isEmpty)
          TdcCard(
            child: Column(
              children: [
                Icon(path.icon,
                    color: path.color.withValues(alpha: 0.4), size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Les modules de ce parcours sont en cours de préparation.',
                  style:
                      TextStyle(color: TdcColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...courses.asMap().entries.map(
                (e) => _buildNode(
                    e.value, e.key, courses.length, prov, path.color),
              ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── Hero card ─────────────────────────────────────────────────

  Widget _buildHeroCard(_Path path, int done, int total, double percent) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: path.color.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            path.color.withValues(alpha: 0.06),
            TdcColors.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: path.color.withValues(alpha: 0.15),
                  borderRadius: TdcRadius.md,
                  border: Border.all(color: path.color.withValues(alpha: 0.3)),
                ),
                child: Icon(path.icon, color: path.color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path.title,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      path.subtitle,
                      style: TextStyle(
                        color: path.color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: path.color.withValues(alpha: 0.1),
                  borderRadius: TdcRadius.md,
                  border: Border.all(color: path.color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$done/$total',
                      style: TextStyle(
                        color: path.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'modules',
                      style: TextStyle(
                        color: path.color.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Audience
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              borderRadius: TdcRadius.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline,
                    color: TdcColors.textMuted, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    path.targetAudience,
                    style: const TextStyle(
                      color: TdcColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Meta: durée
          Row(
            children: [
              Icon(Icons.schedule, color: TdcColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                'Durée estimée : ${path.duration}',
                style:
                    const TextStyle(color: TdcColors.textMuted, fontSize: 12),
              ),
              const Spacer(),
              if (total > 0) ...[
                Text(
                  '${(percent * 100).round()}% complété',
                  style: TextStyle(
                    color: path.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: path.color.withValues(alpha: 0.12),
              color: path.color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.04, end: 0, duration: 350.ms);
  }

  // ── Skills section ────────────────────────────────────────────

  Widget _buildSkillsSection(_Path path) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: path.color, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Compétences visées',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: path.skills.asMap().entries.map((e) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: path.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: path.color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: path.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      e.value,
                      style: TextStyle(
                        color: path.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── Nœud de progression ────────────────────────────────────────

  Widget _buildNode(
      course, int i, int total, CoursesProvider prov, Color color) {
    final completed =
        prov.courseCompletedCount(course.id) == course.chapters.length;
    final inProgress = prov.courseCompletedCount(course.id) > 0 && !completed;
    final completedChapters = prov.courseCompletedCount(course.id);
    final totalChapters = (course.chapters as List).length;

    Color nodeColor;
    IconData nodeIcon;
    String nodeStatus;
    if (completed) {
      nodeColor = TdcColors.success;
      nodeIcon = Icons.check_circle_rounded;
      nodeStatus = 'Terminé';
    } else if (inProgress) {
      nodeColor = color;
      nodeIcon = Icons.play_circle_rounded;
      nodeStatus = '$completedChapters/$totalChapters chapitres';
    } else {
      nodeColor = TdcColors.border;
      nodeIcon = Icons.radio_button_unchecked;
      nodeStatus = '$totalChapters chapitres';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + i * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)), child: child),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline ──────────────────────────────────────
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? TdcColors.success.withValues(alpha: 0.15)
                      : inProgress
                          ? color.withValues(alpha: 0.12)
                          : TdcColors.surfaceAlt,
                  border: Border.all(
                    color: nodeColor,
                    width: inProgress ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: completed
                      ? const Icon(Icons.check,
                          size: 18, color: TdcColors.success)
                      : inProgress
                          ? Icon(Icons.play_arrow, size: 18, color: color)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: TdcColors.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                ),
              ),
              if (i < total - 1)
                Container(
                  width: 2,
                  height: 40,
                  color: i <
                          _firstIncompletedIndex(
                              total, prov, _kPaths[_selected])
                      ? TdcColors.success.withValues(alpha: 0.4)
                      : TdcColors.border,
                ),
            ],
          ),
          const SizedBox(width: 16),

          // ── Card du module ────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TdcColors.surface,
                  borderRadius: TdcRadius.md,
                  border: Border.all(
                    color: inProgress
                        ? color.withValues(alpha: 0.4)
                        : completed
                            ? TdcColors.success.withValues(alpha: 0.25)
                            : TdcColors.border,
                    width: inProgress ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: const TextStyle(
                              color: TdcColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: nodeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(nodeIcon, size: 12, color: nodeColor),
                              const SizedBox(width: 4),
                              Text(
                                nodeStatus,
                                style: TextStyle(
                                  color: nodeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.description,
                      style: const TextStyle(
                        color: TdcColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (inProgress) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: totalChapters > 0
                              ? completedChapters / totalChapters
                              : 0,
                          backgroundColor: color.withValues(alpha: 0.1),
                          color: color,
                          minHeight: 4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if ((course.chapters as List).isNotEmpty) {
                            prov.selectChapter(
                                course.id, course.chapters.first.id);
                            Navigator.pushNamed(context, '/chapter');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              completed ? TdcColors.surfaceAlt : color,
                          foregroundColor: completed
                              ? TdcColors.textSecondary
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: const RoundedRectangleBorder(
                              borderRadius: TdcRadius.sm),
                        ),
                        child: Text(
                          completed
                              ? 'Revoir le cours'
                              : inProgress
                                  ? 'Continuer →'
                                  : 'Commencer →',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _firstIncompletedIndex(int total, CoursesProvider prov, _Path path) {
    final courses =
        prov.courses.where((c) => path.courseIds.contains(c.id)).toList();
    for (int i = 0; i < courses.length; i++) {
      if (prov.courseCompletedCount(courses[i].id) <
          courses[i].chapters.length) {
        return i;
      }
    }
    return total;
  }
}
