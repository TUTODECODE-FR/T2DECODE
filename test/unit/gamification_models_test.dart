// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/courses/models/gamification_models.dart';

void main() {
  group('Gamification Models Full Coverage', () {
    test('Achievement coverage', () {
      final achievement = Achievement(
        id: '1',
        title: 'Test',
        description: 'Desc',
        icon: Icons.star,
        color: Colors.red,
        points: 10,
        category: 'test',
        unlockedAt: DateTime.now(),
        progress: 50,
      );
      
      final json = achievement.toJson();
      expect(json['color'], Colors.red.toARGB32());
      
      final fromJson = Achievement.fromJson(json);
      expect(fromJson.id, '1');
      
      final copied = achievement.copyWith(title: 'New');
      expect(copied.title, 'New');
      
      expect(achievement.isUnlocked, isTrue);
      expect(achievement.isInProgress, isFalse);
    });

    test('SkillTree and SkillNode coverage', () {
      final node = const SkillNode(
        id: 'n1',
        title: 'Node',
        description: 'Desc',
        chapterId: 'c1',
        position: 1,
        connections: [],
      );
      
      final nodeJson = node.toJson();
      final nodeFromJson = SkillNode.fromJson(nodeJson);
      expect(nodeFromJson.id, 'n1');

      final tree = SkillTree(
        id: 't1',
        title: 'Tree',
        description: 'Desc',
        icon: Icons.star,
        color: Colors.blue,
        nodes: [node],
      );
      
      final treeJson = tree.toJson();
      expect(treeJson['color'], Colors.blue.toARGB32());
      
      final treeFromJson = SkillTree.fromJson(treeJson);
      expect(treeFromJson.id, 't1');
      expect(treeFromJson.nodes.length, 1);
    });

    test('UserProfile coverage', () {
      final profile = UserProfile(
        username: 'test',
        lastActivityDate: DateTime.now(),
        experiencePoints: 500,
        currentLevel: 1,
      );
      
      final json = profile.toJson();
      final fromJson = UserProfile.fromJson(json);
      expect(fromJson.username, 'test');
      
      final copied = profile.copyWith(totalPoints: 100);
      expect(copied.totalPoints, 100);
      
      expect(profile.levelProgress, 0.5);
      expect(profile.pointsToNextLevel, 500);
    });

    test('Challenge coverage', () {
      final challenge = Challenge(
        id: 'c1',
        title: 'Chal',
        description: 'Desc',
        pointsReward: 100,
        deadline: DateTime.now().add(const Duration(days: 1)),
        requiredChapters: [],
        category: 'cat',
      );
      
      final json = challenge.toJson();
      final fromJson = Challenge.fromJson(json);
      expect(fromJson.id, 'c1');
      
      final copied = challenge.copyWith(pointsReward: 200);
      expect(copied.pointsReward, 200);
      
      expect(challenge.isExpired, isFalse);
      expect(challenge.isActive, isTrue);
    });

    test('LearningPath coverage', () {
      final path = const LearningPath(
        id: 'p1',
        title: 'Path',
        description: 'Desc',
        courseIds: [],
        estimatedHours: 1,
        difficulty: 'beginner',
        certificate: 'cert',
      );
      
      final json = path.toJson();
      final fromJson = LearningPath.fromJson(json);
      expect(fromJson.id, 'p1');
      
      final copied = path.copyWith(title: 'New Path');
      expect(copied.title, 'New Path');
    });

    test('LeaderboardEntry and Badge coverage', () {
      final entry = LeaderboardEntry(
        username: 'user',
        points: 10,
        level: 1,
        rank: 'Novice',
        avatar: 'img',
        lastActive: DateTime.now(),
      );
      expect(entry.username, 'user');

      const badge = Badge(
        id: 'b1',
        name: 'Badge',
        description: 'Desc',
        iconPath: 'path',
        color: Colors.red,
        rarity: 1,
      );
      expect(badge.id, 'b1');
    });
  });
}
