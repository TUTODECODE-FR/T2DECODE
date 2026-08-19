import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/services/tdc_parser.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('courses.tdc parses all 16 courses', () async {
    final src = await rootBundle.loadString('assets/courses.tdc');
    final maps = TdcParser.parse(src);
    expect(maps.length, 16, reason: 'Expected 16 courses from courses.tdc');

    final courses = maps.map(Course.fromMap).toList();
    expect(courses.first.id, 'linux-basics');
    expect(courses.first.chapters.isNotEmpty, true);
    expect(courses.fold<int>(0, (s, c) => s + c.chapters.length), greaterThan(0));
  });

  test('Course.loadAll prefers tdc over json', () async {
    final courses = await Course.loadAll();
    expect(courses.isNotEmpty, true);
    expect(courses.length, 16);
  });
}
