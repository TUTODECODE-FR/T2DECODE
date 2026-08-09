// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class ToolCatalogEntry {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final String breadcrumb;
  final String category;

  const ToolCatalogEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    required this.breadcrumb,
    required this.category,
  });
}

// ── Catégories ────────────────────────────────────────────────
const String catReseau    = 'Réseau & IP';
const String catSecurite  = 'Sécurité & Crypto';
const String catSysteme   = 'Système & OS';
const String catDev       = 'Dev & Code';
const String catReference = 'Référence';

const List<ToolCatalogEntry> toolCatalog = [
  // ── Réseau & IP ──────────────────────────────────────────────
  ToolCatalogEntry(
    title: 'Calculateur IP / CIDR',
    description: 'Calculez vos sous-réseaux, masques et plages d\'adresses IPv4 rapidement.',
    icon: Icons.settings_ethernet,
    color: TdcColors.accent,
    route: '/tools/ip-calc',
    breadcrumb: 'IP Calc',
    category: catReseau,
  ),
  ToolCatalogEntry(
    title: 'Annuaire des Ports',
    description: 'Référence rapide des ports TCP/UDP les plus courants par service.',
    icon: Icons.lan,
    color: Color(0xFF8B5CF6),
    route: '/tools/ports',
    breadcrumb: 'Ports',
    category: catReseau,
  ),
  ToolCatalogEntry(
    title: 'Référence DNS',
    description: 'Types d\'enregistrements DNS (A, MX, TXT, CNAME, PTR…) et leur utilité concrète.',
    icon: Icons.dns,
    color: Color(0xFF8B5CF6),
    route: '/tools/dns',
    breadcrumb: 'DNS',
    category: catReseau,
  ),
  ToolCatalogEntry(
    title: 'Débit & Téléchargement',
    description: 'Calculez le temps de transfert selon la vitesse réseau et la taille de fichier.',
    icon: Icons.speed,
    color: Color(0xFFF59E0B),
    route: '/tools/bandwidth',
    breadcrumb: 'Débit',
    category: catReseau,
  ),
  ToolCatalogEntry(
    title: 'Codes HTTP',
    description: 'Référentiel complet des codes d\'état HTTP avec conseils de dépannage.',
    icon: Icons.http,
    color: Color(0xFFF43F5E),
    route: '/tools/http-status',
    breadcrumb: 'HTTP',
    category: catReseau,
  ),
  ToolCatalogEntry(
    title: 'Calculateur RAID',
    description: 'Capacité utile et tolérance aux pannes pour RAID 0, 1, 5, 6, 10.',
    icon: Icons.storage,
    color: Color(0xFF10B981),
    route: '/tools/raid',
    breadcrumb: 'RAID',
    category: catReseau,
  ),

  // ── Sécurité & Crypto ────────────────────────────────────────
  ToolCatalogEntry(
    title: 'Générateur de Mot de Passe',
    description: 'Créez des mots de passe forts avec entropie calculée. 100% local, rien n\'est transmis.',
    icon: Icons.password,
    color: Color(0xFF6366F1),
    route: '/tools/password-gen',
    breadcrumb: 'MDP',
    category: catSecurite,
  ),
  ToolCatalogEntry(
    title: 'Générateur de Hash',
    description: 'Calculez MD5, SHA-1 et SHA-256 d\'un texte. Comprendre les empreintes cryptographiques.',
    icon: Icons.fingerprint,
    color: Color(0xFFEF4444),
    route: '/tools/hash',
    breadcrumb: 'Hash',
    category: catSecurite,
  ),
  ToolCatalogEntry(
    title: 'Identité Réseau & Confidentialité',
    description: 'Informations réseau locales : hostname, MAC, utilisateur, IPv6/mDNS/TTL.',
    icon: Icons.manage_accounts,
    color: Color(0xFF8B5CF6),
    route: '/tools/anonymity',
    breadcrumb: 'Identité réseau',
    category: catSecurite,
  ),
  ToolCatalogEntry(
    title: 'Assistant SSH',
    description: 'Guide complet ~/.ssh/config, clés Ed25519, bastion, bonnes pratiques de sécurité.',
    icon: Icons.terminal,
    color: Color(0xFF3B82F6),
    route: '/tools/ssh',
    breadcrumb: 'SSH',
    category: catSecurite,
  ),

  // ── Système & OS ─────────────────────────────────────────────
  ToolCatalogEntry(
    title: 'Multi-Tools Sécurisés',
    description: 'Diagnostic réseau/système/stockage en sandbox — sans exécuter de commandes arbitraires.',
    icon: Icons.security,
    color: Color(0xFF22C55E),
    route: '/tools/safe-tools',
    breadcrumb: 'Safe Tools',
    category: catSysteme,
  ),
  ToolCatalogEntry(
    title: 'Calculateur Chmod',
    description: 'Calculez et visualisez les permissions Unix (755 ↔ rwxr-xr-x) avec explication.',
    icon: Icons.rule,
    color: Color(0xFF3B82F6),
    route: '/tools/chmod',
    breadcrumb: 'Chmod',
    category: catSysteme,
  ),
  ToolCatalogEntry(
    title: 'Expression Cron',
    description: 'Décryptez et testez vos expressions de planification système (crontab).',
    icon: Icons.schedule,
    color: Color(0xFF14B8A6),
    route: '/tools/cron',
    breadcrumb: 'Cron',
    category: catSysteme,
  ),
  ToolCatalogEntry(
    title: 'Niveaux Syslog',
    description: 'Référence des 8 sévérités RFC 5424 pour le filtrage et la compréhension des logs.',
    icon: Icons.list_alt,
    color: Color(0xFFEF4444),
    route: '/tools/syslog',
    breadcrumb: 'Syslog',
    category: catSysteme,
  ),
  ToolCatalogEntry(
    title: 'Aide-mémoire Archivage',
    description: 'Commandes tar, rsync et zip avec exemples commentés pour la sauvegarde et le transfert.',
    icon: Icons.inventory_2,
    color: Color(0xFFF59E0B),
    route: '/tools/archive',
    breadcrumb: 'Archivage',
    category: catSysteme,
  ),
  ToolCatalogEntry(
    title: 'Guides de Survie',
    description: 'Fiches d\'urgence pour résoudre les pannes critiques (Windows, Mac, Linux).',
    icon: Icons.medication,
    color: Color(0xFFEF4444),
    route: '/tools/survival',
    breadcrumb: 'Survie',
    category: catSysteme,
  ),
  ToolCatalogEntry(
    title: 'Référence Matérielle',
    description: 'Codes de bips BIOS, ports communs, connectique et références hardware.',
    icon: Icons.memory,
    color: Color(0xFFF59E0B),
    route: '/tools/hardware',
    breadcrumb: 'Matériel',
    category: catSysteme,
  ),

  // ── Dev & Code ───────────────────────────────────────────────
  ToolCatalogEntry(
    title: 'Formateur JSON',
    description: 'Validez, formatez et minifiez votre code JSON. Détection d\'erreurs de syntaxe.',
    icon: Icons.settings_overscan,
    color: Color(0xFFFACC15),
    route: '/tools/json',
    breadcrumb: 'JSON',
    category: catDev,
  ),
  ToolCatalogEntry(
    title: 'Testeur Regex',
    description: 'Testez vos expressions régulières avec coloration syntaxique et explication des groupes.',
    icon: Icons.find_replace,
    color: Color(0xFFF43F5E),
    route: '/tools/regex',
    breadcrumb: 'Regex',
    category: catDev,
  ),
  ToolCatalogEntry(
    title: 'Encodeur Base64',
    description: 'Encodez et décodez vos textes/données en Base64. Comprendre l\'encodage binaire-texte.',
    icon: Icons.code,
    color: Color(0xFF14B8A6),
    route: '/tools/base64',
    breadcrumb: 'Base64',
    category: catDev,
  ),
  ToolCatalogEntry(
    title: 'ASCII / Hex / Binaire',
    description: 'Convertisseur entre texte, hexadécimal, binaire et décimal. Base de la représentation machine.',
    icon: Icons.swap_horiz,
    color: Color(0xFF6366F1),
    route: '/tools/ascii',
    breadcrumb: 'ASCII',
    category: catDev,
  ),
  ToolCatalogEntry(
    title: 'Cyber Convertisseur',
    description: 'Conversion rapide entre ASCII, Hex, Base64, Binaire et URL-encoding.',
    icon: Icons.transform,
    color: Color(0xFF3B82F6),
    route: '/tools/cyber-converter',
    breadcrumb: 'Cyber Conv',
    category: catDev,
  ),
  ToolCatalogEntry(
    title: 'Scripts Utiles',
    description: 'Bibliothèque de scripts Batch, PowerShell et Bash commentés pour l\'automatisation.',
    icon: Icons.terminal,
    color: Color(0xFF10B981),
    route: '/tools/scripts',
    breadcrumb: 'Scripts',
    category: catDev,
  ),

  // ── Référence ────────────────────────────────────────────────
  ToolCatalogEntry(
    title: 'Glossaire Tech',
    description: 'Définitions claires du jargon informatique pour tous les niveaux.',
    icon: Icons.menu_book,
    color: Color(0xFF8B5CF6),
    route: '/tools/glossary',
    breadcrumb: 'Glossaire',
    category: catReference,
  ),
  ToolCatalogEntry(
    title: 'Convertisseur de Données',
    description: 'Convertissez vos unités de stockage (Octets, Ko, Mo, Go, To) sans erreur.',
    icon: Icons.analytics,
    color: Color(0xFFEC4899),
    route: '/tools/data-converter',
    breadcrumb: 'Convertisseur',
    category: catReference,
  ),
];

Map<String, String> buildToolBreadcrumbMap() {
  final map = <String, String>{};
  for (final tool in toolCatalog) {
    map[tool.route] = tool.breadcrumb;
  }
  return map;
}

/// Returns ordered distinct categories from the catalog
List<String> get toolCategories {
  final seen = <String>{};
  return toolCatalog.map((t) => t.category).where(seen.add).toList();
}
