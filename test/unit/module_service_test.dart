import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:tutodecode/core/services/module_service.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  String _docsPath = '';
  
  void setDocsPath(String path) {
    _docsPath = path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return _docsPath;
  }
}

void main() {
  late ModuleService moduleService;
  late Directory tempDir;
  late FakePathProviderPlatform fakePlatform;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('module_service_test');
    
    fakePlatform = FakePathProviderPlatform();
    fakePlatform.setDocsPath(tempDir.path);
    PathProviderPlatform.instance = fakePlatform;

    moduleService = ModuleService();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('ModuleService', () {
    test('getModulesDirectory creates directory if not exists', () async {
      final dir = await moduleService.getModulesDirectory();
      expect(dir.existsSync(), isTrue);
      expect(dir.path, endsWith('TUTODECODE_Modules'));
    });

    test('getBackupsDirectory creates directory if not exists', () async {
      final dir = await moduleService.getBackupsDirectory();
      expect(dir.existsSync(), isTrue);
      expect(dir.path, endsWith('TUTODECODE_ModuleBackups'));
    });

    test('loadExternalModulesLight handles empty directory', () async {
      final courses = await moduleService.loadExternalModulesLight();
      expect(courses, isEmpty);
    });

    test('loadExternalModulesLight parses valid course with lazy loading', () async {
      final dir = await moduleService.getModulesDirectory();
      final validCourseJson = {
        'id': 'test_course_1',
        'title': 'Test Course',
        'description': 'A test course',
        'difficulty': 'BEGINNER',
        'level': 'BEGINNER',
        'duration': '1h',
        'category': 'NETWORK',
        'keywords': ['TEST'],
        'content': [
          {
            'id': 'chap_1',
            'title': 'Chapter 1',
            'content': 'Long chapter content that should be cleared',
            'codeBlocks': [{'language': 'dart', 'code': 'print("hello");'}],
            'quiz': {'id': 'q1', 'questions': []}
          }
        ]
      };
      
      final file = File('${dir.path}/valid_course.json');
      await file.writeAsString(json.encode(validCourseJson));

      final courses = await moduleService.loadExternalModulesLight();
      expect(courses, hasLength(1));
      
      final course = courses.first;
      expect(course.id, 'test_course_1');
      expect(course.keywords, containsAll(['TEST', 'EXTERNAL', 'LAZY_LOADED']));
      
      // Verify lazy loading effects
      final chapter = course.chapters.first;
      expect(chapter.content, isNot(contains('Long chapter content that should be cleared')));
      expect(chapter.codeBlocks, isNull);
      expect(chapter.quiz, isNull);
    });

    test('loadExternalModulesLight skips invalid files', () async {
      final dir = await moduleService.getModulesDirectory();
      
      // Invalid JSON
      final invalidFile = File('${dir.path}/invalid.json');
      await invalidFile.writeAsString('{ invalid json }');
      
      // Too large file (mocking length)
      // Since we can't easily mock file length for a real file without writing 5MB,
      // we'll rely on the invalid json test.

      // Non-json file
      final txtFile = File('${dir.path}/test.txt');
      await txtFile.writeAsString('hello');

      final courses = await moduleService.loadExternalModulesLight();
      expect(courses, isEmpty);
    });

    test('loadExternalModulesLight validates required fields', () async {
      final dir = await moduleService.getModulesDirectory();
      
      final missingIdJson = {
        'title': 'Test Course',
        'description': 'A test course',
        'difficulty': 'BEGINNER',
        'level': 'BEGINNER',
        'duration': '1h',
        'category': 'NETWORK',
        'keywords': ['TEST'],
        'content': []
      };
      
      final file = File('${dir.path}/missing_id.json');
      await file.writeAsString(json.encode(missingIdJson));

      final courses = await moduleService.loadExternalModulesLight();
      expect(courses, isEmpty);
    });
  });
}
