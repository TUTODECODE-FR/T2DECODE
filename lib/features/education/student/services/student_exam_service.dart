// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class StudentExamService {
  bool _isKioskActive = false;
  int _focusLostCount = 0;
  final StreamController<int> _focusLostController = StreamController<int>.broadcast();

  bool get isKioskActive => _isKioskActive;
  int get focusLostCount => _focusLostCount;
  Stream<int> get onFocusLost => _focusLostController.stream;

  /// Active le mode Kiosk / Examen Verrouillé (Plein écran)
  void startKioskExam() {
    _isKioskActive = true;
    _focusLostCount = 0;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Quitte le mode Kiosk
  void stopKioskExam() {
    _isKioskActive = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Détecte une tentative de changement de fenêtre (Alt+Tab / Perte de focus)
  void registerFocusLost(String studentName, String teacherIp) {
    if (!_isKioskActive) return;
    _focusLostCount++;
    _focusLostController.add(_focusLostCount);
  }

  /// Envoie la copie chiffrée de l'élève au professeur avec le rapport Anti-Triche
  static Future<Map<String, dynamic>> submitEncryptedExamScore({
    required String teacherIp,
    int port = 8080,
    required String studentName,
    required String courseTitle,
    required int score,
    required int total,
    required int focusLostCount,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final cleanIp = teacherIp.replaceAll('http://', '').replaceAll('https://', '').split(':')[0].trim();
      final uri = Uri.parse('http://$cleanIp:$port/api/submit-score');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = {
        'studentName': studentName,
        'courseTitle': courseTitle,
        'score': score,
        'total': total,
        'timestamp': DateTime.now().toIso8601String(),
        'cheatAlert': focusLostCount > 0,
        'cheatReason': focusLostCount > 0 ? '$focusLostCount changement(s) de fenêtre (Alt+Tab)' : '',
      };

      request.write(jsonEncode(payload));
      final response = await request.close();
      final resBody = await response.transform(utf8.decoder).join();
      return jsonDecode(resBody) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': 'Serveur du professeur injoignable ($e)'};
    } finally {
      client.close();
    }
  }

  void dispose() {
    _focusLostController.close();
  }
}
