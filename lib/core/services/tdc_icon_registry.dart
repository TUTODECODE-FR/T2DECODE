// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TDCIconEntry {
  final String token;
  final IconData icon;
  final String group;
  final List<String> tags;

  const TDCIconEntry({
    required this.token,
    required this.icon,
    required this.group,
    required this.tags,
  });
}

class TDCIconRegistry {
  static const List<TDCIconEntry> catalog = [
    // ── SYSTÈME & OS ──
    TDCIconEntry(token: 'Terminal', icon: Icons.terminal, group: 'Système', tags: ['terminal', 'bash', 'shell', 'cli', 'console', 'invite', 'linux']),
    TDCIconEntry(token: 'Memory', icon: Icons.memory, group: 'Système', tags: ['memoire', 'ram', 'cpu', 'processeur', 'hardware', 'materiel', 'composant']),
    TDCIconEntry(token: 'Storage', icon: Icons.storage, group: 'Système', tags: ['stockage', 'disque', 'ssd', 'hdd', 'partition', 'drive', 'volume']),
    TDCIconEntry(token: 'Dns', icon: Icons.dns, group: 'Système', tags: ['dns', 'serveur', 'server', 'domaine', 'hote', 'host']),
    TDCIconEntry(token: 'Settings', icon: Icons.settings, group: 'Système', tags: ['configuration', 'reglages', 'options', 'parametres', 'setup']),
    TDCIconEntry(token: 'Tune', icon: Icons.tune, group: 'Système', tags: ['optimisation', 'tuning', 'curseurs', 'adjust']),
    TDCIconEntry(token: 'Power', icon: Icons.power_settings_new, group: 'Système', tags: ['power', 'reboot', 'shutdown', 'demarrage', 'energie']),
    TDCIconEntry(token: 'DeveloperBoard', icon: Icons.developer_board, group: 'Système', tags: ['carte', 'carte mere', 'motherboard', 'raspberry', 'microcontroleur']),
    TDCIconEntry(token: 'Speed', icon: Icons.speed, group: 'Système', tags: ['performance', 'vitesse', 'benchmark', 'metric']),
    TDCIconEntry(token: 'Folder', icon: Icons.folder, group: 'Système', tags: ['dossier', 'repertoire', 'directory', 'fichier', 'filesystem']),
    TDCIconEntry(token: 'FolderZip', icon: Icons.folder_zip, group: 'Système', tags: ['archive', 'zip', 'tar', 'compression', 'extract', 'backup']),
    TDCIconEntry(token: 'Layers', icon: Icons.layers, group: 'Système', tags: ['couches', 'kernel', 'noyau', 'system', 'architecture']),

    // ── RÉSEAU & INFRA ──
    TDCIconEntry(token: 'Router', icon: Icons.router, group: 'Réseau', tags: ['routeur', 'router', 'gateway', 'passerelle', 'switch', 'routage']),
    TDCIconEntry(token: 'Lan', icon: Icons.lan, group: 'Réseau', tags: ['lan', 'ethernet', 'cable', 'rj45', 'reseau', 'local']),
    TDCIconEntry(token: 'Wifi', icon: Icons.wifi, group: 'Réseau', tags: ['wifi', 'sans fil', 'wireless', 'wlan', 'onde', 'antenne']),
    TDCIconEntry(token: 'Hub', icon: Icons.hub, group: 'Réseau', tags: ['hub', 'noeud', 'node', 'topologie', 'mesh', 'etoile']),
    TDCIconEntry(token: 'Public', icon: Icons.public, group: 'Réseau', tags: ['internet', 'web', 'mondial', 'global', 'wan', 'ip']),
    TDCIconEntry(token: 'Cable', icon: Icons.cable, group: 'Réseau', tags: ['cable', 'fibre', 'liaison', 'connexion', 'link']),
    TDCIconEntry(token: 'Cast', icon: Icons.cast, group: 'Réseau', tags: ['diffusion', 'stream', 'broadcast', 'multicast']),
    TDCIconEntry(token: 'Sensors', icon: Icons.sensors, group: 'Réseau', tags: ['capteur', 'iot', 'signal', 'ping', 'probe']),
    TDCIconEntry(token: 'Podcasts', icon: Icons.podcasts, group: 'Réseau', tags: ['ondes', 'radio', 'frequence', 'spectrum']),
    TDCIconEntry(token: 'SyncAlt', icon: Icons.sync_alt, group: 'Réseau', tags: ['echange', 'flux', 'packet', 'paquet', 'trafic']),

    // ── SÉCURITÉ & CRYPTO ──
    TDCIconEntry(token: 'Security', icon: Icons.security, group: 'Sécurité', tags: ['securite', 'security', 'bouclier', 'protection', 'defense']),
    TDCIconEntry(token: 'Shield', icon: Icons.shield_outlined, group: 'Sécurité', tags: ['bouclier', 'shield', 'antivirus', 'pare-feu', 'firewall']),
    TDCIconEntry(token: 'Lock', icon: Icons.lock_outline, group: 'Sécurité', tags: ['cadenas', 'verrou', 'lock', 'chiffrement', 'secret']),
    TDCIconEntry(token: 'VpnKey', icon: Icons.vpn_key_outlined, group: 'Sécurité', tags: ['cle', 'key', 'certificat', 'ssh', 'rsa', 'ed25519', 'auth']),
    TDCIconEntry(token: 'Fingerprint', icon: Icons.fingerprint, group: 'Sécurité', tags: ['empreinte', 'biometrie', 'signature', 'identite', 'tofu']),
    TDCIconEntry(token: 'Key', icon: Icons.key, group: 'Sécurité', tags: ['clef', 'passe', 'password', 'token', 'jeton']),
    TDCIconEntry(token: 'AdminPanelSettings', icon: Icons.admin_panel_settings, group: 'Sécurité', tags: ['admin', 'root', 'sudo', 'privileges', 'droits', 'rbac']),
    TDCIconEntry(token: 'Policy', icon: Icons.policy, group: 'Sécurité', tags: ['politique', 'conformite', 'audit', 'regle', 'rule']),
    TDCIconEntry(token: 'VisibilityOff', icon: Icons.visibility_off, group: 'Sécurité', tags: ['anonymat', 'masquage', 'tor', 'prive', 'stealth']),
    TDCIconEntry(token: 'GppGood', icon: Icons.gpp_good, group: 'Sécurité', tags: ['valide', 'securise', 'certifie', 'audit']),
    TDCIconEntry(token: 'VpnLock', icon: Icons.vpn_lock, group: 'Sécurité', tags: ['vpn', 'tunnel', 'ipsec', 'wireguard', 'openvpn']),

    // ── CLOUD & DEVOPS ──
    TDCIconEntry(token: 'Cloud', icon: Icons.cloud_outlined, group: 'Cloud', tags: ['cloud', 'nuage', 'aws', 'gcp', 'azure', 'saas']),
    TDCIconEntry(token: 'CloudQueue', icon: Icons.cloud_queue, group: 'Cloud', tags: ['file', 'queue', 'message', 'broker', 'kafka', 'rabbitmq']),
    TDCIconEntry(token: 'Rocket', icon: Icons.rocket_launch, group: 'Cloud', tags: ['deploiement', 'fusee', 'launch', 'release', 'production']),
    TDCIconEntry(token: 'MergeType', icon: Icons.merge_type, group: 'Cloud', tags: ['git', 'merge', 'branche', 'commit', 'versioning']),
    TDCIconEntry(token: 'Backup', icon: Icons.backup, group: 'Cloud', tags: ['sauvegarde', 'backup', 'snapshot', 'restauration']),
    TDCIconEntry(token: 'LayersOutlined', icon: Icons.layers_outlined, group: 'Cloud', tags: ['docker', 'conteneur', 'container', 'k8s', 'kubernetes']),
    TDCIconEntry(token: 'AllInclusive', icon: Icons.all_inclusive, group: 'Cloud', tags: ['devops', 'cicd', 'infini', 'pipeline', 'automation']),

    // ── DÉVELOPPEMENT & CODE ──
    TDCIconEntry(token: 'Code', icon: Icons.code, group: 'Dev', tags: ['code', 'balise', 'dev', 'programmation', 'script', 'source']),
    TDCIconEntry(token: 'DataObject', icon: Icons.data_object, group: 'Dev', tags: ['json', 'objet', 'structure', 'map', 'dictionnaire', 'array']),
    TDCIconEntry(token: 'BugReport', icon: Icons.bug_report_outlined, group: 'Dev', tags: ['bug', 'debug', 'erreur', 'test', 'patch', 'correctif']),
    TDCIconEntry(token: 'TerminalCode', icon: Icons.integration_instructions, group: 'Dev', tags: ['api', 'sdk', 'integration', 'fonction', 'methode']),
    TDCIconEntry(token: 'Javascript', icon: Icons.javascript, group: 'Dev', tags: ['js', 'javascript', 'typescript', 'node', 'web']),
    TDCIconEntry(token: 'Html', icon: Icons.html, group: 'Dev', tags: ['html', 'css', 'frontend', 'dom']),
    TDCIconEntry(token: 'Css', icon: Icons.css, group: 'Dev', tags: ['css', 'style', 'ui', 'design']),
    TDCIconEntry(token: 'DataObjectTwoTone', icon: Icons.data_array, group: 'Dev', tags: ['tableau', 'matrice', 'vecteur', 'index']),

    // ── DATA & BASES DE DONNÉES ──
    TDCIconEntry(token: 'Database', icon: Icons.table_chart_outlined, group: 'Data', tags: ['bdd', 'sql', 'database', 'table', 'relationnel', 'postgres', 'mysql']),
    TDCIconEntry(token: 'Analytics', icon: Icons.analytics_outlined, group: 'Data', tags: ['statistiques', 'metriques', 'dashboard', 'analyse', 'graphe']),
    TDCIconEntry(token: 'QueryStats', icon: Icons.query_stats, group: 'Data', tags: ['requete', 'query', 'sql', 'monitoring', 'logs']),
    TDCIconEntry(token: 'Dataset', icon: Icons.dataset, group: 'Data', tags: ['dataset', 'donnees', 'bigdata', 'corpus']),

    // ── GÉNÉRAL & PÉDAGOGIE ──
    TDCIconEntry(token: 'BookOpen', icon: Icons.menu_book, group: 'Général', tags: ['livre', 'cours', 'chapitre', 'lecture', 'tuto', 'guide']),
    TDCIconEntry(token: 'School', icon: Icons.school_outlined, group: 'Général', tags: ['ecole', 'formation', 'diplome', 'academie', 'etude']),
    TDCIconEntry(token: 'WorkspacePremium', icon: Icons.workspace_premium_outlined, group: 'Général', tags: ['badge', 'trophee', 'medaille', 'reussite', 'xp']),
    TDCIconEntry(token: 'Psychology', icon: Icons.psychology_outlined, group: 'Général', tags: ['cerveau', 'reflexion', 'logique', 'ia', 'concept']),
    TDCIconEntry(token: 'Quiz', icon: Icons.quiz_outlined, group: 'Général', tags: ['quiz', 'qcm', 'question', 'examen', 'test']),
    TDCIconEntry(token: 'Star', icon: Icons.star_outline, group: 'Général', tags: ['favori', 'important', 'etoile', 'focus']),
    TDCIconEntry(token: 'Help', icon: Icons.help_outline, group: 'Général', tags: ['aide', 'question', 'faq', 'support']),
  ];

  static final List<String> _recentIconTokens = [];

  static List<String> get recentTokens => List.unmodifiable(_recentIconTokens);

  static Future<void> loadRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('tdc_recent_icon_tokens_v1') ?? [];
      _recentIconTokens.clear();
      _recentIconTokens.addAll(list);
    } catch (_) {}
  }

  static Future<void> recordRecent(String token) async {
    _recentIconTokens.remove(token);
    _recentIconTokens.insert(0, token);
    if (_recentIconTokens.length > 8) {
      _recentIconTokens.removeLast();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('tdc_recent_icon_tokens_v1', _recentIconTokens);
    } catch (_) {}
  }

  static IconData getIcon(String token, {IconData fallback = Icons.menu_book}) {
    final entry = catalog.cast<TDCIconEntry?>().firstWhere(
          (e) => e?.token.toLowerCase() == token.toLowerCase().trim(),
          orElse: () => null,
        );
    return entry?.icon ?? fallback;
  }

  static bool isValidToken(String token) {
    return catalog.any((e) => e.token.toLowerCase() == token.toLowerCase().trim());
  }

  static List<TDCIconEntry> search(String query, {String? groupFilter}) {
    final q = query.toLowerCase().trim();
    return catalog.where((item) {
      if (groupFilter != null && groupFilter.isNotEmpty && groupFilter != 'Tous' && item.group != groupFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return item.token.toLowerCase().contains(q) ||
          item.group.toLowerCase().contains(q) ||
          item.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }
}
