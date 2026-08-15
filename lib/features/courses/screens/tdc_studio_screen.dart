// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _courseId = 'nouveau-cours';
  String _courseTitle = 'Nouveau Cours Technique';
  String _courseDesc = 'Description du cours et objectifs pédagogiques.';
  String _category = 'linux';
  String _level = 'beginner';
  String _duration = '1h';
  String _icon = 'Terminal';
  List<String> _keywords = ['linux', 'terminal', 'tdc'];

  List<Map<String, dynamic>> _modules = [
    {
      'id': 'module-1',
      'title': 'Chapitre 1 : Introduction',
      'duration': '15min',
      'content': '# Premier Chapitre\n\nBienvenue dans votre cours rédigé en **.tdc** !',
      'codeBlocks': [
        {
          'language': 'bash',
          'title': 'Exemple de commande',
          'code': 'echo "Hello TUTODECODE!"',
        }
      ],
      'quiz': [
        {
          'question': 'Quelle est la première commande de diagnostic ?',
          'choices': ['whoami', 'pwd', 'ls'],
          'correctIndex': 0,
          'explanation': 'whoami indique votre nom d\'utilisateur.',
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
            icon: const Icon(Icons.copy, color: Color(0xFFF5EBDA)),
            tooltip: 'Copier le code .TDC',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _rawCodeController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code .TDC copié dans le presse-papier !')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.flash_on, color: Color(0xFFF5EBDA)),
            tooltip: 'Charger un modèle de cours',
            onSelected: _loadPresetTemplate,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'linux', child: Text('🐧 Modèle Linux Sysadmin')),
              const PopupMenuItem(value: 'network', child: Text('🌐 Modèle Réseau & CIDR')),
            ],
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
                  dropdownColor: Colors.grey[900],
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
                  dropdownColor: Colors.grey[900],
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
    return Card(
      color: Colors.grey[900],
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
            _buildTextField('Titre du Chapitre', mod['title'], (val) {
              setState(() => mod['title'] = val);
              _syncFormToRawCode();
            }),
            const SizedBox(height: 8),
            _buildTextField('Contenu Markdown (Triple """ en .tdc)', mod['content'], (val) {
              setState(() => mod['content'] = val);
              _syncFormToRawCode();
            }, maxLines: 4),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('QCM du Chapitre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  icon: const Icon(Icons.quiz, color: Color(0xFFF5EBDA)),
                  label: const Text('Ajouter une Question', style: TextStyle(color: Color(0xFFF5EBDA))),
                  onPressed: () {
                    setState(() {
                      final quizList = (mod['quiz'] as List);
                      quizList.add({
                        'question': 'Nouvelle Question ?',
                        'choices': ['Option A', 'Option B'],
                        'correctIndex': 0,
                        'explanation': 'Explication.'
                      });
                    });
                    _syncFormToRawCode();
                  },
                ),
              ],
            ),
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
              color: Colors.grey[900],
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
      initialValue: value,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[800]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFF5EBDA)),
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
                              subtitle: 'Créer un cours vierge avec formulaire et code',
                              color: const Color(0xFFF5EBDA),
                              onTap: () {
                                setState(() => _showWelcomeScreen = false);
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildWelcomeActionButton(
                              icon: Icons.folder_open_outlined,
                              title: 'Ouvrir un Fichier .TDC',
                              subtitle: 'Ouvrir un cours .tdc ou .json existant sur votre disque',
                              color: const Color(0xFF8B5CF6),
                              onTap: () {
                                _loadPresetTemplate('linux');
                                setState(() => _showWelcomeScreen = false);
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildWelcomeActionButton(
                              icon: Icons.flash_on_outlined,
                              title: 'Nouveau depuis un Modèle',
                              subtitle: 'Charger un modèle prêt à l\'emploi (Linux, Réseau, CIDR)',
                              color: const Color(0xFF10B981),
                              onTap: () {
                                _loadPresetTemplate('network');
                                setState(() => _showWelcomeScreen = false);
                              },
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
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F0F),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[800]!),
                                ),
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
}
