import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/courses/models/gamification_models.dart';

void main() {
  group('Gamification Models', () {
    test('Achievement toJson uses toARGB32 for color', () {
      const achievement = Achievement(
        id: '1',
        title: 'Test',
        description: 'Desc',
        icon: Icons.star,
        color: Colors.red,
        points: 10,
        category: 'test',
      );
      
      final json = achievement.toJson();
      expect(json['color'], Colors.red.toARGB32());
    });

    test('SkillTree toJson uses toARGB32 for color', () {
      const tree = SkillTree(
        id: '1',
        title: 'Test',
        description: 'Desc',
        icon: Icons.star,
        color: Colors.blue,
        nodes: [],
      );
      
      final json = tree.toJson();
      expect(json['color'], Colors.blue.toARGB32());
    });
  });
}
