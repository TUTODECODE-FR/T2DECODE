// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import '../screens/cheat_sheet_screen.dart';

/// Maps UI filter chips to canonical categories in cheat_sheets.tdc.
class CheatSheetCategories {
  CheatSheetCategories._();

  static const filterLabels = [
    'TOUT',
    'Red Team',
    'Blue Team',
    'Admin Sys',
    'Cloud',
    'SÉCURITÉ',
    'RÉSEAU',
    'Web',
    'Git',
    'Texte',
  ];

  static bool matchesFilter(String filter, CheatSheetEntry entry) {
    if (filter == 'TOUT') return true;

    switch (filter) {
      case 'Red Team':
      case 'Blue Team':
      case 'Admin Sys':
      case 'Cloud':
      case 'Web':
      case 'Git':
      case 'Texte':
        return entry.category == filter;
      case 'SÉCURITÉ':
        return entry.category == 'Securite';
      case 'RÉSEAU':
        return const {'Reseau', 'Diagnostic', 'DNS', 'Wireless'}
            .contains(entry.category);
      default:
        return entry.category == filter;
    }
  }

  static bool matchesSearch(CheatSheetEntry entry, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return entry.command.toLowerCase().contains(q) ||
        entry.description.toLowerCase().contains(q) ||
        entry.category.toLowerCase().contains(q) ||
        (entry.detailedExplanation?.toLowerCase().contains(q) ?? false);
  }
}
