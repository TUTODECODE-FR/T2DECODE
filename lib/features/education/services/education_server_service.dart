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

  factory StudentSubmission.fromJson(Map<String, dynamic> json) =>
      StudentSubmission(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        studentName: json['studentName'] ?? 'Élève anonyme',
        studentIp: json['studentIp'] ?? '127.0.0.1',
        courseTitle: json['courseTitle'] ?? 'QCM',
        score: (json['score'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 10,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        cheatAlert: json['cheatAlert'] as bool? ?? false,
        cheatReason: json['cheatReason']?.toString() ?? '',
      );
}

class EducationServerService {
  HttpServer? _server;
  final List<StudentSubmission> _submissions = [];
  final StreamController<StudentSubmission> _submissionController =
      StreamController.broadcast();
  final List<Map<String, dynamic>> _publishedCourses = [];

  Stream<StudentSubmission> get onSubmission => _submissionController.stream;
  List<StudentSubmission> get submissions => List.unmodifiable(_submissions);
  List<Map<String, dynamic>> get publishedCourses =>
      List.unmodifiable(_publishedCourses);
  bool get isRunning => _server != null;

  /// Obtient les adresses IP locales de la machine
  static Future<List<String>> getLocalIpAddresses() async {
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            ips.add(addr.address);
          }
        }
      }
    } catch (_) {}
    if (ips.isEmpty) ips.add('127.0.0.1');
    return ips;
  }

  /// Démarre le serveur local HTTP pour la classe
  Future<bool> startServer({int port = 8080}) async {
    if (_server != null) return true;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server!.listen(_handleRequest);
      return true;
    } catch (e) {
      _server = null;
      return false;
    }
  }

  /// Arrête le serveur HTTP
  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// Publie un cours généré sur le serveur local
  void publishCourse(Map<String, dynamic> courseJson) {
    _publishedCourses.removeWhere((c) => c['id'] == courseJson['id']);
    _publishedCourses.add(courseJson);
  }

  /// Efface les soumissions enregistrées
  void clearSubmissions() {
    _submissions.clear();
  }

  void _handleRequest(HttpRequest request) async {
    // CORS headers pour autoriser le réseau LAN
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers
        .add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers
        .add('Access-Control-Allow-Headers', 'Content-Type');

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
        'role': 'T2DECODE Educator Server',
        'coursesCount': _publishedCourses.length,
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
        _submissionController.add(sub);

        _jsonResponse(request, {
          'success': true,
          'message': 'Note enregistrée avec succès par le Professeur.'
        });
      } catch (e) {
        _jsonResponse(request, {'success': false, 'error': e.toString()},
            status: HttpStatus.badRequest);
      }
    } else {
      _jsonResponse(request, {'error': 'Endpoint introuvable'},
          status: HttpStatus.notFound);
    }
  }

  void _jsonResponse(HttpRequest request, dynamic data,
      {int status = HttpStatus.ok}) {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(data));
    request.response.close();
  }

  /// Méthode client statique pour envoyer une note au professeur
  static Future<Map<String, dynamic>> sendScoreToTeacher({
    required String teacherIp,
    int port = 8080,
    required String studentName,
    required String courseTitle,
    required int score,
    required int total,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final cleanIp = teacherIp
          .replaceAll('http://', '')
          .replaceAll('https://', '')
          .split(':')[0]
          .trim();
      final uri = Uri.parse('http://$cleanIp:$port/api/submit-score');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'studentName': studentName,
        'courseTitle': courseTitle,
        'score': score,
        'total': total,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      final response = await request.close();
      final resBody = await response.transform(utf8.decoder).join();
      return jsonDecode(resBody) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'error': 'Impossible de joindre le serveur du Professeur ($e)'
      };
    } finally {
      client.close();
    }
  }

  void dispose() {
    stopServer();
    _submissionController.close();
  }
}
