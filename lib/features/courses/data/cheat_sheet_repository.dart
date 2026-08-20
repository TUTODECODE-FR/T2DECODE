// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutodecode/core/services/tdc_parser.dart';
import '../screens/cheat_sheet_screen.dart';

class CheatSheetRepository {
  static const _userEntriesKey = 'user_cheat_entries';

  static Future<List<CheatSheetEntry>> loadAll({String locale = 'fr'}) async {
    final entries = <CheatSheetEntry>[];

    if (locale != 'fr') {
      final localized = await _loadTdcAsset(
          'assets/cheat_sheets_$locale.tdc', entries);
      if (localized == 0) {
        await _loadTdcAsset('assets/cheat_sheets.tdc', entries);
      }
      final netkitLocalized = await _loadTdcAsset(
          'assets/netkit_cheat_sheets_$locale.tdc', entries);
      if (netkitLocalized == 0) {
        await _loadTdcAsset('assets/netkit_cheat_sheets.tdc', entries);
      }
    } else {
      await _loadTdcAsset('assets/cheat_sheets.tdc', entries);
      await _loadTdcAsset('assets/netkit_cheat_sheets.tdc', entries);
    }

    // User-saved entries (JSON in prefs — import .tdc modules later)
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userEntriesKey);
      if (raw != null) {
        final decoded = json.decode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map<String, dynamic>) continue;
            if (!_isValidEntry(item)) continue;
            try {
              entries.add(CheatSheetEntry.fromMap(item));
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading user cheat entries: $e');
    }

    return entries;
  }

  static Future<int> _loadTdcAsset(
      String asset, List<CheatSheetEntry> entries) async {
    try {
      final data = await rootBundle.loadString(asset);
      final maps = parseCheatSheetsSafe(data);
      if (maps.isEmpty) return 0;
      var count = 0;
      for (final item in maps) {
        if (!_isValidEntry(item)) continue;
        try {
          entries.add(CheatSheetEntry.fromMap(item));
          count++;
        } catch (e) {
          if (kDebugMode) debugPrint('Skipping malformed entry in $asset: $e');
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  static bool _isValidEntry(Map<String, dynamic> m) {
    final command = m['command'];
    final description = m['description'];
    if (command is! String || command.trim().isEmpty) return false;
    if (description is! String) return false;
    return true;
  }

  static Future<void> saveUserEntry({
    required String title,
    required String detail,
    required String category,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userEntriesKey);
      final list =
          raw != null ? json.decode(raw) as List<dynamic> : <dynamic>[];

      list.removeWhere((m) =>
          (m as Map<String, dynamic>)['command'] == title &&
          m['category'] == category);

      list.add({
        'command': title,
        'description':
            detail.length > 300 ? '${detail.substring(0, 297)}…' : detail,
        'category': '★ $category',
        'dangerLevel': 0,
        'colorHex': 'F59E0B',
        'iconName': 'bookmark',
      });

      await prefs.setString(_userEntriesKey, json.encode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving user cheat entry: $e');
    }
  }

  static Future<void> clearUserEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEntriesKey);
  }
}

