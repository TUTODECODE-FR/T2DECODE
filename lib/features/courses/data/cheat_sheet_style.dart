// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import '../screens/cheat_sheet_screen.dart';

/// Shared styling for cheat sheet cards and detail views (muted danger palette).
class CheatSheetStyle {
  CheatSheetStyle._();

  static Color dangerColor(int level) {
    switch (level) {
      case 3:
        return TdcColors.levelExpert;
      case 2:
        return TdcColors.warning;
      default:
        return TdcColors.textMuted;
    }
  }

  static String dangerLabel(int level) {
    switch (level) {
      case 3:
        return 'Sensible';
      case 2:
        return 'Prudence';
      default:
        return 'Normal';
    }
  }

  static Color categoryColor(CheatSheetEntry entry) {
    if (entry.colorHex != null && entry.colorHex!.isNotEmpty) {
      final hex = entry.colorHex!.replaceAll('#', '');
      try {
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    switch (entry.category) {
      case 'Red Team':
        return TdcColors.levelExpert;
      case 'Blue Team':
        return TdcColors.info;
      case 'Admin Sys':
        return TdcColors.system;
      case 'Cloud':
        return TdcColors.cloud;
      case 'Securite':
        return TdcColors.security;
      case 'Reseau':
      case 'Diagnostic':
      case 'DNS':
      case 'Wireless':
        return TdcColors.network;
      case 'Web':
        return TdcColors.electric;
      case 'Git':
        return TdcColors.crypto;
      case 'Texte':
        return TdcColors.coral;
      default:
        return TdcColors.accent;
    }
  }

  static IconData categoryIcon(CheatSheetEntry entry) {
    if (entry.iconName != null && entry.iconName!.isNotEmpty) {
      switch (entry.iconName) {
        case 'security':
          return Icons.security;
        case 'terminal':
          return Icons.terminal;
        case 'cloud':
          return Icons.cloud;
        case 'dns':
          return Icons.dns;
        case 'lock':
          return Icons.lock;
        case 'api':
          return Icons.api;
        case 'bug_report':
          return Icons.bug_report;
        case 'admin_panel_settings':
          return Icons.admin_panel_settings;
        case 'storage':
          return Icons.storage;
        case 'network':
          return Icons.network_check;
        case 'search':
          return Icons.search;
        case 'bookmark':
          return Icons.bookmark;
      }
    }
    switch (entry.category) {
      case 'Red Team':
        return Icons.bug_report;
      case 'Blue Team':
        return Icons.shield;
      case 'Admin Sys':
        return Icons.admin_panel_settings;
      case 'Cloud':
        return Icons.cloud;
      case 'Securite':
        return Icons.security;
      case 'Reseau':
      case 'Diagnostic':
      case 'DNS':
      case 'Wireless':
        return Icons.lan;
      case 'Web':
        return Icons.language;
      case 'Git':
        return Icons.merge_type;
      case 'Texte':
        return Icons.text_fields;
      default:
        return Icons.code;
    }
  }
}
