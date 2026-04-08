import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class ToolCatalogEntry {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final String breadcrumb;

  const ToolCatalogEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    required this.breadcrumb,
  });
}

const List<ToolCatalogEntry> toolCatalog = [
  ToolCatalogEntry(
    title: 'Multi-Tools Securises',
    description:
        'Diagnostic reseau/systeme/stockage avec sandbox et logs (sans commandes arbitraires).',
    icon: Icons.security,
    color: Color(0xFF22C55E),
    route: '/tools/safe-tools',
    breadcrumb: 'Safe Tools',
  ),
  ToolCatalogEntry(
    title: 'Calculateur IP',
    description:
        'Calculez vos sous-reseaux, masques et plages d\'adresses rapidement.',
    icon: Icons.settings_ethernet,
    color: TdcColors.accent,
    route: '/tools/ip-calc',
    breadcrumb: 'IP Calc',
  ),
  ToolCatalogEntry(
    title: 'Guides de Survie',
    description:
        'Fiches de secours pour resoudre les pannes critiques (Windows, Mac, Linux).',
    icon: Icons.medication,
    color: Color(0xFFEF4444),
    route: '/tools/survival',
    breadcrumb: 'Survie',
  ),
  ToolCatalogEntry(
    title: 'Glossaire Tech',
    description:
        'Definitions simples et claires pour comprendre tout le jargon informatique.',
    icon: Icons.menu_book,
    color: Color(0xFF8B5CF6),
    route: '/tools/glossary',
    breadcrumb: 'Glossaire',
  ),
  ToolCatalogEntry(
    title: 'Scripts Utiles',
    description:
        'Bibliotheque de scripts Batch, PowerShell et Bash pour automatiser vos taches.',
    icon: Icons.terminal,
    color: Color(0xFF10B981),
    route: '/tools/scripts',
    breadcrumb: 'Scripts',
  ),
  ToolCatalogEntry(
    title: 'Reference Materielle',
    description: 'Codes de bips BIOS, liste des ports communs et connectique.',
    icon: Icons.memory,
    color: Color(0xFFF59E0B),
    route: '/tools/hardware',
    breadcrumb: 'Materiel',
  ),
  ToolCatalogEntry(
    title: 'Generateur de MDP',
    description:
        'Creez des mots de passe ultra-securises et personnalises en un clic.',
    icon: Icons.password,
    color: Color(0xFF6366F1),
    route: '/tools/password-gen',
    breadcrumb: 'Mot de passe',
  ),
  ToolCatalogEntry(
    title: 'Convertisseur de Donnees',
    description:
        'Convertissez vos unites de stockage (Octets, Mo, Go) sans erreur.',
    icon: Icons.analytics,
    color: Color(0xFFEC4899),
    route: '/tools/data-converter',
    breadcrumb: 'Convertisseur',
  ),
  ToolCatalogEntry(
    title: 'Encodeur Base64',
    description: 'Encodez et decodez instantanement vos textes en Base64.',
    icon: Icons.code,
    color: Color(0xFF14B8A6),
    route: '/tools/base64',
    breadcrumb: 'Base64',
  ),
  ToolCatalogEntry(
    title: 'Generateur de Hash',
    description:
        'Generez des empreintes MD5, SHA-1 et SHA-256 en toute simplicite.',
    icon: Icons.fingerprint,
    color: Color(0xFFEF4444),
    route: '/tools/hash',
    breadcrumb: 'Hash',
  ),
  ToolCatalogEntry(
    title: 'Calculateur Chmod',
    description:
        'Calculez et convertissez les permissions Unix (755, rwxr-xr-x).',
    icon: Icons.rule,
    color: Color(0xFF3B82F6),
    route: '/tools/chmod',
    breadcrumb: 'Chmod',
  ),
  ToolCatalogEntry(
    title: 'Formateur JSON',
    description:
        'Validez, formatez et minifiez votre code JSON instantanement.',
    icon: Icons.settings_overscan,
    color: Color(0xFFFACC15),
    route: '/tools/json',
    breadcrumb: 'JSON',
  ),
  ToolCatalogEntry(
    title: 'ASCII / Hex / Bin',
    description:
        'Convertisseur universel entre texte, hexadecimal, binaire et decimal.',
    icon: Icons.swap_horiz,
    color: Color(0xFF6366F1),
    route: '/tools/ascii',
    breadcrumb: 'ASCII',
  ),
  ToolCatalogEntry(
    title: 'Calculateur RAID',
    description:
        'Calculez la capacite utile et la tolerance aux pannes de vos serveurs.',
    icon: Icons.storage,
    color: Color(0xFF10B981),
    route: '/tools/raid',
    breadcrumb: 'RAID',
  ),
  ToolCatalogEntry(
    title: 'Codes HTTP',
    description:
        'Explorateur complet des codes d\'etat HTTP et conseils de depannage.',
    icon: Icons.http,
    color: Color(0xFFF43F5E),
    route: '/tools/http-status',
    breadcrumb: 'HTTP',
  ),
  ToolCatalogEntry(
    title: 'Annuaire des Ports',
    description:
        'Reference rapide des ports TCP/UDP les plus courants par service.',
    icon: Icons.lan,
    color: Color(0xFF8B5CF6),
    route: '/tools/ports',
    breadcrumb: 'Ports',
  ),
  ToolCatalogEntry(
    title: 'Debit & Telecharg.',
    description:
        'Calculez le temps de transfert selon la vitesse et la taille de vos fichiers.',
    icon: Icons.speed,
    color: Color(0xFFF59E0B),
    route: '/tools/bandwidth',
    breadcrumb: 'Debit',
  ),
  ToolCatalogEntry(
    title: 'Expression Cron',
    description:
        'Decodez et testez vos expressions de planification systeme (Cron).',
    icon: Icons.schedule,
    color: Color(0xFF14B8A6),
    route: '/tools/cron',
    breadcrumb: 'Cron',
  ),
  ToolCatalogEntry(
    title: 'Niveaux Syslog',
    description:
        'Reference des severites RFC 5424 pour le filtrage des logs serveur.',
    icon: Icons.list_alt,
    color: Color(0xFFEF4444),
    route: '/tools/syslog',
    breadcrumb: 'Syslog',
  ),
  ToolCatalogEntry(
    title: 'Aide-memoire Archivage',
    description:
        'Commandes rapides pour tar, rsync et zip (sauvegarde et transfert).',
    icon: Icons.inventory_2,
    color: Color(0xFFF59E0B),
    route: '/tools/archive',
    breadcrumb: 'Archivage',
  ),
  ToolCatalogEntry(
    title: 'Assistant SSH',
    description:
        'Guide de configuration ~/.ssh/config et bonnes pratiques de securite.',
    icon: Icons.terminal,
    color: Color(0xFF3B82F6),
    route: '/tools/ssh',
    breadcrumb: 'SSH',
  ),
  ToolCatalogEntry(
    title: 'Reference DNS',
    description:
        'Types d\'enregistrements DNS (A, MX, TXT, etc.) et leur utilite.',
    icon: Icons.dns,
    color: Color(0xFF8B5CF6),
    route: '/tools/dns',
    breadcrumb: 'DNS',
  ),
  ToolCatalogEntry(
    title: 'Anonymisation locale & Identite reseau',
    description:
        'Operations systeme reelles: hostname, MAC, utilisateur, IPv6/mDNS/TTL. IP publique toujours visible.',
    icon: Icons.manage_accounts,
    color: Color(0xFF8B5CF6),
    route: '/tools/anonymity',
    breadcrumb: 'Anonymisation',
  ),
];

Map<String, String> buildToolBreadcrumbMap() {
  final map = <String, String>{};
  for (final tool in toolCatalog) {
    map[tool.route] = tool.breadcrumb;
  }
  return map;
}
