// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class StudentSubmission {
  final String id;
  final String studentName;
  final String studentIp;
  final String courseTitle;
  final int score;
  final int total;
  final DateTime timestamp;
  final bool cheatAlert;
  final String cheatReason;

  StudentSubmission({
    required this.id,
    required this.studentName,
    required this.studentIp,
    required this.courseTitle,
    required this.score,
    required this.total,
    required this.timestamp,
    this.cheatAlert = false,
    this.cheatReason = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentName': studentName,
        'studentIp': studentIp,
        'courseTitle': courseTitle,
        'score': score,
        'total': total,
        'timestamp': timestamp.toIso8601String(),
        'cheatAlert': cheatAlert,
        'cheatReason': cheatReason,
      };

  factory StudentSubmission.fromJson(Map<String, dynamic> json) => StudentSubmission(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        studentName: json['studentName'] ?? 'Élève anonyme',
        studentIp: json['studentIp'] ?? '127.0.0.1',
        courseTitle: json['courseTitle'] ?? 'Évaluation',
        score: (json['score'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 20,
        timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
        cheatAlert: json['cheatAlert'] as bool? ?? false,
        cheatReason: json['cheatReason']?.toString() ?? '',
      );
}

class ProfServerService {
  HttpServer? _server;
  final List<StudentSubmission> _submissions = [];
  final StreamController<StudentSubmission> _submissionController = StreamController.broadcast();
  final List<Map<String, dynamic>> _publishedCourses = [];

  Stream<StudentSubmission> get onSubmission => _submissionController.stream;
  List<StudentSubmission> get submissions => List.unmodifiable(_submissions);
  List<Map<String, dynamic>> get publishedCourses => List.unmodifiable(_publishedCourses);
  bool get isRunning => _server != null;

  static Future<List<String>> getLocalIpAddresses() async {
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) ips.add(addr.address);
        }
      }
    } catch (_) {}
    if (ips.isEmpty) ips.add('127.0.0.1');
    return ips;
  }

  /// Démarre le serveur local HTTP Professeur
  Future<bool> startServer({int port = 8080}) async {
    if (_server != null) return true;
    try {
      await _loadPersistentSubmissions();
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server!.listen(_handleRequest);
      return true;
    } catch (e) {
      _server = null;
      return false;
    }
  }

  /// Arrête le serveur
  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  void publishCourse(Map<String, dynamic> courseJson) {
    _publishedCourses.removeWhere((c) => c['id'] == courseJson['id']);
    _publishedCourses.add(courseJson);
  }

  void clearSubmissions() {
    _submissions.clear();
    _savePersistentSubmissions();
  }

  void _handleRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'Inconnu';

    if (path == '/api/status' && request.method == 'GET') {
      _jsonResponse(request, {
        'status': 'online',
        'role': 'T2DECODE PROF LMS Server',
        'version': '1.0.2.21',
        'publishedCourses': _publishedCourses.length,
        'submissionsCount': _submissions.length,
      });
    } else if (path == '/api/courses' && request.method == 'GET') {
      _jsonResponse(request, _publishedCourses);
    } else if (path == '/api/submit-score' && request.method == 'POST') {
      try {
        final bodyStr = await utf8.decoder.bind(request).join();
        final json = jsonDecode(bodyStr) as Map<String, dynamic>;
        json['studentIp'] = clientIp;

        final sub = StudentSubmission.fromJson(json);
        _submissions.insert(0, sub);
        _savePersistentSubmissions();
        _submissionController.add(sub);

        _jsonResponse(request, {
          'success': true,
          'message': 'Copie déchiffrée et enregistrée avec succès par T2DECODE PROF.',
        });
      } catch (e) {
        _jsonResponse(request, {'success': false, 'error': e.toString()}, status: HttpStatus.badRequest);
      }
    } else {
      _jsonResponse(request, {'error': 'Endpoint non reconnu'}, status: HttpStatus.notFound);
    }
  }

  void _jsonResponse(HttpRequest request, dynamic data, {int status = HttpStatus.ok}) {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(data));
    request.response.close();
  }

  // ── Persistance locale crash-proof ─────────────────────────────────────────
  static Future<File> get _storageFile async {
    final dir = Directory.systemTemp;
    return File('${dir.path}/.t2decode_prof_grades.json');
  }

  Future<void> _savePersistentSubmissions() async {
    try {
      final file = await _storageFile;
      final jsonList = _submissions.map((s) => s.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _loadPersistentSubmissions() async {
    try {
      final file = await _storageFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List;
        _submissions.clear();
        _submissions.addAll(list.map((e) => StudentSubmission.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {}
  }

  /// Export universel Pronote / ENT (.CSV séparé par des points-virgules)
  String exportPronoteCsv() {
    final buffer = StringBuffer();
    // En-tête officiel Pronote / LMS
    buffer.write('Nom;Prénom;Note/20;Total;Pourcentage;Statut Anti-Triche;Date\n');
    for (final s in _submissions) {
      final nameParts = s.studentName.trim().split(' ');
      final nom = nameParts.first;
      final prenom = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Élève';
      final note20 = (s.score / s.total * 20).toStringAsFixed(2);
      final pct = (s.score / s.total * 100).toStringAsFixed(1);
      final cheatText = s.cheatAlert ? '⚠️ ALERTE TRICHE (${s.cheatReason})' : '✅ Valide';
      final dateStr = '${s.timestamp.day.toString().padLeft(2, '0')}/${s.timestamp.month.toString().padLeft(2, '0')}/${s.timestamp.year} ${s.timestamp.hour}:${s.timestamp.minute}';

      buffer.write('$nom;$prenom;$note20;${s.total};$pct%;$cheatText;$dateStr\n');
    }
    return buffer.toString();
  }

  void dispose() {
    stopServer();
    _submissionController.close();
  }
}
