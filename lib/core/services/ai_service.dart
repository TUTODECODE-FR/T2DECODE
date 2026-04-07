import 'dart:async';

// Placeholder AI service. Replace with local model integration.
class AIService {
  Future<String> sendMessage(String message) async {
    await Future.delayed(Duration(milliseconds: 600));
    // Very simple canned reply for prototyping
    return "Réponse IA (placeholder) : j'ai reçu votre message -> $message";
  }
}
