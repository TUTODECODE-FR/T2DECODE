import 'package:tutodecode/core/theme/app_theme.dart';
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Professional Lab Screen — Navigation latérale + simulateurs directs
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/features/lab/lab_catalog.dart';
import 'package:tutodecode/features/lab/widgets/lab_theory_panel.dart';
import 'package:tutodecode/features/lab/data/lab_theory_data.dart';

// ── Widget principal ─────────────────────────────────────────

class ProfessionalLabScreen extends StatefulWidget {
  const ProfessionalLabScreen({super.key});

  @override
  State<ProfessionalLabScreen> createState() => _ProfessionalLabScreenState();
}

class _ProfessionalLabScreenState extends State<ProfessionalLabScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Simulations Professionnelles',
        showBackButton: true,
        actions: [],
      );
      // Support deep-link depuis le menu Outils : arguments = {'sim': 'network'}
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

    return Container(
      color: TdcColors.surfaceElevated,
      child: isNarrow ? _buildMobileLayout() : _buildSidebarLayout(),
    );
  }

  // ── Layout large : sidebar gauche + contenu ───────────────

  Widget _buildSidebarLayout() {
    return Row(
      children: [
        // ── Sidebar ──────────────────────────────────────────
        Container(
          width: 220,
          decoration: BoxDecoration(
            color: TdcColors.textPrimary.withValues(alpha: 0.03),
            border: Border(
              right: BorderSide(color: TdcColors.textPrimary.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête sidebar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science,
                            color: TdcColors.infoDim, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'SIMULATION CORE',
                          style: TextStyle(
                            color: TdcColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${labCatalog.length} simulations',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: labCatalog.length,
                  itemBuilder: (context, i) => _buildSidebarItem(i),
                ),
              ),
              // Footer stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: TdcColors.textPrimary.withValues(alpha: 0.08)),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFooterStat('SERVEURS', '12 ACTIVE', TdcColors.success),
                    const SizedBox(height: 6),
                    _buildFooterStat('UPTIME', '99.9%', TdcColors.info),
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

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? lab.color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? lab.color.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: lab.color.withValues(alpha: isSelected ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(8),
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
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    lab.subtitle,
                    style: TextStyle(
                      color: TdcColors.textPrimary.withValues(alpha: 0.35),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  // ── Layout mobile : bottom sheet selector ────────────────

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Sélecteur horizontal défilant
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: labCatalog.length,
            itemBuilder: (context, i) {
              final lab = labCatalog[i];
              final isSelected = i == _selectedIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? lab.color.withValues(alpha: 0.2)
                        : TdcColors.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? lab.color.withValues(alpha: 0.6)
                          : TdcColors.textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(lab.icon,
                          color: isSelected ? lab.color : TdcColors.textSecondary,
                          size: 14),
                      const SizedBox(width: 6),
                      Text(
                        lab.label,
                        style: TextStyle(
                          color: isSelected ? TdcColors.textPrimary : TdcColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Divider(color: TdcColors.textPrimary.withValues(alpha: 0.1), height: 1),
        Expanded(child: _buildSimulatorPane()),
      ],
    );
  }

  // ── Panneau simulateur ────────────────────────────────────

  Widget _buildSimulatorPane() {
    final lab = labCatalog[_selectedIndex];
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
            // Barre de titre — uniquement pour les simulateurs sans header propre
            if (!lab.hasOwnHeader)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: TdcColors.textPrimary.withValues(alpha: 0.07)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: lab.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: lab.color.withValues(alpha: 0.3)),
                      ),
                      child: Icon(lab.icon, color: lab.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lab.label.toUpperCase(),
                          style: TextStyle(
                            color: lab.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          lab.subtitle,
                          style: TextStyle(
                            color: TdcColors.textPrimary.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedIndex + 1} / ${labCatalog.length}',
                      style: TextStyle(
                        color: TdcColors.textPrimary.withValues(alpha: 0.25),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            // Simulateur lui-même
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: lab.hasOwnHeader
                        // Les simulateurs avec header propre occupent toute la zone sans padding
                        ? lab.build()
                        // Les simulateurs théoriques ont un padding confortable
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
                           title: "Théorie : ${lab.label}", 
                           markdownContent: labTheoryData[lab.id] ?? "La théorie pour ce module est en cours de rédaction...", 
                           accentColor: lab.color,
                         );
                      },
                      backgroundColor: TdcColors.surfaceAlt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: lab.color.withValues(alpha: 0.3)),
                      ),
                      icon: Icon(Icons.menu_book, color: lab.color, size: 18),
                      label: Text("Théorie", style: TextStyle(color: lab.color, fontWeight: FontWeight.bold, fontSize: 13)),
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
        Text(
          '$label: ',
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
