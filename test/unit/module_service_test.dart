import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:tutodecode/core/services/module_service.dart';

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

    test('loadExternalModules parses valid course', () async {
      final dir = await moduleService.getModulesDirectory();
      final validCourseJson = {
        'id': 'test_course_full',
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
            'content': 'Long chapter content that should NOT be cleared',
            'codeBlocks': [{'language': 'dart', 'code': 'print("hello");'}],
            'quiz': []
          }
        ]
      };
      
      final file = File('${dir.path}/valid_course_full.json');
      await file.writeAsString(json.encode(validCourseJson));

      final courses = await moduleService.loadExternalModules();
      expect(courses, hasLength(1));
      
      final course = courses.first;
      expect(course.id, 'test_course_full');
      expect(course.keywords, containsAll(['TEST', 'EXTERNAL']));
      
      final chapter = course.chapters.first;
      expect(chapter.content, contains('Long chapter content that should NOT be cleared'));
      expect(chapter.codeBlocks, isNotNull);
    });

    test('loadExternalModules skips invalid files', () async {
      final dir = await moduleService.getModulesDirectory();
      
      final invalidFile = File('${dir.path}/invalid2.json');
      await invalidFile.writeAsString('{ invalid json }');
      
      final courses = await moduleService.loadExternalModules();
      expect(courses, isEmpty);
    });

    test('loadFullCourse returns course if valid', () async {
      final dir = await moduleService.getModulesDirectory();
      final validCourseJson = {
        'id': 'test_course_load',
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
            'content': 'Some content',
            'codeBlocks': [],
            'quiz': []
          }
        ]
      };
      
      final file = File('${dir.path}/test_course_load.json');
      await file.writeAsString(json.encode(validCourseJson));

      final course = await moduleService.loadFullCourse('test_course_load');
      expect(course, isNotNull);
      expect(course!.id, 'test_course_load');
      expect(course.chapters.first.content, contains('Some content'));
    });

    test('loadFullCourse returns null if not found', () async {
      final course = await moduleService.loadFullCourse('non_existent_course');
      expect(course, isNull);
    });

    test('saveModule, getSavedSha, and deleteModule work correctly', () async {
      await moduleService.saveModule('test_module.json', '{"id":"t1"}', 'sha_123');
      final sha = await moduleService.getSavedSha('test_module.json');
      expect(sha, 'sha_123');
      
      final meta = await moduleService.getSavedMeta('test_module.json');
      expect(meta, isNotNull);
      expect(meta!.sha, 'sha_123');

      // Test backup rotation indirectly by saving multiple times
      for(int i=0; i<7; i++) {
        await moduleService.saveModule('test_module.json', '{"id":"t1", "v":$i}', 'sha_$i');
      }

      final rollbacks = await moduleService.listRollbackCandidates();
      expect(rollbacks, contains('test_module.json'));

      final rbSuccess = await moduleService.rollbackLatest('test_module.json');
      expect(rbSuccess, isTrue);

      final content = await moduleService.readLocalModule('test_module.json');
      expect(content, contains('"id":"t1"'));

      await moduleService.deleteModule('test_module.json');
      final afterDelete = await moduleService.getSavedSha('test_module.json');
      expect(afterDelete, isNull);
    });

    test('module map validation rejects invalid courses', () async {
      final dir = await moduleService.getModulesDirectory();
      
      final missingTitle = {
        'id': 'test',
        'description': 'A test',
        'category': 'NETWORK',
        'content': []
      };
      
      final file = File('${dir.path}/missing_title.json');
      await file.writeAsString(json.encode(missingTitle));

      final courses = await moduleService.loadExternalModulesLight();
      expect(courses, isEmpty); // Should reject due to missing title
      
      final invalidTypes = {
        'id': 123,
        'title': 'Test',
        'description': 'Desc',
        'category': 'NETWORK',
        'content': []
      };
      final file2 = File('${dir.path}/invalid_types.json');
      await file2.writeAsString(json.encode(invalidTypes));
      final courses2 = await moduleService.loadExternalModulesLight();
      expect(courses2, isEmpty); // Should reject due to invalid types
      
      final tooLongId = {
        'id': 'a' * 100,
        'title': 'Test',
        'description': 'Desc',
        'category': 'NETWORK',
        'content': [{'id': 'c1', 'title': 'C1', 'content': 'hello'}]
      };
      final file3 = File('${dir.path}/too_long.json');
      await file3.writeAsString(json.encode(tooLongId));
      final courses3 = await moduleService.loadExternalModulesLight();
      expect(courses3, isEmpty); // Should reject due to too long ID
      
      final missingChapterFields = {
        'id': 'test_chap',
        'title': 'Test',
        'description': 'Desc',
        'category': 'NETWORK',
        'content': [{'id': 'c1'}] // missing title and content
      };
      final file4 = File('${dir.path}/missing_chap.json');
      await file4.writeAsString(json.encode(missingChapterFields));
      final courses4 = await moduleService.loadExternalModulesLight();
      expect(courses4, isEmpty);
    });
    
    test('checksum mismatch skips module', () async {
       // Save a valid module
       final dir = await moduleService.getModulesDirectory();
       final content = json.encode({
        'id': 'valid_course_checksum',
        'title': 'Test',
        'description': 'Desc',
        'category': 'NETWORK',
        'content': [{'id': 'c1', 'title': 'C1', 'content': 'hello'}]
       });
       await moduleService.saveModule('checksum_test.json', content, 'sha123');
       
       // Modify file directly to bypass saveModule checksum generation
       final file = File('${dir.path}/checksum_test.json');
       await file.writeAsString(json.encode({
        'id': 'valid_course_checksum_modified',
        'title': 'Test',
        'description': 'Desc',
        'category': 'NETWORK',
        'content': [{'id': 'c1', 'title': 'C1', 'content': 'hello'}]
       }));
       
       final courses = await moduleService.loadExternalModulesLight();
       expect(courses.where((c) => c.id.startsWith('valid_course_checksum')), isEmpty);
       
       final coursesFull = await moduleService.loadExternalModules();
       expect(coursesFull.where((c) => c.id.startsWith('valid_course_checksum')), isEmpty);
    });
  });
}
