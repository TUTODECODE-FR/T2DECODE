// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// TDC SDK Desktop Studio IDE — Standalone Main
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TDCSdkApp());
}

class TDCSdkApp extends StatelessWidget {
  const TDCSdkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TDC Studio IDE v1.0 — Suite Développeur .TDC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFFF5EBDA),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5EBDA),
          secondary: Color(0xFFD4AF37),
          surface: Color(0xFF141414),
        ),
      ),
      home: const TDCSdkStudioScreen(),
    );
  }
}

class TDCSdkStudioScreen extends StatefulWidget {
  const TDCSdkStudioScreen({super.key});

  @override
  State<TDCSdkStudioScreen> createState() => _TDCSdkStudioScreenState();
}

class _TDCSdkStudioScreenState extends State<TDCSdkStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _editorController = TextEditingController();

  String _courseId = 'intro-linux';
  String _courseTitle = 'Linux & Administration Système';
  String _courseDesc = 'Maîtrisez les commandes réseau, les accès SSH et les droits fichiers.';
  String _category = 'linux';
  String _level = 'beginner';
  String _duration = '2h';
  String _icon = 'Terminal';

  List<Map<String, dynamic>> _modules = [
    {
      'id': 'diag-prod',
      'title': 'Chapitre 1 : Diagnostic système d\'urgence',
      'duration': '15min',
      'content': '# 🚨 Incident de Production\n\nVous êtes connecté en SSH sur un serveur distant.\nAuditez la mémoire et la charge processeur.',
      'codeBlocks': [
        {'language': 'bash', 'title': 'Audit mémoire & processeur', 'code': 'uptime\nfree -h\nps aux --sort=-%mem | head -n 10'}
      ],
      'quiz': [
        {
          'question': 'Quelle commande indique les processus les plus gourmands en mémoire ?',
          'choices': ['ps aux --sort=-%mem', 'whoami', 'pwd'],
          'correctIndex': 0,
          'explanation': 'ps aux trié par %mem affiche les processus consommateurs de RAM.'
        }
      ]
    }
  ];

  String _syntaxStatus = '✅ Syntaxe Valide';
  bool _hasSyntaxError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateCodeFromForm();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _editorController.dispose();
    super.dispose();
  }

  void _generateCodeFromForm() {
    final sb = StringBuffer();
    sb.writeln('course "$_courseId" {');
    sb.writeln('  title: "$_courseTitle"');
    sb.writeln('  description: "$_courseDesc"');
    sb.writeln('  category: $_category');
    sb.writeln('  level: $_level');
    sb.writeln('  duration: $_duration');
    sb.writeln('  icon: $_icon');
    sb.writeln('  keywords: [$_category, sysadmin, tdc]');
    sb.writeln();

    for (final m in _modules) {
      sb.writeln('  module "${m['id']}" {');
      sb.writeln('    title: "${m['title']}"');
      sb.writeln('    duration: ${m['duration']}');
      sb.writeln();
      sb.writeln('    content """');
      sb.writeln(m['content']);
      sb.writeln('    """');

      final codeBlocks = (m['codeBlocks'] as List?) ?? [];
      for (final cb in codeBlocks) {
        sb.writeln();
        sb.writeln('    codeblock "${cb['language']}" {');
        sb.writeln('      title: "${cb['title']}"');
        sb.writeln('      code """');
        sb.writeln(cb['code']);
        sb.writeln('      """');
        sb.writeln('    }');
      }

      final quiz = (m['quiz'] as List?) ?? [];
      if (quiz.isNotEmpty) {
        sb.writeln();
        sb.writeln('    quiz {');
        for (final q in quiz) {
          sb.writeln('      question "${q['question']}" {');
          final choices = (q['choices'] as List?) ?? [];
          final correct = q['correctIndex'] as int? ?? 0;
          for (int i = 0; i < choices.length; i++) {
            final prefix = (i == correct) ? '+' : '-';
            sb.writeln('        $prefix "${choices[i]}"');
          }
          if (q['explanation'] != null) {
            sb.writeln('        explanation: "${q['explanation']}"');
          }
          sb.writeln('      }');
        }
        sb.writeln('    }');
      }

      sb.writeln('  }');
      sb.writeln();
    }

    sb.writeln('}');
    _editorController.text = sb.toString();
    _validateSyntax(sb.toString());
  }

  void _validateSyntax(String code) {
    if (code.contains('course ') && code.contains('module ') && code.contains('{')) {
      setState(() {
        _syntaxStatus = '✅ Syntaxe .TDC Valide';
        _hasSyntaxError = false;
      });
    } else {
      setState(() {
        _syntaxStatus = '❌ Erreur de Syntaxe : Bloc course ou module manquant';
        _hasSyntaxError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBDA).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF5EBDA).withOpacity(0.4)),
              ),
              child: const Text(
                'TDC SDK Studio',
                style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _syntaxStatus,
              style: TextStyle(
                color: _hasSyntaxError ? Colors.redAccent : Colors.greenAccent,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Color(0xFFF5EBDA)),
            tooltip: 'Copier le code .TDC',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _editorController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code .TDC copié dans le presse-papier !')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF5EBDA),
          labelColor: const Color(0xFFF5EBDA),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Formulaire Studio'),
            Tab(icon: Icon(Icons.code), text: 'Éditeur .TDC'),
            Tab(icon: Icon(Icons.remove_red_eye), text: 'Aperçu Direct'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(),
          _buildCodeEditorTab(),
          _buildPreviewTab(),
        ],
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. Informations du Cours', style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 16, FontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _courseId,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'ID du Cours', border: OutlineInputBorder()),
                  onChanged: (v) {
                    _courseId = v;
                    _generateCodeFromForm();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _courseTitle,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Titre du Cours', border: OutlineInputBorder()),
                  onChanged: (v) {
                    _courseTitle = v;
                    _generateCodeFromForm();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _courseDesc,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Description Pédagogique', border: OutlineInputBorder()),
            onChanged: (v) {
              _courseDesc = v;
              _generateCodeFromForm();
            },
          ),
          const SizedBox(height: 24),
          const Text('2. Chapitres & Modules', style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 16, FontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._modules.map((m) {
            return Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['title'], style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: m['content'],
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Contenu Markdown', border: OutlineInputBorder()),
                      onChanged: (v) {
                        m['content'] = v;
                        _generateCodeFromForm();
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCodeEditorTab() {
    return Container(
      color: const Color(0xFF050505),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _editorController,
        maxLines: null,
        style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFF5EBDA), fontSize: 14, height: 1.5),
        decoration: const InputDecoration(border: InputBorder.none),
        onChanged: _validateSyntax,
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF5EBDA).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_courseTitle, style: const TextStyle(color: Colors.white, fontSize: 20, FontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_courseDesc, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._modules.map((m) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['title'], style: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 16, FontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: m['content'],
                  styleSheet: MarkdownStyleSheet.darkThemeStyleSheet(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
