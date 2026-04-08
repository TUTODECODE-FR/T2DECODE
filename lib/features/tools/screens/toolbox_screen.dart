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

  List<ToolCatalogEntry> get _tools => toolCatalog;

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
    final favoriteTools =
        _tools.where((t) => _favoriteRoutes.contains(t.route)).toList();
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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: _crossAxisCount(context),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.2,
              children: [
                for (var i = 0; i < favoriteTools.length; i++)
                  _buildToolCard(context, i, favoriteTools[i],
                      isFavorite: true),
              ],
            ),
            const SizedBox(height: 32),
          ],
          const Text(
            'Tous les outils',
            style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _crossAxisCount(context),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.2,
            children: [
              for (var i = 0; i < _tools.length; i++)
                _buildToolCard(context, i, _tools[i],
                    isFavorite: _favoriteRoutes.contains(_tools[i].route)),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Simulateurs Interactifs',
            style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Accès rapide aux simulateurs du Laboratoire pour pratiquer et tester en temps réel.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _crossAxisCount(context),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.2,
            children: [
              for (var i = 0; i < labCatalog.length; i++)
                _buildSimCard(context, i, labCatalog[i]),
            ],
          ),
          const SizedBox(height: 32),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: lab.color.withValues(alpha: 0.12),
                    borderRadius: TdcRadius.md,
                  ),
                  child: Icon(lab.icon, color: lab.color, size: 22),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: lab.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.science, color: lab.color, size: 10),
                      const SizedBox(width: 3),
                      Text('LAB',
                          style: TextStyle(
                              color: lab.color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 12),
            Text('Simulateur ${lab.label}',
                style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(lab.subtitle,
                style: const TextStyle(
                    color: TdcColors.textSecondary, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tool.color.withValues(alpha: 0.1),
                    borderRadius: TdcRadius.md,
                  ),
                  child: Icon(tool.icon, color: tool.color, size: 28),
                ),
                const Spacer(),
                const SizedBox(height: 16),
                Text(
                  tool.title,
                  style: const TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  tool.description,
                  style: const TextStyle(
                      color: TdcColors.textSecondary,
                      fontSize: 13,
                      height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip:
                    isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                onPressed: () => _toggleFavorite(tool.route),
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavorite
                      ? const Color(0xFFF59E0B)
                      : TdcColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
