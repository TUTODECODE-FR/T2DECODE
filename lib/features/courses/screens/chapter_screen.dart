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

class ChapterScreen extends StatefulWidget {
  const ChapterScreen({super.key});
  @override _ChapterScreenState createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final ScrollController _scroll = ScrollController();

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
      return Center(child: Text('Aucun chapitre', style: TextStyle(color: TdcColors.textMuted)));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(24),
            children: [
              Text(course.title, style: const TextStyle(color: TdcColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(chapter.title, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _markdown(chapter.content),
              const SizedBox(height: 28),
              _practiceSection(course, chapter),
              if (chapter.quiz != null) ...[
                const SizedBox(height: 32),
                const TdcSectionTitle('QUIZ'),
                const SizedBox(height: 16),
                QcmWidget(
                  questions: chapter.quiz!,
                  onComplete: (ok) { if (ok) prov.toggleCompleted(course.id, chapter.id); },
                ),
              ],
              const SizedBox(height: 48),
            ],
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
        Text(
          "Teste le concept dans un environnement contrôlé (simulation locale) ou ouvre directement un lab.",
          style: const TextStyle(color: TdcColors.textMuted, fontSize: 12, height: 1.35),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: l.tint.withOpacity(0.10),
                              border: Border.all(color: l.tint.withOpacity(0.25)),
                            ),
                            child: Text(
                              'Ouvrir le lab',
                              style: TextStyle(color: l.tint, fontSize: 11, fontWeight: FontWeight.bold),
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
                            onPressed: () => Navigator.pushNamed(context, l.toolRoute!),
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
      data: content,
      // Sécurité : Désactiver les images distantes et les liens non-contrôlés
      imageBuilder: (uri, title, alt) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: TdcColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported, size: 16, color: TdcColors.textMuted),
            const SizedBox(width: 8),
            Text('Image bloquée par sécurité: $alt', style: const TextStyle(fontSize: 11, color: TdcColors.textMuted)),
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
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                  TextButton(
                    onPressed: () { 
                      Navigator.pop(ctx);
                      // On pourrait utiliser launchUrl ici si on veut autoriser
                    }, 
                    child: const Text('Ouvrir', style: TextStyle(color: TdcColors.danger))
                  ),
                ],
              ),
            );
          }
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(color: TdcColors.textSecondary, fontSize: 15, height: 1.6),
        h1: const TextStyle(color: TdcColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        h2: const TextStyle(color: TdcColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        h3: const TextStyle(color: TdcColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        code: const TextStyle(color: TdcColors.warning, backgroundColor: TdcColors.surfaceAlt, fontFamily: 'monospace'),
        a: const TextStyle(color: TdcColors.accent, decoration: TextDecoration.underline),
        strong: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold),
        em: const TextStyle(color: TdcColors.textSecondary, fontStyle: FontStyle.italic),
        blockquote: const TextStyle(color: TdcColors.textMuted, fontStyle: FontStyle.italic),
        tableHead: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold),
        tableBody: const TextStyle(color: TdcColors.textSecondary),
      ),
    );
  }

  Widget _nav(course, chapter, prov) {
    final idx = course.chapters.indexOf(chapter);
    final hasNext = idx < course.chapters.length - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, border: Border(top: BorderSide(color: TdcColors.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (idx > 0) 
            Expanded(
              child: TextButton.icon(
                onPressed: () { prov.selectChapter(course.id, course.chapters[idx-1].id); _scroll.jumpTo(0); },
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Précédent'),
              ),
            )
          else 
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () { 
                if (hasNext) {
                  prov.selectChapter(course.id, course.chapters[idx+1].id);
                  _scroll.jumpTo(0);
                } else {
                  Navigator.pop(context);
                }
              }, 
              icon: Icon(hasNext ? Icons.chevron_right : Icons.check, size: 18),
              label: Text(hasNext ? 'Suivant' : 'Terminer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasNext ? TdcColors.accent : TdcColors.success,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
