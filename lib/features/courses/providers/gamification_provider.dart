// ============================================================
// Gamification Provider — Gestion de la progression avancée
// ============================================================
import 'package:flutter/material.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/features/courses/models/gamification_models.dart';

class GamificationProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  
  UserProfile _profile = UserProfile(
    username: 'Utilisateur',
    lastActivityDate: DateTime.now(),
  );
  
  List<Achievement> _allAchievements = [];
  List<SkillTree> _skillTrees = [];
  List<Challenge> _availableChallenges = [];
  List<LearningPath> _learningPaths = [];
  List<LeaderboardEntry> _leaderboard = [];
  
  bool _loaded = false;

  // Getters
  UserProfile get profile => _profile;
  List<Achievement> get allAchievements => _allAchievements;
  List<SkillTree> get skillTrees => _skillTrees;
  List<Challenge> get availableChallenges => _availableChallenges;
  List<LearningPath> get learningPaths => _learningPaths;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get loaded => _loaded;

  List<Achievement> get unlockedAchievements => 
      _allAchievements.where((a) => a.isUnlocked).toList();
  
  List<Achievement> get availableAchievements => 
      _allAchievements.where((a) => !a.isUnlocked).toList();
  
  List<Achievement> get inProgressAchievements => 
      _allAchievements.where((a) => a.isInProgress).toList();

  GamificationProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      _loaded = false;
      notifyListeners();

      // Charger le profil utilisateur
      _profile = await _storage.loadUserProfile();
      
      // Charger les achievements
      await _loadAchievements();
      
      // Charger les arbres de compétences
      await _loadSkillTrees();
      
      // Charger les défis quotidiens/semaine
      await _loadChallenges();
      
      // Charger les parcours d'apprentissage
      await _loadLearningPaths();
      
      // Charger le classement
      await _loadLeaderboard();
      
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement gamification: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _loadAchievements() async {
    _allAchievements = [
      // Achievements Linux
      Achievement(
        id: 'linux_novice',
        title: 'Explorateur Linux',
        description: 'Complétez votre premier chapitre Linux',
        icon: Icons.terminal,
        color: Colors.green,
        points: 50,
        category: 'linux',
        requirements: ['linux-basics:intro'],
      ),
      Achievement(
        id: 'linux_master',
        title: 'Maître du Terminal',
        description: 'Complétez tous les chapitres Linux de base',
        icon: Icons.computer,
        color: Colors.green.shade700,
        points: 500,
        category: 'linux',
        requirements: ['linux-basics:intro', 'linux-basics:navigation', 'linux-basics:files'],
        totalSteps: 3,
      ),
      Achievement(
        id: 'script_kiddie',
        title: 'Script Kiddie',
        description: 'Écrivez votre premier script Bash fonctionnel',
        icon: Icons.code,
        color: Colors.orange,
        points: 150,
        category: 'linux',
        isSecret: true,
      ),

      // Achievements Réseau
      Achievement(
        id: 'network_explorer',
        title: 'Explorateur Réseau',
        description: 'Maîtrisez les bases du réseau',
        icon: Icons.router,
        color: Colors.blue,
        points: 300,
        category: 'network',
        requirements: ['network-basics:tcp_ip', 'network-basics:dns', 'network-basics:ports'],
        totalSteps: 3,
      ),
      Achievement(
        id: 'packet_hunter',
        title: 'Chasseur de Paquets',
        description: 'Analysez 100 paquets réseau dans le labo',
        icon: Icons.radar,
        color: Colors.blue.shade700,
        points: 400,
        category: 'network',
        isSecret: true,
      ),

      // Achievements Cybersécurité
      Achievement(
        id: 'security_guard',
        title: 'Gardien de la Sécurité',
        description: 'Complétez le module de sécurité de base',
        icon: Icons.security,
        color: Colors.red,
        points: 600,
        category: 'security',
        requirements: ['security-basics:owasp', 'security-basics:encryption'],
      ),
      Achievement(
        id: 'ethical_hacker',
        title: 'Hackeur Éthique',
        description: 'Maîtrisez les techniques de pentesting',
        icon: Icons.bug_report,
        color: Colors.red.shade700,
        points: 1000,
        category: 'security',
        requirements: ['security-advanced:pentest', 'security-advanced:forensics'],
        totalSteps: 2,
      ),

      // Achievements Développement
      Achievement(
        id: 'code_warrior',
        title: 'Guerrier du Code',
        description: 'Écrivez 1000 lignes de code dans les labos',
        icon: Icons.code,
        color: Colors.purple,
        points: 800,
        category: 'development',
        isSecret: true,
      ),

      // Achievements Spéciaux
      Achievement(
        id: 'speed_learner',
        title: 'Apprentissage Rapide',
        description: 'Complétez 5 chapitres en une journée',
        icon: Icons.speed,
        color: Colors.yellow,
        points: 200,
        category: 'special',
        isSecret: true,
      ),
      Achievement(
        id: 'perfectionist',
        title: 'Perfectionniste',
        description: 'Obtenez 100% dans tous les quiz',
        icon: Icons.star,
        color: Colors.amber,
        points: 750,
        category: 'special',
        isSecret: true,
      ),
    ];
  }

  Future<void> _loadSkillTrees() async {
    _skillTrees = [
      SkillTree(
        id: 'linux_tree',
        title: 'Maîtrise Linux',
        description: 'De novice à administrateur système',
        icon: Icons.computer,
        color: Colors.green,
        nodes: [
          SkillNode(
            id: 'linux_basics',
            title: 'Bases du Terminal',
            description: 'Navigation et commandes essentielles',
            chapterId: 'linux-basics:intro',
            position: 0,
            connections: ['linux_files'],
            level: 1,
          ),
          SkillNode(
            id: 'linux_files',
            title: 'Gestion des Fichiers',
            description: 'Permissions, recherche et manipulation',
            chapterId: 'linux-basics:files',
            position: 1,
            connections: ['linux_scripts'],
            level: 2,
          ),
          SkillNode(
            id: 'linux_scripts',
            title: 'Scripting Bash',
            description: 'Automatisation avec les scripts',
            chapterId: 'linux-advanced:scripting',
            position: 2,
            connections: ['linux_admin'],
            level: 3,
          ),
          SkillNode(
            id: 'linux_admin',
            title: 'Administration Système',
            description: 'Services, processus et surveillance',
            chapterId: 'linux-advanced:admin',
            position: 3,
            connections: [],
            level: 4,
          ),
        ],
      ),
      SkillTree(
        id: 'network_tree',
        title: 'Expert Réseau',
        description: 'TCP/IP, DNS et au-delà',
        icon: Icons.router,
        color: Colors.blue,
        nodes: [
          SkillNode(
            id: 'network_basics',
            title: 'TCP/IP Fondamentaux',
            description: 'Adresses IP et sous-réseaux',
            chapterId: 'network-basics:tcp_ip',
            position: 0,
            connections: ['network_dns'],
            level: 1,
          ),
          SkillNode(
            id: 'network_dns',
            title: 'Résolution DNS',
            description: 'Comment fonctionne le DNS',
            chapterId: 'network-basics:dns',
            position: 1,
            connections: ['network_advanced'],
            level: 2,
          ),
          SkillNode(
            id: 'network_advanced',
            title: 'Protocoles Avancés',
            description: 'HTTP, HTTPS, TLS et monitoring',
            chapterId: 'network-advanced:protocols',
            position: 2,
            connections: [],
            level: 3,
          ),
        ],
      ),
    ];
  }

  Future<void> _loadChallenges() async {
    final now = DateTime.now();
    _availableChallenges = [
      Challenge(
        id: 'daily_linux',
        title: 'Défi Linux Quotidien',
        description: 'Complétez un chapitre Linux aujourd\'hui',
        pointsReward: 100,
        deadline: now.add(const Duration(days: 1)),
        requiredChapters: ['linux-basics:intro'],
        difficulty: 1,
        category: 'linux',
      ),
      Challenge(
        id: 'weekly_network',
        title: 'Semaine Réseau',
        description: 'Maîtrisez 3 chapitres réseau cette semaine',
        pointsReward: 500,
        deadline: now.add(const Duration(days: 7)),
        requiredChapters: ['network-basics:tcp_ip', 'network-basics:dns', 'network-basics:ports'],
        difficulty: 2,
        category: 'network',
      ),
      Challenge(
        id: 'security_master',
        title: 'Maître de la Sécurité',
        description: 'Complétez le parcours cybersécurité complet',
        pointsReward: 1500,
        deadline: now.add(const Duration(days: 30)),
        requiredChapters: ['security-basics:owasp', 'security-basics:encryption', 'security-advanced:pentest'],
        difficulty: 4,
        category: 'security',
      ),
    ];
  }

  Future<void> _loadLearningPaths() async {
    _learningPaths = [
      LearningPath(
        id: 'devops_path',
        title: 'Parcours DevOps',
        description: 'De Linux à Docker et Kubernetes',
        courseIds: ['linux-basics', 'docker-essentials', 'kubernetes-basics'],
        estimatedHours: 40,
        difficulty: 'intermediate',
        certificate: 'DevOps Foundation',
      ),
      LearningPath(
        id: 'cybersecurity_path',
        title: 'Parcours Cybersécurité',
        description: 'De la défense au pentesting',
        courseIds: ['security-basics', 'network-security', 'ethical-hacking'],
        estimatedHours: 60,
        difficulty: 'advanced',
        certificate: 'Cybersecurity Professional',
      ),
      LearningPath(
        id: 'system_admin_path',
        title: 'Administrateur Système',
        description: 'Maîtrise complète des systèmes Linux/Windows',
        courseIds: ['linux-basics', 'windows-admin', 'network-management'],
        estimatedHours: 50,
        difficulty: 'intermediate',
        certificate: 'System Administrator',
      ),
    ];
  }

  Future<void> _loadLeaderboard() async {
    _leaderboard = [
      LeaderboardEntry(
        username: 'CyberNinja',
        points: 15420,
        level: 15,
        rank: 'Légende',
        avatar: '🥷',
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LeaderboardEntry(
        username: 'TechMaster',
        points: 12300,
        level: 12,
        rank: 'Master',
        avatar: '🎯',
        lastActive: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      LeaderboardEntry(
        username: 'CodeWizard',
        points: 9800,
        level: 10,
        rank: 'Expert',
        avatar: '🧙‍♂️',
        lastActive: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Méthodes de progression
  Future<void> completeChapter(String courseId, String chapterId) async {
    final chapterKey = '$courseId:$chapterId';
    
    if (!_profile.completedChapters.contains(chapterKey)) {
      // Mettre à jour le profil
      final newCompletedChapters = [..._profile.completedChapters, chapterKey];
      final newPoints = _profile.totalPoints + 50; // Points par chapitre
      final newExp = _profile.experiencePoints + 50;
      
      // Calculer le nouveau niveau
      int newLevel = _profile.currentLevel;
      String newRank = _profile.rank;
      
      if (newExp >= newLevel * 1000) {
        newLevel++;
        newRank = _calculateRank(newLevel);
      }
      
      _profile = _profile.copyWith(
        completedChapters: newCompletedChapters,
        totalPoints: newPoints,
        experiencePoints: newExp,
        currentLevel: newLevel,
        rank: newRank,
        lastActivityDate: DateTime.now(),
      );
      
      // Mettre à jour les achievements
      await _updateAchievements(chapterKey);
      
      // Mettre à jour les défis
      await _updateChallenges(chapterKey);
      
      // Mettre à jour les parcours
      await _updateLearningPaths(courseId, chapterId);
      
      // Sauvegarder
      await _storage.saveUserProfile(_profile);
      
      notifyListeners();
    }
  }

  String _calculateRank(int level) {
    if (level >= 15) return 'Légende';
    if (level >= 12) return 'Master';
    if (level >= 8) return 'Expert';
    if (level >= 4) return 'Apprenti';
    return 'Novice';
  }

  Future<void> _updateAchievements(String chapterKey) async {
    for (int i = 0; i < _allAchievements.length; i++) {
      final achievement = _allAchievements[i];
      
      if (!achievement.isUnlocked && achievement.requirements.contains(chapterKey)) {
        final newProgress = achievement.progress + (100 / achievement.requirements.length);
        final newCurrentStep = achievement.currentStep + 1;
        
        Achievement updated;
        if (newProgress >= 100) {
          updated = achievement.copyWith(
            progress: 100,
            currentStep: newCurrentStep,
            unlockedAt: DateTime.now(),
          );
        } else {
          updated = achievement.copyWith(
            progress: newProgress.round(),
            currentStep: newCurrentStep,
          );
        }
        
        _allAchievements[i] = updated;
      }
    }
  }

  Future<void> _updateChallenges(String chapterKey) async {
    for (int i = 0; i < _availableChallenges.length; i++) {
      final challenge = _availableChallenges[i];
      
      if (!challenge.isCompleted && challenge.requiredChapters.contains(chapterKey)) {
        final updatedRequirements = List<String>.from(challenge.requiredChapters)..remove(chapterKey);
        
        if (updatedRequirements.isEmpty) {
          // Défi complété
          _availableChallenges[i] = challenge.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
            requiredChapters: updatedRequirements,
          );
          
          // Ajouter les points du défi
          _profile = _profile.copyWith(
            totalPoints: _profile.totalPoints + challenge.pointsReward,
            experiencePoints: _profile.experiencePoints + challenge.pointsReward,
          );
        } else {
          _availableChallenges[i] = challenge.copyWith(
            requiredChapters: updatedRequirements,
          );
        }
      }
    }
  }

  Future<void> _updateLearningPaths(String courseId, String chapterId) async {
    for (int i = 0; i < _learningPaths.length; i++) {
      final path = _learningPaths[i];
      
      if (path.courseIds.contains(courseId) && !path.isCompleted) {
        // Calculer le progrès (simplifié)
        final completedInPath = _profile.completedChapters
            .where((c) => c.startsWith('$courseId:'))
            .length;
        
        final totalInPath = path.courseIds.length * 3; // ~3 chapitres par cours
        
        final newProgress = completedInPath / totalInPath;
        
        LearningPath updated;
        if (newProgress >= 1.0) {
          updated = path.copyWith(
            progress: 1.0,
            isCompleted: true,
            completedAt: DateTime.now(),
          );
        } else {
          updated = path.copyWith(progress: newProgress);
        }
        
        _learningPaths[i] = updated;
      }
    }
  }

  // Méthodes utilitaires
  List<Achievement> getAchievementsByCategory(String category) {
    return _allAchievements.where((a) => a.category == category).toList();
  }

  List<Challenge> getActiveChallenges() {
    return _availableChallenges.where((c) => c.isActive).toList();
  }

  double getOverallProgress() {
    if (_allAchievements.isEmpty) return 0.0;
    final unlockedCount = unlockedAchievements.length;
    return unlockedCount / _allAchievements.length;
  }

  Map<String, double> getProgressByCategory() {
    final Map<String, double> progress = {};
    
    for (final category in ['linux', 'network', 'security', 'development']) {
      final categoryAchievements = getAchievementsByCategory(category);
      if (categoryAchievements.isNotEmpty) {
        final unlocked = categoryAchievements.where((a) => a.isUnlocked).length;
        progress[category] = unlocked / categoryAchievements.length;
      }
    }
    
    return progress;
  }

  Future<void> resetProgress() async {
    _profile = UserProfile(
      username: 'Utilisateur',
      lastActivityDate: DateTime.now(),
    );
    
    // Reset achievements
    for (int i = 0; i < _allAchievements.length; i++) {
      _allAchievements[i] = _allAchievements[i].copyWith(
        progress: 0,
        currentStep: 0,
        unlockedAt: null,
      );
    }
    
    await _storage.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> updateUsername(String newUsername) async {
    _profile = _profile.copyWith(username: newUsername);
    await _storage.saveUserProfile(_profile);
    notifyListeners();
  }
}
