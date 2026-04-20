// ============================================================
// AI Tutor Provider — Assistant IA local pour tutoriels interactifs
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/core/security/ollama_host.dart';
import 'package:tutodecode/features/ghost_ai/service/ollama_service.dart';

class AiTutorProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  
  bool _isConnected = false;
  bool _isLoading = false;
  bool _isStreaming = false;
  bool _hasCheckedOllama = false;
  bool _checkingOllama = false;
  StreamSubscription<OllamaChunk>? _streamSub;
  String? _errorMessage;
  List<String> _availableModels = [];
  String _selectedModel = 'llama2';
  List<TutorSession> _sessions = [];
  TutorSession? _currentSession;
  List<TutorMessage> _currentMessages = [];
  
  // Tutoring state
  bool _isTutoring = false;
  TutorMode _currentMode = TutorMode.explanation;
  String? _currentTopic;
  List<String> _suggestedTopics = [];

  /// Nettoie un topic avant inclusion dans un prompt système.
  /// Supprime les caractères de contrôle, les backticks, les guillemets,
  /// les séquences de saut de ligne (vecteur d'injection via délimiteur),
  /// et limite à 120 caractères.
  static String _sanitizeTopic(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Informatique générale';
    var clean = raw
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // contrôles ASCII (incl. \n, \r)
        .replaceAll('`', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(r'\', '')
        .replaceAll('---', '') // délimiteurs markdown pouvant casser le prompt
        .replaceAll('===', '')
        .replaceAll('###', '')
        .trim();
    if (clean.isEmpty) return 'Informatique générale';
    return clean.length > 120 ? clean.substring(0, 120) : clean;
  }

  /// Valide une URL Ollama via OllamaHost.normalize().
  /// Retourne null si valide, sinon le message d'erreur.
  static String? _validateOllamaUrl(String url) {
    try {
      OllamaHost.normalize(url);
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }
  Map<String, dynamic> _userProgress = {};
  
  // Ollama connection
  String _ollamaUrl = 'http://localhost:11434';
  Timer? _connectionCheckTimer;

  // Getters
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  bool get hasCheckedOllama => _hasCheckedOllama;
  bool get isCheckingOllama => _checkingOllama;
  String? get errorMessage => _errorMessage;
  List<String> get availableModels => _availableModels;
  String get selectedModel => _selectedModel;
  List<TutorSession> get sessions => _sessions;
  TutorSession? get currentSession => _currentSession;
  List<TutorMessage> get currentMessages => _currentMessages;
  bool get isTutoring => _isTutoring;
  TutorMode get currentMode => _currentMode;
  String? get currentTopic => _currentTopic;
  List<String> get suggestedTopics => _suggestedTopics;
  Map<String, dynamic> get userProgress => _userProgress;

  AiTutorProvider() {
    _loadSettings();
    _initializeTutor();
    _startConnectionCheck();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  void stopStreaming() {
    _streamSub?.cancel();
    _streamSub = null;
    _isStreaming = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _storage.loadAiSettings();
      _ollamaUrl = settings['ollamaUrl'] ?? 'http://localhost:11434';
      _selectedModel = settings['selectedModel'] ?? 'llama2';
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement settings IA: $e');
    }
  }

  Future<void> _initializeTutor() async {
    await checkOllamaConnection();
    if (_isConnected) {
      await loadAvailableModels();
      await loadSessions();
      _generateSuggestedTopics();
    }
  }

  void _startConnectionCheck() {
    // Ping léger pour détecter rapidement un arrêt/redémarrage d'Ollama.
    // - Quand Ollama est dispo: on veut un feedback rapide (UX).
    // - Quand il est indispo: on évite une charge inutile (timeouts courts + pas de /api/tags).
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkOllamaConnection(silent: true, includeModels: false);
    });
  }

  Future<void> checkOllamaConnection({bool silent = false, bool includeModels = true}) async {
    if (_checkingOllama) return;
    _checkingOllama = true;

    final prevConnected = _isConnected;
    final prevError = _errorMessage;
    final prevModels = List<String>.from(_availableModels);
    final prevSelected = _selectedModel;

    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final status = await OllamaService.checkStatus(
        includeModels: includeModels,
        versionTimeout: silent ? const Duration(seconds: 3) : const Duration(seconds: 15),
        tagsTimeout: silent ? const Duration(seconds: 5) : const Duration(seconds: 15),
      );

      _hasCheckedOllama = true;
      _isConnected = status.running;
      if (!status.running) {
        _availableModels = const [];
        _errorMessage = status.error;
      } else {
        _errorMessage = null;
        if (includeModels) {
          _availableModels = status.models;
          if (_availableModels.isNotEmpty && !_availableModels.contains(_selectedModel)) {
            _selectedModel = _availableModels.first;
          }
        } else {
          // Si on vient de repasser en ligne, récupérer les modèles une fois.
          if (!prevConnected) {
            final full = await OllamaService.checkStatus(
              includeModels: true,
              versionTimeout: const Duration(seconds: 8),
              tagsTimeout: const Duration(seconds: 10),
            );
            if (full.running) {
              _availableModels = full.models;
              if (_availableModels.isNotEmpty && !_availableModels.contains(_selectedModel)) {
                _selectedModel = _availableModels.first;
              }
            }
          }
        }
      }
    } catch (e) {
      _hasCheckedOllama = true;
      _isConnected = false;
      _availableModels = const [];
      _errorMessage = e.toString();
    } finally {
      _checkingOllama = false;
      _isLoading = false;
    }

    final changed = prevConnected != _isConnected ||
        prevError != _errorMessage ||
        prevSelected != _selectedModel ||
        prevModels.length != _availableModels.length ||
        !_availableModels.asMap().entries.every((e) => e.value == (prevModels.length > e.key ? prevModels[e.key] : null));

    if (changed || !silent) notifyListeners();
  }

  Future<void> loadAvailableModels() async {
    // Les modèles sont déjà chargés par checkOllamaConnection via OllamaService.checkStatus()
    // Cette méthode reste pour compatibilité ascendante.
    await checkOllamaConnection();
  }

  Future<void> selectModel(String model) async {
    _selectedModel = model;
    await _storage.saveAiSettings({'ollamaUrl': _ollamaUrl, 'selectedModel': model});
    notifyListeners();
  }

  Future<void> updateOllamaUrl(String url) async {
    final error = _validateOllamaUrl(url);
    if (error != null) {
      _errorMessage = 'URL invalide : $error';
      notifyListeners();
      return;
    }
    final normalized = OllamaHost.normalize(url);
    _ollamaUrl = normalized;
    await checkOllamaConnection();
    await _storage.saveAiSettings({'ollamaUrl': normalized, 'selectedModel': _selectedModel});
    notifyListeners();
  }

  // Session management
  Future<void> loadSessions() async {
    try {
      _sessions = List<TutorSession>.from(await _storage.loadTutorSessions());
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement sessions: $e');
    }
  }

  Future<void> createNewSession(String title, String topic) async {
    try {
      final session = TutorSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        topic: topic,
        createdAt: DateTime.now(),
        messages: [],
        mode: _currentMode,
      );
      
      _sessions.insert(0, session);
      _currentSession = session;
      _currentMessages = [];
      _currentTopic = topic;
      _isTutoring = true;
      
      await _storage.saveTutorSessions(_sessions);
      
      // Envoyer le message de bienvenue
      await _sendWelcomeMessage();
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur création session: $e';
      notifyListeners();
    }
  }

  Future<void> selectSession(TutorSession session) async {
    _currentSession = session;
    _currentMessages = session.messages;
    _currentTopic = session.topic;
    _currentMode = session.mode;
    _isTutoring = true;
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_currentSession?.id == sessionId) {
        _currentSession = null;
        _currentMessages = [];
        _isTutoring = false;
      }
      await _storage.saveTutorSessions(_sessions);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur suppression session: $e';
      notifyListeners();
    }
  }

  // Tutoring methods
  Future<void> _sendWelcomeMessage() async {
    final welcomePrompt = _generateWelcomePrompt();
    await _generateAiResponse(welcomePrompt, isWelcome: true);
  }

  String _generateWelcomePrompt() {
    final topic = _sanitizeTopic(_currentTopic);
    // Le topic est isolé entre balises pour éviter l'injection de prompt.
    switch (_currentMode) {
      case TutorMode.explanation:
        return 'Tu es un tuteur technique expert pour T2CODE.\n'
            'Sujet : <TOPIC>$topic</TOPIC>\n'
            'Explique les concepts fondamentaux de manière claire et progressive.\n'
            'Sois encouraging et pose des questions pour vérifier la compréhension.\n'
            'Limite ta réponse à 200 mots maximum.';
      case TutorMode.practice:
        return 'Tu es un coach pratique pour T2CODE.\n'
            'Sujet : <TOPIC>$topic</TOPIC>\n'
            'Propose des exercices pratiques et des scénarios réels.\n'
            'Donne des instructions étape par étape.\n'
            'Sois patient et guide l\'utilisateur à travers les erreurs.\n'
            'Limite ta réponse à 150 mots maximum.';
      case TutorMode.troubleshooting:
        return 'Tu es un expert en dépannage pour T2CODE.\n'
            'Sujet : <TOPIC>$topic</TOPIC>\n'
            'Aide à résoudre des problèmes techniques courants.\n'
            'Pose des questions diagnostiques pertinentes.\n'
            'Propose des solutions étape par étape.\n'
            'Limite ta réponse à 180 mots maximum.';
      case TutorMode.quiz:
        return 'Tu es un évaluateur pédagogique pour T2CODE.\n'
            'Sujet : <TOPIC>$topic</TOPIC>\n'
            'Crée des questions pertinentes pour évaluer les connaissances.\n'
            'Varie les types de questions (QCM, vrai/faux, ouvertes).\n'
            'Donne des feedbacks constructifs.\n'
            'Limite ta réponse à 120 mots maximum.';
    }
  }

  Future<void> sendMessage(String userMessage) async {
    if (!_isConnected || _currentSession == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Ajouter le message utilisateur
      final userMsg = TutorMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: userMessage,
        isFromUser: true,
        timestamp: DateTime.now(),
      );
      
      _currentMessages.add(userMsg);
      
      // Mettre à jour la session
      final updatedSession = _currentSession!.copyWith(
        messages: _currentMessages,
        updatedAt: DateTime.now(),
      );
      
      final sessionIndex = _sessions.indexWhere((s) => s.id == _currentSession!.id);
      if (sessionIndex != -1) {
        _sessions[sessionIndex] = updatedSession;
      }
      
      await _storage.saveTutorSessions(_sessions);
      
      // Générer la réponse IA
      await _generateAiResponse(userMessage);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur envoi message: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _generateAiResponse(String userMessage, {bool isWelcome = false}) async {
    // Préparer le message IA vide qui sera rempli token par token
    final aiMsg = TutorMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '',
      isFromUser: false,
      timestamp: DateTime.now(),
    );
    _currentMessages.add(aiMsg);
    _isStreaming = true;
    notifyListeners();

    final contextMessages = _buildContextMessages(isWelcome);
    // Séparer system prompt et historique pour OllamaService
    final systemPrompt = contextMessages.isNotEmpty && contextMessages.first['role'] == 'system'
        ? contextMessages.first['content'] ?? ''
        : '';
    final history = contextMessages
        .where((m) => m['role'] != 'system')
        .toList(growable: false);

    final buffer = StringBuffer();

    try {
      _streamSub = OllamaService.stream(_selectedModel, history, system: systemPrompt).listen(
        (chunk) {
          if (!chunk.isThinking) {
            buffer.write(chunk.text);
            final idx = _currentMessages.indexWhere((m) => m.id == aiMsg.id);
            if (idx != -1) {
              _currentMessages[idx] = TutorMessage(
                id: aiMsg.id,
                content: buffer.toString(),
                isFromUser: false,
                timestamp: aiMsg.timestamp,
              );
              notifyListeners();
            }
          }
        },
        onDone: () async {
          _isStreaming = false;
          _isLoading = false;
          _updateUserProgress();
          final updatedSession = _currentSession!.copyWith(
            messages: _currentMessages,
            updatedAt: DateTime.now(),
          );
          final sessionIndex = _sessions.indexWhere((s) => s.id == _currentSession!.id);
          if (sessionIndex != -1) _sessions[sessionIndex] = updatedSession;
          await _storage.saveTutorSessions(_sessions);
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Erreur streaming IA: $e');
          final idx = _currentMessages.indexWhere((m) => m.id == aiMsg.id);
          if (idx != -1) {
            _currentMessages[idx] = TutorMessage(
              id: aiMsg.id,
              content: buffer.isNotEmpty
                  ? buffer.toString()
                  : 'Connexion à Ollama interrompue. Vérifiez que le service tourne.',
              isFromUser: false,
              timestamp: aiMsg.timestamp,
            );
          }
          // Forcer un refresh immédiat pour que l'UI repasse en "Ollama indisponible"
          _isConnected = false;
          _errorMessage = 'Ollama indisponible (connexion interrompue)';
          checkOllamaConnection(silent: true, includeModels: false);
          _isStreaming = false;
          _isLoading = false;
          notifyListeners();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Erreur démarrage stream IA: $e');
      final idx = _currentMessages.indexWhere((m) => m.id == aiMsg.id);
      if (idx != -1) {
        _currentMessages[idx] = TutorMessage(
          id: aiMsg.id,
          content: 'Impossible de joindre Ollama.',
          isFromUser: false,
          timestamp: aiMsg.timestamp,
        );
      }
      _isStreaming = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, String>> _buildContextMessages(bool isWelcome) {
    final systemPrompt = isWelcome ? _generateWelcomePrompt() : _generateContextPrompt();
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];
    // Limiter à 10 messages pour éviter les tokens excessifs
    final recent = _currentMessages.length > 10
        ? _currentMessages.sublist(_currentMessages.length - 10)
        : _currentMessages;
    for (final msg in recent) {
      if (msg.content.isNotEmpty) {
        messages.add({'role': msg.isFromUser ? 'user' : 'assistant', 'content': msg.content});
      }
    }
    return messages;
  }

  String _generateContextPrompt() {
    final topic = _sanitizeTopic(_currentTopic);
    final basePrompt = 'Tu es un tuteur technique expert pour T2CODE, une plateforme d\'apprentissage IT 100% offline.\n\n'
        'Règles importantes:\n'
        '- Sois clair, concis et pédagogique\n'
        '- Adapte ton niveau au contexte de la conversation\n'
        '- Utilise des exemples pratiques quand possible\n'
        '- Sois encouraging et constructif\n'
        '- Évite le jargon excessif\n'
        '- Fais un effort de compréhension : reformule en 1 phrase la demande avant de répondre\n'
        '- Si la demande est ambiguë, pose 1-2 questions de clarification avant de conclure\n'
        '- Si tu n\'es pas sûr, dis-le et propose une méthode de vérification (ne pas inventer)\n'
        '- Limite tes réponses à 200 mots maximum\n\n'
        'Sujet actuel : <TOPIC>$topic</TOPIC>\n'
        'Mode : ${_currentMode.name}';

    // Ajouter le contexte des messages précédents
    if (_currentMessages.isNotEmpty) {
      final lastMessages = _currentMessages.reversed.take(4).toList().reversed.toList();
      final context = lastMessages.map((msg) => 
          '${msg.isFromUser ? "Utilisateur" : "Tuteur"}: ${msg.content}'
      ).join('\n');
      
      return '''$basePrompt\n\nContexte récent:\n$context''';
    }
    
    return basePrompt;
  }

  void _updateUserProgress() {
    // Mettre à jour les statistiques d'apprentissage
    final topicKey = _currentTopic?.toLowerCase() ?? 'general';
    final currentProgress = _userProgress[topicKey] ?? {'messages': 0, 'sessions': 0, 'lastActivity': null};
    
    _userProgress[topicKey] = {
      'messages': (currentProgress['messages'] as int? ?? 0) + 1,
      'sessions': (currentProgress['sessions'] as int? ?? 0),
      'lastActivity': DateTime.now().toIso8601String(),
    };
    
    _storage.saveUserProgress(_userProgress);
  }

  void _generateSuggestedTopics() {
    _suggestedTopics = [
      'Linux et Bash',
      'Réseaux TCP/IP',
      'Sécurité informatique',
      'Docker et conteneurs',
      'Python pour l\'admin sys',
      'Bases de données SQL',
      'Virtualisation',
      'Scripting avancé',
      'Monitoring et logs',
      'Cloud computing',
    ];
    notifyListeners();
  }

  Future<void> setTutorMode(TutorMode mode) async {
    _currentMode = mode;
    if (_currentSession != null) {
      final updatedSession = _currentSession!.copyWith(mode: mode);
      final sessionIndex = _sessions.indexWhere((s) => s.id == _currentSession!.id);
      if (sessionIndex != -1) {
        _sessions[sessionIndex] = updatedSession;
        await _storage.saveTutorSessions(_sessions);
      }
    }
    notifyListeners();
  }

  Future<void> clearCurrentSession() async {
    _currentSession = null;
    _currentMessages = [];
    _currentTopic = null;
    _isTutoring = false;
    notifyListeners();
  }

  Future<void> regenerateResponse(String messageId) async {
    if (!_isConnected || _currentSession == null) return;

    try {
      // Trouver le message et le précédent
      final messageIndex = _currentMessages.indexWhere((m) => m.id == messageId);
      if (messageIndex == -1 || messageIndex == 0) return;

      // Supprimer l'ancienne réponse IA
      _currentMessages.removeAt(messageIndex);
      
      // Récupérer le message utilisateur précédent
      final userMessage = _currentMessages[messageIndex - 1];
      
      // Régénérer la réponse
      await _generateAiResponse(userMessage.content);
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur régénération: $e';
      notifyListeners();
    }
  }

  Map<String, dynamic> getStatistics() {
    final totalSessions = _sessions.length;
    final totalMessages = _sessions.fold(0, (sum, session) => sum + session.messages.length);
    final topicsCovered = _sessions.map((s) => s.topic).toSet().length;
    final averageMessagesPerSession = totalSessions > 0 ? totalMessages / totalSessions : 0.0;
    
    return {
      'totalSessions': totalSessions,
      'totalMessages': totalMessages,
      'topicsCovered': topicsCovered,
      'averageMessagesPerSession': averageMessagesPerSession.toStringAsFixed(1),
      'mostUsedMode': _getMostUsedMode(),
      'lastActivity': _sessions.isNotEmpty ? _sessions.first.updatedAt : null,
    };
  }

  TutorMode _getMostUsedMode() {
    final modeCounts = <TutorMode, int>{};
    for (final session in _sessions) {
      modeCounts[session.mode] = (modeCounts[session.mode] ?? 0) + 1;
    }
    
    if (modeCounts.isEmpty) return TutorMode.explanation;
    
    return modeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

// Models
class TutorSession {
  final String id;
  final String title;
  final String topic;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TutorMessage> messages;
  final TutorMode mode;

  const TutorSession({
    required this.id,
    required this.title,
    required this.topic,
    required this.createdAt,
    this.updatedAt,
    required this.messages,
    required this.mode,
  });

  TutorSession copyWith({
    String? id,
    String? title,
    String? topic,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TutorMessage>? messages,
    TutorMode? mode,
  }) {
    return TutorSession(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      mode: mode ?? this.mode,
    );
  }
}

class TutorMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;

  const TutorMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
  });
}

enum TutorMode {
  explanation,
  practice,
  troubleshooting,
  quiz,
}

extension TutorModeExtension on TutorMode {
  String get displayName {
    switch (this) {
      case TutorMode.explanation: return 'Explications';
      case TutorMode.practice: return 'Pratique';
      case TutorMode.troubleshooting: return 'Dépannage';
      case TutorMode.quiz: return 'Quiz';
    }
  }

  String get description {
    switch (this) {
      case TutorMode.explanation: return 'Apprendre les concepts théoriques';
      case TutorMode.practice: return 'Exercices pratiques guidés';
      case TutorMode.troubleshooting: return 'Résolution de problèmes';
      case TutorMode.quiz: return 'Évaluer vos connaissances';
    }
  }

  IconData get icon {
    switch (this) {
      case TutorMode.explanation: return Icons.school;
      case TutorMode.practice: return Icons.build;
      case TutorMode.troubleshooting: return Icons.build_circle;
      case TutorMode.quiz: return Icons.quiz;
    }
  }

  Color get color {
    switch (this) {
      case TutorMode.explanation: return Colors.blue;
      case TutorMode.practice: return Colors.green;
      case TutorMode.troubleshooting: return Colors.orange;
      case TutorMode.quiz: return Colors.purple;
    }
  }
}
