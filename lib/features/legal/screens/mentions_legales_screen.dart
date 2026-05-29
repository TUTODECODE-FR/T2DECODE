// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// mentions_legales_screen.dart — Fiche d'Identité & Mentions
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/responsive/responsive.dart';

class MentionsLegalesScreen extends StatefulWidget {
  const MentionsLegalesScreen({super.key});

  @override
  State<MentionsLegalesScreen> createState() => _MentionsLegalesScreenState();
}

class _MentionsLegalesScreenState extends State<MentionsLegalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Fiche d\'Identité',
        showBackButton: true,
        actions: [],
      );
    });
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.black, size: 15),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
        backgroundColor: TdcColors.accent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  // ── Data ─────────────────────────────────────────────────
  static const _identity = [
    _IdItem(Icons.business_outlined,      'Nom Légal',  'Assoc. TUTODECODE',    null),
    _IdItem(Icons.terminal,               'Logiciel',   'T2DECODE',             null),
    _IdItem(Icons.gavel,                  'Statut',     'Loi 1901',             null),
    _IdItem(Icons.fingerprint,            'SIREN',      '102 763 133',          '102 763 133'),
    _IdItem(Icons.calendar_month_outlined,'Création',   'Mars 2026',            null),
    _IdItem(Icons.location_on_outlined,   'Siège',      '13730 St-Victoret, FR','13730 St-Victoret, FR'),
    _IdItem(Icons.person_outline,         'Fondateur',  'Maxime Martin Civet',  null),
    _IdItem(Icons.alternate_email,        'Contact',    'contact@tutodecode.org','contact@tutodecode.org'),
  ];

  static const _privacy = [
    _PrivacyPill(Icons.wifi_off_outlined,      'Zéro Réseau',      'Aucune requête sortante'),
    _PrivacyPill(Icons.visibility_off_outlined,'Zéro Télémétrie',  'Aucun traceur, aucun log distant'),
    _PrivacyPill(Icons.lock_outline,           'Données Locales',  'Tout reste sur votre machine'),
    _PrivacyPill(Icons.code_outlined,          'Code Ouvert',      'Auditable sous GPL-3.0'),
  ];

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDesktop = TdcBreakpoints.isDesktop(context);
    final isTablet  = TdcBreakpoints.isTablet(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero header ─────────────────────────────────
          _HeroHeader(),
          // ── Body ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : isTablet ? 32 : 20,
              vertical: 40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Identity grid
                    _SectionLabel(label: 'Fiche d\'Identité', index: 0),
                    const SizedBox(height: 16),
                    _IdentityGrid(
                      items: _identity,
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                      onCopy: _copy,
                    ),
                    const SizedBox(height: 48),

                    // 2. Privacy by design
                    _SectionLabel(label: 'Confidentialité & Données', index: 1),
                    const SizedBox(height: 16),
                    _PrivacyRow(pills: _privacy, isDesktop: isDesktop || isTablet),
                    const SizedBox(height: 48),

                    // 3. Legal declaration
                    _SectionLabel(label: 'Déclaration Officielle', index: 2),
                    const SizedBox(height: 16),
                    _LegalDeclarationCard(onCopy: _copy),
                    const SizedBox(height: 48),

                    // 4. RGPD detail
                    _SectionLabel(label: 'Politique RGPD', index: 3),
                    const SizedBox(height: 16),
                    _RgpdCard(),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Data models
// ══════════════════════════════════════════════════════════════

class _IdItem {
  final IconData icon;
  final String label;
  final String value;
  final String? copyValue; // null = non copiable
  const _IdItem(this.icon, this.label, this.value, this.copyValue);
}

class _PrivacyPill {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PrivacyPill(this.icon, this.title, this.subtitle);
}

// ══════════════════════════════════════════════════════════════
// Hero Header
// ══════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: TdcColors.border)),
      ),
      child: Stack(
        children: [
          // Accent glow left
          Positioned(
            left: -60,
            top: -40,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TdcColors.accent.withValues(alpha: 0.025),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 56, 48, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge "Loi 1901"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TdcColors.accent.withValues(alpha: 0.1),
                    border: Border.all(
                        color: TdcColors.accent.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_outlined,
                          size: 12, color: TdcColors.accent),
                      SizedBox(width: 6),
                      Text(
                        'ASSOCIATION LOI 1901 · SIREN 102 763 133',
                        style: TextStyle(
                          color: TdcColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.08, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 20),
                // Main title
                const Text(
                  'Assoc.\nTUTODECODE',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 0.92,
                    letterSpacing: 0.4,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 80.ms)
                    .slideY(begin: 0.1, end: 0, duration: 480.ms, delay: 80.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 18),
                // Subtitle
                const Text(
                  'Éducation numérique souveraine · liberté technologique · privacy by design',
                  style: TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 14,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 160.ms),
                const SizedBox(height: 28),
                // Stats row
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: const [
                    _HeroChip(Icons.shield_outlined,  'Air-Gapped',      TdcColors.accent),
                    _HeroChip(Icons.memory_outlined,   'IA Locale',       TdcColors.info),
                    _HeroChip(Icons.wifi_off_outlined, 'Zéro Télémétrie', TdcColors.success),
                    _HeroChip(Icons.code_outlined,     'GPL-3.0',         TdcColors.textSecondary),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 240.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeroChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Section label
// ══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  final int index;
  const _SectionLabel({required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 18,
            color: TdcColors.accent),
        const SizedBox(width: 12),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: TdcColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
      ],
    )
        .animate(delay: Duration(milliseconds: 60 + index * 80))
        .fadeIn(duration: 380.ms)
        .slideX(begin: -0.05, end: 0, duration: 380.ms, curve: Curves.easeOutCubic);
  }
}

// ══════════════════════════════════════════════════════════════
// Identity grid
// ══════════════════════════════════════════════════════════════

class _IdentityGrid extends StatelessWidget {
  final List<_IdItem> items;
  final bool isDesktop;
  final bool isTablet;
  final void Function(String, String) onCopy;
  const _IdentityGrid({
    required this.items,
    required this.isDesktop,
    required this.isTablet,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final cols = isDesktop ? 4 : isTablet ? 2 : 1;
    final rows = <List<_IdItem>>[];
    for (var i = 0; i < items.length; i += cols) {
      rows.add(items.sublist(i, (i + cols).clamp(0, items.length)));
    }

    return Column(
      children: rows.asMap().entries.map((rowEntry) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: rowEntry.key < rows.length - 1 ? 1 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowEntry.value.asMap().entries.map((cellEntry) {
              final i = rowEntry.key * cols + cellEntry.key;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: cellEntry.key < rowEntry.value.length - 1 ? 1 : 0,
                  ),
                  child: _IdentityTile(
                    item: cellEntry.value,
                    onCopy: onCopy,
                    animDelay: Duration(milliseconds: 100 + i * 55),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _IdentityTile extends StatefulWidget {
  final _IdItem item;
  final void Function(String, String) onCopy;
  final Duration animDelay;
  const _IdentityTile({
    required this.item,
    required this.onCopy,
    required this.animDelay,
  });

  @override
  State<_IdentityTile> createState() => _IdentityTileState();
}

class _IdentityTileState extends State<_IdentityTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final copyable = widget.item.copyValue != null;
    return MouseRegion(
      cursor: copyable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: copyable
            ? () => widget.onCopy(
                widget.item.copyValue!,
                '${widget.item.label} copié')
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          decoration: BoxDecoration(
            color: _hovered && copyable
                ? TdcColors.surfaceHover
                : TdcColors.surfaceAlt,
            border: Border.all(
              color: _hovered && copyable
                  ? TdcColors.borderAccent
                  : TdcColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row : icon + label + copy icon
              Row(
                children: [
                  Icon(widget.item.icon,
                      size: 14, color: TdcColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.item.label.toUpperCase(),
                      style: const TextStyle(
                        color: TdcColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  if (copyable)
                    AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.35,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.copy_outlined,
                        size: 13,
                        color: _hovered
                            ? TdcColors.accent
                            : TdcColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Value
              Text(
                widget.item.value,
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        )
            .animate(delay: widget.animDelay)
            .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.06, end: 0, duration: 360.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Privacy pills row
// ══════════════════════════════════════════════════════════════

class _PrivacyRow extends StatelessWidget {
  final List<_PrivacyPill> pills;
  final bool isDesktop;
  const _PrivacyRow({required this.pills, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        children: pills.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: e.key < pills.length - 1 ? 12 : 0),
              child: _PrivacyCard(pill: e.value, delay: e.key * 70),
            ),
          );
        }).toList(),
      );
    }
    return Column(
      children: pills.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: e.key < pills.length - 1 ? 10 : 0),
          child: _PrivacyCard(pill: e.value, delay: e.key * 60),
        );
      }).toList(),
    );
  }
}

class _PrivacyCard extends StatefulWidget {
  final _PrivacyPill pill;
  final int delay;
  const _PrivacyCard({required this.pill, required this.delay});

  @override
  State<_PrivacyCard> createState() => _PrivacyCardState();
}

class _PrivacyCardState extends State<_PrivacyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hovered ? TdcColors.surfaceHover : TdcColors.surfaceAlt,
          border: Border.all(
              color: _hovered ? TdcColors.borderAccent : TdcColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TdcColors.accent.withValues(alpha: 0.1),
                border: Border.all(
                    color: TdcColors.accent.withValues(alpha: 0.2)),
              ),
              child: Icon(widget.pill.icon,
                  size: 16, color: TdcColors.accent),
            ),
            const SizedBox(height: 12),
            Text(
              widget.pill.title,
              style: const TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.pill.subtitle,
              style: const TextStyle(
                color: TdcColors.textMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 200 + widget.delay))
          .fadeIn(duration: 380.ms)
          .slideY(begin: 0.08, end: 0, duration: 360.ms, curve: Curves.easeOutCubic),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Legal declaration card
// ══════════════════════════════════════════════════════════════

class _LegalDeclarationCard extends StatelessWidget {
  final void Function(String, String) onCopy;
  const _LegalDeclarationCard({required this.onCopy});

  static const _joUrl =
      'https://www.journal-officiel.gouv.fr/pages/associations-detail-annonce/?q.id=id:202600110336';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: TdcColors.accent.withValues(alpha: 0.08),
                  border: Border.all(
                      color: TdcColors.accent.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.gavel,
                    size: 18, color: TdcColors.accent),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Déclaration en Préfecture',
                        style: TextStyle(
                          color: TdcColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
                    SizedBox(height: 2),
                    Text('Journal Officiel de la République Française',
                        style: TextStyle(
                            color: TdcColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              // Verified badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: TdcColors.success.withValues(alpha: 0.08),
                  border: Border.all(
                      color: TdcColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified,
                        size: 12, color: TdcColors.success),
                    SizedBox(width: 5),
                    Text('DÉCLARÉ',
                        style: TextStyle(
                          color: TdcColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Description
          const Text(
            'L\'Association TUTODECODE est déclarée en préfecture et enregistrée sous le SIREN 102 763 133. '
            'Sa création a fait l\'objet d\'une publication au Journal Officiel de la République Française (JOAFE).',
            style: TextStyle(
                color: TdcColors.textSecondary, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 20),
          // JO URL block
          const Text(
            'LIEN OFFICIEL (JOAFE)',
            style: TextStyle(
              color: TdcColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: TdcColors.bg,
              border: Border.all(color: TdcColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  color: TdcColors.accent,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SelectableText(
                    _joUrl,
                    style: const TextStyle(
                      color: TdcColors.accent,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onCopy(_joUrl, 'Lien JOAFE copié'),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(Icons.copy_outlined,
                          size: 15, color: TdcColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: 280.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.06, end: 0, duration: 380.ms, curve: Curves.easeOutCubic);
  }
}

// ══════════════════════════════════════════════════════════════
// RGPD card
// ══════════════════════════════════════════════════════════════

class _RgpdCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: TdcColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: TdcColors.info.withValues(alpha: 0.08),
                    border: Border.all(
                        color: TdcColors.info.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(Icons.security_outlined,
                      size: 18, color: TdcColors.info),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Privacy by Design — RGPD',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                      SizedBox(height: 2),
                      Text(
                          'Règlement Général sur la Protection des Données',
                          style: TextStyle(
                              color: TdcColors.textMuted,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'T2DECODE est conçu selon les principes du Privacy by Design. '
                  'L\'application fonctionne en mode "air-gapped" total — aucune connexion réseau n\'est requise pour l\'ensemble de ses fonctionnalités principales.',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'L\'association TUTODECODE ne dispose d\'aucun serveur de collecte de données et n\'héberge '
                  'aucun service cloud lié à cette application. Toutes vos progressions, notes, clés de chiffrement '
                  'et historiques restent exclusivement stockés sur votre appareil local.\n\n'
                  'Aucune télémétrie, aucun traceur, ni aucun système d\'analyse tiers n\'est embarqué. '
                  'Le code source est entièrement public et auditable sous licence GPL-3.0.',
                  style: TextStyle(
                      color: TdcColors.textSecondary,
                      fontSize: 13,
                      height: 1.7),
                ),
                const SizedBox(height: 24),
                // Highlight row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: TdcColors.bg,
                    border: Border(
                      left: BorderSide(
                          color: TdcColors.accent, width: 3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 15, color: TdcColors.accent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Droit d\'accès, rectification et suppression : toutes vos données '
                          'étant locales, vous en êtes le seul détenteur et gestionnaire.',
                          style: TextStyle(
                            color: TdcColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: 360.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.06, end: 0, duration: 380.ms, curve: Curves.easeOutCubic);
  }
}
