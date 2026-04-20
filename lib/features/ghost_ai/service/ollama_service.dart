import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tutodecode/core/services/storage_service.dart';

const List<Map<String, String>> kRecommendedModels = [
  {'id': 'phi3',      'label': 'Phi-3 Mini',    'desc': 'Microsoft — ultra rapide, 2.3 GB',  'size': '2.3 GB'},
  {'id': 'llama3.2',  'label': 'Llama 3.2 3B',  'desc': 'Meta — léger et efficace, 2.0 GB', 'size': '2.0 GB'},
  {'id': 'qwen3:4b',  'label': 'Qwen3 4B',       'desc': 'Alibaba — raisonnement, 2.6 GB',   'size': '2.6 GB'},
  {'id': 'mistral',   'label': 'Mistral 7B',     'desc': 'Polyvalent, bonne qualité, 4.1 GB','size': '4.1 GB'},
  {'id': 'codellama', 'label': 'CodeLlama 7B',   'desc': 'Spécialisé code, 3.8 GB',          'size': '3.8 GB'},
];

// ─── Statut Ollama ─────────────────────────────────────────────────────────
class OllamaStatus {
  final bool running;
  final String? version;
  final List<String> models;
  final String? error;
  const OllamaStatus({required this.running, this.version, this.models = const [], this.error});
}

// ─── Chunk de streaming ─────────────────────────────────────────────────────
class OllamaChunk {
  final String text;       // texte à afficher
  final bool isThinking;   // est-ce que c'est du raisonnement interne ?
  const OllamaChunk({required this.text, this.isThinking = false});
}

// ─── Service ────────────────────────────────────────────────────────────────
class OllamaService {
  static Future<String> get _base async => await StorageService().getOllamaHost();

  static Future<void> _ensureAllowed() async {
    final storage = StorageService();
    if (await storage.getZeroNetworkMode()) {
      throw Exception('Réseau désactivé (mode zéro réseau)');
    }
  }

  // Vérifie si Ollama tourne
  static Future<OllamaStatus> checkStatus({
    bool includeModels = true,
    Duration versionTimeout = const Duration(seconds: 15),
    Duration tagsTimeout = const Duration(seconds: 15),
  }) async {
    try {
      await _ensureAllowed();
      final baseUrl = await _base;
      // Timeout plus long pour les réseaux distants/VPN
      final res = await http.get(Uri.parse('$baseUrl/api/version'))
          .timeout(versionTimeout);
      
      if (res.statusCode != 200) {
        return OllamaStatus(
          running: false, 
          error: 'Erreur Serveur (HTTP ${res.statusCode})'
        );
      }

      String? version;
      try { 
        version = (jsonDecode(res.body) as Map)['version']?.toString(); 
      } catch (_) {}

      List<String> models = [];
      if (includeModels) {
        final mRes = await http.get(Uri.parse('$baseUrl/api/tags'))
            .timeout(tagsTimeout);
        if (mRes.statusCode == 200) {
          final list = ((jsonDecode(mRes.body) as Map)['models'] as List?) ?? [];
          models = list.map((m) => m['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        }
      }

      return OllamaStatus(running: true, version: version, models: models);
    } on SocketException {
      return const OllamaStatus(
        running: false, 
        error: 'Connexion refusée (Vérifiez l\'IP/Port ou le VPN)'
      );
    } on TimeoutException {
      return const OllamaStatus(
        running: false, 
        error: 'Délai d\'attente dépassé (Réseau trop lent ou Serveur injoignable)'
      );
    } catch (e) {
      return OllamaStatus(running: false, error: 'Erreur : ${e.toString()}');
    }
  }

  /// Stream de chunks — gère les modèles "thinking" (qwen3, deepseek-r1...).
  /// Émets des [OllamaChunk] avec isThinking=true pendant la réflexion,
  /// puis isThinking=false pour la réponse finale.
  static Stream<OllamaChunk> stream(
    String model,
    List<Map<String, String>> messages, {
    String system = '',
    String? context,
  }) async* {
    await _ensureAllowed();
    final msgs = <Map<String, String>>[];
    String fullSystem = system;
    if (context != null && context.isNotEmpty) {
      fullSystem += "\n\nCONTEXTE ACTUEL DU COURS :\n$context\n\nL'utilisateur étudie ce contenu. Utilise ces informations pour répondre de manière précise et personnalisée.";
    }

    if (fullSystem.isNotEmpty) msgs.add({'role': 'system', 'content': fullSystem});
    msgs.addAll(messages);

    final body = jsonEncode({
      'model': model,
      'messages': msgs,
      'stream': true,
      'think': false,          // Desactive la reflexion interne (qwen3)
      'options': {
        'num_predict': 600,    // Reponses courtes
        'temperature': 0.5,    // Moins creatif, plus direct
        'top_k': 20,
        'top_p': 0.8,
      },
    });

    final baseUrl = await _base;
    final req = http.Request('POST', Uri.parse('$baseUrl/api/chat'));
    req.headers['Content-Type'] = 'application/json';
    req.body = body;

    final client = http.Client();
    try {
      // Timeout porté à 60s pour les connexions distantes
      final response = await client.send(req).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        // Lire le corps d'erreur
        final errBody = await response.stream.bytesToString();
        throw Exception('HTTP ${response.statusCode}: $errBody');
      }

      // État du parsing thinking
      bool inThink   = false;
      var  lineBuf   = StringBuffer();

      await for (final raw in response.stream.transform(utf8.decoder)) {
        lineBuf.write(raw);
        final full = lineBuf.toString();
        lineBuf.clear();

        // Séparer les lignes JSON
        final lines = full.split('\n');
        // Protection contre les flux malveillants sans saut de ligne (DoS)
        if (full.length > 50000) {
          throw Exception('Buffer overflow: Réponse du serveur trop longue sans saut de ligne.');
        }

        // La dernière ligne peut être incomplète
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          if (i == lines.length - 1 && !line.endsWith('}')) {
            lineBuf.write(lines[i]); // reprendre au prochain chunk
            break;
          }

          Map<String, dynamic> data;
          try { data = jsonDecode(line) as Map<String, dynamic>; }
          catch (_) { continue; }

          final done    = data['done'] as bool? ?? false;
          final content = data['message']?['content']?.toString() ?? '';

          if (content.isNotEmpty) {
            // Traitement token par token des balises <think>
            var buf = content;

            while (buf.isNotEmpty) {
              if (!inThink) {
                final tOpen = buf.indexOf('<think>');
                if (tOpen == -1) {
                  // Pas de balise — tout est réponse finale
                  if (buf.isNotEmpty) yield OllamaChunk(text: buf, isThinking: false);
                  buf = '';
                } else {
                  // Texte avant <think>
                  if (tOpen > 0) yield OllamaChunk(text: buf.substring(0, tOpen), isThinking: false);
                  inThink = true;
                  buf = buf.substring(tOpen + 7);
                }
              } else {
                // On est dans <think>
                final tClose = buf.indexOf('</think>');
                if (tClose == -1) {
                  // Tout le contenu est du thinking
                  yield OllamaChunk(text: buf, isThinking: true);
                  buf = '';
                } else {
                  // Thinking jusqu'à </think>
                  if (tClose > 0) yield OllamaChunk(text: buf.substring(0, tClose), isThinking: true);
                  inThink = false;
                  buf = buf.substring(tClose + 8);
                }
              }
            }
          }

          if (done) return;
        }
      }
    } finally {
      client.close();
    }
  }
}
