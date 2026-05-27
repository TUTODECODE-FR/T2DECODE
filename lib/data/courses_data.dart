// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import '../features/courses/data/course_repository.dart';

// Note: Course and CourseChapter are now imported from course_repository.dart
// to avoid type mismatch errors.

class CoursesData {
  static Future<List<Course>> loadAll() => Course.loadAll();
}
