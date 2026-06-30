import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/ghost_ai/service/ollama_service.dart';
import 'package:tutodecode/core/providers/settings_provider.dart';

class OnboardingTranslatorScreen extends StatefulWidget {
  const OnboardingTranslatorScreen({super.key});

  @override
  State<OnboardingTranslatorScreen> createState() => _OnboardingTranslatorScreenState();
}

class _OnboardingTranslatorScreenState extends State<OnboardingTranslatorScreen> {
  bool _isTranslating = true;
  bool _isDryRun = true; // Mode test par défaut pour éviter d'écraser tant qu'on teste
  double _progress = 0.0;
  String _statusMessage = 'Initialisation...';
  String _estimatedTime = '--:--';
  DateTime? _startTime;
  
  String _langCode = '';
  String _langName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_langCode.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        _langCode = args['code']?.toString() ?? 'en';
        _langName = args['name']?.toString() ?? 'English';
        _startTranslation();
      }
    }
  }

  Future<void> _startTranslation() async {
    setState(() {
      _isTranslating = true;
      _progress = 0.0;
      _statusMessage = 'Lecture du dictionnaire natif (Français)...';
      _startTime = DateTime.now();
    });

    try {
      final String frStr = await rootBundle.loadString('assets/translations/fr.json');
      final Map<String, dynamic> baseJson = jsonDecode(frStr);
      final flatKeys = _flattenJson(baseJson);
      
      setState(() => _statusMessage = 'Préparation de l\'IA pour $_langName...');

      final settings = context.read<SettingsProvider>();
      final model = settings.ollamaModel;

      Map<String, dynamic> translatedFlat = {};
      final chunks = _chunkMap(flatKeys, 40); // 40 clés par lot
      int completed = 0;

      for (var chunk in chunks) {
        if (!mounted) return;
        
        final chunkStartTime = DateTime.now();
        final translatedChunk = await _translateChunk(chunk, _langName, model);
        translatedFlat.addAll(translatedChunk);
        completed++;
        
        if (!mounted) return;
        
        // Calcul du temps estimé
        final elapsed = DateTime.now().difference(_startTime!);
        final timePerChunk = elapsed.inSeconds / completed;
        final remainingChunks = chunks.length - completed;
        final estimatedSecondsRemaining = (remainingChunks * timePerChunk).round();
        
        final minutes = estimatedSecondsRemaining ~/ 60;
        final seconds = estimatedSecondsRemaining % 60;
        final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        setState(() {
          _progress = completed / chunks.length;
          _estimatedTime = timeStr;
          _statusMessage = 'Traduction en cours... (Lot \$completed/\${chunks.length})';
        });
      }

      setState(() {
        _statusMessage = 'Vérification de sécurité JSON...';
        _estimatedTime = '00:00';
      });
      
      final unflattened = _unflattenJson(translatedFlat);
      
      // Validation JSON strict
      final finalJsonString = jsonEncode(unflattened);
      jsonDecode(finalJsonString); // throws if invalid

      // Sauvegarde si on n'est pas en mode Test
      if (!_isDryRun) {
        final docDir = await getApplicationDocumentsDirectory();
        final transDir = Directory('\${docDir.path}/T2DECODE/translations');
        if (!await transDir.exists()) {
          await transDir.create(recursive: true);
        }
        final file = File('\${transDir.path}/$_langCode.json');
        await file.writeAsString(finalJsonString);
        
        // Appliquer la langue !
        if (mounted) {
          final settings = Provider.of<SettingsProvider>(context, listen: false);
          await settings.setHasSelectedLanguage(true);
          await context.setLocale(Locale(_langCode));
        }
      }

      setState(() {
        _isTranslating = false;
        _progress = 1.0;
        _statusMessage = _isDryRun 
            ? 'Traduction simulée avec succès (Mode Test) ! Aucune sauvegarde effectuée.'
            : 'Traduction terminée et appliquée !';
      });

      if (!_isDryRun && mounted) {
        // Laisser 1 seconde à l'utilisateur pour voir le message 100%
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _statusMessage = 'Erreur critique : $e';
        });
      }
    }
  }

  Future<Map<String, dynamic>> _translateChunk(Map<String, dynamic> chunk, String langName, String model) async {
    final jsonStr = jsonEncode(chunk);
    final prompt = """Tu es un traducteur expert. Traduis les valeurs de ce JSON du Français vers : $langName. Ne traduis JAMAIS les clés. Renvoie uniquement un objet JSON valide et rien d'autre.
$jsonStr""";

    String resultStr = '';
    try {
      final stream = OllamaService.stream(
        model,
        [{'role': 'user', 'content': prompt}],
      );
      await for (final chunk in stream) {
        if (!chunk.isThinking) {
          resultStr += chunk.text;
        }
      }
      return _cleanAndParseJson(resultStr);
    } catch (e) {
      debugPrint('Chunk error: $e. Fallback to original keys.');
      return chunk; // En cas d'erreur de lot, on garde la clé non traduite (fr)
    }
  }

  Map<String, dynamic> _cleanAndParseJson(String input) {
    var clean = input.trim();
    if (clean.startsWith('```json')) clean = clean.substring(7);
    else if (clean.startsWith('```')) clean = clean.substring(3);
    if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
    clean = clean.trim();
    try {
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (e) {
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        clean = clean.substring(start, end + 1);
        return jsonDecode(clean) as Map<String, dynamic>;
      }
      throw FormatException('JSON généré invalide');
    }
  }

  Map<String, dynamic> _flattenJson(Map<String, dynamic> json, [String prefix = '']) {
    Map<String, dynamic> flat = {};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        flat.addAll(_flattenJson(value, '\$prefix\$key.'));
      } else {
        flat['\$prefix\$key'] = value;
      }
    });
    return flat;
  }

  Map<String, dynamic> _unflattenJson(Map<String, dynamic> flat) {
    Map<String, dynamic> unflattened = {};
    flat.forEach((key, value) {
      List<String> parts = key.split('.');
      Map<String, dynamic> current = unflattened;
      for (int i = 0; i < parts.length - 1; i++) {
        current.putIfAbsent(parts[i], () => <String, dynamic>{});
        current = current[parts[i]] as Map<String, dynamic>;
      }
      current[parts.last] = value;
    });
    return unflattened;
  }

  List<Map<String, dynamic>> _chunkMap(Map<String, dynamic> map, int chunkSize) {
    List<Map<String, dynamic>> chunks = [];
    Map<String, dynamic> currentChunk = {};
    int count = 0;
    map.forEach((key, value) {
      currentChunk[key] = value;
      count++;
      if (count >= chunkSize) {
        chunks.add(currentChunk);
        currentChunk = {};
        count = 0;
      }
    });
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TdcColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 64, color: TdcColors.accent),
                const SizedBox(height: 24),
                Text(
                  'Génération de la langue : $_langName',
                  style: const TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre IA locale traduit actuellement l\'application.\nAucun appel réseau externe n\'est effectué.',
                  style: const TextStyle(color: TdcColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: TdcColors.surface,
                  color: TdcColors.accent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(color: TdcColors.textPrimary, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isTranslating)
                      Text(
                        '~ $_estimatedTime',
                        style: const TextStyle(color: TdcColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TdcColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TdcColors.border),
                  ),
                  child: Row(
                    children: [
                      Switch(
                        value: _isDryRun,
                        activeColor: TdcColors.accent,
                        onChanged: _isTranslating ? null : (bool value) {
                          setState(() {
                            _isDryRun = value;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mode Test (Ne pas sauvegarder)', style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold)),
                            Text('Permet de tester le processus complet sans enregistrer la langue sur le disque.', style: TextStyle(color: TdcColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (!_isTranslating) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/language-selection'),
                    style: ElevatedButton.styleFrom(backgroundColor: TdcColors.surface),
                    child: const Text('Retour à la sélection'),
                  ),
                  if (!_isDryRun) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                      child: const Text("Aller à l'accueil"),
                    ),
                  ]
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
