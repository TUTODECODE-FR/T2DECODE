import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';

class ModuleService {
  static const String _moduleFolder = 'TUTODECODE_Modules';
  static const String _backupFolder = 'TUTODECODE_ModuleBackups';
  static const String _shaFile = '.module_shas.json';
  static const int _maxModuleBytes = 5 * 1024 * 1024; // 5 MB
  static const int _maxBackupsPerModule = 5;

  /// Returns the directory where external modules should be placed.
  Future<Directory> getModulesDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_moduleFolder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> getBackupsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_backupFolder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Scans the modules directory for .json files and loads them as Courses.
  Future<List<Course>> loadExternalModules() async {
    final List<Course> externalCourses = [];
    try {
      final dir = await getModulesDirectory();
      if (!await dir.exists()) return [];

      final List<FileSystemEntity> files = dir.listSync();

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final len = await file.length();
            if (len > _maxModuleBytes) {
              if (kDebugMode) {
                debugPrint('Skipping module (too large: $len bytes): ${file.path}');
              }
              continue;
            }
            final content = await file.readAsString();
            final Map<String, dynamic> data = json.decode(content);

            final fileName = file.path.split(Platform.pathSeparator).last;
            final meta = await getSavedMeta(fileName);
            if (meta != null && meta.sha256B64 != null) {
              final bytes = await file.readAsBytes();
              final actualB64 = await _sha256B64(bytes);
              if (actualB64 != meta.sha256B64) {
                if (kDebugMode) {
                  debugPrint('Skipping module (checksum mismatch): ${file.path}');
                }
                continue;
              }
            }

            // Étape de validation stricte avant parsing complet
            final validationError = _validateModuleMap(data);
            if (validationError != null) {
              if (kDebugMode) {
                debugPrint('Rejet du module ($validationError): ${file.path}');
              }
              continue;
            }
            
            final course = Course.fromMap(data);
            if (!course.keywords.contains('EXTERNAL')) {
              course.keywords.add('EXTERNAL');
            }
            
            externalCourses.add(course);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error loading module ${file.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error scanning modules directory: $e');
      }
    }
    return externalCourses;
  }

  /// Saves a module's content and its SHA hash.
  Future<void> saveModule(String fileName, String content, String sha) async {
    // Sécurité : Extraire uniquement le nom de fichier pour éviter le Path Traversal
    final safeFileName = fileName.split('/').last.split('\\').last;
    if (safeFileName.isEmpty || safeFileName == '..' || safeFileName == '.') return;

    final dir = await getModulesDirectory();
    final file = File('${dir.path}/$safeFileName');

    // Backup before overwriting.
    if (await file.exists()) {
      await _backupExisting(file, safeFileName);
    }

    await file.writeAsString(content);
    final bytes = utf8.encode(content);
    final sha256B64 = await _sha256B64(bytes);
    await _updateMeta(safeFileName, ModuleMeta(
      sha: sha,
      sha256B64: sha256B64,
      size: bytes.length,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    ));
  }

  /// Returns the saved SHA for a given module file.
  Future<String?> getSavedSha(String fileName) async {
    final meta = await getSavedMeta(fileName);
    return meta?.sha;
  }

  Future<ModuleMeta?> getSavedMeta(String fileName) async {
    final all = await _loadMetaMap();
    final v = all[fileName];
    if (v is String) {
      // Backward-compat: old format was fileName -> sha.
      return ModuleMeta(sha: v);
    }
    if (v is Map<String, dynamic>) {
      return ModuleMeta.fromMap(v);
    }
    return null;
  }

  Future<Map<String, dynamic>> _loadMetaMap() async {
    final dir = await getModulesDirectory();
    final file = File('${dir.path}/$_shaFile');
    if (await file.exists()) {
      final content = await file.readAsString();
      return json.decode(content);
    }
    return {};
  }

  Future<void> _updateMeta(String fileName, ModuleMeta meta) async {
    final shas = await _loadMetaMap();
    shas[fileName] = meta.toMap();
    final dir = await getModulesDirectory();
    final file = File('${dir.path}/$_shaFile');
    await file.writeAsString(json.encode(shas));
  }

  Future<void> _backupExisting(File existing, String safeFileName) async {
    try {
      final backupsDir = await getBackupsDirectory();
      final ts = DateTime.now().toUtc().toIso8601String().replaceAll(':', '').replaceAll('.', '');
      final backupName = '${safeFileName}_$ts.bak';
      final backupFile = File('${backupsDir.path}/$backupName');
      await existing.copy(backupFile.path);
      await _rotateBackups(safeFileName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Backup failed for $safeFileName: $e');
      }
    }
  }

  Future<void> _rotateBackups(String safeFileName) async {
    final backupsDir = await getBackupsDirectory();
    final files = backupsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.split(Platform.pathSeparator).last.startsWith('${safeFileName}_'))
        .toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    if (files.length <= _maxBackupsPerModule) return;
    for (final f in files.skip(_maxBackupsPerModule)) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }

  Future<List<File>> listBackups(String safeFileName) async {
    final backupsDir = await getBackupsDirectory();
    final files = backupsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.split(Platform.pathSeparator).last.startsWith('${safeFileName}_'))
        .toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  Future<List<String>> listRollbackCandidates() async {
    final modulesDir = await getModulesDirectory();
    final moduleFiles = modulesDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.path.split(Platform.pathSeparator).last)
        .toList();
    final out = <String>[];
    for (final name in moduleFiles) {
      final backups = await listBackups(name);
      if (backups.isNotEmpty) out.add(name);
    }
    out.sort();
    return out;
  }

  Future<bool> rollbackLatest(String safeFileName) async {
    final backups = await listBackups(safeFileName);
    if (backups.isEmpty) return false;
    final dir = await getModulesDirectory();
    final target = File('${dir.path}/$safeFileName');
    await backups.first.copy(target.path);
    return true;
  }

  Future<String> readLocalModule(String safeFileName) async {
    final dir = await getModulesDirectory();
    final file = File('${dir.path}/${safeFileName.split('/').last.split('\\').last}');
    return file.readAsString();
  }

  Future<void> deleteModule(String fileName) async {
    final safeFileName = fileName.split('/').last.split('\\').last;
    final dir = await getModulesDirectory();
    final file = File('${dir.path}/$safeFileName');
    if (await file.exists()) {
      await file.delete();
    }
    
    // Clean up meta
    final meta = await _loadMetaMap();
    if (meta.containsKey(safeFileName)) {
      meta.remove(safeFileName);
      final metaFile = File('${dir.path}/$_shaFile');
      await metaFile.writeAsString(json.encode(meta));
    }
  }

  Future<String> _sha256B64(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return base64Encode(hash.bytes);
  }

  /// Validation stricte de la structure du module JSON.
  String? _validateModuleMap(Map<String, dynamic> m) {
    // 1. Champs obligatoires au niveau racine
    final requiredFields = ['id', 'title', 'description', 'category', 'content'];
    for (final f in requiredFields) {
      if (m[f] == null) return 'Champ manquant: $f';
    }

    // 2. Types et tailles (Défense contre les débordements mémoire / UI)
    if (m['id'] is! String || (m['id'] as String).length > 64) return 'ID invalide ou trop long';
    if (m['title'] is! String || (m['title'] as String).length > 100) return 'Titre trop long (>100)';
    if (m['description'] is! String || (m['description'] as String).length > 500) return 'Description trop longue (>500)';
    if (m['content'] is! List) return 'Le contenu doit être une liste';

    final content = m['content'] as List;
    if (content.isEmpty) return 'Contenu vide';
    if (content.length > 50) return 'Trop de chapitres (>50)';

    // 3. Validation des chapitres
    for (var i = 0; i < content.length; i++) {
      final chap = content[i];
      if (chap is! Map) return 'Chapitre $i invalide';
      if (chap['id'] == null || chap['title'] == null || chap['content'] == null) {
        return 'Chapitre $i: champs obligatoires manquants';
      }
      
      // Limiter la taille du texte par chapitre (ex: max 100KB de markdown)
      final text = chap['content']?.toString() ?? '';
      if (text.length > 102400) return 'Chapitre $i: texte trop volumineux (>100KB)';

      // Sanitarisation basique additionnelle si nécessaire (Markdown hardened plus tard)
    }

    return null; // OK
  }
}

class ModuleMeta {
  final String sha;
  final String? sha256B64;
  final int? size;
  final String? updatedAt;

  const ModuleMeta({
    required this.sha,
    this.sha256B64,
    this.size,
    this.updatedAt,
  });

  factory ModuleMeta.fromMap(Map<String, dynamic> m) {
    return ModuleMeta(
      sha: m['sha']?.toString() ?? '',
      sha256B64: m['sha256_b64']?.toString(),
      size: (m['size'] is num) ? (m['size'] as num).toInt() : int.tryParse(m['size']?.toString() ?? ''),
      updatedAt: m['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'sha': sha,
    if (sha256B64 != null) 'sha256_b64': sha256B64,
    if (size != null) 'size': size,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };
}
