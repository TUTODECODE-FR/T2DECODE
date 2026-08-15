// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tutodecode/core/parser/tdc_parser.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// TDC Studio — Éditeur interactif & Créateur de Cours souverain (.tdc).
class TDCStudioScreen extends StatefulWidget {
  const TDCStudioScreen({Key? key}) : super(key: key);

  @override
  State<TDCStudioScreen> createState() => _TDCStudioScreenState();
}

class _TDCStudioScreenState extends State<TDCStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rawCodeController = TextEditingController();

  // Form State
  String _courseId = 'nouveau-cours-technique';
  String _courseTitle = 'Titre de Votre Nouveau Cours';
  String _courseDesc = 'Description pédagogique et objectifs de votre cours en langage .tdc.';
  String _category = 'linux';
  String _level = 'beginner';
  String _duration = '1h';
  String _icon = 'Terminal';
  List<String> _keywords = ['tutodecode', 'tdc', 'cours'];

  List<Map<String, dynamic>> _modules = [
    {
      'id': 'chapitre-1',
      'title': 'Chapitre 1 : Introduction & Concepts',
      'duration': '15min',
      'content': '# 🚀 Bienvenue dans votre cours\n\nRédigez ici le contenu en **Markdown** (explications, schémas, astuces).',
      'codeBlocks': [
        {
          'language': 'bash',
          'title': 'Exemple de commande',
          'code': 'echo "Bienvenue dans T2DECODE Studio !"'
        }
      ],
      'quiz': [
        {
          'question': 'Quelle est la première étape du cours ?',
          'choices': ['Lire le premier chapitre', 'Ignorer la théorie', 'Fermer le terminal'],
          'correctIndex': 0,
          'explanation': 'Lire attentivement le chapitre permet d\'assimiler les notions.'
        }
      ]
    }
  ];

  Map<String, dynamic>? _parsedCourse;
  String _parseError = '';

  bool _showWelcomeScreen = true;
  final List<Map<String, String>> _recentProjects = [
    {
      'id': 'linux-sysadmin',
      'title': 'Administration Système Linux',
      'category': 'linux',
      'date': 'Modifié aujourd\'hui à 18:05',
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

  void _createNewDefaultCourse() {
    setState(() {
      _courseId = 'mon-nouveau-cours';
      _courseTitle = 'Nouveau Cours Technique';
      _courseDesc = 'Description globale et objectifs pédagogiques de ce cours.';
      _category = 'linux';
      _level = 'beginner';
      _duration = '1h';
      _icon = 'Terminal';
      _keywords = ['tutodecode', 'tdc', 'cours'];
      _modules = [
        {
          'id': 'chapitre-1',
          'title': 'Chapitre 1 : Introduction',
          'duration': '15min',
          'content': '# 📌 Introduction\n\nContenu rédigé en **Markdown**.',
          'codeBlocks': [
            {
              'language': 'bash',
              'title': 'Exemple bash',
              'code': 'echo "Hello TDC Studio"'
            }
          ],
          'quiz': [
            {
              'question': 'Quelle est la commande pour afficher du texte ?',
              'choices': ['echo', 'cat', 'ls'],
              'correctIndex': 0,
              'explanation': 'echo affiche la chaîne de caractères transmise.'
            }
          ]
        }
      ];
      _showWelcomeScreen = false;
    });
    _syncFormToRawCode();
  }

  void _syncFormToRawCode() {
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
    _rawCodeController.text = tdcCode;
    _parseRawCode(tdcCode);
  }

  void _parseRawCode(String code) {
    try {
      final parsed = TDCParser.parseCourse(code);
      setState(() {
        _parsedCourse = parsed;
        _parseError = '';
      });
    } catch (e) {
      setState(() {
        _parseError = e.toString();
      });
    }
  }

  /// Opens the native OS file explorer to pick any .tdc or .json course file.
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
          _showWelcomeScreen = false;
        });

        _syncFormToRawCode();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier importé avec succès : ${result.files.single.name}'),
            backgroundColor: const Color(0xFFF5EBDA),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'ouverture du fichier : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Displays an inspiring, ultra-pro modal with rich category templates.
  void _showTemplateSelectionDialog() {
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
            constraints: const BoxConstraints(maxWidth: 850),
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
                          'Choisir un Modèle de Cours Professionnel',
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
                  'Sélectionnez une trame complète prête à l\'emploi pour démarrer la création de votre cours en .tdc',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
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
                        id: 'crypto',
                        icon: Icons.lock,
                        category: 'CRYPTO',
                        title: 'Cryptographie & Hashes',
                        desc: 'Algorithmes SHA-256, salage PBKDF2 et paires de clés RSA.',
                        level: 'Intermédiaire • 2h',
                        color: const Color(0xFFE11D48),
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
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                desc,
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                level,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadPresetTemplate(String type) {
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
    }
    _syncFormToRawCode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modèle $type chargé !'),
        backgroundColor: const Color(0xFFF5EBDA),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcomeScreen) {
      return _buildWelcomeScreen();
    }
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Color(0xFFF5EBDA)),
          tooltip: 'Accueil Studio',
          onPressed: () => setState(() => _showWelcomeScreen = true),
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
              'Studio de Création de Cours',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Color(0xFFF5EBDA)),
            tooltip: 'Importer un fichier .TDC',
            onPressed: _openNativeFilePicker,
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Color(0xFFF5EBDA)),
            tooltip: 'Copier le code .TDC',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _rawCodeController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code .TDC copié dans le presse-papier !')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Color(0xFFF5EBDA)),
            tooltip: 'Choisir un modèle de cours',
            onPressed: _showTemplateSelectionDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF5EBDA),
          labelColor: const Color(0xFFF5EBDA),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Formulaire'),
            Tab(icon: Icon(Icons.code), text: 'Code .TDC'),
            Tab(icon: Icon(Icons.remove_red_eye), text: 'Aperçu Live'),
          ],
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
                child: _buildTextField('ID du Cours (minuscules/tires)', _courseId, (val) {
                  setState(() => _courseId = val);
                  _syncFormToRawCode();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('Titre du Cours', _courseTitle, (val) {
                  setState(() => _courseTitle = val);
                  _syncFormToRawCode();
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('Description Pédagogique', _courseDesc, (val) {
            setState(() => _courseDesc = val);
            _syncFormToRawCode();
          }, maxLines: 2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _category,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Catégorie'),
                  items: const [
                    DropdownMenuItem(value: 'linux', child: Text('🐧 Linux')),
                    DropdownMenuItem(value: 'network', child: Text('🌐 Réseau')),
                    DropdownMenuItem(value: 'security', child: Text('🛡️ Sécurité')),
                    DropdownMenuItem(value: 'cloud', child: Text('☁️ Cloud')),
                    DropdownMenuItem(value: 'crypto', child: Text('🔑 Crypto')),
                    DropdownMenuItem(value: 'development', child: Text('💻 Développement')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _category = val);
                      _syncFormToRawCode();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
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
                  });
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

  Widget _buildModuleCard(int index, Map<String, dynamic> mod) {
    if (mod['quiz'] == null || mod['quiz'] is! List) {
      mod['quiz'] = <Map<String, dynamic>>[];
    }
    final List<Map<String, dynamic>> quizList = (mod['quiz'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    mod['quiz'] = quizList;

    return Card(
      color: const Color(0xFF121212),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFF5EBDA).withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chapitre #${index + 1} : ${mod['title']}',
                  style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _modules.removeAt(index);
                    });
                    _syncFormToRawCode();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField('Titre du Chapitre', mod['title'] ?? '', (val) {
              setState(() => mod['title'] = val);
              _syncFormToRawCode();
            }),
            const SizedBox(height: 8),
            _buildTextField('Contenu Markdown (Triple """ en .tdc)', mod['content'] ?? '', (val) {
              setState(() => mod['content'] = val);
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
                        'choices': ['Réponse correcte (+)', 'Mauvaise réponse A', 'Mauvaise réponse B'],
                        'correctIndex': 0,
                        'explanation': 'Explication pédagogique de la réponse.'
                      });
                      mod['quiz'] = List<Map<String, dynamic>>.from(quizList);
                    });
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
                key: ValueKey('quiz_${index}_$qIdx'),
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
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          onPressed: () {
                            setState(() {
                              quizList.removeAt(qIdx);
                              mod['quiz'] = List<Map<String, dynamic>>.from(quizList);
                            });
                            _syncFormToRawCode();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildTextField('Question', q['question'] ?? '', (val) {
                      setState(() => q['question'] = val);
                      _syncFormToRawCode();
                    }),
                    const SizedBox(height: 8),
                    const Text('Choix de réponses (+ = Correcte) :', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                              tooltip: isCorrect ? 'Réponse Correcte (+)' : 'Définir comme réponse correcte',
                              onPressed: () {
                                setState(() {
                                  q['correctIndex'] = cIdx;
                                });
                                _syncFormToRawCode();
                              },
                            ),
                            Expanded(
                              child: _buildTextField('Choix ${cIdx + 1}', choices[cIdx], (val) {
                                setState(() => choices[cIdx] = val);
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
                        _syncFormToRawCode();
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildTextField('Explication Pédagogique', q['explanation'] ?? '', (val) {
                      setState(() => q['explanation'] = val);
                      _syncFormToRawCode();
                    }),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeView() {
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
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
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
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Saisissez du code .TDC brut ici...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (val) {
                _parseRawCode(val);
              },
            ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 8),
                Text(
                  c['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  c['description'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...modules.map((m) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['title'] ?? '',
                  style: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: m['content'] ?? '',
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
              // Logo & Header
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

              // Two columns: Left Actions, Right Recent Projects
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
                              title: 'Nouveau Cours .TDC',
                              subtitle: 'Créer un cours avec structure et exemple pré-rempli',
                              color: const Color(0xFFF5EBDA),
                              onTap: _createNewDefaultCourse,
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
                              subtitle: 'Explorer nos 6 modèles professionnels (Linux, Réseau, Sécurité)',
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
      key: ValueKey('${label}_$value'),
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
