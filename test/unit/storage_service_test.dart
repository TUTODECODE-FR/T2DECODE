import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/features/courses/models/gamification_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService AiSettings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async {
          return null; // Mock all operations
        },
      );
    });

    test('saveAiSettings coverage', () async {
      final storage = StorageService();
      
      await storage.saveAiSettings({
        'ollamaUrl': 'http://localhost:11434',
        'selectedModel': 'llama3'
      });
      
      expect(await storage.getOllamaHost(), 'http://localhost:11434');
      expect(await storage.getOllamaModel(), 'llama3');
      
      final loaded = await storage.loadAiSettings();
      expect(loaded['ollamaUrl'], 'http://localhost:11434');
    });

    test('UserProfile save/load', () async {
      final storage = StorageService();
      
      // Load empty profile
      final emptyProfile = await storage.loadUserProfile();
      expect(emptyProfile.username, 'Utilisateur');

      // Save custom profile
      final customProfile = UserProfile(username: 'TestUser', lastActivityDate: DateTime.now());
      await storage.saveUserProfile(customProfile);

      // Load custom profile
      final loadedProfile = await storage.loadUserProfile();
      expect(loadedProfile.username, 'TestUser');
    });
  });
}
