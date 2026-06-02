// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutodecode/features/ghost_ai/providers/ai_tutor_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiTutorProvider Smoke Test', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initialization and session management', () async {
      final provider = AiTutorProvider();
      
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(provider.isConnected, isFalse);
      expect(provider.sessions, isEmpty);
      
      // Select dummy session
      final dummySession = TutorSession(
        id: '1',
        title: 'Test',
        mode: TutorMode.explanation,
        topic: 'General',
        messages: [],
        createdAt: DateTime.now(),
      );
      
      await provider.selectSession(dummySession);
      expect(provider.currentSession?.id, '1');
      
      // Delete session
      await provider.deleteSession('1');
      expect(provider.sessions.any((s) => s.id == '1'), isFalse);
      
      provider.dispose();
    });
  });
}
