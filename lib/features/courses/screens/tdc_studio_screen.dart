// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tutodecode/core/parser/tdc_parser.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// TDC Studio IDE — Environnement Développeur & Créateur de Cours souverain (.tdc).
class TDCStudioScreen extends StatefulWidget {
  const TDCStudioScreen({super.key});

  @override
  State<TDCStudioScreen> createState() => _TDCStudioScreenState();
}

class _TDCStudioScreenState extends State<TDCStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rawCodeController = TextEditingController();

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
  DateTime? _lastSavedTime;
  Map<String, dynamic>? _lastDeletedState;

  // Parser Feedback
  Map<String, dynamic>? _parsedCourse;
  String _parseError = '';
  bool _isCodeSourceOfTruth = false;

  bool _showWelcomeScreen = true;

  final List<Map<String, String>> _recentProjects = [
    {
      'id': 'linux-sysadmin',
      'title': 'Administration Système Linux',
      'category': 'linux',
      'date': 'Modifié aujourd\'hui à 18:24',
      'path': 'assets/courses/sample_course.tdc',
    },
    {
      'id': 'network-subnetting',
      'title': 'Subnetting IPv4 & Masques CIDR',
      'category': 'network',
      'date': 'Modifié hier',
      'path': 'assets/courses/courses_fr.json',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _syncFormToRawCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rawCodeController.dispose();
    super.dispose();
  }

  void _markModified() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  void _syncFormToRawCode() {
    if (_isCodeSourceOfTruth) return;

    final map = {
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
    try {
      final parsed = TDCParser.parseCourse(code);
      setState(() {
        _parsedCourse = parsed;
        _parseError = '';

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
      setState(() {
        _parseError = e.toString();
      });
    }
  }

  void _createNewBlankCourse() {
    _confirmActionIfUnsaved('Créer un nouveau cours', () {
      setState(() {
        _courseId = '';
        _courseTitle = '';
        _courseDesc = '';
        _category = 'linux';
        _level = 'beginner';
        _duration = '';
        _icon = 'Terminal';
        _keywords = [];
        _modules = [];
        _expandedModules.clear();
        _showWelcomeScreen = false;
        _hasUnsavedChanges = false;
      });
      _syncFormToRawCode();
      _showFloatingToast('Nouveau cours vierge créé !');
    });
  }

  void _confirmActionIfUnsaved(String actionTitle, VoidCallback onConfirm) {
    if (!_hasUnsavedChanges) {
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
          title: Text('Modifications non enregistrées ($actionTitle)', style: const TextStyle(color: Color(0xFFF5EBDA))),
          content: const Text(
            'Vous avez des modifications non enregistrées. Continuer écrasera votre travail en cours.',
            style: TextStyle(color: Colors.grey),
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
              child: const Text('Continuer sans sauvegarder'),
            ),
          ],
        );
      },
    );
  }

  /// Opens native file picker to select a .tdc file
  Future<void> _openNativeFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tdc', 'json', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileContent = await File(filePath).readAsString();
        final parsed = TDCParser.parseCourse(fileContent);

        setState(() {
          _courseId = parsed['id'] ?? 'cours-importe';
          _courseTitle = parsed['title'] ?? _courseId;
          _courseDesc = parsed['description'] ?? '';
          _category = parsed['category'] ?? 'linux';
          _level = parsed['level'] ?? 'beginner';
          _duration = parsed['duration'] ?? '1h';
          _icon = parsed['icon'] ?? 'BookOpen';
          _keywords = (parsed['keywords'] as List?)?.cast<String>() ?? ['tdc'];
          _modules = (parsed['content'] as List?)?.map((m) => Map<String, dynamic>.from(m as Map)).toList() ?? [];
          _expandedModules.clear();
          for (var i = 0; i < _modules.length; i++) {
            _expandedModules.add(i == 0);
          }
          _showWelcomeScreen = false;
          _hasUnsavedChanges = false;
          _lastSavedTime = DateTime.now();
        });

        _syncFormToRawCode();
        _showFloatingToast('Fichier .tdc chargé : ${result.files.single.name}');
      }
    } catch (e) {
      _showFloatingToast('Erreur d\'ouverture du fichier : $e', isError: true);
    }
  }

  /// Exports current .tdc code to native File System Save As Dialog
  Future<void> _exportTdcFile() async {
    try {
      final tdcContent = _rawCodeController.text;
      final fileName = '$_courseId.tdc';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter le cours au format .tdc',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['tdc'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(tdcContent);
        setState(() {
          _hasUnsavedChanges = false;
          _lastSavedTime = DateTime.now();
        });
        _showFloatingToast('Cours exporté avec succès : ${file.path}');
      }
    } catch (e) {
      _showFloatingToast('Erreur lors de l\'exportation : $e', isError: true);
    }
  }

  void _showFloatingToast(String message, {bool isError = false, VoidCallback? onUndo}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 100, right: 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isError ? const Color(0xFFE11D48) : const Color(0xFF1E1E1E),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.white : const Color(0xFFF5EBDA),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            if (onUndo != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onUndo();
                },
                child: const Text('Annuler', style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  void _showTemplateSelectionDialog() {
    _confirmActionIfUnsaved('Charger un Modèle', () {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: const Color(0xFF121212),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.flash_on, color: Color(0xFFF5EBDA), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Modèles de Cours Professionnels (6)',
                            style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sélectionnez une trame technique officielle pré-rédigée pour démarrer votre cours .tdc',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.1,
                        children: [
                          _buildTemplateCard(
                            id: 'linux',
                            icon: Icons.terminal,
                            category: 'LINUX',
                            title: 'Administration Linux & Bash',
                            desc: 'Audit système, processus CPU/RAM, permissions CHMOD et commandes SSH.',
                            level: 'Débutant • 2h',
                            color: const Color(0xFFF5EBDA),
                          ),
                          _buildTemplateCard(
                            id: 'network',
                            icon: Icons.network_check,
                            category: 'RÉSEAU',
                            title: 'Subnetting IPv4 & CIDR',
                            desc: 'Calcul des masques de sous-réseau, adresses hôtes et plages CIDR.',
                            level: 'Intermédiaire • 3h',
                            color: const Color(0xFF8B5CF6),
                          ),
                          _buildTemplateCard(
                            id: 'security',
                            icon: Icons.security,
                            category: 'SÉCURITÉ',
                            title: 'Hardening & Pare-Feu UFW',
                            desc: 'Sécurisation serveur, règles d\'accès SSH et filtrage réseau.',
                            level: 'Avancé • 4h',
                            color: const Color(0xFF10B981),
                          ),
                          _buildTemplateCard(
                            id: 'cloud',
                            icon: Icons.cloud_queue,
                            category: 'CLOUD',
                            title: 'Containers Docker & Microservices',
                            desc: 'Création de Dockerfiles, volumes, réseaux et Docker Compose.',
                            level: 'Intermédiaire • 3h',
                            color: const Color(0xFF3B82F6),
                          ),
                          _buildTemplateCard(
                            id: 'crypto',
                            icon: Icons.lock,
                            category: 'CRYPTO',
                            title: 'Cryptographie & Hashes',
                            desc: 'Algorithmes SHA-256, salage PBKDF2 et paires de clés RSA.',
                            level: 'Intermédiaire • 2h',
                            color: const Color(0xFFE11D48),
                          ),
                          _buildTemplateCard(
                            id: 'dev',
                            icon: Icons.code,
                            category: 'DEVELOPPEMENT',
                            title: 'Scripting Python & Automatisations',
                            desc: 'Création d\'outils CLI, parsing JSON/.tdc et scripts d\'infrastructures.',
                            level: 'Débutant • 2.5h',
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildTemplateCard({
    required String id,
    required IconData icon,
    required String category,
    required String title,
    required String desc,
    required String level,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          _loadPresetTemplate(id);
          setState(() => _showWelcomeScreen = false);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                desc,
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                level,
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadPresetTemplate(String type) {
    setState(() {
      if (type == 'linux') {
        _courseId = 'linux-sysadmin';
        _courseTitle = 'Administration Système Linux';
        _courseDesc = 'Maîtrisez les commandes de base, les permissions et la gestion des processus.';
        _category = 'linux';
        _level = 'beginner';
        _duration = '2h';
        _icon = 'Terminal';
        _keywords = ['linux', 'sysadmin', 'bash', 'terminal'];
        _modules = [
          {
            'id': 'audit-processus',
            'title': 'Audit des Processus & Mémoire',
            'duration': '20min',
            'content': '# 📊 Audit de la RAM et du CPU\n\nLorsque le serveur ralentit, utilisez les outils système natifs.',
            'codeBlocks': [
              {'language': 'bash', 'title': 'Affichage des processus', 'code': 'ps aux --sort=-%mem | head -n 10\nfree -h'}
            ],
            'quiz': [
              {
                'question': 'Quelle commande affiche la mémoire disponible ?',
                'choices': ['free -h', 'ls -la', 'cat /etc/passwd'],
                'correctIndex': 0,
                'explanation': 'free -h affiche la mémoire physique et le SWAP en format lisible (GB/MB).'
              }
            ]
          }
        ];
      } else if (type == 'network') {
        _courseId = 'network-subnetting';
        _courseTitle = 'Subnetting IPv4 & CIDR';
        _courseDesc = 'Calcul des sous-réseaux, masques et adresses de broadcast.';
        _category = 'network';
        _level = 'intermediate';
        _duration = '3h';
        _icon = 'Network';
        _keywords = ['network', 'ip', 'cidr', 'subnetting'];
        _modules = [
          {
            'id': 'cidr-masks',
            'title': 'Comprendre les masques /24 à /30',
            'duration': '30min',
            'content': '# 🌐 Masques CIDR\n\nLe masque détermine la frontière entre le réseau et les hôtes.',
            'codeBlocks': [
              {'language': 'bash', 'title': 'Calculatrice sous Linux', 'code': 'ipcalc 192.168.1.0/24'}
            ],
            'quiz': [
              {
                'question': 'Combien d\'hôtes utilisables dans un /28 ?',
                'choices': ['16', '14', '30'],
                'correctIndex': 1,
                'explanation': '2^4 - 2 = 14 hôtes utiles.'
              }
            ]
          }
        ];
      } else if (type == 'security') {
        _courseId = 'security-hardening';
        _courseTitle = 'Hardening & Sécurisation Serveur';
        _courseDesc = 'Sécurisation de l\'accès SSH, règles de filtrage pare-feu UFW et surveillance d\'intégrité.';
        _category = 'security';
        _level = 'advanced';
        _duration = '4h';
        _icon = 'Shield';
        _keywords = ['security', 'hardening', 'ssh', 'ufw'];
        _modules = [
          {
            'id': 'ssh-hardening',
            'title': 'Securiser le Service SSH',
            'duration': '40min',
            'content': '# 🔒 Hardening SSH\n\nDésactiver la connexion par mot de passe et forcer les clés RSA/Ed25519.',
            'codeBlocks': [
              {'language': 'bash', 'title': 'Fichier de configuration SSH', 'code': 'nano /etc/ssh/sshd_config\nPasswordAuthentication no\nPermitRootLogin no'}
            ],
            'quiz': [
              {
                'question': 'Quelle directive désactive la connexion root directe en SSH ?',
                'choices': ['PermitRootLogin no', 'PasswordAuthentication no', 'AllowUsers none'],
                'correctIndex': 0,
                'explanation': 'PermitRootLogin no interdit la connexion en tant que superutilisateur root.'
              }
            ]
          }
        ];
      } else if (type == 'crypto') {
        _courseId = 'crypto-hashes';
        _courseTitle = 'Cryptographie & Empreintes Numériques';
        _courseDesc = 'Comprendre les fonctions de hachage SHA-256, le salage PBKDF2 et la clé publique RSA.';
        _category = 'crypto';
        _level = 'intermediate';
        _duration = '2h';
        _icon = 'Lock';
        _keywords = ['crypto', 'hash', 'sha256', 'rsa'];
        _modules = [
          {
            'id': 'sha256-basics',
            'title': 'Hachage SHA-256 & Intégrité',
            'duration': '25min',
            'content': '# 🔐 Algorithmes de Hachage\n\nUn hash est une empreinte à sens unique non inversible.',
            'codeBlocks': [
              {'language': 'bash', 'title': 'Calcul de checksum', 'code': 'echo -n "TUTODECODE" | sha256sum'}
            ],
            'quiz': [
              {
                'question': 'Quelle est la taille en bits d\'une empreinte SHA-256 ?',
                'choices': ['256 bits', '128 bits', '512 bits'],
                'correctIndex': 0,
                'explanation': 'SHA-256 produit une empreinte de 256 bits (64 caractères hexadécimaux).'
              }
            ]
          }
        ];
      } else if (type == 'cloud') {
        _courseId = 'cloud-docker';
        _courseTitle = 'Containers Docker & Infrastructure';
        _courseDesc = 'Création d\'images Docker, écriture de Dockerfiles et déploiement avec Docker Compose.';
        _category = 'cloud';
        _level = 'intermediate';
        _duration = '3h';
        _icon = 'Cloud';
        _keywords = ['docker', 'cloud', 'containers'];
        _modules = [
          {
            'id': 'dockerfile-build',
            'title': 'Écrire un Dockerfile Optime',
            'duration': '30min',
            'content': '# 🐳 Containers Docker\n\nLe Dockerfile définit les étapes de construction de l\'image.',
            'codeBlocks': [
              {'language': 'dockerfile', 'title': 'Dockerfile basique', 'code': 'FROM alpine:latest\nRUN apk add --no-cache bash\nCMD ["bash"]'}
            ],
            'quiz': [
              {
                'question': 'Quelle instruction définit le point d\'entrée par défaut d\'un container ?',
                'choices': ['CMD', 'FROM', 'COPY'],
                'correctIndex': 0,
                'explanation': 'CMD spécifie la commande exécutée au démarrage du container.'
              }
            ]
          }
        ];
      } else if (type == 'dev') {
        _courseId = 'dev-python-cli';
        _courseTitle = 'Scripting Python & Automatisations CLI';
        _courseDesc = 'Création d\'outils en ligne de commande Python pour parser et manipuler des fichiers.';
        _category = 'development';
        _level = 'beginner';
        _duration = '2.5h';
        _icon = 'Code';
        _keywords = ['python', 'dev', 'cli'];
        _modules = [
          {
            'id': 'argparse-python',
            'title': 'Parsing des Arguments CLI',
            'duration': '25min',
            'content': '# 🐍 Scripting Python CLI\n\nUtilisez `argparse` pour créer des outils système robustes.',
            'codeBlocks': [
              {'language': 'python', 'title': 'Script argparse', 'code': 'import argparse\nparser = argparse.ArgumentParser()\nparser.add_argument("--file")\nargs = parser.parse_args()'}
            ],
            'quiz': [
              {
                'question': 'Quel module standard Python permet de parser les arguments CLI ?',
                'choices': ['argparse', 'sys', 'os'],
                'correctIndex': 0,
                'explanation': 'argparse est le module officiel recommandé pour la gestion des options CLI.'
              }
            ]
          }
        ];
      }
      _expandedModules.clear();
      for (var i = 0; i < _modules.length; i++) {
        _expandedModules.add(true);
      }
      _hasUnsavedChanges = false;
    });
    _syncFormToRawCode();
    _showFloatingToast('Modèle $type chargé avec succès !');
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcomeScreen) {
      return _buildWelcomeScreen();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Color(0xFFF5EBDA)),
          tooltip: 'Accueil Studio',
          onPressed: () => _confirmActionIfUnsaved('Revenir à l\'accueil', () {
            setState(() => _showWelcomeScreen = true);
          }),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBDA).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF5EBDA).withOpacity(0.3)),
              ),
              child: const Text(
                '.TDC',
                style: TextStyle(
                  color: Color(0xFFF5EBDA),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'TDC Studio IDE',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),
            // Live status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _hasUnsavedChanges ? const Color(0x20F59E0B) : const Color(0x2010B981),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasUnsavedChanges ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: _hasUnsavedChanges ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hasUnsavedChanges ? 'Non enregistré' : 'Enregistré',
                    style: TextStyle(
                      color: _hasUnsavedChanges ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Color(0xFFF5EBDA)),
            tooltip: 'Ouvrir un fichier .TDC',
            onPressed: _openNativeFilePicker,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Color(0xFFF5EBDA)),
            tooltip: 'Choisir un modèle (6)',
            onPressed: _showTemplateSelectionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Color(0xFFF5EBDA)),
            tooltip: 'Copier le code .TDC',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _rawCodeController.text));
              _showFloatingToast('Code .TDC copié dans le presse-papier !');
            },
          ),
          const SizedBox(width: 8),
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
                  key: ValueKey('category_select_$_category'),
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
                  key: ValueKey('level_select_$_level'),
                  value: _level,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Niveau'),
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('🟢 Débutant')),
                    DropdownMenuItem(value: 'intermediate', child: Text('🟡 Intermédiaire')),
                    DropdownMenuItem(value: 'advanced', child: Text('🔴 Avancé')),
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('2. Chapitres & Modules (${_modules.length})', Icons.view_module),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5EBDA),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un Chapitre'),
                onPressed: () {
                  setState(() {
                    _modules.add({
                      'id': 'module-${_modules.length + 1}',
                      'title': 'Chapitre ${_modules.length + 1}',
                      'duration': '15min',
                      'content': '# Nouveau Chapitre\n\nRédigez votre cours ici.',
                      'codeBlocks': [],
                      'quiz': []
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
          ..._modules.asMap().entries.map((entry) {
            final idx = entry.key;
            final mod = entry.value;
            return _buildModuleCard(idx, mod);
          }).toList(),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildCategoryItem(String value, String label, Color color) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildModuleCard(int index, Map<String, dynamic> mod) {
    if (mod['quiz'] == null || mod['quiz'] is! List) {
      mod['quiz'] = <Map<String, dynamic>>[];
    }
    final List<Map<String, dynamic>> quizList = (mod['quiz'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    mod['quiz'] = quizList;

    final isExpanded = index < _expandedModules.length ? _expandedModules[index] : true;

    return Card(
      key: ValueKey('module_card_${index}_${mod['id']}'),
      color: const Color(0xFF121212),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFF5EBDA).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Accordion Header
          InkWell(
            onTap: () {
              setState(() {
                if (index < _expandedModules.length) {
                  _expandedModules[index] = !_expandedModules[index];
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: const Color(0xFFF5EBDA),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chapitre #${index + 1} : ${mod['title']}',
                          style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${quizList.length} question(s) QCM',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Reordering buttons: Move Up / Move Down
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.grey, size: 18),
                    tooltip: 'Déplacer vers le haut',
                    onPressed: index == 0 ? null : () {
                      setState(() {
                        final item = _modules.removeAt(index);
                        _modules.insert(index - 1, item);
                      });
                      _markModified();
                      _syncFormToRawCode();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, color: Colors.grey, size: 18),
                    tooltip: 'Déplacer vers le bas',
                    onPressed: index == _modules.length - 1 ? null : () {
                      setState(() {
                        final item = _modules.removeAt(index);
                        _modules.insert(index + 1, item);
                      });
                      _markModified();
                      _syncFormToRawCode();
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    tooltip: 'Supprimer ce chapitre',
                    onPressed: () {
                      final backup = Map<String, dynamic>.from(mod);
                      setState(() {
                        _modules.removeAt(index);
                      });
                      _markModified();
                      _syncFormToRawCode();
                      _showFloatingToast('Chapitre #${index + 1} supprimé', onUndo: () {
                        setState(() {
                          _modules.insert(index, backup);
                        });
                        _syncFormToRawCode();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            const Divider(color: Color(0xFF222222), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('Titre du Chapitre', mod['title'] ?? '', (val) {
                    setState(() => mod['title'] = val);
                    _markModified();
                    _syncFormToRawCode();
                  }),
                  const SizedBox(height: 12),
                  _buildTextField('Contenu Markdown du Chapitre', mod['content'] ?? '', (val) {
                    setState(() => mod['content'] = val);
                    _markModified();
                    _syncFormToRawCode();
                  }, maxLines: 4),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('QCM du Chapitre (${quizList.length} question(s))', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5EBDA).withOpacity(0.15),
                          foregroundColor: const Color(0xFFF5EBDA),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.quiz, size: 18),
                        label: const Text('Ajouter une Question'),
                        onPressed: () {
                          setState(() {
                            quizList.add({
                              'question': 'Nouvelle Question QCM ?',
                              'choices': ['Réponse correcte', 'Mauvaise réponse A', 'Mauvaise réponse B'],
                              'correctIndex': 0,
                              'explanation': 'Explication pédagogique de la réponse.'
                            });
                            mod['quiz'] = List<Map<String, dynamic>>.from(quizList);
                          });
                          _markModified();
                          _syncFormToRawCode();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...quizList.asMap().entries.map((qEntry) {
                    final qIdx = qEntry.key;
                    final q = qEntry.value;
                    final choices = (q['choices'] as List?)?.cast<String>() ?? [];
                    final correctIdx = q['correctIndex'] as int? ?? 0;

                    return Container(
                      key: ValueKey('quiz_${index}_${qIdx}_${q['question'].hashCode}'),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Question #${qIdx + 1}', style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward, color: Colors.grey, size: 16),
                                    onPressed: qIdx == 0 ? null : () {
                                      setState(() {
                                        final qItem = quizList.removeAt(qIdx);
                                        quizList.insert(qIdx - 1, qItem);
                                        mod['quiz'] = List<Map<String, dynamic>>.from(quizList);
                                      });
                                      _markModified();
                                      _syncFormToRawCode();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward, color: Colors.grey, size: 16),
                                    onPressed: qIdx == quizList.length - 1 ? null : () {
                                      setState(() {
                                        final qItem = quizList.removeAt(qIdx);
                                        quizList.insert(qIdx + 1, qItem);
                                        mod['quiz'] = List<Map<String, dynamic>>.from(quizList);
                                      });
                                      _markModified();
                                      _syncFormToRawCode();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                    onPressed: () {
                                      final qBackup = Map<String, dynamic>.from(q);
                                      setState(() {
                                        quizList.removeAt(qIdx);
                                        mod['quiz'] = List<Map<String, dynamic>>.from(quizList);
                                      });
                                      _markModified();
                                      _syncFormToRawCode();
                                      _showFloatingToast('Question #${qIdx + 1} supprimée', onUndo: () {
                                        setState(() {
                                          quizList.insert(qIdx, qBackup);
                                          mod['quiz'] = List<Map<String, dynamic>>.from(quizList);
                                        });
                                        _syncFormToRawCode();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildTextField('Question', q['question'] ?? '', (val) {
                            setState(() => q['question'] = val);
                            _markModified();
                            _syncFormToRawCode();
                          }),
                          const SizedBox(height: 8),
                          const Text('Choix de réponses (Sélectionnez la pastille verte pour la réponse correcte) :', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 6),
                          ...choices.asMap().entries.map((cEntry) {
                            final cIdx = cEntry.key;
                            final isCorrect = (cIdx == correctIdx);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isCorrect ? Colors.greenAccent : Colors.grey,
                                    ),
                                    tooltip: isCorrect ? 'Réponse Correcte' : 'Définir comme réponse correcte',
                                    onPressed: () {
                                      setState(() {
                                        q['correctIndex'] = cIdx;
                                      });
                                      _markModified();
                                      _syncFormToRawCode();
                                    },
                                  ),
                                  Expanded(
                                    child: _buildTextField('Choix ${cIdx + 1}', choices[cIdx], (val) {
                                      setState(() => choices[cIdx] = val);
                                      _markModified();
                                      _syncFormToRawCode();
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                                    onPressed: () {
                                      if (choices.length > 2) {
                                        setState(() {
                                          choices.removeAt(cIdx);
                                          if (q['correctIndex'] >= choices.length) {
                                            q['correctIndex'] = 0;
                                          }
                                        });
                                        _markModified();
                                        _syncFormToRawCode();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFFF5EBDA)),
                            label: const Text('Ajouter un choix', style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 12)),
                            onPressed: () {
                              setState(() {
                                choices.add('Nouveau Choix');
                              });
                              _markModified();
                              _syncFormToRawCode();
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildTextField('Explication Pédagogique', q['explanation'] ?? '', (val) {
                            setState(() => q['explanation'] = val);
                            _markModified();
                            _syncFormToRawCode();
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeView() {
    final lines = _rawCodeController.text.split('\n');

    return Column(
      children: [
        if (_parseError.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Erreur de Syntaxe .TDC : $_parseError',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line numbers gutter
              Container(
                width: 45,
                color: const Color(0xFF0A0A0A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: List.generate(
                      lines.length,
                      (i) => SizedBox(
                        height: 20,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'monospace'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: Color(0xFF222222)),
              // Bidirectional Code Editor
              Expanded(
                child: Container(
                  color: const Color(0xFF0F0F0F),
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _rawCodeController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFF5EBDA),
                      fontSize: 14,
                      height: 1.42,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
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
    if (_parsedCourse == null) {
      return const Center(
        child: Text('Code .TDC invalide pour l\'aperçu', style: TextStyle(color: Colors.redAccent)),
      );
    }

    final c = _parsedCourse!;
    final modules = (c['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF5EBDA).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EBDA).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (c['category'] ?? 'linux').toString().toUpperCase(),
                        style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${c['level']} • ${c['duration']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  c['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  c['description'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ...modules.asMap().entries.map((mEntry) {
            final mIdx = mEntry.key;
            final m = mEntry.value;
            final quizList = (m['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapitre #${mIdx + 1} : ${m['title'] ?? ''}',
                    style: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: m['content'] ?? '',
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (quizList.isNotEmpty) ...[
                    const Divider(color: Color(0xFF2A2A2A)),
                    const SizedBox(height: 8),
                    const Text('📝 Testez vos connaissances (QCM Apprenant) :', style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),

                    ...quizList.asMap().entries.map((qEntry) {
                      final qIdx = qEntry.key;
                      final q = qEntry.value;
                      final quizKey = 'q_${mIdx}_$qIdx';
                      final choices = (q['choices'] as List?)?.cast<String>() ?? [];
                      final correctIdx = q['correctIndex'] as int? ?? 0;
                      final selectedChoice = _userQuizAnswers[quizKey];
                      final isResultChecked = _quizValidationResults[quizKey];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${qIdx + 1}. ${q['question']}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 10),

                            ...choices.asMap().entries.map((cEntry) {
                              final cIdx = cEntry.key;
                              final cText = cEntry.value;
                              final isSelected = (selectedChoice == cIdx);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _userQuizAnswers[quizKey] = cIdx;
                                      _quizValidationResults[quizKey] = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFF5EBDA).withOpacity(0.15) : const Color(0xFF121212),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFF5EBDA) : Colors.grey[800]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                          color: isSelected ? const Color(0xFFF5EBDA) : Colors.grey,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            cText,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.grey[300],
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),

                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF5EBDA),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: selectedChoice == null ? null : () {
                                    setState(() {
                                      _quizValidationResults[quizKey] = (selectedChoice == correctIdx);
                                    });
                                  },
                                  child: const Text('Vérifier la réponse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                if (isResultChecked != null)
                                  Row(
                                    children: [
                                      Icon(
                                        isResultChecked ? Icons.check_circle : Icons.cancel,
                                        color: isResultChecked ? Colors.greenAccent : Colors.redAccent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isResultChecked ? 'Bravo ! Bonne réponse (+50 XP)' : 'Incorrect ! Essayez encore',
                                        style: TextStyle(
                                          color: isResultChecked ? Colors.greenAccent : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                            if (isResultChecked != null && q['explanation'] != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222222),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '💡 Explication : ${q['explanation']}',
                                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBDA).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF5EBDA).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.code_rounded, color: Color(0xFFF5EBDA), size: 36),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TDC Studio IDE',
                        style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Environnement de création & IDE spécialisé pour le langage TUTODECODE Script (.tdc)',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Layout
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Quick Actions
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Démarrer un Projet',
                              style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildWelcomeActionButton(
                              icon: Icons.add_circle_outline,
                              title: 'Nouveau Cours Vierge .TDC',
                              subtitle: 'Créer un projet 100% vierge sans aucun exemple',
                              color: const Color(0xFFF5EBDA),
                              onTap: _createNewBlankCourse,
                            ),
                            const SizedBox(height: 12),
                            _buildWelcomeActionButton(
                              icon: Icons.folder_open_outlined,
                              title: 'Ouvrir un Fichier (Explorateur OS)',
                              subtitle: 'Parcourir votre disque pour ouvrir un cours .tdc ou .json',
                              color: const Color(0xFF8B5CF6),
                              onTap: _openNativeFilePicker,
                            ),
                            const SizedBox(height: 12),
                            _buildWelcomeActionButton(
                              icon: Icons.flash_on_outlined,
                              title: 'Nouveau depuis un Modèle',
                              subtitle: 'Explorer nos 6 modèles professionnels (Linux, Réseau, Sécurité, Cloud, Crypto, Dev)',
                              color: const Color(0xFF10B981),
                              onTap: _showTemplateSelectionDialog,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Right Column: Recent Projects
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Projets & Cours Récents',
                                  style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Icon(Icons.history, color: Colors.grey, size: 20),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._recentProjects.map((p) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: const Color(0xFF0F0F0F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.grey[800]!),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5EBDA).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        p['category'] == 'linux' ? Icons.terminal : Icons.network_check,
                                        color: const Color(0xFFF5EBDA),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      p['title']!,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '${p['id']} • ${p['date']}',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                                    onTap: () {
                                      if (p['category'] == 'network') {
                                        _loadPresetTemplate('network');
                                      } else {
                                        _loadPresetTemplate('linux');
                                      }
                                      setState(() => _showWelcomeScreen = false);
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF5EBDA), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged, {int maxLines = 1}) {
    return TextFormField(
      key: ValueKey('input_${label}_${value.hashCode}'),
      initialValue: value,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration(label),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFB1A89E), fontSize: 13),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0xFF141414),
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF5EBDA), width: 1.5),
      ),
    );
  }
}
