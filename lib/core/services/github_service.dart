import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import './module_service.dart';
import './storage_service.dart';

class GithubService {
  final String repoOwner = 'TUTODECODE-FR';
  final String repoName = 'T2DECODE';
  final String modulesPath = 'modules'; // Folder in the repo containing .json files
  final ModuleService _moduleService = ModuleService();

  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxModuleBytes = 5 * 1024 * 1024; // 5 MB
  static const int _maxModulesListed = 200;
  
  // PINNING: Utiliser un tag stable plutôt que 'main' pour le contenu distant
  static const String _repoRef = 'v1.0.3'; 

  static const String officialRepoUrl = 'https://github.com/TUTODECODE-FR/T2DECODE';

  /// Fetches the list of files in the modules directory and downloads new/updated ones.
  Future<int> syncModules() async {
    int updatedCount = 0;
    try {
      await _ensureNetworkAllowed();
      final remote = await _listRemoteModules();
      for (final m in remote) {
        if (await _shouldUpdate(m.fileName, m.sha)) {
          final content = await _downloadText(m.downloadUri);
          if (!_looksLikeCourseModule(content)) continue;
          // ModuleService.saveModule() calcule et persiste automatiquement
          // le SHA-256 du contenu — intégrité vérifiée à chaque rechargement.
          await _moduleService.saveModule(m.fileName, content, m.sha);
          updatedCount++;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during GitHub sync: $e');
      }
    }
    return updatedCount;
  }

  Future<bool> _shouldUpdate(String fileName, String remoteSha) async {
    final localSha = await _moduleService.getSavedSha(fileName);
    return localSha != remoteSha;
  }

  /// Checks how many course JSON modules differ from the local cached versions.
  /// This performs a read-only check against GitHub and does not download content.
  Future<int> countAvailableModuleUpdates() async {
    try {
      await _ensureNetworkAllowed();
      final remote = await _listRemoteModules();
      var count = 0;
      for (final m in remote) {
        if (await _shouldUpdate(m.fileName, m.sha)) count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<List<ModuleUpdateInfo>> listAvailableUpdates() async {
    await _ensureNetworkAllowed();
    final remote = await _listRemoteModules();
    final out = <ModuleUpdateInfo>[];
    for (final m in remote) {
      final localMeta = await _moduleService.getSavedMeta(m.fileName);
      final needs = await _shouldUpdate(m.fileName, m.sha);
      if (!needs) continue;
      out.add(ModuleUpdateInfo(
        fileName: m.fileName,
        remoteSha: m.sha,
        remoteSize: m.size,
        localSha: localMeta?.sha,
        localUpdatedAt: localMeta?.updatedAt,
      ));
    }
    return out;
  }

  Future<ModuleDiff> diffModule(String fileName) async {
    await _ensureNetworkAllowed();
    final remote = (await _listRemoteModules()).firstWhere((m) => m.fileName == fileName);
    final remoteContent = await _downloadText(remote.downloadUri);
    final localSha = (await _moduleService.getSavedMeta(fileName))?.sha;
    String? localContent;
    try {
      localContent = await _moduleService.readLocalModule(fileName);
    } catch (_) {}
    return ModuleDiff.fromJsonTexts(
      fileName: fileName,
      localSha: localSha,
      remoteSha: remote.sha,
      localJson: localContent,
      remoteJson: remoteContent,
    );
  }

  Future<List<_RemoteModule>> _listRemoteModules() async {
    await _ensureNetworkAllowed();
    final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/contents/$modulesPath?ref=$_repoRef');
    if (url.scheme != 'https') {
      throw Exception('GitHub API must use HTTPS');
    }

    final response = await http
        .get(
          url,
          headers: const {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'T2DECODE',
          },
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load repo contents: HTTP ${response.statusCode}');
    }

    // Sécurité: Vérification stricte du TYPE MIME de l'API GitHub
    final ct = response.headers['content-type']?.toLowerCase() ?? '';
    if (!ct.contains('application/json')) {
      throw Exception('API GitHub : Type de contenu invalide ($ct)');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) return const [];

    final List<_RemoteModule> out = [];
    for (final item in decoded) {
      if (out.length >= _maxModulesListed) break;
      if (item is! Map) continue;
      if (item['type'] != 'file') continue;

      final name = item['name']?.toString() ?? '';
      if (!name.endsWith('.json')) continue;

      final sha = item['sha']?.toString() ?? '';
      if (sha.isEmpty) continue;

      final size = (item['size'] is num) ? (item['size'] as num).toInt() : int.tryParse(item['size']?.toString() ?? '');

      final downloadUrl = item['download_url']?.toString() ?? '';
      final downloadUri = Uri.tryParse(downloadUrl);
      if (downloadUri == null) continue;
      if (!_isAllowedGitHubDownload(downloadUri)) continue;

      out.add(_RemoteModule(fileName: name, sha: sha, size: size, downloadUri: downloadUri));
    }
    return out;
  }

  bool _isAllowedGitHubDownload(Uri uri) {
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    // Hôte exact uniquement — aucun sous-domaine accepté.
    return host == 'raw.githubusercontent.com';
  }

  Future<String> _downloadText(Uri uri) async {
    await _ensureNetworkAllowed();
      final client = http.Client();
    try {
      final req = http.Request('GET', uri);
      req.headers['User-Agent'] = 'T2DECODE';
      final streamed = await client.send(req).timeout(_timeout);

      if (streamed.statusCode != 200) {
        final errBody = await streamed.stream.bytesToString();
        throw Exception('Download failed (HTTP ${streamed.statusCode}): $errBody');
      }

      // Sécurité: Vérification MIME & Charset du contenu brut
      final ct = streamed.headers['content-type']?.toLowerCase() ?? '';
      if (!ct.contains('application/json') && !ct.contains('text/plain')) { // GitHub raw peut être text/plain
        throw Exception('Contenu non autorisé : $ct');
      }
      if (!ct.contains('utf-8')) {
        // Optionnel: on peut accepter si absent, ou forcer UTF-8
        debugPrint('Warning: UTF-8 not explicit in Content-Type, forcing decode.');
      }

      final expected = streamed.contentLength;
      if (expected != null && expected > _maxModuleBytes) {
        throw Exception('Module too large ($expected bytes)');
      }

      final bytes = await _readBytesWithLimit(streamed, _maxModuleBytes);
      return utf8.decode(bytes);
    } finally {
      client.close();
    }
  }

  Future<Uint8List> _readBytesWithLimit(http.StreamedResponse response, int limit) async {
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in response.stream) {
      total += chunk.length;
      if (total > limit) {
        throw Exception('Module too large (>$limit bytes)');
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  bool _looksLikeCourseModule(String content) {
    try {
      final decoded = json.decode(content);
      if (decoded is! Map) return false;
      final id = decoded['id'];
      final title = decoded['title'];
      final chapters = decoded['content'];
      if (id is! String || id.trim().isEmpty) return false;
      if (title is! String || title.trim().isEmpty) return false;
      if (chapters is! List) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureNetworkAllowed() async {
    final storage = StorageService();
    if (await storage.getZeroNetworkMode()) {
      throw Exception('Réseau désactivé (mode zéro réseau)');
    }
    if (await storage.getOfflineMode()) {
      throw Exception('Mode hors-ligne activé');
    }
  }

  /// Vérifie la version actuelle de l'application sur le dépôt officiel (GitHub)
  /// L'URL est encodée en base64 (Anti-ScriptKiddie) pour éviter un simple rechercher-remplacer par un fork malveillant.
  Future<String?> fetchOfficialAppVersion() async {
    try {
      await _ensureNetworkAllowed();
      // "https://raw.githubusercontent.com/TUTODECODE-FR/T2DECODE/main/pubspec.yaml"
      final b64Url = 'aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL1RVVE9ERUNPREUtRlIvVDJERUNPREUvbWFpbi9wdWJzcGVjLnlhbWw=';
      final uri = Uri.parse(utf8.decode(base64Decode(b64Url)));
      
      final response = await http.get(
        uri,
        headers: {'Cache-Control': 'no-cache'}, // Forcer la mise à jour
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        for (final line in lines) {
          if (line.trim().startsWith('version:')) {
            return line.split(':')[1].trim();
          }
        }
      }
    } catch (_) {
      // Échoue silencieusement si pas de réseau
    }
    return null;
  }
}

class _RemoteModule {
  final String fileName;
  final String sha;
  final int? size;
  final Uri downloadUri;

  const _RemoteModule({
    required this.fileName,
    required this.sha,
    required this.size,
    required this.downloadUri,
  });
}

class ModuleUpdateInfo {
  final String fileName;
  final String remoteSha;
  final int? remoteSize;
  final String? localSha;
  final String? localUpdatedAt;

  const ModuleUpdateInfo({
    required this.fileName,
    required this.remoteSha,
    required this.remoteSize,
    required this.localSha,
    required this.localUpdatedAt,
  });
}

class ModuleDiff {
  final String fileName;
  final String? localId;
  final String? remoteId;
  final String? localTitle;
  final String? remoteTitle;
  final int? localChapters;
  final int? remoteChapters;
  final String? localSha;
  final String remoteSha;

  const ModuleDiff({
    required this.fileName,
    required this.localId,
    required this.remoteId,
    required this.localTitle,
    required this.remoteTitle,
    required this.localChapters,
    required this.remoteChapters,
    required this.localSha,
    required this.remoteSha,
  });

  static ModuleDiff fromJsonTexts({
    required String fileName,
    required String? localSha,
    required String remoteSha,
    required String? localJson,
    required String remoteJson,
  }) {
    Map<String, dynamic>? local;
    Map<String, dynamic>? remote;
    try {
      if (localJson != null) local = json.decode(localJson) as Map<String, dynamic>;
    } catch (_) {}
    try {
      remote = json.decode(remoteJson) as Map<String, dynamic>;
    } catch (_) {}

    int? chaptersCount(Map<String, dynamic>? m) {
      final c = m?['content'];
      if (c is List) return c.length;
      return null;
    }

    return ModuleDiff(
      fileName: fileName,
      localId: local?['id']?.toString(),
      remoteId: remote?['id']?.toString(),
      localTitle: local?['title']?.toString(),
      remoteTitle: remote?['title']?.toString(),
      localChapters: chaptersCount(local),
      remoteChapters: chaptersCount(remote),
      localSha: localSha,
      remoteSha: remoteSha,
    );
  }
}
