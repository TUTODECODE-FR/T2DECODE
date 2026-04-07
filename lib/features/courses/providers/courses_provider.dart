// Feature: courses — State management (Provider)
// Single source of truth for all course state.
import 'package:flutter/material.dart';
import '../data/course_repository.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/core/services/module_service.dart';

class CoursesProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final ModuleService _moduleService = ModuleService();

  List<Course> _courses = [];
  List<String> _completed = [];
  String? _currentCourseId;
  String? _currentChapterId;
  bool _loaded = false;
  bool _isUpdating = false;
  String? _errorMessage;
  bool _startupUpdateCheckDone = false;

  CoursesProvider() {
    _load();
  }

  // ── Getters ─────────────────────────────────────────────
  List<Course> get courses => _courses;
  List<String> get completed => _completed;
  String? get currentCourseId => _currentCourseId;
  String? get currentChapterId => _currentChapterId;
  bool get loaded => _loaded;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  bool get startupUpdateCheckDone => _startupUpdateCheckDone;

  int get totalChaptersCount =>
      _courses.fold(0, (s, c) => s + c.chapters.length);
  int get completedCount => _completed.length;
  double get overallProgress =>
      totalChaptersCount == 0 ? 0.0 : completedCount / totalChaptersCount;

  int courseChaptersCount(String courseId) {
    for (final c in _courses) {
      if (c.id == courseId) return c.chapters.length;
    }
    return 0;
  }

  int courseCompletedCount(String courseId) =>
      _completed.where((k) => k.startsWith('$courseId:')).length;

  Course? get currentCourse {
    if (_currentCourseId == null) {
      return _courses.isNotEmpty ? _courses.first : null;
    }
    for (final c in _courses) {
      if (c.id == _currentCourseId) return c;
    }
    return _courses.isNotEmpty ? _courses.first : null;
  }

  CourseChapter? get currentChapter {
    final course = currentCourse;
    if (course == null || _currentChapterId == null) return null;
    return course.chapters.firstWhere(
      (ch) => ch.id == _currentChapterId,
      orElse: () => course.chapters.first,
    );
  }

  // ── Actions ─────────────────────────────────────────────
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

  Future<void> reload() => _load();

  /// Read-only update check (no downloads). Intended for startup notifications.
  Future<int> checkForUpdatesAvailable({bool markStartupDone = false}) async {
    if (markStartupDone) _startupUpdateCheckDone = true;
    _errorMessage = 'Mises à jour distantes désactivées.';
    if (markStartupDone) notifyListeners();
    return 0;
  }


  Future<bool> rollbackModule(String fileName) async {
    try {
      final ok = await _moduleService.rollbackLatest(fileName);
      if (ok) await _load();
      return ok;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<List<String>> listRollbackCandidates() async {
    try {
      return await _moduleService.listRollbackCandidates();
    } catch (_) {
      return const [];
    }
  }

  /// Triggers a synchronization with the remote GitHub repository.
  Future<int> checkForUpdates() async {
    _isUpdating = false;
    _errorMessage = 'Mises à jour distantes désactivées.';
    notifyListeners();
    return 0;
  }

  Future<bool> deleteModule(String fileName) async {
    try {
      await _moduleService.deleteModule(fileName);
      await _load();
      return true;
    } catch (e) {
      _errorMessage = 'Delete failed: $e';
      return false;
    }
  }


  Future<void> _load() async {
    try {
      _errorMessage = null;
      _loaded = false;
      _completed = await _storage.loadCompleted();
      
      final assetCourses = await Course.loadAll();
      final externalCourses = await _moduleService.loadExternalModules();
      
      _courses = [...assetCourses, ...externalCourses];
    } catch (err) {
      _errorMessage = err.toString();
      _courses = [];
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }
}
