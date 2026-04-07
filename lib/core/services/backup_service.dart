import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './storage_service.dart';
import '../security/ollama_host.dart';

class BackupService {
  static const int formatVersion = 1;
  // OWASP 2024 recommande 600 000 itérations minimum pour PBKDF2-HMAC-SHA256.
  static const int _pbkdf2Iterations = 600000;
  static const int _maxBackupBytes = 10 * 1024 * 1024;
  static const int _minPbkdf2Iterations = 600000;
  static const int _maxPbkdf2Iterations = 600000;

  static const int _saltBytes = 16;
  static const int _nonceBytes = 12;
  static const int _macBytes = 16;

  static const String _fileMagic = 'TDCB';

  final StorageService _storage = StorageService();

  Future<Uint8List> exportEncrypted({
    required String password,
  }) async {
    final payload = await _buildPayload();
    final plaintext = utf8.encode(jsonEncode(payload));

    final salt = _randomBytes(_saltBytes);
    final nonce = _randomBytes(_nonceBytes);
    final secretKey = await _deriveKey(password: password, salt: salt, iterations: _pbkdf2Iterations);

    final algorithm = AesGcm.with256bits();
    final box = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    final header = <String, dynamic>{
      'magic': _fileMagic,
      'v': formatVersion,
      'alg': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iter': _pbkdf2Iterations,
      'salt_b64': base64Encode(salt),
      'nonce_b64': base64Encode(nonce),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    final fileJson = jsonEncode(<String, dynamic>{
      'header': header,
      'ciphertext_b64': base64Encode(box.cipherText),
      'mac_b64': base64Encode(box.mac.bytes),
    });

    return Uint8List.fromList(utf8.encode(fileJson));
  }

  Future<void> importEncrypted({
    required Uint8List bytes,
    required String password,
  }) async {
    if (bytes.isEmpty || bytes.length > _maxBackupBytes) {
      throw Exception('Fichier de sauvegarde invalide');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw Exception('Fichier de sauvegarde invalide');
    }
    if (decoded is! Map) throw Exception('Fichier de sauvegarde invalide');

    final header = decoded['header'];
    if (header is! Map) throw Exception('Fichier de sauvegarde invalide');
    if (header['magic'] != _fileMagic) throw Exception('Fichier de sauvegarde invalide');
    if (header['v'] != formatVersion) throw Exception('Version de sauvegarde non supportée');

    final salt = _decodeBase64Field(header, 'salt_b64', expectedLength: _saltBytes);
    final nonce = _decodeBase64Field(header, 'nonce_b64', expectedLength: _nonceBytes);
    final iter = int.tryParse(header['iter']?.toString() ?? '') ?? _pbkdf2Iterations;
    if (iter < _minPbkdf2Iterations || iter > _maxPbkdf2Iterations) {
      throw Exception('Paramètres de chiffrement invalides');
    }

    final cipherText = _decodeBase64Field(decoded, 'ciphertext_b64', maxLength: _maxBackupBytes);
    if (cipherText.isEmpty) throw Exception('Contenu de sauvegarde invalide');
    final macBytes = _decodeBase64Field(decoded, 'mac_b64', expectedLength: _macBytes);
    final secretKey = await _deriveKey(password: password, salt: salt, iterations: iter);

    final algorithm = AesGcm.with256bits();
    late final List<int> clear;
    try {
      clear = await algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
        secretKey: secretKey,
      );
    } catch (_) {
      throw Exception('Mot de passe incorrect ou sauvegarde corrompue');
    }

    dynamic payload;
    try {
      payload = jsonDecode(utf8.decode(clear));
    } catch (_) {
      throw Exception('Contenu de sauvegarde invalide');
    }
    if (payload is! Map) throw Exception('Contenu de sauvegarde invalide');

    await _applyPayload(payload);
  }

  List<int> _decodeBase64Field(
    Map source,
    String key, {
    int? expectedLength,
    int? maxLength,
  }) {
    final raw = source[key]?.toString() ?? '';
    if (raw.isEmpty) throw Exception('Fichier de sauvegarde invalide');
    late final List<int> decoded;
    try {
      decoded = base64Decode(raw);
    } catch (_) {
      throw Exception('Fichier de sauvegarde invalide');
    }
    if (expectedLength != null && decoded.length != expectedLength) {
      throw Exception('Fichier de sauvegarde invalide');
    }
    if (maxLength != null && decoded.length > maxLength) {
      throw Exception('Fichier de sauvegarde invalide');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final completed = await _storage.loadCompleted();

    final settings = <String, dynamic>{
      'offlineMode': await _storage.getOfflineMode(),
      'zeroNetworkMode': await _storage.getZeroNetworkMode(),
      'securityUpdates': await _storage.getSecurityUpdates(),
      'contentUpdates': await _storage.getContentUpdates(),
      'ollamaHost': await _storage.getOllamaHost(),
      'ollamaModel': await _storage.getOllamaModel(),
      'tutorPersonality': await _storage.getTutorPersonality(),
      'terminalFontSize': await _storage.getTerminalFontSize(),
      'terminalTheme': await _storage.getTerminalTheme(),
      'appTheme': await _storage.getAppTheme(),
    };

    final search = <String, dynamic>{
      'favorites': await _storage.getSearchFavorites(),
      'history': await _storage.getSearchHistory(),
    };

    final tools = <String, dynamic>{
      'permissions': await _storage.getToolPermissions(),
    };

    return <String, dynamic>{
      'v': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'completed': completed,
      'settings': settings,
      'search': search,
      'tools': tools,
    };
  }

  Future<void> _applyPayload(Map payload) async {
    final settings = payload['settings'];
    if (settings is Map) {
      await _storage.setOfflineMode(settings['offlineMode'] == true);
      await _storage.setZeroNetworkMode(settings['zeroNetworkMode'] == true);
      if (settings.containsKey('securityUpdates')) {
        await _storage.setSecurityUpdates(settings['securityUpdates'] == true);
      }
      if (settings.containsKey('contentUpdates')) {
        await _storage.setContentUpdates(settings['contentUpdates'] == true);
      }
      final host = settings['ollamaHost']?.toString();
      if (host != null && host.isNotEmpty) {
        // Valider l'URL Ollama avant de l'appliquer (protection SSRF)
        try {
          final normalized = OllamaHost.normalize(host);
          await _storage.saveOllamaHost(normalized);
        } catch (_) {
          // URL invalide dans le backup — on l'ignore silencieusement
        }
      }
      final model = settings['ollamaModel']?.toString();
      if (model != null && model.isNotEmpty) {
        await _storage.setOllamaModel(model);
      }
      final personality = settings['tutorPersonality']?.toString();
      if (personality != null && personality.isNotEmpty) {
        await _storage.setTutorPersonality(personality);
      }
      final font = settings['terminalFontSize'];
      if (font is num) await _storage.setTerminalFontSize(font.toDouble());
      final termTheme = settings['terminalTheme']?.toString();
      if (termTheme != null) await _storage.setTerminalTheme(termTheme);
      final appTheme = settings['appTheme']?.toString();
      if (appTheme != null) await _storage.setAppTheme(appTheme);
    }

    final completed = payload['completed'];
    if (completed is List) {
      await _storage.saveCompleted(completed.map((e) => e.toString()).toList());
    }

    final search = payload['search'];
    if (search is Map) {
      final fav = search['favorites'];
      if (fav is List) await _storage.setSearchFavorites(fav.map((e) => e.toString()).toList());
      final hist = search['history'];
      if (hist is List) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('search_history', hist.map((e) => e.toString()).toList());
      }
    }

    final tools = payload['tools'];
    if (tools is Map) {
      final perms = tools['permissions'];
      if (perms is Map) {
        await _storage.setToolPermissions(perms.map((k, v) => MapEntry(k.toString(), v == true)));
      }
    }
  }

  Future<SecretKey> _deriveKey({
    required String password,
    required List<int> salt,
    required int iterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  Uint8List _randomBytes(int n) {
    final r = Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = r.nextInt(256);
    }
    return out;
  }
}
