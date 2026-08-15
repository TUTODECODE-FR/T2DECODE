// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tutodecode/core/parser/tdc_parser.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Contrôleur de texte avec coloration syntaxique personnalisée pour la grammaire .TDC
class TDCSyntaxTextEditingController extends TextEditingController {
  TDCSyntaxTextEditingController({super.text});

  static final _keywordsRegex = RegExp(
    r'\b(course|metadata|category|level|duration|icon|keywords|module|markdown|quiz|question|options|answer|explanation|pass_mark)\b',
  );
  static final _stringRegex = RegExp(r'"([^"\\]|\\.)*"');
  static final _numberRegex = RegExp(r'\b\d+\b');
  static final _boolRegex = RegExp(r'\b(true|false)\b');
  static final _commentRegex = RegExp(r'(#|//).*$');
  static final _bracketsRegex = RegExp(r'[\{\}\[\]]');

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final List<TextSpan> children = [];
    final textContent = text;

    if (textContent.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final lines = textContent.split('\n');
    for (int l = 0; l < lines.length; l++) {
      final line = lines[l];
      int index = 0;

      while (index < line.length) {
        // Comment
        final commentMatch = _commentRegex.matchAsPrefix(line, index);
        if (commentMatch != null) {
          children.add(TextSpan(
            text: line.substring(index),
            style: style?.copyWith(color: const Color(0xFF6B7280), fontStyle: FontStyle.italic),
          ));
          index = line.length;
          break;
        }

        // String
        final stringMatch = _stringRegex.matchAsPrefix(line, index);
        if (stringMatch != null) {
          children.add(TextSpan(
            text: stringMatch.group(0),
            style: style?.copyWith(color: const Color(0xFF10B981)), // Emerald green
          ));
          index = stringMatch.end;
          continue;
        }

        // Keywords
        final kwMatch = _keywordsRegex.matchAsPrefix(line, index);
        if (kwMatch != null) {
          children.add(TextSpan(
            text: kwMatch.group(0),
            style: style?.copyWith(color: const Color(0xFFF5EBDA), fontWeight: FontWeight.bold),
          ));
          index = kwMatch.end;
          continue;
        }

        // Numbers
        final numMatch = _numberRegex.matchAsPrefix(line, index);
        if (numMatch != null) {
          children.add(TextSpan(
            text: numMatch.group(0),
            style: style?.copyWith(color: const Color(0xFF38BDF8)), // Sky blue
          ));
          index = numMatch.end;
          continue;
        }

        // Booleans
        final boolMatch = _boolRegex.matchAsPrefix(line, index);
        if (boolMatch != null) {
          children.add(TextSpan(
            text: boolMatch.group(0),
            style: style?.copyWith(color: const Color(0xFFEC4899), fontWeight: FontWeight.bold),
          ));
          index = boolMatch.end;
          continue;
        }

        // Brackets
        final bracketMatch = _bracketsRegex.matchAsPrefix(line, index);
        if (bracketMatch != null) {
          children.add(TextSpan(
            text: bracketMatch.group(0),
            style: style?.copyWith(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold),
          ));
          index = bracketMatch.end;
          continue;
        }

        // Plain text character
        children.add(TextSpan(
          text: line[index],
          style: style?.copyWith(color: const Color(0xFFD4D4D4)),
        ));
        index++;
      }

      if (l < lines.length - 1) {
        children.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(style: style, children: children);
  }
}

/// TDC Studio IDE — Environnement Développeur & Créateur de Cours souverain (.tdc).
class TDCStudioScreen extends StatefulWidget {
  const TDCStudioScreen({super.key});

  @override
  State<TDCStudioScreen> createState() => _TDCStudioScreenState();
}

class _TDCStudioScreenState extends State<TDCStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TDCSyntaxTextEditingController _rawCodeController = TDCSyntaxTextEditingController();
  final ScrollController _codeScrollController = ScrollController();

  // Core Course Model State (100% Blank Slate)
  String _courseId = '';
  String _courseTitle = '';
  String _courseDesc = '';
  String _category = 'linux';
  String _level = 'beginner';
  String _duration = '';
  String _icon = 'Terminal';
  List<String> _keywords = [];

  List<Map<String, dynamic>> _modules = [];

  // Accordion state
  final List<bool> _expandedModules = [];

  // Live QCM Interactive State (Apprenant mode in Preview)
  final Map<String, int> _userQuizAnswers = {};
  final Map<String, bool?> _quizValidationResults = {};

  // Undo & Save State Tracking
  bool _hasUnsavedChanges = false;
  bool _isNewUnsavedProject = true;
  final List<String> _undoHistory = [];
  bool _isUndoAction = false;

  // Parser Feedback
  Map<String, dynamic>? _parsedCourse;
  String _parseError = '';
  int? _parseErrorLine;
  bool _isCodeSourceOfTruth = false;

  bool _showWelcomeScreen = true;

  final List<Map<String, dynamic>> _recentProjects = [];
  final Set<String> _deletedProjectIds = {};

  // Color mappings
  static const Map<String, Color> _categoryColors = {
    'linux': Color(0xFFD7CDBF),
    'network': Color(0xFF8B5CF6),
    'security': Color(0xFF10B981),
    'cloud': Color(0xFF3B82F6),
    'crypto': Color(0xFFE11D48),
    'development': Color(0xFFF59E0B),
  };

  static const Map<String, Color> _levelColors = {
    'beginner': Color(0xFF10B981),
    'intermediate': Color(0xFFF59E0B),
    'advanced': Color(0xFFEF4444),
  };

  static const Map<String, String> _levelLabels = {
    'beginner': 'Fondation / Débutant',
    'intermediate': 'Intermédiaire',
    'advanced': 'Avancé',
  };

  Color _getCategoryColor(String cat) {
    return _categoryColors[cat.toLowerCase()] ?? const Color(0xFFD7CDBF);
  }

  Color _getLevelColor(String lvl) {
    return _levelColors[lvl.toLowerCase()] ?? const Color(0xFF10B981);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _syncFormToRawCode();
      } else if (_tabController.index == 2) {
        _syncFormToRawCode();
      }
    });
    _syncFormToRawCode();
    _loadRecentProjectsFromPrefs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rawCodeController.dispose();
    _codeScrollController.dispose();
    super.dispose();
  }

  void _pushHistorySnapshot() {
    if (_isUndoAction) return;
    final map = _serializeCurrentState();
    final jsonStr = jsonEncode(map);
    if (_undoHistory.isEmpty || _undoHistory.last != jsonStr) {
      _undoHistory.add(jsonStr);
      if (_undoHistory.length > 30) {
        _undoHistory.removeAt(0);
      }
    }
  }

  Map<String, dynamic> _serializeCurrentState() {
    return {
      'id': _courseId,
      'title': _courseTitle,
      'description': _courseDesc,
      'category': _category,
      'level': _level,
      'duration': _duration,
      'icon': _icon,
      'keywords': _keywords,
      'content': _modules,
    };
  }

  void _restoreHistorySnapshot(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _isUndoAction = true;
      setState(() {
        _courseId = map['id'] ?? '';
        _courseTitle = map['title'] ?? '';
        _courseDesc = map['description'] ?? '';
        _category = map['category'] ?? 'linux';
        _level = map['level'] ?? 'beginner';
        _duration = map['duration'] ?? '';
        _icon = map['icon'] ?? 'Terminal';
        _keywords = (map['keywords'] as List?)?.cast<String>() ?? [];
        _modules = (map['content'] as List?)?.map((m) => Map<String, dynamic>.from(m as Map)).toList() ?? [];
        while (_expandedModules.length < _modules.length) {
          _expandedModules.add(true);
        }
      });
      _syncFormToRawCode();
      _isUndoAction = false;
      _showFloatingToast('Action annulée');
    } catch (e) {
      _isUndoAction = false;
    }
  }

  void _performUndo() {
    if (_undoHistory.length > 1) {
      _undoHistory.removeLast(); // current
      final prev = _undoHistory.last;
      _restoreHistorySnapshot(prev);
    } else {
      _showFloatingToast('Aucune action à annuler');
    }
  }

  void _markModified() {
    _pushHistorySnapshot();
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _loadRecentProjectsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedList = prefs.getStringList('tdc_deleted_project_ids_v1') ?? [];
      _deletedProjectIds.addAll(deletedList);

      final rawJson = prefs.getString('tdc_recent_projects_v1');
      if (rawJson != null && rawJson.isNotEmpty) {
        final List decoded = jsonDecode(rawJson);
        final loaded = decoded.cast<Map<String, dynamic>>().where((p) {
          final id = p['id']?.toString() ?? '';
          final title = p['title']?.toString() ?? '';
          final path = p['path']?.toString() ?? '';
          return id != 'linux-sysadmin' &&
                 id != 'network-subnetting' &&
                 !_deletedProjectIds.contains(id) &&
                 !_deletedProjectIds.contains(title) &&
                 !_deletedProjectIds.contains(path);
        }).toList();

        setState(() {
          _recentProjects.clear();
          _recentProjects.addAll(loaded);
        });
      } else {
        setState(() {
          _recentProjects.clear();
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement projets récents: $e');
    }
  }

  Future<void> _saveRecentProjectsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('tdc_deleted_project_ids_v1', _deletedProjectIds.toList());
      final jsonStr = jsonEncode(_recentProjects);
      await prefs.setString('tdc_recent_projects_v1', jsonStr);
    } catch (e) {
      debugPrint('Erreur sauvegarde projets récents: $e');
    }
  }

  void _syncFormToRawCode() {
    if (_isCodeSourceOfTruth) return;

    final map = _serializeCurrentState();
    final tdcCode = TDCParser.serializeToTdc(map);
    if (_rawCodeController.text != tdcCode) {
      _rawCodeController.value = TextEditingValue(
        text: tdcCode,
        selection: TextSelection.collapsed(offset: tdcCode.length),
      );
    }
    _parseRawCode(tdcCode, updateForm: false);
  }

  void _parseRawCode(String code, {bool updateForm = true}) {
    final validationErrors = TDCParser.validateSyntax(code);
    if (validationErrors.isNotEmpty) {
      final first = validationErrors.first;
      setState(() {
        _parseError = first.message;
        _parseErrorLine = first.line;
        _parsedCourse = null;
      });
      return;
    }

    try {
      final parsed = TDCParser.parseCourse(code);
      setState(() {
        _parsedCourse = parsed;
        _parseError = '';
        _parseErrorLine = null;

        if (updateForm) {
          _courseId = parsed['id'] ?? _courseId;
          _courseTitle = parsed['title'] ?? _courseTitle;
          _courseDesc = parsed['description'] ?? _courseDesc;
          _category = parsed['category'] ?? _category;
          _level = parsed['level'] ?? _level;
          _duration = parsed['duration'] ?? _duration;
          _icon = parsed['icon'] ?? _icon;
          _keywords = (parsed['keywords'] as List?)?.cast<String>() ?? _keywords;
          _modules = (parsed['content'] as List?)?.map((m) => Map<String, dynamic>.from(m as Map)).toList() ?? _modules;

          while (_expandedModules.length < _modules.length) {
            _expandedModules.add(true);
          }
        }
      });
    } catch (e) {
      final errStr = e.toString().replaceAll('Exception: ', '').replaceAll('FormatException: ', '');
      int? lineNum;
      final match = RegExp(r'ligne\s*(\d+)', caseSensitive: false).firstMatch(errStr) ??
                    RegExp(r'line\s*(\d+)', caseSensitive: false).firstMatch(errStr);
      if (match != null) {
        lineNum = int.tryParse(match.group(1)!);
      }
      setState(() {
        _parseError = errStr;
        _parseErrorLine = lineNum;
        _parsedCourse = null;
      });
    }
  }

  void _navigateHomeAndAutoSaveDraft() {
    _syncFormToRawCode();
    final pId = _courseId.isNotEmpty ? _courseId : 'nouveau-cours';
    final pTitle = _courseTitle.isNotEmpty ? _courseTitle : 'Nouveau Cours';
    final pCat = _category.isNotEmpty ? _category : 'linux';

    // Auto-save project into recent history
    _recentProjects.removeWhere((p) => p['id'] == pId || p['title'] == pTitle);
    _recentProjects.insert(0, {
      'id': pId,
      'title': pTitle,
      'category': pCat,
      'level': _level,
      'date': "Modifié à l'instant",
      'path': 'workspace/$pId.tdc',
      'rawCode': _rawCodeController.text,
    });
    _saveRecentProjectsToPrefs();

    setState(() {
      _showWelcomeScreen = true;
      _hasUnsavedChanges = false;
    });
  }

  void _openRecentProject(Map<String, dynamic> p) {
    final rawCode = p['rawCode'] as String?;
    final path = p['path'] as String?;
    if (rawCode != null && rawCode.isNotEmpty) {
      _loadRawCodeIntoEditor(rawCode, isNewDoc: false, originalPath: path);
    } else if (path != null && File(path).existsSync()) {
      final content = File(path).readAsStringSync();
      _loadRawCodeIntoEditor(content, isNewDoc: false, originalPath: path);
    } else {
      _loadTemplate(p['category'] as String? ?? 'linux');
    }
  }

  void _createNewBlankCourse() {
    // If on home screen, previous session is already saved in history, no need to ask
    void initBlank() {
      setState(() {
        _courseId = 'nouveau-cours';
        _courseTitle = 'Nouveau Cours';
        _courseDesc = '';
        _category = 'linux';
        _level = 'beginner';
        _duration = '1h';
        _icon = 'BookOpen';
        _keywords = [];
        _modules = [];
        _expandedModules.clear();
        _showWelcomeScreen = false;
        _hasUnsavedChanges = false;
        _isNewUnsavedProject = true;
        _undoHistory.clear();
      });
      _pushHistorySnapshot();
      _syncFormToRawCode();
      _showFloatingToast('Nouveau projet initialisé');
    }

    if (_showWelcomeScreen) {
      initBlank();
    } else {
      _confirmActionIfUnsaved('Créer un nouveau cours', initBlank);
    }
  }

  void _confirmActionIfUnsaved(String actionTitle, VoidCallback onConfirm) {
    // If the project is 100% blank or has no meaningful unsaved changes, do not annoy the user
    final isBlank = (_courseTitle == 'Nouveau Cours' || _courseTitle.isEmpty) &&
                    _courseDesc.isEmpty &&
                    _modules.isEmpty;
    if (!_hasUnsavedChanges || isBlank) {
      onConfirm();
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          title: Text('Projet en cours non enregistré ($actionTitle)', style: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 16)),
          content: Text(
            'Vous avez des modifications non exportées sur "${_courseTitle.isEmpty ? "Nouveau cours" : _courseTitle}".\n\nSouhaitez-vous continuer et démarrer une nouvelle session ?',
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('Écraser et continuer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNativeFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tdc', 'json', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final content = await file.readAsString();

        _confirmActionIfUnsaved('Ouvrir un fichier', () {
          if (filePath.endsWith('.json')) {
            final jsonMap = jsonDecode(content);
            final tdcStr = TDCParser.serializeToTdc(jsonMap);
            _loadRawCodeIntoEditor(tdcStr, isNewDoc: true, originalPath: filePath);
          } else {
            _loadRawCodeIntoEditor(content, isNewDoc: true, originalPath: filePath);
          }
          _showFloatingToast('Fichier .tdc chargé : ${result.files.single.name}');
        });
      }
    } catch (e) {
      _showFloatingToast('Erreur d\'ouverture du fichier : $e', isError: true);
    }
  }

  List<String> _validateCourse() {
    final List<String> errors = [];
    if (_courseTitle.trim().isEmpty) {
      errors.add('Le titre du cours est obligatoire.');
    }
    if (_courseId.trim().isEmpty) {
      errors.add('L\'identifiant (slug) du cours est obligatoire.');
    }
    if (_modules.isEmpty) {
      errors.add('Le cours doit contenir au moins 1 chapitre.');
    }
    for (int i = 0; i < _modules.length; i++) {
      final m = _modules[i];
      final title = (m['title'] ?? '').toString().trim();
      final markdown = (m['markdown'] ?? '').toString().trim();
      if (title.isEmpty) {
        errors.add('Chapitre #${i + 1} : Titre manquant.');
      }
      if (markdown.isEmpty) {
        errors.add('Chapitre #${i + 1} : Contenu Markdown vide.');
      }

      final quizList = (m['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (int q = 0; q < quizList.length; q++) {
        final quiz = quizList[q];
        final qText = (quiz['question'] ?? '').toString().trim();
        final options = (quiz['options'] as List?)?.cast<String>() ?? [];
        final answer = (quiz['answer'] as int?) ?? -1;

        if (qText.isEmpty) {
          errors.add('Chapitre #${i + 1}, Question #${q + 1} : Énoncé vide.');
        }
        if (options.length < 2) {
          errors.add('Chapitre #${i + 1}, Question #${q + 1} : Minimum 2 choix requis.');
        }
        if (answer < 0 || answer >= options.length) {
          errors.add('Chapitre #${i + 1}, Question #${q + 1} : Bonne réponse non sélectionnée.');
        }
      }
    }
    return errors;
  }

  void _exportTdcFile() async {
    final errors = _validateCourse();
    if (errors.isNotEmpty) {
      _showValidationErrorsDialog(errors);
      return;
    }

    try {
      _syncFormToRawCode();
      final tdcContent = _rawCodeController.text;
      final defaultName = '${_courseId.isNotEmpty ? _courseId : "course"}.tdc';

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter le cours (.tdc)',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['tdc'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(tdcContent);

        setState(() {
          _hasUnsavedChanges = false;
          _isNewUnsavedProject = false;
        });

        _showFloatingToast('Cours exporté avec succès : ${file.path.split("/").last}');
      }
    } catch (e) {
      _showFloatingToast('Erreur lors de l\'exportation : $e', isError: true);
    }
  }

  void _showValidationErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE11D48)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48)),
              SizedBox(width: 10),
              Text('Checklist de validation .TDC', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 350),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Corrigez les points suivants avant d\'exporter votre cours :',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: errors.length,
                    itemBuilder: (context, i) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1215),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                errors[i],
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5EBDA),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Compris, je corrige'),
            ),
          ],
        );
      },
    );
  }

  void _showFloatingToast(String message, {bool isError = false, VoidCallback? onUndo}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 380,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isError ? const Color(0xFFE11D48) : const Color(0xFF1E1E1E),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.white : const Color(0xFFF5EBDA),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onUndo != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onUndo();
                },
                child: const Text('Annuler', style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  void _loadRawCodeIntoEditor(String code, {bool isNewDoc = false, String? originalPath}) {
    _rawCodeController.text = code;
    _parseRawCode(code, updateForm: true);
    setState(() {
      _showWelcomeScreen = false;
      _hasUnsavedChanges = !isNewDoc;
      _isNewUnsavedProject = false;
    });

    if (_parsedCourse != null) {
      final pId = _parsedCourse!['id'] ?? 'cours-ouvert';
      final pTitle = _parsedCourse!['title'] ?? 'Cours ouvert';
      final pCat = _parsedCourse!['category'] ?? 'linux';

      _recentProjects.removeWhere((p) => p['id'] == pId || p['title'] == pTitle);
      _recentProjects.insert(0, {
        'id': pId,
        'title': pTitle,
        'category': pCat,
        'date': "Modifié à l'instant",
        'path': originalPath ?? 'workspace/$pId.tdc',
      });
      _saveRecentProjectsToPrefs();
    }
  }

  void _loadTemplate(String type) {
    final Map<String, dynamic> templateData = _getTemplateData(type);

    if (!_showWelcomeScreen && _modules.isNotEmpty) {
      // User is already inside editor and has started work: import modules only
      final newModules = (templateData['content'] as List?)?.map((m) => Map<String, dynamic>.from(m as Map)).toList() ?? [];
      setState(() {
        _modules.addAll(newModules);
        while (_expandedModules.length < _modules.length) {
          _expandedModules.add(true);
        }
      });
      _markModified();
      _syncFormToRawCode();
      _showFloatingToast('${newModules.length} chapitres importés depuis le modèle ${templateData['title']}');
      return;
    }

    // Otherwise load full template
    final tdcStr = TDCParser.serializeToTdc(templateData);
    _loadRawCodeIntoEditor(tdcStr, isNewDoc: true);
    _showFloatingToast('Modèle ${templateData['title']} chargé avec succès !');
  }

  Map<String, dynamic> _getTemplateData(String type) {
    switch (type) {
      case 'linux':
        return {
          'id': 'linux-mastery',
          'title': 'Maîtrise de l\'Administration Linux',
          'description': 'Guide complet d\'administration système, permissions POSIX et services systemd.',
          'category': 'linux',
          'level': 'intermediate',
          'duration': '3h',
          'icon': 'Terminal',
          'keywords': ['linux', 'sysadmin', 'bash', 'posix'],
          'content': [
            {
              'title': '1. Gestion des Droits et Permissions POSIX',
              'markdown': '## Permissions Linux\n\nComprendre `chmod`, `chown` et les masques octaux (ex: 755, 644).\n\n```bash\nchmod 700 /root/.ssh\nls -la /root/.ssh\n```\n\n### Points Clés :\n- `r` (read) = 4\n- `w` (write) = 2\n- `x` (execute) = 1',
              'quiz': [
                {
                  'question': 'Quelle valeur octale correspond aux permissions rwxr-xr-x ?',
                  'options': ['755', '644', '700', '777'],
                  'answer': 0,
                  'explanation': 'rwx = 4+2+1=7, r-x = 4+0+1=5, r-x = 4+0+1=5. Le résultat est 755.',
                }
              ]
            },
            {
              'title': '2. Gestion des Services avec Systemd',
              'markdown': '## Contrôle de services avec systemctl\n\n```bash\nsudo systemctl status sshd\nsudo systemctl restart sshd\n```',
              'quiz': [
                {
                  'question': 'Quelle commande permet d\'activer un service au démarrage ?',
                  'options': ['systemctl enable <service>', 'systemctl start <service>', 'systemctl boot <service>', 'service <service> on'],
                  'answer': 0,
                  'explanation': '`systemctl enable` crée les liens symboliques nécessaires au démarrage automatique.',
                }
              ]
            }
          ]
        };

      case 'network':
        return {
          'id': 'network-foundations',
          'title': 'Architecture Réseau & Routage IP',
          'description': 'Comprendre le modèle OSI, le subnetting IPv4/IPv6 et les protocoles TCP/UDP.',
          'category': 'network',
          'level': 'beginner',
          'duration': '2h30',
          'icon': 'Server',
          'keywords': ['network', 'ip', 'cidr', 'tcp', 'udp'],
          'content': [
            {
              'title': '1. Masques CIDR et Sous-Réseaux',
              'markdown': '## Subnetting IPv4\n\nUn masque `/24` correspond à `255.255.255.0` et offre 254 adresses hôtes exploitables.',
              'quiz': [
                {
                  'question': 'Combien d\'adresses IP utilisables contient un sous-réseau en /28 ?',
                  'options': ['14', '16', '30', '6'],
                  'answer': 0,
                  'explanation': '2^(32-28) - 2 = 16 - 2 = 14 adresses hôtes utilisables.',
                }
              ]
            }
          ]
        };

      case 'security':
        return {
          'id': 'cybersecurity-defense',
          'title': 'Fondamentaux de la Sécurité Offensive & Défensive',
          'description': 'Hardening d\'infrastructures, analyse de vulnérabilités et cryptographie appliquée.',
          'category': 'security',
          'level': 'advanced',
          'duration': '4h',
          'icon': 'ShieldAlert',
          'keywords': ['security', 'hardening', 'ctf', 'ssh'],
          'content': [
            {
              'title': '1. Hardening SSH et Clés Cryptographiques',
              'markdown': '## Sécurisation de SSH\n\nDésactivez l\'authentification par mot de passe et l\'accès direct root.',
              'quiz': [
                {
                  'question': 'Quelle directive sshd_config désactive la connexion root par mot de passe ?',
                  'options': ['PermitRootLogin prohibit-password', 'AllowRoot no', 'DisableRoot yes', 'RootLogin off'],
                  'answer': 0,
                  'explanation': '`PermitRootLogin prohibit-password` restreint l\'accès root aux seules clés publiques.',
                }
              ]
            }
          ]
        };

      case 'cloud':
        return {
          'id': 'cloud-docker-k8s',
          'title': 'Conteneurisation Docker & Orchestration',
          'description': 'Création d\'images Docker souveraines, multi-stage builds et déploiements locaux.',
          'category': 'cloud',
          'level': 'intermediate',
          'duration': '2h',
          'icon': 'Cloud',
          'keywords': ['cloud', 'docker', 'containers', 'linux'],
          'content': [
            {
              'title': '1. Anatomie d\'un Dockerfile Optimisé',
              'markdown': '## Multi-stage Builds\n\nRéduisez la taille de vos images de production en séparant build et runtime.',
              'quiz': [
                {
                  'question': 'Quel mot-clé Dockerfile permet d\'utiliser plusieurs étapes de build ?',
                  'options': ['FROM <image> AS <stage>', 'STAGE <name>', 'BUILD <step>', 'MULTI <base>'],
                  'answer': 0,
                  'explanation': '`FROM <image> AS <stage>` nomme l\'étape de build pour copier ses artefacts plus loin.',
                }
              ]
            }
          ]
        };

      case 'crypto':
        return {
          'id': 'cryptography-applied',
          'title': 'Cryptographie Appliquée & Chiffrement Asymétrique',
          'description': 'Principes de RSA, courbes elliptiques Ed25519 et intégrité SHA-256.',
          'category': 'crypto',
          'level': 'advanced',
          'duration': '3h',
          'icon': 'Key',
          'keywords': ['crypto', 'rsa', 'ed25519', 'sha256'],
          'content': [
            {
              'title': '1. Chiffrement Symétrique vs Asymétrique',
              'markdown': '## AES vs RSA\n\nAES-256-GCM offre rapidité et intégrité (chiffrement authentifié).',
              'quiz': [
                {
                  'question': 'Quel algorithme asymétrique moderne est recommandé pour SSH ?',
                  'options': ['Ed25519', 'DSA 1024', 'DES', 'MD5'],
                  'answer': 0,
                  'explanation': 'Ed25519 offre la meilleure sécurité et performance pour les signatures numériques.',
                }
              ]
            }
          ]
        };

      case 'development':
      default:
        return {
          'id': 'python-automation',
          'title': 'Développement & Automatisation Système',
          'description': 'Scripts d\'administration, parsing de logs et interactions API réseau.',
          'category': 'development',
          'level': 'beginner',
          'duration': '2h',
          'icon': 'Code',
          'keywords': ['python', 'scripting', 'automation', 'cli'],
          'content': [
            {
              'title': '1. Scripts CLI et Gestion des Arguments',
              'markdown': '## Module argparse\n\nCréez des outils en ligne de commande conviviaux et professionnels.',
              'quiz': [
                {
                  'question': 'Quel module standard Python permet de parser les arguments CLI ?',
                  'options': ['argparse', 'syscli', 'optparser', 'cli_parser'],
                  'answer': 0,
                  'explanation': '`argparse` est le module standard officiel pour construire des interfaces en ligne de commande.',
                }
              ]
            }
          ]
        };
    }
  }

  void _showTemplatesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final templates = [
          {'type': 'linux', 'title': 'Administration Linux', 'cat': 'LINUX', 'color': const Color(0xFFD7CDBF), 'desc': 'POSIX, systemd, gestion de paquets et logs.', 'meta': '2 chapitres • 2 questions'},
          {'type': 'network', 'title': 'Architecture Réseau', 'cat': 'RÉSEAU', 'color': const Color(0xFF8B5CF6), 'desc': 'Subnetting IPv4/IPv6, CIDR, DNS et routage.', 'meta': '1 chapitre • 1 question'},
          {'type': 'security', 'title': 'Sécurité Offensive & Hardening', 'cat': 'SÉCURITÉ', 'color': const Color(0xFF10B981), 'desc': 'Hardening SSH, CTF et cryptographie.', 'meta': '1 chapitre • 1 question'},
          {'type': 'cloud', 'title': 'Docker & Conteneurs', 'cat': 'CLOUD', 'color': const Color(0xFF3B82F6), 'desc': 'Images souveraines, multi-stage et orchestration.', 'meta': '1 chapitre • 1 question'},
          {'type': 'crypto', 'title': 'Cryptographie Appliquée', 'cat': 'CRYPTO', 'color': const Color(0xFFE11D48), 'desc': 'AES-256, RSA, Ed25519 et hachage SHA-256.', 'meta': '1 chapitre • 1 question'},
          {'type': 'development', 'title': 'Python & Automatisation', 'cat': 'DEV', 'color': const Color(0xFFF59E0B), 'desc': 'Scripts système, parsing JSON et outils CLI.', 'meta': '1 chapitre • 1 question'},
        ];

        return Dialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2E2E2E)),
          ),
          child: Container(
            width: 780,
            constraints: const BoxConstraints(maxHeight: 580),
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EBDA).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFFF5EBDA), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Modèles de Cours Professionnels', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Sélectionnez une trame technique prête à l\'emploi.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 135,
                      ),
                      itemCount: templates.length,
                      itemBuilder: (context, idx) {
                        final t = templates[idx];
                        final catColor = t['color'] as Color;
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            _loadTemplate(t['type'] as String);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1B1B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2D2D2D)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: catColor.withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        t['cat'] as String,
                                        style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  t['title'] as String,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t['desc'] as String,
                                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Text(
                                  t['meta'] as String,
                                  style: TextStyle(color: catColor.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommandPaletteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        final List<Map<String, dynamic>> allActions = [
          {'title': 'Nouveau cours vierge', 'subtitle': 'Créer un projet vide de zéro', 'icon': Icons.add_circle_outline, 'action': () => _createNewBlankCourse()},
          {'title': 'Ouvrir un fichier .tdc', 'subtitle': 'Importer un cours existant', 'icon': Icons.file_open_outlined, 'action': () => _openNativeFilePicker()},
          {'title': 'Partir d\'un modèle Linux', 'subtitle': 'Trame d\'administration système', 'icon': Icons.terminal, 'action': () => _loadTemplate('linux')},
          {'title': 'Partir d\'un modèle Réseau', 'subtitle': 'Trame d\'architecture IP & CIDR', 'icon': Icons.hub_outlined, 'action': () => _loadTemplate('network')},
          {'title': 'Partir d\'un modèle Sécurité', 'subtitle': 'Trame de sécurité offensive & SSH', 'icon': Icons.shield_outlined, 'action': () => _loadTemplate('security')},
          {'title': 'Partir d\'un modèle Cloud', 'subtitle': 'Trame Docker & conteneurisation', 'icon': Icons.cloud_outlined, 'action': () => _loadTemplate('cloud')},
          {'title': 'Partir d\'un modèle Cryptographie', 'subtitle': 'Trame de chiffrement & Ed25519', 'icon': Icons.key_outlined, 'action': () => _loadTemplate('crypto')},
          {'title': 'Partir d\'un modèle Développement', 'subtitle': 'Trame de scripts Python & CLI', 'icon': Icons.code, 'action': () => _loadTemplate('development')},
          {'title': 'Aperçu Apprenant T2DECODE', 'subtitle': 'Visualiser l\'immersion du lecteur', 'icon': Icons.play_circle_fill_rounded, 'action': () => _openT2DecodePlayerPreview(null)},
          {'title': 'Exporter le cours (.tdc)', 'subtitle': 'Générer le fichier de distribution', 'icon': Icons.download, 'action': () => _exportTdcFile()},
          {'title': 'Documentation Spécification .TDC', 'subtitle': 'Grammaire et syntaxe du format', 'icon': Icons.menu_book_outlined, 'action': () => _showDocsDialog()},
        ];

        return StatefulBuilder(
          builder: (context, setPaletteState) {
            final filtered = query.trim().isEmpty
                ? allActions
                : allActions.where((a) =>
                    a['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
                    a['subtitle'].toString().toLowerCase().contains(query.toLowerCase())).toList();

            return Dialog(
              backgroundColor: const Color(0xFF141414),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF333333)),
              ),
              child: Container(
                width: 580,
                constraints: const BoxConstraints(maxHeight: 460),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFF5EBDA)),
                        hintText: 'Rechercher une action, un modèle${_recentProjects.isNotEmpty ? " ou un cours" : ""}…',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1C1C1C),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF333333))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF333333))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5EBDA))),
                      ),
                      onChanged: (val) {
                        setPaletteState(() => query = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF242424), height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('Aucune action correspondante', style: TextStyle(color: Colors.grey, fontSize: 13)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, idx) {
                                final act = filtered[idx];
                                return ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  leading: Icon(act['icon'] as IconData, color: const Color(0xFFF5EBDA), size: 18),
                                  title: Text(act['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                  subtitle: Text(act['subtitle'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  trailing: const Icon(Icons.keyboard_return, size: 14, color: Colors.grey),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    (act['action'] as VoidCallback)();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDocsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF2E2E2E)),
          ),
          title: const Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFFF5EBDA), size: 20),
              SizedBox(width: 10),
              Text('Spécification & Grammaire .TDC', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 420),
            child: const SingleChildScrollView(
              child: Text(
                'Le format TDC (TutoDeCode Course) est une grammaire de description déclarative de modules d\'ingénierie.\n\n'
                'Syntaxe globale :\n'
                'course "slug-id" {\n'
                '  metadata {\n'
                '    title: "Titre du Cours"\n'
                '    description: "Description"\n'
                '    category: "linux"\n'
                '    level: "beginner"\n'
                '    duration: "2h"\n'
                '  }\n'
                '  module "Titre du Chapitre" {\n'
                '    markdown: "Contenu..."\n'
                '    quiz {\n'
                '      question: "Énoncé ?"\n'
                '      options: ["A", "B"]\n'
                '      answer: 0\n'
                '      explanation: "Raison"\n'
                '    }\n'
                '  }\n'
                '}',
                style: TextStyle(fontFamily: 'monospace', color: Color(0xFFD4D4D4), fontSize: 12, height: 1.5),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5EBDA),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF2E2E2E)),
          ),
          title: const Text('Paramètres de l\'IDE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TDC Studio IDE v1.7 • Mode Développeur', style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 8),
              Text('• Encodage par défaut : UTF-8', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('• Auto-sauvegarde : Activée (Temps réel)', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('• Parseur : Grammaire TDC Lexer v2', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5EBDA), foregroundColor: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarkdownToolbar(TextEditingController controller, VoidCallback onUpdate) {
    void wrapSelection(String prefix, String suffix) {
      final sel = controller.selection;
      final text = controller.text;
      if (sel.isValid && sel.start != sel.end) {
        final selectedText = text.substring(sel.start, sel.end);
        final newText = text.replaceRange(sel.start, sel.end, '$prefix$selectedText$suffix');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection(baseOffset: sel.start + prefix.length, extentOffset: sel.end + prefix.length),
        );
      } else {
        final pos = sel.isValid ? sel.start : text.length;
        final newText = text.replaceRange(pos, pos, '$prefix$suffix');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: pos + prefix.length),
        );
      }
      onUpdate();
    }

    Widget toolBtn(String label, IconData? icon, VoidCallback onTap, {String? tooltip}) {
      return Tooltip(
        message: tooltip ?? label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, size: 13, color: const Color(0xFFF5EBDA)),
                if (icon != null && label.isNotEmpty) const SizedBox(width: 4),
                if (label.isNotEmpty)
                  Text(label, style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
        border: Border(
          top: BorderSide(color: Color(0xFF2B2B2B)),
          left: BorderSide(color: Color(0xFF2B2B2B)),
          right: BorderSide(color: Color(0xFF2B2B2B)),
          bottom: BorderSide(color: Color(0xFF242424)),
        ),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          toolBtn('H1', null, () => wrapSelection('# ', ''), tooltip: 'Titre 1'),
          toolBtn('H2', null, () => wrapSelection('## ', ''), tooltip: 'Titre 2'),
          toolBtn('B', Icons.format_bold, () => wrapSelection('**', '**'), tooltip: 'Gras'),
          toolBtn('I', Icons.format_italic, () => wrapSelection('*', '*'), tooltip: 'Italique'),
          toolBtn('Code', Icons.code, () => wrapSelection('```bash\n', '\n```'), tooltip: 'Bloc de code'),
          toolBtn('Liste', Icons.format_list_bulleted, () => wrapSelection('- ', ''), tooltip: 'Liste à puces'),
          toolBtn('Terminal', Icons.terminal, () => wrapSelection('```terminal\n\$ ', '\n```'), tooltip: 'Bac à sable terminal'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcomeScreen) {
      return _buildWelcomeScreen();
    }
    return _buildCourseEditor();
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_recentProjects.isNotEmpty) ...[
                        _buildSectionLabel('REPRENDRE'),
                        const SizedBox(height: 10),
                        _buildHeroResumeCard(),
                        const SizedBox(height: 28),
                      ],

                      _buildSectionLabel('CRÉER'),
                      const SizedBox(height: 10),
                      _buildCreateSectionCards(),

                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionLabel('RÉCENTS'),
                          if (_recentProjects.isNotEmpty) _buildSortDropdown(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildRecentProjectsFullTable(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(bottom: BorderSide(color: Color(0xFF262626))),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              'assets/logo_128.png',
              height: 32,
              width: 32,
              filterQuality: FilterQuality.high,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TDC Studio IDE',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                'Créez, éditez et prévisualisez vos cours au format .tdc.',
                style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: InkWell(
                onTap: _showCommandPaletteDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFFA3A3A3), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rechercher une action, un modèle${_recentProjects.isNotEmpty ? " ou un cours" : ""}…',
                          style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Ctrl K', style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD4D4D4),
              side: const BorderSide(color: Color(0xFF333333)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.description_outlined, size: 15),
            label: const Text('Docs', style: TextStyle(fontSize: 12)),
            onPressed: _showDocsDialog,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFD4D4D4), size: 18),
            tooltip: 'Paramètres',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFA3A3A3),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildHeroResumeCard() {
    if (_recentProjects.isEmpty) return const SizedBox.shrink();
    final hero = _recentProjects.first;
    final categoryColor = _getCategoryColor(hero['category'] as String? ?? 'linux');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: categoryColor.withOpacity(0.3)),
            ),
            child: Icon(Icons.edit_document, color: categoryColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hero['title'] as String? ?? 'Projet récent',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (hero['category'] as String? ?? 'LINUX').toUpperCase(),
                        style: TextStyle(color: categoryColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${hero['date'] ?? "Modifié récemment"} • Emplacement : ${hero['path'] ?? "local"}',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5EBDA),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.black),
            label: const Text('Reprendre l\'édition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => _openRecentProject(hero),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSectionCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 820;

        Widget c1 = _buildActionCard(
          title: 'Nouveau cours',
          subtitle: 'Partir de zéro : formulaire, chapitres et QCM vierges.',
          icon: Icons.add_box_outlined,
          shortcut: 'N',
          onTap: _createNewBlankCourse,
        );

        Widget c2 = _buildActionCard(
          title: 'Ouvrir un fichier',
          subtitle: 'Importez un cours .tdc ou .json (ou glissez-déposez).',
          icon: Icons.folder_open_outlined,
          shortcut: 'O',
          onTap: _openNativeFilePicker,
        );

        Widget c3 = _buildActionCard(
          title: 'Partir d\'un modèle',
          subtitle: '6 trames pro prêtes à l\'emploi.',
          icon: Icons.auto_awesome_outlined,
          tags: ['LINUX', 'RÉSEAU', 'SÉCURITÉ', 'CLOUD', 'CRYPTO', 'DEV'],
          onTap: _showTemplatesDialog,
        );

        if (isNarrow) {
          return Column(
            children: [
              c1,
              const SizedBox(height: 12),
              c2,
              const SizedBox(height: 12),
              c3,
              const SizedBox(height: 14),
              _buildDropzoneCard(),
            ],
          );
        }

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: c1),
                  const SizedBox(width: 14),
                  Expanded(child: c2),
                  const SizedBox(width: 14),
                  Expanded(child: c3),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildDropzoneCard(),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    String? shortcut,
    List<String>? tags,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF262626)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFFF5EBDA), size: 18),
                ),
                if (shortcut != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: Text(shortcut, style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontFamily: 'monospace')),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 12)),
              ],
            ),
            if (tags != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((t) {
                  final catColor = _getCategoryColor(t == 'RÉSEAU' ? 'network' : (t == 'SÉCURITÉ' ? 'security' : (t == 'DEV' ? 'development' : t.toLowerCase())));
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(t, style: TextStyle(color: catColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropzoneCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2B2B2B), style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_outlined, color: Color(0xFFF5EBDA), size: 20),
          const SizedBox(width: 12),
          const Text(
            'Déposez un fichier .tdc / .json ici pour l\'ouvrir directement dans l\'IDE',
            style: TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
          const SizedBox(width: 14),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF5EBDA),
              side: const BorderSide(color: Color(0xFF444444)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _openNativeFilePicker,
            child: const Text('Parcourir', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Row(
        children: [
          const Text('Trier par : Modifié', style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 11)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, color: Color(0xFFA3A3A3), size: 16),
        ],
      ),
    );
  }

  Widget _buildRecentProjectsFullTable() {
    if (_recentProjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, color: Color(0xFF666666), size: 36),
            const SizedBox(height: 12),
            const Text(
              'Aucun projet récent',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pour démarrer votre premier module d\'ingénierie :',
              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5EBDA),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Nouveau cours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _createNewBlankCourse,
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF5EBDA),
                    side: const BorderSide(color: Color(0xFF444444)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 15),
                  label: const Text('Partir d\'un modèle', style: TextStyle(fontSize: 12)),
                  onPressed: _showTemplatesDialog,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF222222))),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('PROJET', style: TextStyle(color: Color(0xFF777777), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('CATÉGORIE', style: TextStyle(color: Color(0xFF777777), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('NIVEAU', style: TextStyle(color: Color(0xFF777777), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('DERNIÈRE MUTATION', style: TextStyle(color: Color(0xFF777777), fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 60, child: Text('ACTIONS', style: TextStyle(color: Color(0xFF777777), fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentProjects.length,
            separatorBuilder: (_, __) => const Divider(color: Color(0xFF222222), height: 1),
            itemBuilder: (context, idx) {
              final p = _recentProjects[idx];
              final catColor = _getCategoryColor(p['category'] as String? ?? 'linux');
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined, color: catColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p['title'] as String? ?? 'Sans titre',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text((p['category'] as String? ?? 'LINUX').toUpperCase(), style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Fondation', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(p['date'] as String? ?? 'Récemment', style: const TextStyle(color: Color(0xFF777777), fontSize: 12)),
                    ),
                    SizedBox(
                      width: 60,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                        color: const Color(0xFF1C1C1C),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'open', child: Text('Ouvrir l\'éditeur', style: TextStyle(color: Colors.white, fontSize: 12))),
                          const PopupMenuItem(value: 'duplicate', child: Text('Dupliquer', style: TextStyle(color: Colors.white, fontSize: 12))),
                          const PopupMenuItem(value: 'delete', child: Text('Supprimer des récents', style: TextStyle(color: Color(0xFFE11D48), fontSize: 12))),
                        ],
                        onSelected: (val) {
                          if (val == 'open') {
                            _openRecentProject(p);
                          } else if (val == 'duplicate') {
                            setState(() {
                              _recentProjects.insert(0, {
                                ...p,
                                'id': '${p['id']}-copie',
                                'title': '${p['title']} (Copie)',
                                'date': "Modifié à l'instant",
                              });
                            });
                            _saveRecentProjectsToPrefs();
                            _showFloatingToast('Projet dupliqué avec succès');
                          } else if (val == 'delete') {
                            final pId = p['id']?.toString() ?? '';
                            final pTitle = p['title']?.toString() ?? '';
                            final pPath = p['path']?.toString() ?? '';
                            if (pId.isNotEmpty) _deletedProjectIds.add(pId);
                            if (pTitle.isNotEmpty) _deletedProjectIds.add(pTitle);
                            if (pPath.isNotEmpty) _deletedProjectIds.add(pPath);

                            setState(() {
                              _recentProjects.removeAt(idx);
                            });
                            _saveRecentProjectsToPrefs();
                            _showFloatingToast('Projet supprimé des récents');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                onTap: () => _openRecentProject(p),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final hasActiveDraft = (_courseTitle.isNotEmpty && _courseTitle != 'Nouveau Cours') || _modules.isNotEmpty || _courseDesc.isNotEmpty;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Color(0xFF222222))),
      ),
      child: Row(
        children: [
          const Text('v1.7', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const SizedBox(width: 14),
          if (_showWelcomeScreen) ...[
            if (hasActiveDraft && _hasUnsavedChanges)
              Row(
                children: [
                  const Icon(Icons.circle, color: Color(0xFFF59E0B), size: 9),
                  const SizedBox(width: 6),
                  Text(
                    'Session active en mémoire : ${_courseTitle.isEmpty ? "Nouveau cours" : _courseTitle}',
                    style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                  ),
                ],
              )
            else
              const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF10B981), size: 9),
                  SizedBox(width: 6),
                  Text('Prêt', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                ],
              ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.check_circle, color: _hasUnsavedChanges ? const Color(0xFFF59E0B) : const Color(0xFF10B981), size: 12),
                const SizedBox(width: 4),
                Text(
                  _hasUnsavedChanges ? 'Modifications non enregistrées' : 'Autosave ✓',
                  style: TextStyle(color: _hasUnsavedChanges ? const Color(0xFFF59E0B) : const Color(0xFF10B981), fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.grey, size: 12),
                const SizedBox(width: 4),
                Text('${_modules.length} ${_modules.length == 1 ? "chapitre" : "chapitres"}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
          const Spacer(),
          const Text('Spécification .TDC', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 14),
          const Text('UTF-8', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCourseEditor() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF5EBDA)),
          tooltip: 'Retour à l\'accueil (Cockpit)',
          onPressed: _navigateHomeAndAutoSaveDraft,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _courseTitle.isEmpty ? 'Nouveau Cours' : _courseTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    String statusLabel = 'Enregistré';
                    Color statusBg = const Color(0xFF10B981).withOpacity(0.15);
                    Color statusColor = const Color(0xFF10B981);

                    if (_isNewUnsavedProject && !_hasUnsavedChanges) {
                      statusLabel = 'Nouveau';
                      statusBg = const Color(0xFF262626);
                      statusColor = const Color(0xFFAAAAAA);
                    } else if (_hasUnsavedChanges) {
                      statusLabel = 'Modifié';
                      statusBg = const Color(0xFFF59E0B).withOpacity(0.15);
                      statusColor = const Color(0xFFF59E0B);
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            Text(
              '${_courseId.isEmpty ? "sans-id" : _courseId}.tdc • ${_modules.length} ${_modules.length == 1 ? "chapitre" : "chapitres"}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Color(0xFFF5EBDA)),
            tooltip: 'Annuler (Ctrl+Z)',
            onPressed: _undoHistory.length > 1 ? _performUndo : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Color(0xFFF5EBDA)),
            tooltip: 'Plus d\'actions',
            color: const Color(0xFF1C1C1C),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.file_open_outlined, color: Color(0xFFF5EBDA), size: 16),
                    SizedBox(width: 8),
                    Text('Ouvrir un fichier .tdc', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: Color(0xFFF5EBDA), size: 16),
                    SizedBox(width: 8),
                    Text('Charger un modèle...', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, color: Color(0xFFF5EBDA), size: 16),
                    SizedBox(width: 8),
                    Text('Copier le code .TDC', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'open') {
                _openNativeFilePicker();
              } else if (val == 'template') {
                _showTemplatesDialog();
              } else if (val == 'copy') {
                Clipboard.setData(ClipboardData(text: _rawCodeController.text));
                _showFloatingToast('Code .TDC copié dans le presse-papier !');
              }
            },
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5EBDA),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Exporter .TDC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _exportTdcFile,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFFF5EBDA).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF5EBDA).withOpacity(0.4)),
              ),
              labelColor: const Color(0xFFF5EBDA),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit_note, size: 18), SizedBox(width: 6), Text('Formulaire')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.code, size: 18), SizedBox(width: 6), Text('Code .TDC')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_circle_outline, size: 18), SizedBox(width: 6), Text('Aperçu Apprenant')])),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormView(),
          _buildCodeView(),
          _buildLivePreviewView(),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('1. Informations Générales du Cours', Icons.info_outline),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField('ID du Cours (slug-kebab-case)', _courseId, (val) {
                  final slug = val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '-');
                  setState(() {
                    _courseId = slug;
                  });
                  _markModified();
                  _syncFormToRawCode();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('Titre du Cours', _courseTitle, (val) {
                  setState(() => _courseTitle = val);
                  _markModified();
                  _syncFormToRawCode();
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('Description Pédagogique', _courseDesc, (val) {
            setState(() => _courseDesc = val);
            _markModified();
            _syncFormToRawCode();
          }, maxLines: 2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('category_select'),
                  value: _category,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Catégorie'),
                  items: [
                    _buildCategoryItem('linux', 'Linux', const Color(0xFFD7CDBF)),
                    _buildCategoryItem('network', 'Réseau', const Color(0xFF8B5CF6)),
                    _buildCategoryItem('security', 'Sécurité', const Color(0xFF10B981)),
                    _buildCategoryItem('cloud', 'Cloud', const Color(0xFF3B82F6)),
                    _buildCategoryItem('crypto', 'Crypto', const Color(0xFFE11D48)),
                    _buildCategoryItem('development', 'Développement', const Color(0xFFF59E0B)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _category = val);
                      _markModified();
                      _syncFormToRawCode();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('level_select'),
                  value: _level,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Niveau'),
                  items: [
                    _buildLevelItem('beginner', 'Fondation / Débutant', const Color(0xFF10B981)),
                    _buildLevelItem('intermediate', 'Intermédiaire', const Color(0xFFF59E0B)),
                    _buildLevelItem('advanced', 'Avancé', const Color(0xFFEF4444)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _level = val);
                      _markModified();
                      _syncFormToRawCode();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Durée estimée (ex: 2h30)', _duration, (val) {
                  setState(() => _duration = val);
                  _markModified();
                  _syncFormToRawCode();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('Mots-clés (séparés par des virgules)', _keywords.join(', '), (val) {
                  setState(() {
                    _keywords = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  });
                  _markModified();
                  _syncFormToRawCode();
                }),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Modules Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('2. Chapitres & Modules (${_modules.length})', Icons.menu_book),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5EBDA),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter un chapitre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  setState(() {
                    _modules.add({
                      'title': 'Nouveau Chapitre ${_modules.length + 1}',
                      'markdown': '## Introduction\n\nContenu de la leçon en Markdown...',
                      'quiz': [],
                    });
                    _expandedModules.add(true);
                  });
                  _markModified();
                  _syncFormToRawCode();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_modules.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.menu_book_outlined, color: Color(0xFF555555), size: 36),
                  const SizedBox(height: 12),
                  const Text('Aucun chapitre pour le moment', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Commencez par ajouter votre premier chapitre ou partez d\'un modèle prêt à l\'emploi.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5EBDA),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Ajouter un chapitre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            _modules.add({
                              'title': 'Chapitre 1 : Introduction',
                              'markdown': '## Introduction\n\nContenu du chapitre en Markdown...',
                              'quiz': [],
                            });
                            _expandedModules.add(true);
                          });
                          _markModified();
                          _syncFormToRawCode();
                        },
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF5EBDA),
                          side: const BorderSide(color: Color(0xFF444444)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 14),
                        label: const Text('Partir d\'un modèle', style: TextStyle(fontSize: 12)),
                        onPressed: _showTemplatesDialog,
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            ...List.generate(_modules.length, (index) => _buildModuleCard(index)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildCategoryItem(String val, String label, Color color) {
    return DropdownMenuItem(
      value: val,
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildLevelItem(String val, String label, Color color) {
    return DropdownMenuItem(
      value: val,
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildModuleCard(int index) {
    final m = _modules[index];
    while (_expandedModules.length <= index) {
      _expandedModules.add(true);
    }
    final isExpanded = _expandedModules[index];
    final quizList = (m['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final markdownController = TextEditingController(text: m['markdown'] ?? '');
    markdownController.selection = TextSelection.collapsed(offset: markdownController.text.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        children: [
          // Header Accordion
          InkWell(
            onTap: () {
              setState(() {
                _expandedModules[index] = !_expandedModules[index];
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(isExpanded ? 0 : 12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: const Color(0xFFF5EBDA),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBDA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m['title']?.toString().isEmpty ?? true ? 'Chapitre ${index + 1}' : m['title'].toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${quizList.length} ${quizList.length == 1 ? "question" : "questions"}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  if (index > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 16, color: Colors.grey),
                      tooltip: 'Monter',
                      onPressed: () {
                        setState(() {
                          final item = _modules.removeAt(index);
                          _modules.insert(index - 1, item);
                          final exp = _expandedModules.removeAt(index);
                          _expandedModules.insert(index - 1, exp);
                        });
                        _markModified();
                        _syncFormToRawCode();
                      },
                    ),
                  if (index < _modules.length - 1)
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
                      tooltip: 'Descendre',
                      onPressed: () {
                        setState(() {
                          final item = _modules.removeAt(index);
                          _modules.insert(index + 1, item);
                          final exp = _expandedModules.removeAt(index);
                          _expandedModules.insert(index + 1, exp);
                        });
                        _markModified();
                        _syncFormToRawCode();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE11D48)),
                    tooltip: 'Supprimer ce chapitre',
                    onPressed: () {
                      final deletedModule = Map<String, dynamic>.from(_modules[index]);
                      setState(() {
                        _modules.removeAt(index);
                        _expandedModules.removeAt(index);
                      });
                      _markModified();
                      _syncFormToRawCode();
                      _showFloatingToast('Chapitre #${index + 1} supprimé', onUndo: () {
                        setState(() {
                          _modules.insert(index, deletedModule);
                          _expandedModules.insert(index, true);
                        });
                        _markModified();
                        _syncFormToRawCode();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('Titre du Chapitre', m['title'] ?? '', (val) {
                    setState(() => m['title'] = val);
                    _markModified();
                    _syncFormToRawCode();
                  }),
                  const SizedBox(height: 16),
                  const Text('Contenu du Chapitre (Markdown)', style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),

                  // Mini Toolbar Markdown
                  _buildMarkdownToolbar(markdownController, () {
                    setState(() => m['markdown'] = markdownController.text);
                    _markModified();
                    _syncFormToRawCode();
                  }),

                  TextFormField(
                    controller: markdownController,
                    maxLines: null,
                    minLines: 6,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF181818),
                      hintText: 'Rédigez le contenu du chapitre en Markdown...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      contentPadding: EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFF2B2B2B)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFF2B2B2B)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFFF5EBDA)),
                      ),
                    ),
                    onChanged: (val) {
                      m['markdown'] = val;
                      _markModified();
                      _syncFormToRawCode();
                    },
                  ),

                  const SizedBox(height: 20),

                  // Quiz QCM section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions QCM (${quizList.length})',
                        style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF5EBDA),
                          side: const BorderSide(color: Color(0xFF444444)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Ajouter un QCM', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            quizList.add({
                              'question': 'Nouvelle question ?',
                              'options': ['Option A', 'Option B', 'Option C', 'Option D'],
                              'answer': 0,
                              'explanation': 'Explication de la réponse correcte.',
                            });
                            m['quiz'] = quizList;
                          });
                          _markModified();
                          _syncFormToRawCode();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ...List.generate(quizList.length, (qIdx) => _buildQuizCard(index, qIdx, quizList[qIdx])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(int modIdx, int qIdx, Map<String, dynamic> quiz) {
    final options = (quiz['options'] as List?)?.cast<String>() ?? [];
    final answerIdx = (quiz['answer'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF5EBDA).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text('Q${qIdx + 1}', style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField('Énoncé de la question', quiz['question'] ?? '', (val) {
                  setState(() => quiz['question'] = val);
                  _markModified();
                  _syncFormToRawCode();
                }),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Color(0xFFE11D48)),
                tooltip: 'Supprimer cette question',
                onPressed: () {
                  final deletedQuiz = Map<String, dynamic>.from(quiz);
                  setState(() {
                    (_modules[modIdx]['quiz'] as List).removeAt(qIdx);
                  });
                  _markModified();
                  _syncFormToRawCode();
                  _showFloatingToast('Question #${qIdx + 1} supprimée', onUndo: () {
                    setState(() {
                      (_modules[modIdx]['quiz'] as List).insert(qIdx, deletedQuiz);
                    });
                    _markModified();
                    _syncFormToRawCode();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Options de réponse (Cochez la bonne réponse) :', style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 8),
          ...List.generate(options.length, (optIdx) {
            final isCorrect = answerIdx == optIdx;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Radio<int>(
                    value: optIdx,
                    groupValue: answerIdx,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => quiz['answer'] = val);
                        _markModified();
                        _syncFormToRawCode();
                      }
                    },
                  ),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('opt_${modIdx}_${qIdx}_$optIdx'),
                      initialValue: options[optIdx],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isCorrect ? const Color(0xFF10B981) : const Color(0xFF333333))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isCorrect ? const Color(0xFF10B981) : const Color(0xFF333333))),
                      ),
                      onChanged: (val) {
                        options[optIdx] = val;
                        _markModified();
                        _syncFormToRawCode();
                      },
                    ),
                  ),
                  if (options.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          options.removeAt(optIdx);
                          if (quiz['answer'] >= options.length) {
                            quiz['answer'] = options.length - 1;
                          }
                        });
                        _markModified();
                        _syncFormToRawCode();
                      },
                    ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 14, color: Color(0xFFF5EBDA)),
              label: const Text('Ajouter une option', style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 11)),
              onPressed: () {
                setState(() {
                  options.add('Option ${String.fromCharCode(65 + options.length)}');
                });
                _markModified();
                _syncFormToRawCode();
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField('Explication Pédagogique (affichée après réponse)', quiz['explanation'] ?? '', (val) {
            setState(() => quiz['explanation'] = val);
            _markModified();
            _syncFormToRawCode();
          }, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildCodeView() {
    final lines = _rawCodeController.text.split('\n');

    return Column(
      children: [
        // Status Bar of TDC Code Editor
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF161616),
            border: Border(bottom: BorderSide(color: Color(0xFF262626))),
          ),
          child: Row(
            children: [
              if (_parseError.isEmpty) ...[
                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Syntaxe .TDC valide • ${_modules.length} ${_modules.length == 1 ? "chapitre" : "chapitres"} détectés',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ] else ...[
                const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _parseErrorLine != null
                        ? 'Erreur de syntaxe ligne $_parseErrorLine : $_parseError'
                        : 'Erreur de syntaxe : $_parseError',
                    style: const TextStyle(color: Color(0xFFE11D48), fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF5EBDA),
                  side: const BorderSide(color: Color(0xFF444444)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.copy, size: 13),
                label: const Text('Copier', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _rawCodeController.text));
                  _showFloatingToast('Code .TDC copié dans le presse-papier !');
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5EBDA),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.sync, size: 13),
                label: const Text('Synchroniser', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _parseRawCode(_rawCodeController.text, updateForm: true);
                  _showFloatingToast('Formulaire synchronisé depuis le code');
                },
              ),
            ],
          ),
        ),

        // Gutter + Code Editor
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line Number Gutter
              Container(
                width: 48,
                color: const Color(0xFF141414),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ListView.builder(
                  controller: _codeScrollController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lines.length,
                  itemBuilder: (context, i) {
                    final isErrorLine = _parseErrorLine == (i + 1);
                    return SizedBox(
                      height: 20,
                      child: Container(
                        color: isErrorLine ? const Color(0xFFE11D48).withOpacity(0.3) : Colors.transparent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: isErrorLine ? const Color(0xFFE11D48) : Colors.grey[600],
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: isErrorLine ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1, color: Color(0xFF242424)),

              // Text Field Editor
              Expanded(
                child: Container(
                  color: const Color(0xFF0D0D0D),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: TextField(
                    controller: _rawCodeController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFD4D4D4),
                      fontSize: 13.5,
                      height: 1.48,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: 'Saisissez du code .TDC brut ici...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onChanged: (val) {
                      _isCodeSourceOfTruth = true;
                      _parseRawCode(val, updateForm: true);
                      _markModified();
                      _isCodeSourceOfTruth = false;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreviewView() {
    final modules = _modules;

    if (modules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            const Text('Aucun chapitre à prévisualiser', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Ajoutez des chapitres dans le formulaire pour voir le rendu apprenant.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5EBDA), foregroundColor: Colors.black),
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Aller au formulaire'),
            ),
          ],
        ),
      );
    }

    final catColor = _getCategoryColor(_category);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header Badge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF262626)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: catColor.withOpacity(0.4)),
                          ),
                          child: Text(_category.toUpperCase(), style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: _getLevelColor(_level), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(_levelLabels[_level] ?? _level, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (_duration.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text('• $_duration', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.amber, size: 14),
                              SizedBox(width: 4),
                              Text('+150 XP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _courseTitle.isEmpty ? 'Titre du cours' : _courseTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (_courseDesc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_courseDesc, style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13, height: 1.4)),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Modules List with Markdown & Interactive QCM
              ...modules.asMap().entries.map((entry) {
                final modIdx = entry.key;
                final mod = entry.value;
                final quizList = (mod['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF222222)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFF5EBDA).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                            child: Text('CHAPITRE ${modIdx + 1}', style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mod['title']?.toString() ?? 'Chapitre ${modIdx + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF222222)),
                      const SizedBox(height: 16),

                      // Markdown Rendered Body
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF282828)),
                        ),
                        child: MarkdownBody(
                          data: mod['markdown']?.toString() ?? '',
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 14, height: 1.5),
                            h1: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 20, fontWeight: FontWeight.bold),
                            h2: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 17, fontWeight: FontWeight.bold),
                            h3: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 15, fontWeight: FontWeight.bold),
                            code: const TextStyle(color: Color(0xFF38BDF8), backgroundColor: Color(0xFF0F0F0F), fontFamily: 'monospace', fontSize: 13),
                            codeblockDecoration: BoxDecoration(
                              color: const Color(0xFF0A0A0A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF222222)),
                            ),
                          ),
                        ),
                      ),

                      if (quizList.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'ÉVALUATION DE CONNAISSANCES (${quizList.length} ${quizList.length == 1 ? "QUESTION" : "QUESTIONS"})',
                          style: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 12),
                        ...quizList.asMap().entries.map((qEntry) {
                          final qIdx = qEntry.key;
                          final q = qEntry.value;
                          final quizKey = '${modIdx}_$qIdx';
                          final options = (q['options'] as List?)?.cast<String>() ?? [];
                          final answer = (q['answer'] as int?) ?? 0;
                          final explanation = (q['explanation'] as String?) ?? '';

                          final userAns = _userQuizAnswers[quizKey];
                          final isValidated = _quizValidationResults[quizKey] != null;
                          final isCorrect = _quizValidationResults[quizKey] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161616),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isValidated ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFE11D48)) : const Color(0xFF2A2A2A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(4)),
                                      child: Text('Q${qIdx + 1}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        q['question']?.toString() ?? '',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (isValidated)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isCorrect ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFE11D48).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isCorrect ? '✓ Correct (+20 XP)' : '✗ Incorrect',
                                          style: TextStyle(color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFE11D48), fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...options.asMap().entries.map((oEntry) {
                                  final oIdx = oEntry.key;
                                  final oText = oEntry.value;
                                  final isSelected = userAns == oIdx;
                                  final isAnswerOption = answer == oIdx;

                                  Color optBg = const Color(0xFF1E1E1E);
                                  Color optBorder = const Color(0xFF333333);

                                  if (isValidated) {
                                    if (isAnswerOption) {
                                      optBg = const Color(0xFF10B981).withOpacity(0.15);
                                      optBorder = const Color(0xFF10B981);
                                    } else if (isSelected && !isCorrect) {
                                      optBg = const Color(0xFFE11D48).withOpacity(0.15);
                                      optBorder = const Color(0xFFE11D48);
                                    }
                                  } else if (isSelected) {
                                    optBg = const Color(0xFFF5EBDA).withOpacity(0.15);
                                    optBorder = const Color(0xFFF5EBDA);
                                  }

                                  return InkWell(
                                    onTap: isValidated
                                        ? null
                                        : () {
                                            setState(() {
                                              _userQuizAnswers[quizKey] = oIdx;
                                            });
                                          },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: optBg,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: optBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                            size: 16,
                                            color: isSelected ? const Color(0xFFF5EBDA) : Colors.grey,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(oText, style: const TextStyle(color: Colors.white, fontSize: 13))),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                                const SizedBox(height: 10),
                                if (!isValidated)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF5EBDA),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: userAns == null
                                        ? null
                                        : () {
                                            setState(() {
                                              _quizValidationResults[quizKey] = (userAns == answer);
                                            });
                                          },
                                    child: const Text('Valider la réponse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  )
                                else ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCorrect ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFE11D48).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isCorrect ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFE11D48).withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      isCorrect
                                          ? 'Explication : $explanation'
                                          : 'Bonne réponse : ${options[answer]}. $explanation',
                                      style: TextStyle(color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFFCA5A5), fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.refresh, size: 14, color: Colors.grey),
                                    label: const Text('Rejouer la question', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    onPressed: () {
                                      setState(() {
                                        _userQuizAnswers.remove(quizKey);
                                        _quizValidationResults.remove(quizKey);
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF5EBDA), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF5EBDA)),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged, {int maxLines = 1}) {
    return TextFormField(
      key: ValueKey('input_$label'),
      initialValue: value,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: _inputDecoration(label),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF181818),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2C2C2C))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2C2C2C))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF5EBDA))),
    );
  }

  void _openT2DecodePlayerPreview(Map<String, dynamic>? customCourse) {
    final course = customCourse ?? _parsedCourse ?? _serializeCurrentState();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _buildT2DecodePlayerDialog(course),
    );
  }

  Widget _buildT2DecodePlayerDialog(Map<String, dynamic> course) {
    final modules = (course['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final firstModule = modules.isNotEmpty ? modules.first : {
      'title': 'Chapitre 1 : Introduction',
      'markdown': '# Bienvenue dans T2DECODE\n\nVoici la prévisualisation exacte de la première page de cours dans T2DECODE.\n\n```bash\n# Testez vos commandes Linux en direct\nuname -a\nwhoami\n```',
      'quiz': [
        {
          'question': 'Quel est l\'objectif principal de ce module ?',
          'options': ['Découvrir l\'environnement T2DECODE', 'Créer un fichier texte', 'Fermer l\'application'],
          'answer': 0,
          'explanation': 'Bravo ! Vous êtes en mode immersion apprenant T2DECODE.',
        }
      ]
    };

    int selectedChapterIdx = 0;
    int selectedOption = -1;
    bool quizSubmitted = false;

    return StatefulBuilder(
      builder: (context, setStateModal) {
        final activeMod = (modules.isNotEmpty && selectedChapterIdx < modules.length)
            ? modules[selectedChapterIdx]
            : firstModule;
        final quizList = (activeMod['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: const Color(0xFF0F0F0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF333333)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                // Top Header T2DECODE Player
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161616),
                    border: Border(bottom: BorderSide(color: Color(0xFF262626))),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset('assets/logo_128.png', height: 26, width: 26, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'T2DECODE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EBDA).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('MODE IMMERSION APPRENANT', style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF333333)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text('+150 XP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        tooltip: 'Quitter l\'aperçu T2DECODE',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Main Player Layout Split View
                Expanded(
                  child: Row(
                    children: [
                      // Sidebar Chapters Navigation
                      Container(
                        width: 280,
                        decoration: const BoxDecoration(
                          color: Color(0xFF121212),
                          border: Border(right: BorderSide(color: Color(0xFF222222))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (course['title'] ?? 'Nouveau cours').toString(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: modules.isEmpty ? 0 : (selectedChapterIdx + 1) / modules.length,
                                      backgroundColor: const Color(0xFF222222),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5EBDA)),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${modules.isEmpty ? 0 : selectedChapterIdx + 1}/${modules.length} chapitres complétés',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: Color(0xFF222222), height: 1),
                            Expanded(
                              child: modules.isEmpty
                                  ? const Center(child: Text('Aucun chapitre', style: TextStyle(color: Colors.grey, fontSize: 12)))
                                  : ListView.builder(
                                      itemCount: modules.length,
                                      itemBuilder: (context, idx) {
                                        final isSel = idx == selectedChapterIdx;
                                        final m = modules[idx];
                                        return ListTile(
                                          dense: true,
                                          selected: isSel,
                                          selectedTileColor: const Color(0xFF1E1E1E),
                                          leading: Icon(
                                            isSel ? Icons.play_circle_fill : Icons.circle_outlined,
                                            color: isSel ? const Color(0xFFF5EBDA) : Colors.grey,
                                            size: 16,
                                          ),
                                          title: Text(
                                            (m['title'] ?? 'Chapitre ${idx + 1}').toString(),
                                            style: TextStyle(
                                              color: isSel ? Colors.white : Colors.grey[400],
                                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 12,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${(m['quiz'] as List?)?.length ?? 0} ${(m['quiz'] as List?)?.length == 1 ? "question" : "questions"}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                                          ),
                                          onTap: () {
                                            setStateModal(() {
                                              selectedChapterIdx = idx;
                                              selectedOption = -1;
                                              quizSubmitted = false;
                                            });
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // Right Content Viewer & Interactive Quiz
                      Expanded(
                        child: Container(
                          color: const Color(0xFF0F0F0F),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Chapter Title Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5EBDA).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'CHAPITRE ${selectedChapterIdx + 1}',
                                        style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      (course['category'] ?? 'LINUX').toString().toUpperCase(),
                                      style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  (activeMod['title'] ?? 'Titre du chapitre').toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: Color(0xFF222222)),
                                const SizedBox(height: 20),

                                // Markdown Content Render
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141414),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF242424)),
                                  ),
                                  child: MarkdownBody(
                                    data: (activeMod['markdown'] ?? 'Contenu du chapitre en cours de rédaction...').toString(),
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 14, height: 1.6),
                                      h1: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 20, fontWeight: FontWeight.bold),
                                      h2: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 17, fontWeight: FontWeight.bold),
                                      code: const TextStyle(color: Color(0xFF38BDF8), backgroundColor: Color(0xFF0F0F0F), fontFamily: 'monospace', fontSize: 13),
                                      codeblockDecoration: BoxDecoration(
                                        color: const Color(0xFF0A0A0A),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF222222)),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // QCM Quiz Interactive Component
                                if (quizList.isNotEmpty) ...[
                                  Text(
                                    'VALIDEZ VOS CONNAISSANCES (${quizList.length} ${quizList.length == 1 ? "QUESTION" : "QUESTIONS"})',
                                    style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
                                  ),
                                  const SizedBox(height: 12),
                                  ...quizList.asMap().entries.map((qEntry) {
                                    final qIdx = qEntry.key;
                                    final q = qEntry.value;
                                    final opts = (q['options'] as List?)?.cast<String>() ?? [];
                                    final corrAns = (q['answer'] as int?) ?? 0;
                                    final expl = (q['explanation'] as String?) ?? '';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF161616),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF2A2A2A)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Q${qIdx + 1}. ${(q['question'] ?? '').toString()}',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 14),
                                          ...opts.asMap().entries.map((oEntry) {
                                            final oIdx = oEntry.key;
                                            final optText = oEntry.value;
                                            final isSelected = selectedOption == oIdx;
                                            final isCorrect = quizSubmitted && oIdx == corrAns;
                                            final isWrong = quizSubmitted && isSelected && oIdx != corrAns;

                                            Color borderColor = const Color(0xFF333333);
                                            Color bgColor = const Color(0xFF1F1F1F);
                                            if (isCorrect) {
                                              borderColor = const Color(0xFF10B981);
                                              bgColor = const Color(0xFF10B981).withOpacity(0.15);
                                            } else if (isWrong) {
                                              borderColor = const Color(0xFFE11D48);
                                              bgColor = const Color(0xFFE11D48).withOpacity(0.15);
                                            } else if (isSelected) {
                                              borderColor = const Color(0xFFF5EBDA);
                                              bgColor = const Color(0xFFF5EBDA).withOpacity(0.1);
                                            }

                                            return InkWell(
                                              onTap: quizSubmitted ? null : () => setStateModal(() => selectedOption = oIdx),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: bgColor,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: borderColor),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isCorrect ? Icons.check_circle : (isWrong ? Icons.cancel : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked)),
                                                      color: isCorrect ? const Color(0xFF10B981) : (isWrong ? const Color(0xFFE11D48) : (isSelected ? const Color(0xFFF5EBDA) : Colors.grey)),
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        optText,
                                                        style: TextStyle(
                                                          color: isSelected || isCorrect ? Colors.white : Colors.grey[300],
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),

                                          const SizedBox(height: 12),
                                          if (!quizSubmitted)
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFF5EBDA),
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onPressed: selectedOption == -1 ? null : () {
                                                setStateModal(() => quizSubmitted = true);
                                              },
                                              child: const Text('Valider la réponse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: selectedOption == corrAns ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFE11D48).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: selectedOption == corrAns ? const Color(0xFF10B981) : const Color(0xFFE11D48)),
                                              ),
                                              child: Text(
                                                selectedOption == corrAns
                                                    ? '✓ Explication : $expl'
                                                    : '✗ Réponse incorrecte. La bonne réponse est : ${opts[corrAns]}. $expl',
                                                style: TextStyle(
                                                  color: selectedOption == corrAns ? const Color(0xFF10B981) : const Color(0xFFFCA5A5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],

                                const SizedBox(height: 32),
                                // Footer Navigation Chapter
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Color(0xFF333333)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      icon: const Icon(Icons.arrow_back, size: 14),
                                      label: const Text('Chapitre Précédent'),
                                      onPressed: selectedChapterIdx == 0 ? null : () {
                                        setStateModal(() {
                                          selectedChapterIdx--;
                                          selectedOption = -1;
                                          quizSubmitted = false;
                                        });
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF5EBDA),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                      icon: const Icon(Icons.arrow_forward, size: 14, color: Colors.black),
                                      label: Text(
                                        selectedChapterIdx + 1 < modules.length ? 'Chapitre Suivant (+50 XP)' : 'Terminer le cours (+100 XP)',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: selectedChapterIdx + 1 >= modules.length ? null : () {
                                        setStateModal(() {
                                          selectedChapterIdx++;
                                          selectedOption = -1;
                                          quizSubmitted = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
