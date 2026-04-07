import '../data/course_repository.dart';

class RagService {
  static final RagService _instance = RagService._internal();
  factory RagService() => _instance;
  RagService._internal();

  List<Course>? _cachedCourses;

  Future<void> _ensureLoaded() async {
    if (_cachedCourses != null) return;
    try {
      _cachedCourses = await Course.loadAll();
    } catch (_) {
      _cachedCourses = [];
    }
  }

  /// Simplistic RAG: Search for keywords in the message and return matching course snippets.
  Future<String?> findRelevantContext(String query) async {
    await _ensureLoaded();
    if (_cachedCourses == null || _cachedCourses!.isEmpty) return null;

    final q = query.toLowerCase();
    final results = <String>[];

    for (var course in _cachedCourses!) {
      // Check keywords
      bool matches = false;
      for (var kw in course.keywords) {
        if (q.contains(kw.toLowerCase())) {
          matches = true;
          break;
        }
      }

      if (matches || q.contains(course.title.toLowerCase())) {
        // Add course description and some chapter titles
        String context = "### PARCOURS : ${course.title}\n${course.description}\n";
        context += "Chapitres inclus : ${course.chapters.map((c) => c.title).join(', ')}.\n";
        
        // Search in chapters
        for (var ch in course.chapters) {
          if (q.contains(ch.title.toLowerCase())) {
            context += "\nEXTRAIT CH. '${ch.title}' :\n${ch.content.length > 500 ? ch.content.substring(0, 500) + "..." : ch.content}\n";
          }
        }
        results.add(context);
      }
    }

    if (results.isEmpty) return null;
    return results.join("\n---\n");
  }
}
