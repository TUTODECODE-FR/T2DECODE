import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tutodecode/core/services/phantom_cache_service.dart';
import 'package:tutodecode/core/security/phantom_trust_validator.dart';

import 'package:tutodecode/core/services/storage_service.dart';

class PhantomProvider extends ChangeNotifier {
  final PhantomCacheService _phantomService = PhantomCacheService(PhantomTrustValidator());
  
  bool _isRunning = false;
  bool _hasChecked = false;
  Timer? _pollingTimer;

  bool get isRunning => _isRunning;
  bool get hasChecked => _hasChecked;
  String get activePath => _phantomService.activeCachePath;
  String get defaultPath => _phantomService.defaultCachePath;
  bool get hasCustomPath => _phantomService.customCachePath != null;

  PhantomProvider() {
    _initCheck();
    // Vérification périodique toutes les 5 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkPhantomStatus());
  }

  Future<void> _initCheck() async {
    final customPath = await StorageService().getString('phantom_cache_path');
    if (customPath.isNotEmpty) {
      _phantomService.customCachePath = customPath;
    }
    await _checkPhantomStatus();
  }

  Future<void> updateCustomPath(String? newPath) async {
    if (newPath == null || newPath.trim().isEmpty) {
      _phantomService.customCachePath = null;
      await StorageService().setString('phantom_cache_path', '');
    } else {
      _phantomService.customCachePath = newPath;
      await StorageService().setString('phantom_cache_path', newPath);
    }
    _hasChecked = false;
    await _checkPhantomStatus();
  }

  Future<void> _checkPhantomStatus() async {
    try {
      final dir = Directory(_phantomService.activeCachePath);
      final exists = await dir.exists();
      
      if (_isRunning != exists || !_hasChecked) {
        _isRunning = exists;
        _hasChecked = true;
        notifyListeners();
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement pour ne pas spammer la console
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
