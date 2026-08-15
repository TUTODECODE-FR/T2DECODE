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
import 'package:tutodecode/features/courses/practice/course_practice_engine.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:tutodecode/features/courses/practice/widgets/practice_flow.dart';
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
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/ghost_ai');
                },
                icon: const Icon(Icons.smart_toy_outlined, size: 14, color: Colors.black),
                label: const Text('POSER UNE QUESTION À GHOST AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TdcColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  // Chapter Header & Pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF333333)),
                        ),
                        child: Text(
                          'CHAPITRE ${course.chapters.indexOf(chapter) + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        chapter.duration.isNotEmpty ? chapter.duration : '15min',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    chapter.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contenu Markdown du chapitre dans une carte stylisée
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF242424)),
                    ),
                    child: _markdown(chapter.content),
                  ),
                  const SizedBox(height: 36),

                  _practiceSection(course, chapter),
                  const SizedBox(height: 28),

                  // Section Quiz & Évaluation
                  Row(
                    children: const [
                      Text('✦', style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Text(
                        'Quiz & Évaluation',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (chapter.quiz == null || chapter.quiz!.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF242424)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 16, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Aucun QCM dans ce chapitre (contenu purement théorique).',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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

  Widget _practiceSection(Course course, CourseChapter chapter) {
    final links = CoursePracticeEngine.recommend(course, chapter);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TdcSectionTitle('PRATIQUE (VIRTUEL)'),
        const SizedBox(height: 12),
        const Text(
          "Teste le concept dans un environnement contrôlé (simulation locale) ou ouvre directement un lab.",
          style:
              TextStyle(color: TdcColors.textMuted, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 14),
        ...links.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TdcCard(
                padding: const EdgeInsets.all(14),
                onTap: l.labArgs != null ? () => _openLab(l.labArgs!) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(l.icon, size: 18, color: l.tint),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.title,
                                style: const TextStyle(
                                  color: TdcColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.subtitle,
                                style: const TextStyle(
                                  color: TdcColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (l.labArgs != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: l.tint.withValues(alpha: 0.10),
                              border: Border.all(
                                  color: l.tint.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              'Ouvrir le lab',
                              style: TextStyle(
                                  color: l.tint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PracticeFlowDiagram(nodes: l.flow),
                    if (l.embeddedSandbox != null) ...[
                      const SizedBox(height: 12),
                      l.embeddedSandbox!,
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (l.labArgs != null)
                          OutlinedButton.icon(
                            onPressed: () => _openLab(l.labArgs!),
                            icon: const Icon(Icons.science_outlined, size: 16),
                            label: const Text('Lab'),
                          ),
                        if (l.toolRoute != null)
                          OutlinedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, l.toolRoute!),
                            icon: const Icon(Icons.handyman_outlined, size: 16),
                            label: const Text('Outil'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void _openLab(Map<String, dynamic> args) {
    Navigator.pushNamed(context, '/lab', arguments: args);
  }

  Widget _markdown(String content) {
    return MarkdownBody(
      data: MarkdownSanitizer.sanitize(content),
      // Sécurité : Désactiver les images distantes et les liens non-contrôlés
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
      onTapLink: (text, href, title) {
        if (href != null) {
          final uri = Uri.tryParse(href);
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Lien externe'),
                content: Text('Voulez-vous ouvrir ce lien externe ?\n\n$href'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler')),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // On pourrait utiliser launchUrl ici si on veut autoriser
                      },
                      child: const Text('Ouvrir',
                          style: TextStyle(color: TdcColors.danger))),
                ],
              ),
            );
          }
        }
      },
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
