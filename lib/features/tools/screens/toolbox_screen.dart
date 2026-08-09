// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:tutodecode/features/lab/lab_catalog.dart';
import 'package:tutodecode/features/tools/tool_catalog.dart';

class ToolboxScreen extends StatefulWidget {
  const ToolboxScreen({super.key});

  @override
  State<ToolboxScreen> createState() => _ToolboxScreenState();
}

class _ToolboxScreenState extends State<ToolboxScreen> {
  final StorageService _storage = StorageService();
  final Set<String> _favoriteRoutes = <String>{};
  bool _favoritesLoaded = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Boîte à Outils',
        showBackButton: false,
        actions: [],
      );
    });
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final saved = await _storage.getToolFavorites();
    if (!mounted) return;
    setState(() {
      _favoriteRoutes
        ..clear()
        ..addAll(saved);
      _favoritesLoaded = true;
    });
  }

  Future<void> _toggleFavorite(String route) async {
    final next = Set<String>.from(_favoriteRoutes);
    if (!next.add(route)) {
      next.remove(route);
    }
    setState(() => _favoriteRoutes
      ..clear()
      ..addAll(next));
    await _storage.setToolFavorites(next.toList());
  }

  int _crossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 1100) return 3;
    if (w > 650) return 2;
    return 1;
  }

  List<ToolCatalogEntry> get _filteredTools {
    final q = _searchQuery.toLowerCase();
    return toolCatalog.where((t) {
      final matchQuery = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q);
      final matchCat =
          _selectedCategory == 'Tous' || t.category == _selectedCategory;
      return matchQuery && matchCat;
    }).toList();
  }

  List<LabCatalogEntry> get _filteredLabs {
    final q = _searchQuery.toLowerCase();
    return (_selectedCategory == 'Tous' || _selectedCategory == 'Simulateurs')
        ? labCatalog
            .where((l) =>
                q.isEmpty ||
                l.label.toLowerCase().contains(q) ||
                l.subtitle.toLowerCase().contains(q))
            .toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final filteredTools = _filteredTools;
    final filteredLabs = _filteredLabs;
    final favoriteTools =
        filteredTools.where((t) => _favoriteRoutes.contains(t.route)).toList();

    return TdcPageWrapper(
      child: ListView(
        children: [
          // ── Hero Header ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Boîte à Outils',
                        style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1.1)),
                    const SizedBox(height: 6),
                    const Text(
                      'Tous vos utilitaires IT, 100% hors-ligne. Aucune donnée ne quitte votre machine.',
                      style: TextStyle(
                          color: TdcColors.textSecondary,
                          fontSize: 14,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Stats pills
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatPill(
                    count: toolCatalog.length,
                    label: 'outils',
                    color: TdcColors.accent,
                  ),
                  const SizedBox(height: 6),
                  _StatPill(
                    count: labCatalog.length,
                    label: 'simulateurs',
                    color: TdcColors.info,
                  ),
                ],
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.05, end: 0, duration: 400.ms),
          const SizedBox(height: 20),

          // ── Search Bar ────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: TdcColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher un outil, une fonction...',
              hintStyle: const TextStyle(color: TdcColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: TdcColors.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: TdcColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: TdcColors.surfaceAlt,
              border: const OutlineInputBorder(
                  borderRadius: TdcRadius.md, borderSide: BorderSide.none),
              enabledBorder: const OutlineInputBorder(
                  borderRadius: TdcRadius.md,
                  borderSide: BorderSide(color: TdcColors.border)),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: TdcRadius.md,
                  borderSide: BorderSide(color: TdcColors.accent, width: 1.5)),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),

          // ── Category Filter Chips ─────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tous',
                  isSelected: _selectedCategory == 'Tous',
                  count: toolCatalog.length + labCatalog.length,
                  onTap: () => setState(() => _selectedCategory = 'Tous'),
                ),
                const SizedBox(width: 8),
                ...toolCategories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: cat,
                        isSelected: _selectedCategory == cat,
                        count:
                            toolCatalog.where((t) => t.category == cat).length,
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                    )),
                _FilterChip(
                  label: 'Simulateurs',
                  isSelected: _selectedCategory == 'Simulateurs',
                  count: labCatalog.length,
                  onTap: () =>
                      setState(() => _selectedCategory = 'Simulateurs'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 24),

          // ── Favoris ───────────────────────────────────────────
          if (_favoritesLoaded &&
              favoriteTools.isNotEmpty &&
              _searchQuery.isEmpty &&
              _selectedCategory == 'Tous') ...[
            _SectionHeader(
              icon: Icons.star_rounded,
              title: 'Favoris',
              subtitle: 'Vos ${favoriteTools.length} outil(s) épinglés',
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount(context),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 110,
              ),
              itemCount: favoriteTools.length,
              itemBuilder: (context, i) => _buildToolCard(
                  context, i, favoriteTools[i],
                  isFavorite: true),
            ),
            const SizedBox(height: 32),
          ],

          // ── Tools by category (or all filtered) ────────────────
          if (filteredTools.isNotEmpty) ...[
            if (_selectedCategory == 'Tous' && _searchQuery.isEmpty) ...[
              // Group by category
              ...toolCategories.expand((cat) {
                final catTools =
                    filteredTools.where((t) => t.category == cat).toList();
                if (catTools.isEmpty) return <Widget>[];
                return [
                  _SectionHeader(
                    icon: _categoryIcon(cat),
                    title: cat,
                    subtitle: '${catTools.length} outil(s)',
                    color: _categoryColor(cat),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _crossAxisCount(context),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 110,
                    ),
                    itemCount: catTools.length,
                    itemBuilder: (context, i) => _buildToolCard(
                        context, i, catTools[i],
                        isFavorite:
                            _favoriteRoutes.contains(catTools[i].route)),
                  ),
                  const SizedBox(height: 28),
                ];
              }),
            ] else ...[
              // Flat filtered list
              _SectionHeader(
                icon: Icons.filter_list,
                title: _selectedCategory == 'Tous'
                    ? 'Résultats de recherche'
                    : _selectedCategory,
                subtitle: '${filteredTools.length} outil(s) trouvé(s)',
                color: TdcColors.accent,
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount(context),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 110,
                ),
                itemCount: filteredTools.length,
                itemBuilder: (context, i) => _buildToolCard(
                    context, i, filteredTools[i],
                    isFavorite:
                        _favoriteRoutes.contains(filteredTools[i].route)),
              ),
              const SizedBox(height: 28),
            ],
          ],

          // ── Simulateurs Lab ───────────────────────────────────
          if (filteredLabs.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.science,
              title: 'Simulateurs Interactifs',
              subtitle: '${filteredLabs.length} simulation(s) disponible(s)',
              color: TdcColors.info,
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount(context),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 110,
              ),
              itemCount: filteredLabs.length,
              itemBuilder: (context, i) =>
                  _buildSimCard(context, i, filteredLabs[i]),
            ),
            const SizedBox(height: 28),
          ],

          // ── Vide ──────────────────────────────────────────────
          if (filteredTools.isEmpty && filteredLabs.isEmpty) ...[
            TdcEmptyState(
              icon: Icons.search_off,
              title: 'Aucun résultat',
              subtitle:
                  'Aucun outil ou simulateur ne correspond à "$_searchQuery".',
            ),
            const SizedBox(height: 32),
          ],

          // ── Footer ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              borderRadius: TdcRadius.md,
              border: Border.all(color: TdcColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.offline_bolt, color: TdcColors.textMuted, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '100% hors-ligne · Aucune donnée ne quitte votre appareil · Zéro tracking · Open Source GPL-3.0',
                    style: TextStyle(color: TdcColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSimCard(BuildContext context, int index, LabCatalogEntry lab) {
    return TdcFadeSlide(
      delay: Duration(milliseconds: 50 * index),
      child: _HoverCard(
        onTap: () =>
            Navigator.pushNamed(context, '/lab', arguments: {'sim': lab.id}),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lab.color.withValues(alpha: 0.12),
                borderRadius: TdcRadius.md,
              ),
              child: Icon(lab.icon, color: lab.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lab.label,
                          style: const TextStyle(
                              color: TdcColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: lab.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('SIM',
                            style: TextStyle(
                                color: lab.color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(lab.subtitle,
                      style: const TextStyle(
                          color: TdcColors.textSecondary,
                          fontSize: 12,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, int index, ToolCatalogEntry tool,
      {required bool isFavorite}) {
    return TdcFadeSlide(
      delay: Duration(milliseconds: 40 * index),
      child: _HoverCard(
        onTap: () => Navigator.pushNamed(context, tool.route),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.1),
                borderRadius: TdcRadius.md,
              ),
              child: Icon(tool.icon, color: tool.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tool.title,
                          style: const TextStyle(
                              color: TdcColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool.description,
                    style: const TextStyle(
                        color: TdcColors.textSecondary,
                        fontSize: 11,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip:
                  isFavorite ? 'Retirer des favoris' : 'Épingler en favori',
              onPressed: () => _toggleFavorite(tool.route),
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color:
                    isFavorite ? const Color(0xFFF59E0B) : TdcColors.textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case catReseau:
        return Icons.hub;
      case catSecurite:
        return Icons.shield;
      case catSysteme:
        return Icons.memory;
      case catDev:
        return Icons.code;
      case catReference:
        return Icons.menu_book;
      default:
        return Icons.folder;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case catReseau:
        return TdcColors.network;
      case catSecurite:
        return TdcColors.security;
      case catSysteme:
        return TdcColors.system;
      case catDev:
        return TdcColors.info;
      case catReference:
        return TdcColors.crypto;
      default:
        return TdcColors.accent;
    }
  }
}

// ── Section Header ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: TdcRadius.sm,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(subtitle,
                style:
                    const TextStyle(color: TdcColors.textMuted, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? TdcColors.accent.withValues(alpha: 0.15)
              : TdcColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? TdcColors.accent : TdcColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color:
                        isSelected ? TdcColors.accent : TdcColors.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? TdcColors.accent.withValues(alpha: 0.2)
                    : TdcColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color:
                          isSelected ? TdcColors.accent : TdcColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Pill ──────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatPill(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Hover Card ────────────────────────────────────────────────

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverCard({required this.child, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered ? TdcColors.surfaceElevated : TdcColors.surface,
            borderRadius: TdcRadius.md,
            border: Border.all(
              color: _hovered
                  ? TdcColors.accent.withValues(alpha: 0.35)
                  : TdcColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: TdcColors.accent.withValues(alpha: 0.06),
                      blurRadius: 12,
                      spreadRadius: 0,
                    )
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
