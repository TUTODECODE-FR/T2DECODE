// ignore_for_file: library_private_types_in_public_api, strict_top_level_inference
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import '../widgets/lesson_reading.dart';
import '../widgets/qcm_widget.dart';

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
        child: Text(
          'Aucun chapitre',
          style: TextStyle(color: TdcColors.textMuted),
        ),
      );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TdcColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: TdcColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: TdcColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '+50 XP',
                      style: const TextStyle(
                        color: TdcColors.accent,
                        fontFamily: 'Aileron',
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
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: TdcColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    chapter.duration.isNotEmpty ? chapter.duration : '15 min',
                    style: const TextStyle(
                      color: TdcColors.textMuted,
                      fontFamily: 'Aileron',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/ghost_ai');
                  },
                  icon: const Icon(
                    Icons.smart_toy_outlined,
                    size: 14,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Poser une question à Ghost AI',
                    style: TextStyle(
                      fontFamily: 'Aileron',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),

        LessonScrollProgress(controller: _scroll),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kLessonColumnWidth),
              child: OfficialLessonBody(
                scrollController: _scroll,
                course: course,
                chapter: chapter,
                quiz: chapter.quiz == null || chapter.quiz!.isEmpty
                    ? null
                    : QcmWidget(
                        questions: chapter.quiz!,
                        chapterContent: chapter.content,
                        onComplete: (ok) {
                          if (!ok) return;
                          prov.toggleCompleted(course.id, chapter.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: TdcColors.accent,
                              content: Text(
                                'Chapitre validé, +50 XP.',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
        _nav(course, chapter, prov),
      ],
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
        border: Border(top: BorderSide(color: TdcColors.border)),
      ),
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
                          content: Text(
                            'Réussissez le quiz en bas du chapitre pour continuer.',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                  : () {
                      setState(() => _quizPassed = false);
                      if (hasNext) {
                        prov.selectChapter(
                          course.id,
                          course.chapters[idx + 1].id,
                        );
                        _scroll.jumpTo(0);
                      } else {
                        Navigator.pop(context);
                      }
                    },
              icon: Icon(
                isLocked
                    ? Icons.lock_outline
                    : (hasNext ? Icons.chevron_right : Icons.check),
                size: 18,
                color: Colors.black,
              ),
              label: Text(
                isLocked
                    ? 'Quiz obligatoire'
                    : (hasNext ? 'Suivant' : 'Terminer'),
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Aileron',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked || hasNext
                    ? TdcColors.accent
                    : TdcColors.success,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
