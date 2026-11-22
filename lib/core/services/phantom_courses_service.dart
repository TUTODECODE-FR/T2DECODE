// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
//
// Cours depuis T2C Phantom : au lancement (option dans les Réglages), lit
// http://cours.t2c/index.json à travers le proxy local de T2C Phantom
// (127.0.0.1:8080). T2C Phantom vérifie la signature de TUTODECODE avant de
// servir le moindre octet ; ici on revérifie en plus l'empreinte de chaque
// module et sa structure avant de l'enregistrer dans TUTODECODE_Modules.
// Aucune requête vers GitHub ni Internet : si T2C Phantom n'est pas lancé, rien.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import '../navigation/nav_keys.dart';
import 'module_service.dart';
import 'storage_service.dart';

class PhantomCoursesService {
  static const String indexUrl = 'http://cours.t2c/index.json';
  static const int defaultProxyPort = 8080;
  static const int _maxIndexBytes = 1 << 20; // 1 Mo
  static const int _maxModuleBytes = 5 << 20; // limite de ModuleService
  static final RegExp _idRe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$');
  static final RegExp _pathRe = RegExp(r'^modules/[A-Za-z0-9_-]{1,64}\.json$');

  /// Appelée par main() : vérifie si l'option est active, puis prévient
  /// l'utilisateur qu'il faut redémarrer si de nouveaux cours sont arrivés.
  static Future<void> checkAtLaunch() async {
    try {
      final storage = StorageService();
      if (!await storage.getPhantomCourses() ||
          await storage.getZeroNetworkMode() ||
          await storage.getOfflineMode()) {
        return;
      }
      final n = await checkForUpdates();
      if (n > 0) _askRestart(n);
    } catch (e) {
      debugPrint('Cours T2C Phantom : $e');
    }
  }

  /// Télécharge les modules plus récents. Renvoie le nombre de cours mis à jour.
  static Future<int> checkForUpdates({int proxyPort = defaultProxyPort}) async {
    final client = HttpClient()
      ..findProxy = ((_) => 'PROXY 127.0.0.1:$proxyPort')
      ..connectionTimeout = const Duration(seconds: 3)
      ..idleTimeout = const Duration(seconds: 5);
    try {
      final index = json.decode(utf8.decode(
          await _get(client, Uri.parse(indexUrl), _maxIndexBytes)));
      if (index is! Map || index['courses'] is! List) return 0;
      final modules = ModuleService();
      var updated = 0;
      for (final c in index['courses'] as List) {
        if (c is! Map) continue;
        final id = c['id'], path = c['module'], sha = c['sha256'];
        if (id is! String || path is! String || sha is! String) continue;
        if (!_idRe.hasMatch(id) || !_pathRe.hasMatch(path)) continue;
        final fileName = 't2c-$id.json';
        final version = 't2c:$sha';
        if (await modules.getSavedSha(fileName) == version) continue;

        final bytes = await _get(
            client, Uri.parse('http://cours.t2c/$path'), _maxModuleBytes);
        final digest = await Sha256().hash(bytes);
        if (_hex(digest.bytes) != sha.toLowerCase()) continue; // incohérent : ignoré
        final content = utf8.decode(bytes);
        if (modules.validateModuleJson(content) != null) continue;
        await modules.saveModule(fileName, content, version);
        updated++;
      }
      return updated;
    } on SocketException {
      return 0; // T2C Phantom non lancé : rien à faire
    } on TimeoutException {
      return 0;
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<int>> _get(HttpClient client, Uri uri, int max) async {
    final req = await client.getUrl(uri).timeout(const Duration(seconds: 10));
    final resp = await req.close().timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      await resp.drain<void>();
      throw HttpException('HTTP ${resp.statusCode}', uri: uri);
    }
    final out = <int>[];
    await for (final chunk in resp.timeout(const Duration(seconds: 30))) {
      out.addAll(chunk);
      if (out.length > max) throw const HttpException('réponse trop volumineuse');
    }
    return out;
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  static void _askRestart(int n) {
    void show() {
      final ctx = AppNavigator.context;
      if (ctx == null) return;
      showDialog<void>(
        context: ctx,
        builder: (c) => AlertDialog(
          title: const Text('Nouveaux cours disponibles'),
          content: Text(n == 1
              ? 'Un cours plus récent a été reçu depuis T2C Phantom.\nRedémarre l\'application pour l\'afficher.'
              : '$n cours plus récents ont été reçus depuis T2C Phantom.\nRedémarre l\'application pour les afficher.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('Plus tard')),
            FilledButton(
                onPressed: () => exit(0),
                child: const Text('Quitter pour redémarrer')),
          ],
        ),
      );
    }

    // l'interface peut ne pas être prête si la vérification est très rapide
    if (AppNavigator.context != null) {
      show();
    } else {
      Future.delayed(const Duration(seconds: 2), show);
    }
  }
}
