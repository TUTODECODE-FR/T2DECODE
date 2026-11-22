// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
//
// Cours depuis T2C Phantom (option des Réglages). Au lancement :
//  1. lit http://cours.t2c/cours.tdc.sig.json via le proxy local de T2C Phantom
//     (127.0.0.1:8080) — aucune requête vers GitHub ni Internet ;
//  2. si la version est plus récente que celle installée, télécharge cours.tdc ;
//  3. vérifie l'empreinte ET la signature Ed25519 de TUTODECODE avec la clé
//     publique intégrée ci-dessous. Un serveur, un relais ou un conteneur
//     piraté ne peut donc ni faire accepter un faux fichier, ni revenir à une
//     version plus ancienne ;
//  4. lit les cours (.tdc), les valide et les installe, puis propose de
//     redémarrer T2DECODE.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import '../navigation/nav_keys.dart';
import 'module_service.dart';
import 'storage_service.dart';
import 'tdc_parser.dart';

class PhantomCoursesService {
  /// Clé publique racine de TUTODECODE (la même que T2C Phantom).
  static const String rootPublicKeyHex =
      '985c6d08ed885e08d69611f861595b7d4d6ae7a11a0cfc4c6a7f8267fa2d984f';
  static const String sigUrl = 'http://cours.t2c/cours.tdc.sig.json';
  static const String fileUrl = 'http://cours.t2c/cours.tdc';
  static const int defaultProxyPort = 8080;
  static const String _prefix = 't2c-';
  static const String _versionFile = '.t2c-cours-version.json';
  static final RegExp _idRe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$');

  /// Appelée par main() : uniquement si l'option est active et le réseau permis.
  static Future<void> checkAtLaunch() async {
    try {
      final storage = StorageService();
      if (!await storage.getPhantomCourses() ||
          await storage.getZeroNetworkMode() ||
          await storage.getOfflineMode()) {
        return;
      }
      final r = await checkForUpdates();
      if (r != null) _askRestart(r);
    } catch (e) {
      debugPrint('Cours T2C Phantom : $e');
    }
  }

  /// Installe la nouvelle version vérifiée ; null si rien de nouveau.
  static Future<CoursUpdate?> checkForUpdates(
      {int proxyPort = defaultProxyPort}) async {
    final client = HttpClient()
      ..findProxy = ((_) => 'PROXY 127.0.0.1:$proxyPort')
      ..connectionTimeout = const Duration(seconds: 3);
    try {
      final sig = json.decode(
          utf8.decode(await _get(client, Uri.parse(sigUrl), 64 << 10)));
      if (sig is! Map) return null;
      final sha = sig['sha256'], size = sig['size'], issued = sig['issued'];
      final sigHex = sig['sig'];
      if (sha is! String || size is! int || issued is! int || sigHex is! String) {
        return null;
      }
      final modules = ModuleService();
      final dir = await modules.getModulesDirectory();
      final current = await _installedVersion(dir);
      if (issued <= current) return null; // déjà à jour, ou retour arrière refusé
      if (size <= 0 || size > (16 << 20)) return null;

      final data = await _get(client, Uri.parse(fileUrl), size);
      final digest = await Sha256().hash(data);
      if (data.length != size || _hex(digest.bytes) != sha.toLowerCase()) {
        throw const FormatException('cours.tdc différent de celui signé');
      }
      final msg = utf8.encode('t2c/cours/v1\n$sha\n$size\n$issued');
      final ok = await Ed25519().verify(msg,
          signature: Signature(_unhex(sigHex),
              publicKey: SimplePublicKey(_unhex(rootPublicKeyHex),
                  type: KeyPairType.ed25519)));
      if (!ok) throw const FormatException('signature TUTODECODE invalide');

      final courses = parseTdcCourses(utf8.decode(data));
      final keep = <String>{};
      var changed = 0;
      for (final c in courses) {
        final id = c['id'];
        if (id is! String || !_idRe.hasMatch(id)) continue;
        final content = json.encode(c);
        if (modules.validateModuleJson(content) != null) continue;
        final fileName = '$_prefix$id.json';
        keep.add(fileName);
        final version = 't2c:${_hex((await Sha256().hash(utf8.encode(content))).bytes)}';
        if (await modules.getSavedSha(fileName) == version) continue;
        await modules.saveModule(fileName, content, version);
        changed++;
      }
      // cours retirés du fichier : retirés de l'application
      for (final f in dir.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.startsWith(_prefix) && name.endsWith('.json') && !keep.contains(name)) {
          await f.delete();
          changed++;
        }
      }
      await File('${dir.path}/$_versionFile')
          .writeAsString(json.encode({'issued': issued, 'sha256': sha}));
      return CoursUpdate(keep.length, changed, DateTime.fromMillisecondsSinceEpoch(issued * 1000));
    } on SocketException {
      return null; // T2C Phantom non lancé : rien à faire
    } on TimeoutException {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<int> _installedVersion(Directory dir) async {
    try {
      final v = json.decode(await File('${dir.path}/$_versionFile').readAsString());
      return v is Map && v['issued'] is int ? v['issued'] as int : 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<List<int>> _get(HttpClient client, Uri uri, int max) async {
    final req = await client.getUrl(uri).timeout(const Duration(seconds: 10));
    final resp = await req.close().timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      await resp.drain<void>();
      throw HttpException('HTTP ${resp.statusCode}', uri: uri);
    }
    final out = <int>[];
    await for (final chunk in resp.timeout(const Duration(seconds: 60))) {
      out.addAll(chunk);
      if (out.length > max) throw const HttpException('réponse trop volumineuse');
    }
    return out;
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  static List<int> _unhex(String s) {
    if (s.length.isOdd) throw const FormatException('hex');
    return [for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)];
  }

  static void _askRestart(CoursUpdate u) {
    void show() {
      final ctx = AppNavigator.context;
      if (ctx == null) return;
      final d = '${u.version.day.toString().padLeft(2, '0')}/${u.version.month.toString().padLeft(2, '0')}/${u.version.year}';
      showDialog<void>(
        context: ctx,
        builder: (c) => AlertDialog(
          title: const Text('Nouvelle version des cours'),
          content: Text(
              'La version du $d de cours.tdc a été reçue par T2C Phantom et sa signature TUTODECODE vérifiée (${u.total} cours).\n\nRedémarre T2DECODE pour l\'utiliser.'),
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

    if (AppNavigator.context != null) {
      show();
    } else {
      Future.delayed(const Duration(seconds: 2), show);
    }
  }
}

class CoursUpdate {
  final int total;
  final int changed;
  final DateTime version;
  CoursUpdate(this.total, this.changed, this.version);
}
