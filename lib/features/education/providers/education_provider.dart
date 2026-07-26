// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tutodecode/features/education/services/education_server_service.dart';
import 'package:tutodecode/features/ghost_ai/service/ollama_service.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';

class EducationProvider extends ChangeNotifier {
  final EducationServerService _serverService = EducationServerService();
  StreamSubscription<StudentSubmission>? _subSubscription;

  bool _isGenerating = false;
  String _generationStatus = '';
  List<String> _localIps = [];
  int _port = 8080;

  // Modèle Ollama actuellement sélectionné
  String _selectedModel = 'phi3';

  // Cours généré par Ghost AI
  Map<String, dynamic>? _lastGeneratedCourse;
  List<QuizQuestion> _lastGeneratedQuiz = [];

  EducationProvider() {
    _initIps();
    _subSubscription = _serverService.onSubmission.listen((_) {
      notifyListeners();
    });
  }

  bool get isServerRunning => _serverService.isRunning;
  List<String> get localIps => _localIps;
  int get port => _port;
  List<StudentSubmission> get submissions => _serverService.submissions;
  List<Map<String, dynamic>> get publishedCourses => _serverService.publishedCourses;

  bool get isGenerating => _isGenerating;
  String get generationStatus => _generationStatus;
  String get selectedModel => _selectedModel;
  Map<String, dynamic>? get lastGeneratedCourse => _lastGeneratedCourse;
  List<QuizQuestion> get lastGeneratedQuiz => _lastGeneratedQuiz;

  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  Future<void> _initIps() async {
    _localIps = await EducationServerService.getLocalIpAddresses();
    notifyListeners();
  }

  Future<bool> toggleServer({int port = 8080}) async {
    _port = port;
    if (_serverService.isRunning) {
      await _serverService.stopServer();
    } else {
      await _serverService.startServer(port: port);
      await _initIps();
    }
    notifyListeners();
    return _serverService.isRunning;
  }

  void clearSubmissions() {
    _serverService.clearSubmissions();
    notifyListeners();
  }

  /// Génère un cours et son QCM automatiquement avec Ghost AI
  Future<bool> generateCourseWithAI({
    required String topic,
    required String level,
  }) async {
    _isGenerating = true;
    _generationStatus = 'Génération de la structure du cours avec Ghost AI...';
    notifyListeners();

    try {
      final promptMessages = [
        {
          'role': 'system',
          'content': '''Tu es un Professeur expert en informatique et cybersécurité. 
Rédige un cours complet au format JSON STRICT pour une classe de niveau $level.
Format JSON attendu :
{
  "id": "course-${DateTime.now().millisecondsSinceEpoch}",
  "title": "Titre explicite",
  "description": "Courte description pédagogique du cours",
  "chapters": [
    {
      "id": "chap-1",
      "title": "Chapitre 1: Introduction",
      "content": "Contenu détaillé du chapitre en Markdown..."
    },
    {
      "id": "chap-2",
      "title": "Chapitre 2: Approfondissement",
      "content": "Contenu détaillé du chapitre en Markdown..."
    }
  ]
}
Ne renvoie RIEN d'autre que du JSON valide.''',
        },
        {
          'role': 'user',
          'content': 'Sujet du cours à générer : $topic',
        }
      ];

      String fullRes = '';
      await for (final chunk in OllamaService.stream(_selectedModel, promptMessages)) {
        if (!chunk.isThinking) {
          fullRes += chunk.text;
        }
      }

      String jsonStr = fullRes.trim();
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
      }

      // 2. Générer le QCM associé
      _generationStatus = 'Génération du QCM d\'évaluation automatique...';
      notifyListeners();

      final quizList = await OllamaService.generateQcm(_selectedModel, topic);

      _lastGeneratedCourse = {
        'id': 'generated-${DateTime.now().millisecondsSinceEpoch}',
        'title': topic,
        'description': 'Cours généré par Ghost AI pour la classe.',
        'content': fullRes,
        'jsonStr': jsonStr,
      };
      _lastGeneratedQuiz = quizList ?? [];

      // Publier le cours sur le serveur local
      _serverService.publishCourse(_lastGeneratedCourse!);

      _isGenerating = false;
      _generationStatus = 'Génération terminée avec succès !';
      notifyListeners();
      return true;
    } catch (e) {
      _isGenerating = false;
      _generationStatus = 'Erreur lors de la génération : ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Exporte les notes d'évaluation au format CSV
  String exportSubmissionsCsv() {
    final buffer = StringBuffer();
    buffer.writestring('ID,Nom Élève,IP,Cours,Note,Total,Pourcentage,Date\n');
    for (final s in submissions) {
      final pct = (s.score / s.total * 100).toStringAsFixed(1);
      final dateStr = s.timestamp.toIso8601String();
      buffer.writestring('"${s.id}","${s.studentName}","${s.studentIp}","${s.courseTitle}",${s.score},${s.total},"$pct%","$dateStr"\n');
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _subSubscription?.cancel();
    _serverService.dispose();
    super.dispose();
  }
}

extension on StringBuffer {
  void writestring(String s) => write(s);
}
