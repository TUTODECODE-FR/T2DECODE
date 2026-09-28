// ignore_for_file: library_private_types_in_public_api, strict_top_level_inference
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import '../widgets/qcm_widget.dart';
import 'package:tutodecode/utils/markdown_sanitizer.dart';

class ChapterScreen extends StatefulWidget {
  const ChapterScreen({super.key});
  @override
  _ChapterScreenState createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final ScrollController _scroll = ScrollController();
  bool _quizPassed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateShell();
    });
  }

  void _updateShell() {
    final prov = context.read<CoursesProvider>();
    final course = prov.currentCourse;
    final chapter = prov.currentChapter;
    if (course != null && chapter != null) {
      context.read<ShellProvider>().updateShell(
            title: chapter.title,
            showBackButton: true,
          );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<CoursesProvider>(context);
    final course = prov.currentCourse;
    final chapter = prov.currentChapter;

    if (course == null || chapter == null) {
      return const Center(
          child: Text('Aucun chapitre',
              style: TextStyle(color: TdcColors.textMuted)));
    }

    return Column(
      children: [
        // Barre d'engagement & XP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: TdcColors.surfaceAlt,
            border: Border(bottom: BorderSide(color: TdcColors.border)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TdcColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TdcColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: TdcColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '+50 XP',
                      style: const TextStyle(
                        color: TdcColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: TdcColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    chapter.duration.isNotEmpty ? chapter.duration : '15 min',
                    style: const TextStyle(color: TdcColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/ghost_ai');
                  },
                  icon: const Icon(Icons.smart_toy_outlined, size: 14, color: Colors.black),
                  label: const Text('Poser une question à Ghost AI',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                children: [
                  // Bannière Hero de Chapitre (Design 2026)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14141E), Color(0xFF09090D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TdcColors.accent.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: TdcColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: TdcColors.accent.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                course.category.toUpperCase(),
                                style: const TextStyle(
                                  color: TdcColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            if (course.keywords.any((k) => k.toLowerCase().contains('incident')) ||
                                course.id.toLowerCase().contains('incident'))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  '🔥 MODE INCIDENT RÉEL',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.star, color: TdcColors.accent, size: 14),
                                SizedBox(width: 4),
                                Text('+50 XP', style: TextStyle(color: TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          chapter.title,
                          style: const TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Module : ${course.title} • Durée estimée : ${chapter.duration.isNotEmpty ? chapter.duration : "15 min"}',
                          style: const TextStyle(color: TdcColors.textMuted, fontSize: 12),
                        ),
                        if (course.author != null && course.author!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline, size: 13, color: TdcColors.accent),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Auteur : ${course.author}',
                                    style: const TextStyle(
                                      color: TdcColors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (course.signedBy != null && course.signedBy!.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_outlined, size: 13, color: Colors.greenAccent),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Signé : ${course.signedBy}',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Contenu Markdown du chapitre
                  _markdown(chapter.content),

                  if (chapter.quiz != null && chapter.quiz!.isNotEmpty) ...[
                    const SizedBox(height: 36),
                    const TdcSectionTitle('QUIZ & DÉFI XP'),
                    const SizedBox(height: 16),
                    QcmWidget(
                      questions: chapter.quiz!,
                      chapterContent: chapter.content,
                      onComplete: (ok) {
                        if (ok) {
                          prov.toggleCompleted(course.id, chapter.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: TdcColors.accent,
                              content: Text('🎉 Bravo ! Chapitre validé +50 XP remportés !', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
        _nav(course, chapter, prov),
      ],
    );
  }

  Widget _markdown(String content) {
    return MarkdownBody(
      data: MarkdownSanitizer.sanitize(content),
      imageBuilder: (uri, title, alt) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: TdcColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported,
                size: 16, color: TdcColors.textMuted),
            const SizedBox(width: 8),
            Text('Image bloquée par sécurité: $alt',
                style:
                    const TextStyle(fontSize: 11, color: TdcColors.textMuted)),
          ],
        ),
      ),
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
            color: TdcColors.textPrimary, fontSize: 15, height: 1.7),
        h1: const TextStyle(
            color: TdcColors.accent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.4),
        h2: const TextStyle(
            color: TdcColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.4),
        h3: const TextStyle(
            color: TdcColors.accent,
            fontSize: 15,
            fontWeight: FontWeight.w600),
        code: const TextStyle(
            color: TdcColors.accent,
            backgroundColor: Color(0xFF14141E),
            fontFamily: 'monospace',
            fontSize: 13),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF06060A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TdcColors.border),
        ),
        codeblockPadding: const EdgeInsets.all(16),
        a: const TextStyle(
            color: TdcColors.accent, decoration: TextDecoration.underline),
        strong: const TextStyle(
            color: TdcColors.textPrimary, fontWeight: FontWeight.bold),
        em: const TextStyle(
            color: TdcColors.textSecondary, fontStyle: FontStyle.italic),
        blockquote: const TextStyle(
            color: TdcColors.accent, fontStyle: FontStyle.italic, fontSize: 14, height: 1.5),
        blockquoteDecoration: BoxDecoration(
          color: const Color(0xFF0F0F16),
          borderRadius: BorderRadius.circular(8),
          border: const Border(left: BorderSide(color: TdcColors.accent, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.all(16),
        tableHead: const TextStyle(
            color: TdcColors.accent, fontWeight: FontWeight.bold),
        tableBody: const TextStyle(color: TdcColors.textPrimary),
        tableBorder: TableBorder.all(color: TdcColors.border),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: TdcColors.accent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(course, chapter, prov) {
    final idx = course.chapters.indexOf(chapter);
    final hasNext = idx < course.chapters.length - 1;
    final isCompleted = prov.completed.contains('${course.id}:${chapter.id}');
    final isLocked = chapter.quiz != null && !_quizPassed && !isCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          color: TdcColors.surface,
          border: Border(top: BorderSide(color: TdcColors.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (idx > 0)
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _quizPassed = false);
                  prov.selectChapter(course.id, course.chapters[idx - 1].id);
                  _scroll.jumpTo(0);
                },
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Précédent'),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLocked
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: TdcColors.warning,
                          content: Text('🔒 Vous devez réussir le Quiz à la fin du chapitre pour débloquer la suite !', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }
                  : () {
                      setState(() => _quizPassed = false);
                      if (hasNext) {
                        prov.selectChapter(course.id, course.chapters[idx + 1].id);
                        _scroll.jumpTo(0);
                      } else {
                        Navigator.pop(context);
                      }
                    },
              icon: Icon(isLocked ? Icons.lock : (hasNext ? Icons.chevron_right : Icons.check), size: 18),
              label: Text(isLocked ? 'Quiz Obligatoire' : (hasNext ? 'Suivant' : 'Terminer')),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked ? TdcColors.surfaceAlt : (hasNext ? TdcColors.accent : TdcColors.success),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
