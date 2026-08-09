// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Professional Lab Screen — Grille d'entrée premium + sidebar redesignée
// ============================================================
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/features/lab/lab_catalog.dart';
import 'package:tutodecode/features/lab/widgets/lab_theory_panel.dart';
import 'package:tutodecode/features/lab/data/lab_theory_data.dart';
import 'package:easy_localization/easy_localization.dart';

// ── Métadonnées de difficulté ──────────────────────────────────
const Map<String, _DifficultyInfo> _labDifficulty = {
  'network':    _DifficultyInfo('Intermédiaire', Color(0xFFF59E0B)),
  'security':   _DifficultyInfo('Expert',        Color(0xFFEF4444)),
  'ctf_prep':   _DifficultyInfo('Expert',        Color(0xFFEF4444)),
  'system':     _DifficultyInfo('Intermédiaire', Color(0xFFF59E0B)),
  'cloud':      _DifficultyInfo('Expert',        Color(0xFFEF4444)),
  'crypto':     _DifficultyInfo('Intermédiaire', Color(0xFFF59E0B)),
  'theory':     _DifficultyInfo('Débutant',      Color(0xFF22C55E)),
  'linux':      _DifficultyInfo('Intermédiaire', Color(0xFFF59E0B)),
  'algorithms': _DifficultyInfo('Expert',        Color(0xFFEF4444)),
};

class _DifficultyInfo {
  final String label;
  final Color color;
  const _DifficultyInfo(this.label, this.color);
}

// ── Widget principal ─────────────────────────────────────────

class ProfessionalLabScreen extends StatefulWidget {
  const ProfessionalLabScreen({super.key});

  @override
  State<ProfessionalLabScreen> createState() => _ProfessionalLabScreenState();
}

class _ProfessionalLabScreenState extends State<ProfessionalLabScreen> {
  int? _selectedIndex; // null = affiche la grille d'accueil

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'home.sections.simulations'.tr(),
        showBackButton: true,
        actions: [],
      );
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['sim'] is String) {
        final simId = args['sim'] as String;
        final idx = labCatalog.indexWhere((l) => l.id == simId);
        if (idx >= 0) setState(() => _selectedIndex = idx);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isNarrow = w < 700;

    // Grille d'accueil si aucun simulateur sélectionné
    if (_selectedIndex == null) {
      return _buildLandingGrid();
    }

    return Container(
      color: TdcColors.surfaceElevated,
      child: isNarrow ? _buildMobileLayout() : _buildSidebarLayout(),
    );
  }

  // ── Landing Grid ─────────────────────────────────────────────

  Widget _buildLandingGrid() {
    final w = MediaQuery.of(context).size.width;
    final crossCount = w > 1000 ? 3 : w > 650 ? 2 : 1;

    return Container(
      color: TdcColors.surfaceElevated,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TdcColors.info.withValues(alpha: 0.12),
                  borderRadius: TdcRadius.md,
                ),
                child: const Icon(Icons.science, color: TdcColors.info, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SIMULATION CORE',
                        style: TextStyle(
                            color: TdcColors.info,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    const Text('Lab Interactif T2DECODE',
                        style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    Text('${labCatalog.length} simulateurs hors-ligne · Pratiquez en conditions réelles',
                        style: const TextStyle(
                            color: TdcColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.05, end: 0, duration: 400.ms),
          const SizedBox(height: 28),

          // Stats row
          Row(
            children: [
              _LabStatCard(
                  icon: Icons.terminal,
                  label: 'Simulateurs',
                  value: '${labCatalog.length}',
                  color: TdcColors.info),
              const SizedBox(width: 12),
              const _LabStatCard(
                  icon: Icons.offline_bolt,
                  label: 'Mode',
                  value: 'Hors-ligne',
                  color: TdcColors.success),
              const SizedBox(width: 12),
              const _LabStatCard(
                  icon: Icons.lock,
                  label: 'Données',
                  value: 'Locales',
                  color: TdcColors.crypto),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),

          // Grid of simulators
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: 160,
            ),
            itemCount: labCatalog.length,
            itemBuilder: (context, i) {
              final lab = labCatalog[i];
              final diff = _labDifficulty[lab.id] ??
                  const _DifficultyInfo('Intermédiaire', Color(0xFFF59E0B));
              return _LabCard(
                lab: lab,
                difficulty: diff,
                index: i,
                onTap: () => setState(() => _selectedIndex = i),
              );
            },
          ),
          const SizedBox(height: 24),

          // Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              borderRadius: TdcRadius.md,
              border: Border.all(color: TdcColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: TdcColors.textMuted, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tous les simulateurs fonctionnent entièrement hors-ligne. Aucune donnée n\'est transmise à des serveurs externes.',
                    style: TextStyle(color: TdcColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Layout large : sidebar gauche + contenu ───────────────

  Widget _buildSidebarLayout() {
    return Row(
      children: [
        // ── Sidebar ──────────────────────────────────────────
        Container(
          width: 230,
          decoration: BoxDecoration(
            color: TdcColors.textPrimary.withValues(alpha: 0.03),
            border: Border(
              right: BorderSide(
                  color: TdcColors.textPrimary.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header sidebar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science, color: TdcColors.infoDim, size: 16),
                        const SizedBox(width: 8),
                        const Text('SIMULATION CORE',
                            style: TextStyle(
                              color: TdcColors.info,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            )),
                        const Spacer(),
                        // Back to grid button
                        GestureDetector(
                          onTap: () => setState(() => _selectedIndex = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: TdcColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.grid_view,
                                color: TdcColors.textMuted, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${labCatalog.length} simulateurs',
                      style: TextStyle(
                        color: TdcColors.textPrimary.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: TdcColors.border, height: 1),
              const SizedBox(height: 8),
              // Liste des labs
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: labCatalog.length,
                  itemBuilder: (context, i) => _buildSidebarItem(i),
                ),
              ),
              // Footer stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: TdcColors.textPrimary.withValues(alpha: 0.08)),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFooterStat('SIMULATEURS', '${labCatalog.length} ACTIFS', TdcColors.success),
                    const SizedBox(height: 6),
                    _buildFooterStat('MODE', 'HORS-LIGNE', TdcColors.info),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        // ── Contenu principal ─────────────────────────────────
        Expanded(
          child: _buildSimulatorPane(),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int i) {
    final lab = labCatalog[i];
    final isSelected = i == _selectedIndex;
    final diff = _labDifficulty[lab.id] ??
        const _DifficultyInfo('Intermédiaire', Color(0xFFF59E0B));

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? lab.color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? lab.color.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: lab.color.withValues(alpha: isSelected ? 0.25 : 0.1),
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: lab.color.withValues(alpha: 0.4))
                    : null,
              ),
              child: Icon(lab.icon, color: lab.color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lab.label,
                    style: TextStyle(
                      color: isSelected ? TdcColors.textPrimary : TdcColors.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: diff.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        diff.label,
                        style: TextStyle(
                          color: diff.color.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.chevron_right, color: lab.color, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Layout mobile ─────────────────────────────────────────

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Back to grid + horizontal scroll
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: TdcColors.border)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TdcColors.surfaceAlt,
                    borderRadius: TdcRadius.sm,
                    border: Border.all(color: TdcColors.border),
                  ),
                  child: const Icon(Icons.grid_view, color: TdcColors.textMuted, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: labCatalog.length,
                    itemBuilder: (context, i) {
                      final lab = labCatalog[i];
                      final isSelected = i == _selectedIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? lab.color.withValues(alpha: 0.2)
                                : TdcColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? lab.color.withValues(alpha: 0.6)
                                  : TdcColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(lab.icon,
                                  color: isSelected ? lab.color : TdcColors.textSecondary,
                                  size: 13),
                              const SizedBox(width: 5),
                              Text(lab.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? TdcColors.textPrimary
                                        : TdcColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildSimulatorPane()),
      ],
    );
  }

  // ── Panneau simulateur ────────────────────────────────────

  Widget _buildSimulatorPane() {
    final idx = _selectedIndex ?? 0;
    final lab = labCatalog[idx];
    final diff = _labDifficulty[lab.id] ??
        const _DifficultyInfo('Intermédiaire', Color(0xFFF59E0B));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(lab.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de titre redesignée
            if (!lab.hasOwnHeader)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: lab.color.withValues(alpha: 0.04),
                  border: Border(
                    bottom: BorderSide(
                        color: TdcColors.textPrimary.withValues(alpha: 0.07)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: lab.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: lab.color.withValues(alpha: 0.35)),
                      ),
                      child: Icon(lab.icon, color: lab.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lab.label.toUpperCase(),
                              style: TextStyle(
                                color: lab.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              )),
                          Text(lab.subtitle,
                              style: TextStyle(
                                color: TdcColors.textPrimary.withValues(alpha: 0.5),
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ),
                    // Difficulty badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: diff.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: diff.color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: diff.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: diff.color, blurRadius: 4)
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(diff.label,
                              style: TextStyle(
                                  color: diff.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${idx + 1} / ${labCatalog.length}',
                        style: TextStyle(
                          color: TdcColors.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        )),
                  ],
                ),
              ),
            // Simulateur
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: lab.hasOwnHeader
                        ? lab.build()
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: lab.build(),
                          ),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: FloatingActionButton.extended(
                      heroTag: 'theory_fab_${lab.id}',
                      elevation: 4,
                      onPressed: () {
                        LabTheoryPanel.show(
                          context,
                          title: 'Théorie : ${lab.label}',
                          markdownContent: labTheoryData[lab.id] ??
                              'La théorie pour ce module est en cours de rédaction...',
                          accentColor: lab.color,
                        );
                      },
                      backgroundColor: TdcColors.surfaceAlt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: lab.color.withValues(alpha: 0.3)),
                      ),
                      icon: Icon(Icons.menu_book, color: lab.color, size: 18),
                      label: Text('Théorie',
                          style: TextStyle(
                              color: lab.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color, blurRadius: 3)],
          ),
        ),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            )),
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            )),
      ],
    );
  }
}

// ── Lab Card (Grille d'accueil) ───────────────────────────────

class _LabCard extends StatefulWidget {
  final LabCatalogEntry lab;
  final _DifficultyInfo difficulty;
  final int index;
  final VoidCallback onTap;

  const _LabCard({
    required this.lab,
    required this.difficulty,
    required this.index,
    required this.onTap,
  });

  @override
  State<_LabCard> createState() => _LabCardState();
}

class _LabCardState extends State<_LabCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lab = widget.lab;
    final diff = widget.difficulty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + widget.index * 60),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _hovered
                  ? lab.color.withValues(alpha: 0.08)
                  : TdcColors.surface,
              borderRadius: TdcRadius.md,
              border: Border.all(
                color: _hovered
                    ? lab.color.withValues(alpha: 0.5)
                    : TdcColors.border,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: lab.color.withValues(alpha: 0.1),
                        blurRadius: 16,
                        spreadRadius: 0,
                      )
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: lab.color.withValues(alpha: 0.15),
                        borderRadius: TdcRadius.sm,
                      ),
                      child: Icon(lab.icon, color: lab.color, size: 22),
                    ),
                    const Spacer(),
                    // Difficulty badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: diff.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: diff.color.withValues(alpha: 0.25)),
                      ),
                      child: Text(diff.label,
                          style: TextStyle(
                              color: diff.color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(lab.label,
                    style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(lab.subtitle,
                    style: const TextStyle(
                        color: TdcColors.textSecondary,
                        fontSize: 12,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(
                  children: [
                    Text('Lancer la simulation',
                        style: TextStyle(
                            color: lab.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: lab.color, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────

class _LabStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LabStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: TdcRadius.md,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(label,
                    style: const TextStyle(
                        color: TdcColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
