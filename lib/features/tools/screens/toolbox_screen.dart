// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
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

  List<ToolCatalogEntry> get _tools => toolCatalog;

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
    if (w > 900) return 3;
    if (w > 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase();
    
    final filteredTools = _tools.where((t) => 
      t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q)
    ).toList();
    
    final filteredLabs = labCatalog.where((l) => 
      l.label.toLowerCase().contains(q) || l.subtitle.toLowerCase().contains(q)
    ).toList();

    final favoriteTools =
        filteredTools.where((t) => _favoriteRoutes.contains(t.route)).toList();
        
    return TdcPageWrapper(
      child: ListView(
        children: [
          const Text(
            'Outils de Diagnostic & Support',
            style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Utilitaires essentiels pour vos interventions sur site ou à distance, 100% hors-ligne.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: TdcColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher un outil ou un simulateur...',
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
              border: const OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide.none),
              enabledBorder: const OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide(color: TdcColors.border)),
              focusedBorder: const OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide(color: TdcColors.accent)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Astuce: Clique sur l\'étoile d\'une carte pour l\'épingler ici en favoris.',
            style: TextStyle(color: TdcColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (_favoritesLoaded && favoriteTools.isNotEmpty) ...[
            const Text(
              'Favoris',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Accès rapide à tes outils les plus utilisés.',
              style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount(context),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 100,
              ),
              itemCount: favoriteTools.length,
              itemBuilder: (context, i) => _buildToolCard(context, i, favoriteTools[i], isFavorite: true),
            ),
            const SizedBox(height: 32),
          ],
          if (filteredTools.isNotEmpty) ...[
            const Text(
              'Tous les outils',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount(context),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 100,
              ),
              itemCount: filteredTools.length,
              itemBuilder: (context, i) => _buildToolCard(context, i, filteredTools[i], isFavorite: _favoriteRoutes.contains(filteredTools[i].route)),
            ),
            const SizedBox(height: 32),
          ],
          if (filteredLabs.isNotEmpty) ...[
            const Text(
              'Simulateurs Interactifs',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
          const Text(
            'Acces rapide aux simulations pour pratiquer et tester en temps reel.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount(context),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 100,
            ),
            itemCount: filteredLabs.length,
            itemBuilder: (context, i) => _buildSimCard(context, i, filteredLabs[i]),
          ),
          const SizedBox(height: 32),
          ] else if (filteredTools.isEmpty && filteredLabs.isEmpty) ...[
            TdcEmptyState(
              icon: Icons.search_off,
              title: 'Aucun résultat',
              subtitle: 'Aucun outil ou simulateur ne correspond à "$_searchQuery".',
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildSimCard(BuildContext context, int index, LabCatalogEntry lab) {
    return TdcFadeSlide(
      delay: Duration(milliseconds: 60 * (_tools.length + index)),
      child: TdcCard(
        onTap: () =>
            Navigator.pushNamed(context, '/lab', arguments: {'sim': lab.id}),
        padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'Simulation ${lab.label}',
                        style: const TextStyle(color: TdcColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: lab.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SIM',
                          style: TextStyle(color: lab.color, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lab.subtitle,
                    style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
      delay: Duration(milliseconds: 60 * index),
      child: TdcCard(
        onTap: () => Navigator.pushNamed(context, tool.route),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.1),
                borderRadius: TdcRadius.md,
              ),
              child: Icon(tool.icon, color: tool.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tool.title,
                    style: const TextStyle(color: TdcColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool.description,
                    style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              onPressed: () => _toggleFavorite(tool.route),
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavorite ? const Color(0xFFF59E0B) : TdcColors.textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
