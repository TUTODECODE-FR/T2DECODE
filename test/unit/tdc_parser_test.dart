import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/services/tdc_parser.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses embedded python docstrings in code blocks', () {
    const src = '''
course "test" {
  title: "Test"
  category: linux
  level: beginner
  module "m1" {
    title: "Chapitre"
    duration: 15min
    content """
# Hello
    """
    codeblock "python" {
      title: "Demo"
      code """
def foo():
    """docstring inside code"""
    return 1
      """
    }
    quiz {
      question "Q?" {
        + "yes"
        - "no"
        explanation "because"
      }
    }
  }
}
''';
    final maps = TdcParser.parse(src);
    expect(maps.length, 1);
    expect((maps.first['content'] as List).length, 1);
  });

  test('courses.tdc loads 16 courses with chapters', () async {
    final src = await rootBundle.loadString('assets/courses.tdc');
    final maps = TdcParser.parse(src);
    expect(maps.length, 16);

    final courses = maps.map(Course.fromMap).toList();
    expect(courses.first.id, 'linux-basics');
    expect(courses.fold<int>(0, (s, c) => s + c.chapters.length), greaterThan(0));

    final loaded = await Course.loadAll();
    expect(loaded.length, 16);
  });

  test('cheat_sheets.tdc loads 106 entries with explanations', () async {
    final src = await rootBundle.loadString('assets/cheat_sheets.tdc');
    final maps = TdcParser.parseCheatSheets(src);
    expect(maps.length, 106);
    expect(maps.first['command'], isNotEmpty);
    expect(maps.first['detailedExplanation'], isNotEmpty);

    final redTeam = maps.where((m) => m['category'] == 'Red Team').length;
    expect(redTeam, 14);
  });

  test('netkit_cheat_sheets.tdc loads 10 entries', () async {
    final src = await rootBundle.loadString('assets/netkit_cheat_sheets.tdc');
    final maps = TdcParser.parseCheatSheets(src);
    expect(maps.length, 10);
  });
}
