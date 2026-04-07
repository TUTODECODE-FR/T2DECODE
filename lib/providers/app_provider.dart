import 'package:flutter/material.dart';
import '../features/courses/data/course_repository.dart';
import '../core/services/storage_service.dart';

// completed keys stored as "courseId:chapterId"

class AppProvider with ChangeNotifier {
  final StorageService _storage = StorageService();

  List<Course> _courses = [];
  List<String> _completed = [];
  String? _currentCourseId;
  String? _currentChapterId;
  bool _loaded = false;
  String? _errorMessage;

  AppProvider() {
    _load();
  }

  List<Course> get courses => _courses;
  List<String> get completed => _completed;
  String? get currentCourseId => _currentCourseId;
  String? get currentChapterId => _currentChapterId;
  bool get loaded => _loaded;
  String? get errorMessage => _errorMessage;

  int get totalChaptersCount => _courses.fold(0, (s, c) => s + c.chapters.length);
  int get completedCount => _completed.length;
  double get overallProgress => totalChaptersCount == 0 ? 0.0 : completedCount / totalChaptersCount;

  int courseChaptersCount(String courseId) {
    for (final c in _courses) {
      if (c.id == courseId) return c.chapters.length;
    }
    return 0;
  }

  int courseCompletedCount(String courseId) {
    return _completed.where((k) => k.startsWith('$courseId:')).length;
  }

  Course? get currentCourse {
    if (_currentCourseId == null) {
      return _courses.isNotEmpty ? _courses.first : null;
    }
    for (var c in _courses) {
      if (c.id == _currentCourseId) return c;
    }
    return _courses.isNotEmpty ? _courses.first : null;
  }
  CourseChapter? get currentChapter {
    final course = currentCourse;
    if (course == null || _currentChapterId == null) return null;
    return course.chapters.firstWhere((ch) => ch.id == _currentChapterId, orElse: () => course.chapters.first);
  }

  void selectChapter(String courseId, String chapterId) {
    _currentCourseId = courseId;
    _currentChapterId = chapterId;
    notifyListeners();
  }

  void toggleCompleted(String courseId, String chapterId) {
    final key = '$courseId:$chapterId';
    if (_completed.contains(key)) {
      _completed.remove(key);
    } else {
      _completed.add(key);
    }
    _storage.saveCompleted(_completed);
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      _errorMessage = null;
      _loaded = false;
      _completed = await _storage.loadCompleted();
      _courses = await Course.loadAll();
    } catch (err) {
      _errorMessage = err.toString();
      _courses = [];
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    await _load();
  }
}
