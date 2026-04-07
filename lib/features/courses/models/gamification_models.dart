// ============================================================
// Gamification Models — Système de progression avancé
// ============================================================
import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int points;
  final String category; // 'linux', 'network', 'security', 'development'
  final List<String> requirements; // IDs des chapitres requis
  final bool isSecret;
  final DateTime? unlockedAt;
  final int progress; // 0-100
  final int currentStep;
  final int totalSteps;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.points,
    required this.category,
    this.requirements = const [],
    this.isSecret = false,
    this.unlockedAt,
    this.progress = 0,
    this.currentStep = 0,
    this.totalSteps = 1,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    int? points,
    String? category,
    List<String>? requirements,
    bool? isSecret,
    DateTime? unlockedAt,
    int? progress,
    int? currentStep,
    int? totalSteps,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      points: points ?? this.points,
      category: category ?? this.category,
      requirements: requirements ?? this.requirements,
      isSecret: isSecret ?? this.isSecret,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'color': color.value,
      'points': points,
      'category': category,
      'requirements': requirements,
      'isSecret': isSecret,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
      'currentStep': currentStep,
      'totalSteps': totalSteps,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      points: json['points'],
      category: json['category'],
      requirements: List<String>.from(json['requirements']),
      isSecret: json['isSecret'],
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
      progress: json['progress'],
      currentStep: json['currentStep'],
      totalSteps: json['totalSteps'],
    );
  }

  bool get isUnlocked => unlockedAt != null;
  bool get isInProgress => progress > 0 && !isUnlocked;
}

class SkillTree {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<SkillNode> nodes;
  final List<String> prerequisites; // IDs des arbres requis

  const SkillTree({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.nodes,
    this.prerequisites = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'color': color.value,
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'prerequisites': prerequisites,
    };
  }

  factory SkillTree.fromJson(Map<String, dynamic> json) {
    return SkillTree(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      nodes: (json['nodes'] as List).map((n) => SkillNode.fromJson(n)).toList(),
      prerequisites: List<String>.from(json['prerequisites']),
    );
  }
}

class SkillNode {
  final String id;
  final String title;
  final String description;
  final String chapterId; // Lien vers le chapitre de cours
  final int position; // Position dans l'arbre (x, y)
  final List<String> connections; // IDs des noeuds connectés
  final bool isUnlocked;
  final bool isCompleted;
  final int level; // 1-5 pour difficulté

  const SkillNode({
    required this.id,
    required this.title,
    required this.description,
    required this.chapterId,
    required this.position,
    required this.connections,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.level = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'chapterId': chapterId,
      'position': position,
      'connections': connections,
      'isUnlocked': isUnlocked,
      'isCompleted': isCompleted,
      'level': level,
    };
  }

  factory SkillNode.fromJson(Map<String, dynamic> json) {
    return SkillNode(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      chapterId: json['chapterId'],
      position: json['position'],
      connections: List<String>.from(json['connections']),
      isUnlocked: json['isUnlocked'],
      isCompleted: json['isCompleted'],
      level: json['level'],
    );
  }
}

class UserProfile {
  final String username;
  final int totalPoints;
  final int currentLevel;
  final int experiencePoints;
  final String rank; // 'Novice', 'Apprenti', 'Expert', 'Master', 'Légende'
  final List<Achievement> unlockedAchievements;
  final List<String> completedChapters;
  final Map<String, int> skillProgress; // category -> progress
  final int streakDays; // Jours consécutifs d'apprentissage
  final DateTime lastActivityDate;
  final List<Challenge> activeChallenges;
  final Map<String, dynamic> statistics; // Stats détaillées

  const UserProfile({
    required this.username,
    this.totalPoints = 0,
    this.currentLevel = 1,
    this.experiencePoints = 0,
    this.rank = 'Novice',
    this.unlockedAchievements = const [],
    this.completedChapters = const [],
    this.skillProgress = const {},
    this.streakDays = 0,
    required this.lastActivityDate,
    this.activeChallenges = const [],
    this.statistics = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'experiencePoints': experiencePoints,
      'rank': rank,
      'unlockedAchievements': unlockedAchievements.map((a) => a.toJson()).toList(),
      'completedChapters': completedChapters,
      'skillProgress': skillProgress,
      'streakDays': streakDays,
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'activeChallenges': activeChallenges.map((c) => c.toJson()).toList(),
      'statistics': statistics,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'],
      totalPoints: json['totalPoints'],
      currentLevel: json['currentLevel'],
      experiencePoints: json['experiencePoints'],
      rank: json['rank'],
      unlockedAchievements: (json['unlockedAchievements'] as List)
          .map((a) => Achievement.fromJson(a))
          .toList(),
      completedChapters: List<String>.from(json['completedChapters']),
      skillProgress: Map<String, int>.from(json['skillProgress']),
      streakDays: json['streakDays'],
      lastActivityDate: DateTime.parse(json['lastActivityDate']),
      activeChallenges: (json['activeChallenges'] as List)
          .map((c) => Challenge.fromJson(c))
          .toList(),
      statistics: Map<String, dynamic>.from(json['statistics']),
    );
  }

  UserProfile copyWith({
    String? username,
    int? totalPoints,
    int? currentLevel,
    int? experiencePoints,
    String? rank,
    List<Achievement>? unlockedAchievements,
    List<String>? completedChapters,
    Map<String, int>? skillProgress,
    int? streakDays,
    DateTime? lastActivityDate,
    List<Challenge>? activeChallenges,
    Map<String, dynamic>? statistics,
  }) {
    return UserProfile(
      username: username ?? this.username,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      rank: rank ?? this.rank,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      completedChapters: completedChapters ?? this.completedChapters,
      skillProgress: skillProgress ?? this.skillProgress,
      streakDays: streakDays ?? this.streakDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      activeChallenges: activeChallenges ?? this.activeChallenges,
      statistics: statistics ?? this.statistics,
    );
  }

  double get levelProgress {
    final xpForNextLevel = currentLevel * 1000;
    return experiencePoints / xpForNextLevel;
  }

  int get pointsToNextLevel {
    final xpForNextLevel = currentLevel * 1000;
    return xpForNextLevel - experiencePoints;
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final int pointsReward;
  final DateTime deadline;
  final List<String> requiredChapters;
  final bool isCompleted;
  final DateTime? completedAt;
  final int difficulty; // 1-5
  final String category;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsReward,
    required this.deadline,
    required this.requiredChapters,
    this.isCompleted = false,
    this.completedAt,
    this.difficulty = 1,
    required this.category,
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    int? pointsReward,
    DateTime? deadline,
    List<String>? requiredChapters,
    bool? isCompleted,
    DateTime? completedAt,
    int? difficulty,
    String? category,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsReward: pointsReward ?? this.pointsReward,
      deadline: deadline ?? this.deadline,
      requiredChapters: requiredChapters ?? this.requiredChapters,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsReward': pointsReward,
      'deadline': deadline.toIso8601String(),
      'requiredChapters': requiredChapters,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'difficulty': difficulty,
      'category': category,
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pointsReward: json['pointsReward'],
      deadline: DateTime.parse(json['deadline']),
      requiredChapters: List<String>.from(json['requiredChapters']),
      isCompleted: json['isCompleted'],
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      difficulty: json['difficulty'],
      category: json['category'],
    );
  }

  bool get isExpired => DateTime.now().isAfter(deadline);
  bool get isActive => !isCompleted && !isExpired;
}

class LearningPath {
  final String id;
  final String title;
  final String description;
  final List<String> courseIds; // Ordre des cours
  final int estimatedHours;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final List<String> prerequisites;
  final String certificate; // Nom du certificat obtenu
  final bool isCompleted;
  final DateTime? completedAt;
  final double progress; // 0.0-1.0

  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.courseIds,
    required this.estimatedHours,
    required this.difficulty,
    this.prerequisites = const [],
    required this.certificate,
    this.isCompleted = false,
    this.completedAt,
    this.progress = 0.0,
  });

  LearningPath copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? courseIds,
    int? estimatedHours,
    String? difficulty,
    List<String>? prerequisites,
    String? certificate,
    bool? isCompleted,
    DateTime? completedAt,
    double? progress,
  }) {
    return LearningPath(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseIds: courseIds ?? this.courseIds,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      difficulty: difficulty ?? this.difficulty,
      prerequisites: prerequisites ?? this.prerequisites,
      certificate: certificate ?? this.certificate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'courseIds': courseIds,
      'estimatedHours': estimatedHours,
      'difficulty': difficulty,
      'prerequisites': prerequisites,
      'certificate': certificate,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'progress': progress,
    };
  }

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      courseIds: List<String>.from(json['courseIds']),
      estimatedHours: json['estimatedHours'],
      difficulty: json['difficulty'],
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      certificate: json['certificate'],
      isCompleted: json['isCompleted'],
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      progress: json['progress'],
    );
  }
}

class LeaderboardEntry {
  final String username;
  final int points;
  final int level;
  final String rank;
  final String avatar;
  final List<Achievement> recentAchievements;
  final DateTime lastActive;

  const LeaderboardEntry({
    required this.username,
    required this.points,
    required this.level,
    required this.rank,
    required this.avatar,
    this.recentAchievements = const [],
    required this.lastActive,
  });
}

// Badges spéciaux avec animations
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final Color color;
  final bool isAnimated;
  final String? animationType; // 'pulse', 'glow', 'rotate'
  final int rarity; // 1-5 (commun à légendaire)

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.color,
    this.isAnimated = false,
    this.animationType,
    required this.rarity,
  });
}
