import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../security/ollama_host.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storage = StorageService();

  bool _offlineMode = false;
  bool _zeroNetworkMode = false;
  bool _securityUpdates = true;
  bool _contentUpdates = true;
  String _ollamaUrl = 'http://localhost:11434';
  String _ollamaModel = 'qwen2.5:1.5b';
  String _tutorPersonality = 'Socratique';
  double _terminalFontSize = 14.0;
  String _terminalTheme = 'Dark';
  String _appTheme = 'Sombre';

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> reload() => _loadSettings();

  // Getters
  bool get offlineMode => _offlineMode;
  bool get zeroNetworkMode => _zeroNetworkMode;
  bool get securityUpdates => _securityUpdates;
  bool get contentUpdates => _contentUpdates;
  String get ollamaUrl => _ollamaUrl;
  String get ollamaModel => _ollamaModel;
  String get tutorPersonality => _tutorPersonality;
  double get terminalFontSize => _terminalFontSize;
  String get terminalTheme => _terminalTheme;
  String get appTheme => _appTheme;

  ThemeMode get themeMode {
    switch (_appTheme) {
      case 'Clair':
        return ThemeMode.light;
      case 'Sombre':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _loadSettings() async {
    _offlineMode = await _storage.getOfflineMode();
    _zeroNetworkMode = await _storage.getZeroNetworkMode();
    _securityUpdates = await _storage.getSecurityUpdates();
    _contentUpdates = await _storage.getContentUpdates();
    _ollamaUrl = await _storage.getOllamaHost();
    _ollamaModel = await _storage.getOllamaModel();
    _tutorPersonality = await _storage.getTutorPersonality();
    _terminalFontSize = await _storage.getTerminalFontSize();
    _terminalTheme = await _storage.getTerminalTheme();
    _appTheme = await _storage.getAppTheme();
    notifyListeners();
  }

  // Setters
  Future<void> setOfflineMode(bool value) async {
    _offlineMode = value;
    await _storage.setOfflineMode(value);
    notifyListeners();
  }

  Future<void> setZeroNetworkMode(bool value) async {
    _zeroNetworkMode = value;
    await _storage.setZeroNetworkMode(value);
    notifyListeners();
  }

  Future<void> setSecurityUpdates(bool value) async {
    _securityUpdates = value;
    await _storage.setSecurityUpdates(value);
    notifyListeners();
  }

  Future<void> setContentUpdates(bool value) async {
    _contentUpdates = value;
    await _storage.setContentUpdates(value);
    notifyListeners();
  }

  Future<bool> setOllamaUrl(String value) async {
    try {
      final normalized = OllamaHost.normalize(value);
      _ollamaUrl = normalized;
      await _storage.saveOllamaHost(normalized);
      notifyListeners();
      return true;
    } on FormatException {
      // URL invalide — ne pas sauvegarder, conserver l'ancienne valeur.
      return false;
    }
  }

  Future<void> setOllamaModel(String value) async {
    _ollamaModel = value;
    await _storage.setOllamaModel(value);
    notifyListeners();
  }

  Future<void> setTutorPersonality(String value) async {
    _tutorPersonality = value;
    await _storage.setTutorPersonality(value);
    notifyListeners();
  }

  Future<void> setTerminalFontSize(double value) async {
    _terminalFontSize = value;
    await _storage.setTerminalFontSize(value);
    notifyListeners();
  }

  Future<void> setTerminalTheme(String value) async {
    _terminalTheme = value;
    await _storage.setTerminalTheme(value);
    notifyListeners();
  }

  Future<void> setAppTheme(String value) async {
    _appTheme = value;
    await _storage.setAppTheme(value);
    notifyListeners();
  }

  // Actions
  Future<void> clearChatHistory() async {
    await _storage.clearChatHistory();
  }

  Future<void> resetProgress() async {
    await _storage.resetProgress();
  }
}
