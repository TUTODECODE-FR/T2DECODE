// Core service for local persistence (SharedPreferences).
// All features import from here — single source of truth.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../security/ollama_host.dart';
import '../../features/courses/models/gamification_models.dart';

// IMPORTANT : SharedPreferences est utilisé ici pour des préférences non-sensibles.
// Pour des secrets (mots de passe, clés d'API), utilisez flutter_secure_storage.
class StorageService {
  static const _completedKey = 'completed_chapters';
  static const _legacyOllamaHostKey = 'ollama_host';
  static const _secureOllamaHostKey = 'secure_ollama_host';

  // Network Transparency
  static const _offlineModeKey = 'offline_mode';
  static const _zeroNetworkModeKey = 'zero_network_mode';
  static const _securityUpdatesKey = 'security_updates';
  static const _contentUpdatesKey = 'content_updates';
  static const _securityLogsKey = 'security_logs';

  // Ghost AI
  static const _ollamaModelKey = 'ollama_model';
  static const _tutorPersonalityKey = 'tutor_personality';

  // Personalization
  static const _terminalFontSizeKey = 'terminal_font_size';
  static const _terminalThemeKey = 'terminal_theme';
  static const _appThemeKey = 'app_theme';

  // Backup/Snapshots
  static const _secureSnapshotKeyKey = 'secure_snapshot_key_b64';
  static const _snapshotKeyFallback = 'snapshot_key_b64_fallback';

  // Search
  static const _favoritesKey = 'search_favorites';
  static const _historyKey = 'search_history';

  // Multi-tools permissions
  static const _toolPermissionsKey = 'tool_permissions_v1';
  static const _toolFavoritesKey = 'tool_favorites_v1';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  Future<void> saveCompleted(List<String> completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedKey, completed);
  }

  Future<List<String>> loadCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedKey) ?? [];
  }

  Future<String> getOllamaHost() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = await _secure.read(key: _secureOllamaHostKey);
    if (raw == null || raw.isEmpty) {
      raw = prefs.getString(_legacyOllamaHostKey) ?? OllamaHost.defaultBaseUrl;
      // Best-effort migration to secure storage.
      try {
        await _secure.write(key: _secureOllamaHostKey, value: raw);
        await prefs.remove(_legacyOllamaHostKey);
      } catch (_) {}
    }
    try {
      return OllamaHost.normalize(raw);
    } catch (_) {
      // Défense en profondeur : si les prefs ont été modifiées (desktop / appareil compromis),
      // revenir à un host sûr.
      return OllamaHost.defaultBaseUrl;
    }
  }

  Future<void> saveOllamaHost(String host) async {
    final normalized = OllamaHost.normalize(host);
    await _secure.write(key: _secureOllamaHostKey, value: normalized);
  }

  // --- Generic Getters/Setters ---

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<String> getString(String key, {String defaultValue = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<double> getDouble(String key, {double defaultValue = 14.0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key) ?? defaultValue;
  }

  Future<void> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  // --- Specific Settings Getters/Setters ---

  Future<bool> getOfflineMode() =>
      getBool(_offlineModeKey, defaultValue: false);
  Future<void> setOfflineMode(bool value) => setBool(_offlineModeKey, value);

  Future<bool> getZeroNetworkMode() =>
      getBool(_zeroNetworkModeKey, defaultValue: false);
  Future<void> setZeroNetworkMode(bool value) =>
      setBool(_zeroNetworkModeKey, value);

  Future<bool> getSecurityUpdates() =>
      getBool(_securityUpdatesKey, defaultValue: true);
  Future<void> setSecurityUpdates(bool value) =>
      setBool(_securityUpdatesKey, value);

  Future<bool> getContentUpdates() =>
      getBool(_contentUpdatesKey, defaultValue: true);
  Future<void> setContentUpdates(bool value) =>
      setBool(_contentUpdatesKey, value);

  Future<String> getOllamaModel() =>
      getString(_ollamaModelKey, defaultValue: 'qwen2.5:1.5b');
  Future<void> setOllamaModel(String value) =>
      setString(_ollamaModelKey, value);

  Future<String> getTutorPersonality() =>
      getString(_tutorPersonalityKey, defaultValue: 'Socratique');
  Future<void> setTutorPersonality(String value) =>
      setString(_tutorPersonalityKey, value);

  Future<double> getTerminalFontSize() =>
      getDouble(_terminalFontSizeKey, defaultValue: 14.0);
  Future<void> setTerminalFontSize(double value) =>
      setDouble(_terminalFontSizeKey, value);

  Future<String> getTerminalTheme() =>
      getString(_terminalThemeKey, defaultValue: 'Dark');
  Future<void> setTerminalTheme(String value) =>
      setString(_terminalThemeKey, value);

  Future<String> getAppTheme() =>
      getString(_appThemeKey, defaultValue: 'System');
  Future<void> setAppTheme(String value) => setString(_appThemeKey, value);

  // --- Security Logs & Telemetry ---
  // Stockés dans flutter_secure_storage pour empêcher la lecture en clair.

  Future<void> addSecurityLog(String message) async {
    final raw = await _secure.read(key: _securityLogsKey);
    final logs =
        raw != null ? List<String>.from(jsonDecode(raw) as List) : <String>[];
    final timestamp = DateTime.now().toUtc().toIso8601String();
    logs.insert(0, '[$timestamp] $message');
    if (logs.length > 200)
      logs.removeRange(200, logs.length); // Limite 200 entrées
    await _secure.write(key: _securityLogsKey, value: jsonEncode(logs));
  }

  Future<List<String>> getSecurityLogs() async {
    try {
      final raw = await _secure.read(key: _securityLogsKey);
      if (raw == null || raw.isEmpty) return [];
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  // --- Search Favorites/History ---
  // Historique stocké dans flutter_secure_storage (données potentiellement sensibles).

  Future<List<String>> getSearchFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> setSearchFavorites(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, ids);
  }

  Future<List<String>> getSearchHistory() async {
    try {
      final raw = await _secure.read(key: _historyKey);
      if (raw == null || raw.isEmpty) return [];
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> pushSearchHistory(String query, {int max = 20}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    final current = await getSearchHistory();
    final list = current.where((q) => q.trim().isNotEmpty).toList();
    list.removeWhere((q) => q == normalized);
    list.insert(0, normalized);
    if (list.length > max) list.removeRange(max, list.length);
    await _secure.write(key: _historyKey, value: jsonEncode(list));
  }

  Future<void> clearSearchHistory() async {
    await _secure.delete(key: _historyKey);
  }

  // --- Multi-tools permissions ---

  Future<Map<String, bool>> getToolPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_toolPermissionsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((k, v) => MapEntry(k.toString(), v == true));
    } catch (_) {
      return {};
    }
  }

  Future<void> setToolPermissions(Map<String, bool> perms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_toolPermissionsKey, jsonEncode(perms));
  }

  // --- Toolbox favorites ---

  Future<List<String>> getToolFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_toolFavoritesKey) ?? [];
  }

  Future<void> setToolFavorites(List<String> routes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_toolFavoritesKey, routes);
  }

  // --- Snapshot key (device-local) ---

  Future<String?> getSnapshotKeyB64() async {
    try {
      final secureValue = await _secure.read(key: _secureSnapshotKeyKey);
      if (secureValue != null && secureValue.isNotEmpty) return secureValue;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_snapshotKeyFallback);
  }

  Future<void> setSnapshotKeyB64(String value) async {
    try {
      await _secure.write(key: _secureSnapshotKeyKey, value: value);
      return;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_snapshotKeyFallback, value);
  }

  // --- Reset & Cleanup ---

  Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming chat history is stored with certain keys, or we might need a separate service.
    // For now, let's clear keys that start with 'chat_history_'
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('chat_history_')) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }

  // AI Tutor Additions
  Future<Map<String, dynamic>> loadAiSettings() async {
    final url = await getOllamaHost();
    final model = await getOllamaModel();
    return {'ollamaUrl': url, 'selectedModel': model};
  }

  Future<void> saveAiSettings(Map<String, String> settings) async {
    if (settings['ollamaUrl'] != null)
      await saveOllamaHost(settings['ollamaUrl']!);
    if (settings['selectedModel'] != null)
      await setOllamaModel(settings['selectedModel']!);
  }

  Future<List<dynamic>> loadTutorSessions() async {
    return [];
  }

  Future<void> saveTutorSessions(List<dynamic> sessions) async {}
  Future<void> saveUserProgress(Map<String, dynamic> progress) async {}

  // Gamification Profile
  Future<UserProfile> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_profile_v1');
    if (raw == null || raw.isEmpty) {
      return UserProfile(
        username: 'Utilisateur',
        lastActivityDate: DateTime.now(),
      );
    }
    try {
      return UserProfile.fromJson(jsonDecode(raw));
    } catch (_) {
      return UserProfile(
        username: 'Utilisateur',
        lastActivityDate: DateTime.now(),
      );
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_v1', jsonEncode(profile.toJson()));
  }
}
