import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/cheat_sheet_screen.dart';

class CheatSheetRepository {
  static const _userEntriesKey = 'user_cheat_entries';

  static Future<List<CheatSheetEntry>> loadAll() async {
    final entries = <CheatSheetEntry>[];

    // 1. Charger les assets JSON officiels
    for (final asset in ['assets/cheat_sheets.json', 'assets/netkit_cheat_sheets.json']) {
      try {
        final data = await rootBundle.loadString(asset);
        final decoded = json.decode(data);
        if (decoded is! List) {
          if (kDebugMode) debugPrint('Invalid format in $asset: expected List');
          continue;
        }
        for (final item in decoded) {
          if (item is! Map<String, dynamic>) continue;
          // Validation de schéma : champs obligatoires
          if (!_isValidEntry(item)) continue;
          try {
            entries.add(CheatSheetEntry.fromMap(item));
          } catch (e) {
            if (kDebugMode) debugPrint('Skipping malformed entry in $asset: $e');
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error loading cheat sheets from $asset: $e');
      }
    }

    // 2. Charger les entrées sauvegardées par l'utilisateur
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

  /// Valide qu'une entrée possède les champs obligatoires et les types attendus.
  static bool _isValidEntry(Map<String, dynamic> m) {
    final command = m['command'];
    final description = m['description'];
    if (command is! String || command.trim().isEmpty) return false;
    if (description is! String) return false;
    return true;
  }

  /// Sauvegarde une entrée "retenue" depuis un simulateur
  static Future<void> saveUserEntry({
    required String title,
    required String detail,
    required String category,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userEntriesKey);
      final list = raw != null ? json.decode(raw) as List<dynamic> : <dynamic>[];

      // Évite les doublons (même title + category)
      list.removeWhere((m) =>
          (m as Map<String, dynamic>)['command'] == title &&
          m['category'] == category);

      list.add({
        'command': title,
        'description': detail.length > 300 ? '${detail.substring(0, 297)}…' : detail,
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

  /// Supprime toutes les entrées sauvegardées par l'utilisateur
  static Future<void> clearUserEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEntriesKey);
  }
}
