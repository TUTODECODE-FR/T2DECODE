import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class ToolboxScreen extends StatefulWidget {
  const ToolboxScreen({super.key});

  @override
  State<ToolboxScreen> createState() => _ToolboxScreenState();
}

class _ToolboxScreenState extends State<ToolboxScreen> {
  final StorageService _storage = StorageService();
  final Set<String> _favoriteRoutes = <String>{};
  bool _favoritesLoaded = false;

  static const List<_ToolDef> _tools = [
    _ToolDef(
        'Multi-Tools Sécurisés',
        'Diagnostic réseau/système/stockage avec sandbox et logs (sans commandes arbitraires).',
        Icons.security,
        Color(0xFF22C55E),
        '/tools/safe-tools'),
    _ToolDef(
        'Calculateur IP',
        'Calculez vos sous-réseaux, masques et plages d\'adresses rapidement.',
        Icons.settings_ethernet,
        TdcColors.accent,
        '/tools/ip-calc'),
    _ToolDef(
        'Guides de Survie',
        'Fiches de secours pour résoudre les pannes critiques (Windows, Mac, Linux).',
        Icons.medication,
        Color(0xFFEF4444),
        '/tools/survival'),
    _ToolDef(
        'Glossaire Tech',
        'Définitions simples et claires pour comprendre tout le jargon informatique.',
        Icons.menu_book,
        Color(0xFF8B5CF6),
        '/tools/glossary'),
    _ToolDef(
        'Scripts Utiles',
        'Bibliothèque de scripts Batch, PowerShell et Bash pour automatiser vos tâches.',
        Icons.terminal,
        Color(0xFF10B981),
        '/tools/scripts'),
    _ToolDef(
        'Référence Matérielle',
        'Codes de bips BIOS, liste des ports communs et connectique.',
        Icons.memory,
        Color(0xFFF59E0B),
        '/tools/hardware'),
    _ToolDef(
        'Générateur de MDP',
        'Créez des mots de passe ultra-sécurisés et personnalisés en un clic.',
        Icons.password,
        Color(0xFF6366F1),
        '/tools/password-gen'),
    _ToolDef(
        'Convertisseur de Données',
        'Convertissez vos unités de stockage (Octets, Mo, Go) sans erreur.',
        Icons.analytics,
        Color(0xFFEC4899),
        '/tools/data-converter'),
    _ToolDef(
        'Encodeur Base64',
        'Encodez et décodez instantanément vos textes en Base64.',
        Icons.code,
        Color(0xFF14B8A6),
        '/tools/base64'),
    _ToolDef(
        'Générateur de Hash',
        'Générez des empreintes MD5, SHA-1 et SHA-256 en toute simplicité.',
        Icons.fingerprint,
        Color(0xFFEF4444),
        '/tools/hash'),
    _ToolDef(
        'Calculateur Chmod',
        'Calculez et convertissez les permissions Unix (755, rwxr-xr-x).',
        Icons.rule,
        Color(0xFF3B82F6),
        '/tools/chmod'),
    _ToolDef(
        'Formateur JSON',
        'Validez, formatez et minifiez votre code JSON instantanément.',
        Icons.settings_overscan,
        Color(0xFFFACC15),
        '/tools/json'),
    _ToolDef(
        'ASCII / Hex / Bin',
        'Convertisseur universel entre texte, hexadécimal, binaire et décimal.',
        Icons.swap_horiz,
        Color(0xFF6366F1),
        '/tools/ascii'),
    _ToolDef(
        'Calculateur RAID',
        'Calculez la capacité utile et la tolérance aux pannes de vos serveurs.',
        Icons.storage,
        Color(0xFF10B981),
        '/tools/raid'),
    _ToolDef(
        'Codes HTTP',
        'Explorateur complet des codes d\'état HTTP et conseils de dépannage.',
        Icons.http,
        Color(0xFFF43F5E),
        '/tools/http-status'),
    _ToolDef(
        'Annuaire des Ports',
        'Référence rapide des ports TCP/UDP les plus courants par service.',
        Icons.lan,
        Color(0xFF8B5CF6),
        '/tools/ports'),
    _ToolDef(
        'Débit & Télécharg.',
        'Calculez le temps de transfert selon la vitesse et la taille de vos fichiers.',
        Icons.speed,
        Color(0xFFF59E0B),
        '/tools/bandwidth'),
    _ToolDef(
        'Expression Cron',
        'Décodez et testez vos expressions de planification système (Cron).',
        Icons.schedule,
        Color(0xFF14B8A6),
        '/tools/cron'),
    _ToolDef(
        'Niveaux Syslog',
        'Référence des sévérités RFC 5424 pour le filtrage des logs serveur.',
        Icons.list_alt,
        Color(0xFFEF4444),
        '/tools/syslog'),
    _ToolDef(
        'Aide-émémoire Archivage',
        'Commandes rapides pour tar, rsync et zip (sauvegarde et transfert).',
        Icons.inventory_2,
        Color(0xFFF59E0B),
        '/tools/archive'),
    _ToolDef(
        'Assistant SSH',
        'Guide de configuration ~/.ssh/config et bonnes pratiques de sécurité.',
        Icons.terminal,
        Color(0xFF3B82F6),
        '/tools/ssh'),
    _ToolDef(
        'Référence DNS',
        'Types d\'enregistrements DNS (A, MX, TXT, etc.) et leur utilité.',
        Icons.dns,
        Color(0xFF8B5CF6),
        '/tools/dns'),
    _ToolDef(
        'Anonymat & Identité Réseau',
        'Commandes pour changer hostname, MAC, nom utilisateur. ⚠ L\'IP publique reste visible.',
        Icons.manage_accounts,
        Color(0xFF8B5CF6),
        '/tools/anonymity'),
  ];

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
              _buildSimCard(
                  context,
                  0,
                  'Simulateur Réseau',
                  'Ping · Scan · Traceroute · Sniffer · Monitoring',
                  Icons.lan,
                  const Color(0xFF3B82F6),
                  'network'),
              _buildSimCard(
                  context,
                  1,
                  'Simulateur Sécurité',
                  'Scan Vulnérabilités · Pentest · IDS/IPS · Forensics',
                  Icons.shield,
                  const Color(0xFFEF4444),
                  'security'),
              _buildSimCard(
                  context,
                  2,
                  'Simulateur Système',
                  'Processus · Services · Disques · Performance',
                  Icons.memory,
                  const Color(0xFFF97316),
                  'system'),
              _buildSimCard(
                  context,
                  3,
                  'Simulateur Cloud',
                  'Instances · Load Balancer · Déploiements · Coûts',
                  Icons.cloud,
                  const Color(0xFF06B6D4),
                  'cloud'),
              _buildSimCard(
                  context,
                  4,
                  'Simulateur Crypto',
                  'AES/RSA · Hashage · Signature · SSL/TLS',
                  Icons.lock,
                  const Color(0xFF8B5CF6),
                  'crypto'),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSimCard(BuildContext context, int index, String title,
      String desc, IconData icon, Color color, String simId) {
    return TdcFadeSlide(
      delay: Duration(milliseconds: 60 * (22 + index)),
      child: TdcCard(
        onTap: () =>
            Navigator.pushNamed(context, '/lab', arguments: {'sim': simId}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: TdcRadius.md,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.science, color: color, size: 10),
                      const SizedBox(width: 3),
                      Text('LAB',
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(
                    color: TdcColors.textSecondary, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, int index, _ToolDef tool,
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

class _ToolDef {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  const _ToolDef(
      this.title, this.description, this.icon, this.color, this.route);
}
