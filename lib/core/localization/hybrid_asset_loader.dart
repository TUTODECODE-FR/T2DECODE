import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';

class HybridAssetLoader extends AssetLoader {
  const HybridAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    // 1. Charger la base en Français depuis les assets (Fallback)
    Map<String, dynamic> baseTranslations = {};
    try {
      final String frStr = await rootBundle.loadString('$path/fr.json');
      baseTranslations = jsonDecode(frStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[HybridAssetLoader] Impossible de charger fr.json: $e');
    }

    if (locale.languageCode == 'fr') {
      return baseTranslations;
    }

    // 2. Tenter de charger la langue cible depuis le dossier local de l'utilisateur
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final targetFile = File('${docDir.path}/T2DECODE/translations/${locale.languageCode}.json');
      
      if (await targetFile.exists()) {
        final String localStr = await targetFile.readAsString();
        final Map<String, dynamic> localTranslations = jsonDecode(localStr) as Map<String, dynamic>;
        
        // 3. Fusionner : Les clés locales écrasent les clés de base (fr.json comble les trous)
        final Map<String, dynamic> merged = Map<String, dynamic>.from(baseTranslations);
        _mergeDeep(merged, localTranslations);
        return merged;
      }
    } catch (e) {
      debugPrint('[HybridAssetLoader] Erreur de chargement pour ${locale.languageCode}: $e');
    }

    // Si pas de traduction locale, retourner le Français par défaut
    return baseTranslations;
  }

  void _mergeDeep(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (value is Map<String, dynamic> && target[key] is Map<String, dynamic>) {
        _mergeDeep(target[key] as Map<String, dynamic>, value);
      } else {
        target[key] = value;
      }
    });
  }
}
