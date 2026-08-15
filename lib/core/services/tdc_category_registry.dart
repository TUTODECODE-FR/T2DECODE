// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Définition d'une catégorie (intégrée ou personnalisée).
class TDCCategory {
  final String id;
  final String label;
  final String colorToken;
  final String iconToken;
  final bool isCustom;

  const TDCCategory({
    required this.id,
    required this.label,
    required this.colorToken,
    required this.iconToken,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'colorToken': colorToken,
        'iconToken': iconToken,
        'isCustom': isCustom,
      };

  factory TDCCategory.fromJson(Map<String, dynamic> json) => TDCCategory(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        colorToken: json['colorToken'] ?? 'mint',
        iconToken: json['iconToken'] ?? 'BookOpen',
        isCustom: json['isCustom'] ?? true,
      );
}

/// Palette de tokens de couleurs curatés pour contraste optimal sur fond sombre.
class TDCColorTokens {
  static const Map<String, Color> tokens = {
    'creme': Color(0xFFF5EBDA),
    'mint': Color(0xFF10B981),
    'lavande': Color(0xFF8B5CF6),
    'ambre': Color(0xFFF59E0B),
    'coral': Color(0xFFE11D48),
    'sky': Color(0xFF38BDF8),
    'pink': Color(0xFFEC4899),
    'emerald': Color(0xFF059669),
    'cyan': Color(0xFF06B6D4),
    'gold': Color(0xFFD97706),
    'linux': Color(0xFFD7CDBF),
  };

  static Color getColor(String token, {Color defaultColor = const Color(0xFFF5EBDA)}) {
    return tokens[token.toLowerCase().trim()] ?? defaultColor;
  }

  static bool isValidToken(String token) {
    return tokens.containsKey(token.toLowerCase().trim());
  }

  static List<String> get availableTokens => tokens.keys.toList();
}

/// Registre local des catégories.
class TDCCategoryRegistry {
  static const List<TDCCategory> builtinCategories = [
    TDCCategory(id: 'linux', label: 'Linux', colorToken: 'linux', iconToken: 'Terminal', isCustom: false),
    TDCCategory(id: 'network', label: 'Réseau', colorToken: 'lavande', iconToken: 'Router', isCustom: false),
    TDCCategory(id: 'security', label: 'Sécurité', colorToken: 'mint', iconToken: 'Shield', isCustom: false),
    TDCCategory(id: 'cloud', label: 'Cloud', colorToken: 'sky', iconToken: 'Cloud', isCustom: false),
    TDCCategory(id: 'crypto', label: 'Crypto', colorToken: 'coral', iconToken: 'Lock', isCustom: false),
    TDCCategory(id: 'development', label: 'Développement', colorToken: 'ambre', iconToken: 'Code', isCustom: false),
  ];

  static final List<TDCCategory> _customCategories = [];

  static List<TDCCategory> get allCategories => [...builtinCategories, ..._customCategories];
  static List<TDCCategory> get customCategories => List.unmodifiable(_customCategories);

  static bool isBuiltin(String id) {
    final clean = id.toLowerCase().trim();
    return builtinCategories.any((c) => c.id == clean);
  }

  static TDCCategory? findById(String id) {
    final clean = id.toLowerCase().trim();
    return allCategories.cast<TDCCategory?>().firstWhere((c) => c?.id == clean, orElse: () => null);
  }

  static Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('tdc_custom_categories_v1');
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        _customCategories.clear();
        for (final item in decoded) {
          _customCategories.add(TDCCategory.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } catch (_) {}
  }

  static Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_customCategories.map((c) => c.toJson()).toList());
      await prefs.setString('tdc_custom_categories_v1', raw);
    } catch (_) {}
  }

  static bool registerCustomCategory(TDCCategory cat) {
    if (isBuiltin(cat.id)) return false;
    final idx = _customCategories.indexWhere((c) => c.id == cat.id);
    if (idx >= 0) {
      _customCategories[idx] = cat;
    } else {
      _customCategories.add(cat);
    }
    saveToPrefs();
    return true;
  }

  static bool removeCustomCategory(String id) {
    final initialLength = _customCategories.length;
    _customCategories.removeWhere((c) => c.id == id);
    if (_customCategories.length != initialLength) {
      saveToPrefs();
      return true;
    }
    return false;
  }
}
