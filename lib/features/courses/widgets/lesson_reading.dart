// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
// markdown is the AST used by flutter_markdown_plus's public builder API.
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:tutodecode/utils/markdown_sanitizer.dart';

/// Comfortable measure for a lesson column (about 70 characters at 16px).
const double kLessonColumnWidth = 720;

const int _chapoMaxChars = 480;

const TextStyle _proseStyle = TextStyle(
  color: TdcColors.textSecondary,
  fontFamily: 'Aileron',
  fontSize: 16.5,
  height: 1.75,
);

const TextStyle _h1Style = TextStyle(
  color: TdcColors.textPrimary,
  fontFamily: 'Aileron',
  fontSize: 26,
  fontWeight: FontWeight.w700,
  height: 1.25,
  letterSpacing: -0.3,
);

const TextStyle _h2Style = TextStyle(
  color: TdcColors.textPrimary,
  fontFamily: 'Aileron',
  fontSize: 22,
  fontWeight: FontWeight.w700,
  height: 1.3,
  letterSpacing: -0.2,
);

const TextStyle _h3Style = TextStyle(
  color: TdcColors.textPrimary,
  fontFamily: 'Aileron',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.35,
);

const TextStyle _monoStyle = TextStyle(
  color: TdcColors.textPrimary,
  fontFamily: 'monospace',
  fontSize: 13.5,
  height: 1.55,
);

/// Opening of a lesson after the page title has been lifted out of the body.
class LessonOpening {
  const LessonOpening({
    required this.kicker,
    required this.chapoMarkdown,
    required this.bodyMarkdown,
  });

  /// First level-1 heading when it is not the chapter title.
  final String? kicker;

  /// Short opening paragraph. Empty when the lesson does not start with prose.
  final String chapoMarkdown;

  /// Remaining markdown, without the lifted heading and chapô.
  final String bodyMarkdown;
}

String _flat(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

/// Pulls a readable title, lead, and body out of official lesson markdown.
///
/// The chapter title stays in the masthead. A matching level-1 heading is
/// dropped so the page does not repeat it. A short first paragraph becomes
/// the chapô. Fences, lists, and long openings stay in the body.
LessonOpening prepareLessonOpening(String markdown, String chapterTitle) {
  var rest = markdown.replaceAll('\r\n', '\n').trim();
  String? kicker;

  if (rest.isNotEmpty) {
    final newline = rest.indexOf('\n');
    final firstLine = (newline == -1 ? rest : rest.substring(0, newline))
        .trim();
    final heading = RegExp(r'^#\s+([^#].*)$').firstMatch(firstLine);
    if (heading != null) {
      final text = heading.group(1)!.trim();
      if (text.isNotEmpty && _flat(text) != _flat(chapterTitle)) {
        kicker = text;
      }
      rest = newline == -1 ? '' : rest.substring(newline + 1).trimLeft();
    }
  }

  rest = rest.trim();
  if (!_isLiftedProse(rest)) {
    return LessonOpening(kicker: kicker, chapoMarkdown: '', bodyMarkdown: rest);
  }

  final splitAt = rest.indexOf('\n\n');
  final first = (splitAt == -1 ? rest : rest.substring(0, splitAt)).trim();
  final after = splitAt == -1 ? '' : rest.substring(splitAt + 2).trim();
  if (!_isLiftedProse(first)) {
    return LessonOpening(kicker: kicker, chapoMarkdown: '', bodyMarkdown: rest);
  }

  return LessonOpening(
    kicker: kicker,
    chapoMarkdown: first,
    bodyMarkdown: after,
  );
}

bool _isLiftedProse(String block) {
  final trimmed = block.trimLeft();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('```')) return false;
  if (trimmed.startsWith('#')) return false;
  if (trimmed.startsWith('>')) return false;
  if (trimmed.startsWith('---')) return false;
  if (RegExp(r'^([-*+] |\d+\. )').hasMatch(trimmed)) return false;
  final first = trimmed.split('\n\n').first.trim();
  if (first.length > _chapoMaxChars) return false;
  return true;
}

/// Unlabeled fences in the official lessons are teaching panels (flows,
/// verb lists, status codes). Fences with a language, or with code tokens,
/// stay monospace code.
bool lessonFenceIsCallout(String code, String? language) {
  final lang = language?.trim() ?? '';
  if (lang.isNotEmpty) return false;
  final trimmed = code.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) return false;
  if (trimmed.contains('→') || trimmed.contains('←')) return true;
  final codeToken = RegExp(
    r'''[{};]|^\s*(def|class|import|function|const|let|var|fn|pub |package |#include|#!|from |func )\b|=>|::''',
    multiLine: true,
  );
  if (codeToken.hasMatch(trimmed)) return false;
  final lines = trimmed.split('\n').where((line) => line.trim().isNotEmpty);
  return lines.every((line) => line.trim().length <= 88);
}

/// Pinned reading progress for the open chapter. Chapter index lives in the
/// masthead; this bar tracks the scroll position inside that chapter.
class LessonScrollProgress extends StatelessWidget {
  const LessonScrollProgress({super.key, required this.controller});

  final ScrollController controller;

  double _value() {
    if (!controller.hasClients) return 0;
    final max = controller.position.maxScrollExtent;
    if (max <= 0) return 0;
    return (controller.offset / max).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = _value();
        return Semantics(
          label: 'Progression de la lecture',
          value: '${(value * 100).round()} %',
          child: LinearProgressIndicator(
            key: const Key('lesson-scroll-progress'),
            value: value,
            minHeight: 2,
            backgroundColor: const Color(0xFF1A1A1A),
            color: TdcColors.accent,
          ),
        );
      },
    );
  }
}

/// Official lesson column: masthead, chapô, markdown, authored examples, quiz.
class OfficialLessonBody extends StatelessWidget {
  const OfficialLessonBody({
    super.key,
    required this.course,
    required this.chapter,
    this.scrollController,
    this.quiz,
  });

  final Course course;
  final CourseChapter chapter;
  final ScrollController? scrollController;
  final Widget? quiz;

  @override
  Widget build(BuildContext context) {
    final opening = prepareLessonOpening(
      MarkdownSanitizer.sanitize(chapter.content),
      chapter.title,
    );
    final index = course.chapters.indexWhere((item) => item.id == chapter.id);
    final number = index < 0 ? 1 : index + 1;
    final total = course.chapters.isEmpty ? number : course.chapters.length;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 64),
      children: [
        _LessonMasthead(
          category: course.category,
          title: chapter.title,
          kicker: opening.kicker,
          chapoMarkdown: opening.chapoMarkdown,
          moduleTitle: course.title,
          duration: chapter.duration.trim().isEmpty
              ? '15 min'
              : chapter.duration.trim(),
          chapterNumber: number,
          chapterCount: total,
          incident: _isIncident(course),
          attribution: _attribution(course),
        ),
        const SizedBox(height: 8),
        if (opening.bodyMarkdown.trim().isNotEmpty)
          _LessonMarkdown(data: opening.bodyMarkdown),
        ..._examplePanels(chapter),
        if (quiz != null) ...[
          const SizedBox(height: 28),
          _QuizFrame(child: quiz!),
        ],
      ],
    );
  }
}

bool _isIncident(Course course) {
  return course.keywords.any(
        (word) => word.toLowerCase().contains('incident'),
      ) ||
      course.id.toLowerCase().contains('incident');
}

String? _attribution(Course course) {
  final signed = course.signedBy?.trim();
  if (signed != null && signed.isNotEmpty) return signed;
  final author = course.author?.trim();
  if (author != null && author.isNotEmpty) return author;
  return null;
}

List<Widget> _examplePanels(CourseChapter chapter) {
  final blocks = chapter.codeBlocks;
  if (blocks == null || blocks.isEmpty) return const [];
  final panels = <Widget>[];
  for (final block in blocks) {
    final code = block['code']?.toString() ?? '';
    if (code.trim().isEmpty) continue;
    final title = block['title']?.toString().trim();
    final language = block['language']?.toString().trim();
    panels.add(
      Padding(
        padding: const EdgeInsets.only(top: 14),
        child: _CodePanel(
          code: code.trimRight(),
          language: language,
          title: title == null || title.isEmpty ? null : title,
          authored: true,
        ),
      ),
    );
  }
  if (panels.isEmpty) return const [];
  return [
    const SizedBox(height: 36),
    const _Eyebrow('EXEMPLE'),
    const SizedBox(height: 6),
    const Text(
      'Le code du chapitre, à lire après le texte.',
      style: TextStyle(
        color: TdcColors.textMuted,
        fontFamily: 'Aileron',
        fontSize: 13,
        height: 1.4,
      ),
    ),
    ...panels,
  ];
}

class _LessonMasthead extends StatelessWidget {
  const _LessonMasthead({
    required this.category,
    required this.title,
    required this.kicker,
    required this.chapoMarkdown,
    required this.moduleTitle,
    required this.duration,
    required this.chapterNumber,
    required this.chapterCount,
    required this.incident,
    required this.attribution,
  });

  final String category;
  final String title;
  final String? kicker;
  final String chapoMarkdown;
  final String moduleTitle;
  final String duration;
  final int chapterNumber;
  final int chapterCount;
  final bool incident;
  final String? attribution;

  @override
  Widget build(BuildContext context) {
    final safeCount = chapterCount <= 0 ? 1 : chapterCount;
    final safeNumber = chapterNumber < 1
        ? 1
        : (chapterNumber > safeCount ? safeCount : chapterNumber);
    return Column(
      key: const Key('lesson-masthead'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (category.trim().isNotEmpty)
              _Chip(label: category.trim().toUpperCase()),
            if (incident) const _Chip(label: 'MODE INCIDENT'),
            Text(
              duration,
              style: const TextStyle(
                color: TdcColors.textMuted,
                fontFamily: 'Aileron',
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Chapitre $safeNumber sur $safeCount',
          key: const Key('lesson-chapter-label'),
          style: const TextStyle(
            color: TdcColors.accent,
            fontFamily: 'Aileron',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        if (safeCount > 1) ...[
          const SizedBox(height: 8),
          _ChapterPips(count: safeCount, current: safeNumber),
        ],
        const SizedBox(height: 22),
        Text(
          title,
          key: const Key('lesson-title'),
          style: const TextStyle(
            color: TdcColors.textPrimary,
            fontFamily: 'Aileron',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.12,
            letterSpacing: -0.6,
          ),
        ),
        if (kicker != null && kicker!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            kicker!,
            key: const Key('lesson-kicker'),
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontFamily: 'Aileron',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
        if (chapoMarkdown.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _LessonMarkdown(
            key: const Key('lesson-chapo'),
            data: chapoMarkdown,
            proseOnly: true,
          ),
        ],
        const SizedBox(height: 18),
        Text(
          moduleTitle,
          style: const TextStyle(
            color: TdcColors.textMuted,
            fontFamily: 'Aileron',
            fontSize: 13,
            height: 1.4,
          ),
        ),
        if (attribution != null) ...[
          const SizedBox(height: 4),
          Text(
            attribution!,
            style: const TextStyle(
              color: TdcColors.textTertiary,
              fontFamily: 'Aileron',
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Container(height: 1, color: TdcColors.accent.withValues(alpha: 0.28)),
      ],
    );
  }
}

class _ChapterPips extends StatelessWidget {
  const _ChapterPips({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final shown = count > 12 ? 12 : count;
    return Row(
      key: const Key('lesson-chapter-pips'),
      children: [
        for (var i = 0; i < shown; i++)
          Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i == shown - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: i == current - 1
                    ? TdcColors.accent
                    : i < current - 1
                    ? TdcColors.accent.withValues(alpha: 0.4)
                    : const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TdcColors.accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TdcColors.accent,
          fontFamily: 'Aileron',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: TdcColors.accent,
        fontFamily: 'Aileron',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _QuizFrame extends StatelessWidget {
  const _QuizFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('lesson-quiz'),
      width: double.infinity,
      padding: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: TdcColors.accent.withValues(alpha: 0.28)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('QUIZ OBLIGATOIRE'),
          const SizedBox(height: 8),
          const Text(
            'Validez ce chapitre pour continuer. Le quiz embarqué fonctionne hors ligne.',
            style: TextStyle(
              color: TdcColors.textSecondary,
              fontFamily: 'Aileron',
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _LessonMarkdown extends StatelessWidget {
  const _LessonMarkdown({
    super.key,
    required this.data,
    this.proseOnly = false,
  });

  final String data;
  final bool proseOnly;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      imageBuilder: _blockedImage,
      builders: proseOnly
          ? const {}
          : {
              'pre': _FenceBuilder(),
              'h1': _HeadingBuilder(1),
              'h2': _HeadingBuilder(2),
              'h3': _HeadingBuilder(3),
            },
      styleSheet: MarkdownStyleSheet(
        p: proseOnly
            ? _proseStyle.copyWith(
                fontSize: 18,
                height: 1.65,
                color: TdcColors.textSecondary,
              )
            : _proseStyle,
        pPadding: const EdgeInsets.only(bottom: 4),
        h1: _h1Style,
        h1Padding: EdgeInsets.zero,
        h2: _h2Style,
        h2Padding: EdgeInsets.zero,
        h3: _h3Style,
        h3Padding: EdgeInsets.zero,
        h4: _h3Style,
        h5: _h3Style,
        h6: _h3Style,
        blockSpacing: 16,
        listIndent: 22,
        listBullet: const TextStyle(
          color: TdcColors.accent,
          fontFamily: 'Aileron',
          fontSize: 16,
        ),
        strong: const TextStyle(
          color: TdcColors.textPrimary,
          fontFamily: 'Aileron',
          fontWeight: FontWeight.w700,
        ),
        em: const TextStyle(
          color: TdcColors.textSecondary,
          fontFamily: 'Aileron',
          fontStyle: FontStyle.italic,
        ),
        a: const TextStyle(
          color: TdcColors.accent,
          fontFamily: 'Aileron',
          decoration: TextDecoration.underline,
        ),
        code: const TextStyle(
          color: TdcColors.textPrimary,
          backgroundColor: Color(0xFF161616),
          fontFamily: 'monospace',
          fontSize: 13.5,
        ),
        codeblockPadding: EdgeInsets.zero,
        codeblockDecoration: const BoxDecoration(),
        blockquote: const TextStyle(
          color: TdcColors.textSecondary,
          fontFamily: 'Aileron',
          fontSize: 16,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        blockquoteDecoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: TdcColors.accent.withValues(alpha: 0.85),
              width: 3,
            ),
          ),
        ),
        tableHead: const TextStyle(
          color: TdcColors.accent,
          fontFamily: 'Aileron',
          fontWeight: FontWeight.w700,
        ),
        tableBody: _proseStyle.copyWith(fontSize: 14, height: 1.4),
        tableBorder: TableBorder.all(
          color: TdcColors.accent.withValues(alpha: 0.22),
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: TdcColors.accent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _blockedImage(Uri uri, String? title, String? alt) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF101010),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: TdcColors.accent.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.image_not_supported,
          size: 16,
          color: TdcColors.textMuted,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Image bloquée par sécurité${alt == null || alt.isEmpty ? '' : ' : $alt'}',
            style: const TextStyle(
              fontSize: 12,
              color: TdcColors.textMuted,
              fontFamily: 'Aileron',
            ),
          ),
        ),
      ],
    ),
  );
}

class _HeadingBuilder extends MarkdownElementBuilder {
  _HeadingBuilder(this.level);

  final int level;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final text = element.textContent.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final TextStyle style;
    if (level == 1) {
      style = _h1Style;
    } else if (level == 2) {
      style = _h2Style;
    } else {
      style = _h3Style;
    }
    return Padding(
      padding: EdgeInsets.only(top: level == 1 ? 8 : 26, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: style),
          if (level <= 2) ...[
            const SizedBox(height: 8),
            Container(
              width: level == 1 ? 48 : 28,
              height: 2,
              color: TdcColors.accent.withValues(alpha: level == 1 ? 0.9 : 0.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _FenceBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) => null;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = _fenceText(element.textContent);
    final language = _languageOf(element);
    if (lessonFenceIsCallout(code, language)) {
      return _Callout(code: code);
    }
    return _CodePanel(code: code, language: language);
  }
}

String _fenceText(String raw) {
  var text = raw.replaceAll('\r\n', '\n');
  if (text.startsWith('\n')) text = text.substring(1);
  if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
  return text;
}

String? _languageOf(md.Element pre) {
  for (final child in pre.children ?? const []) {
    if (child is md.Element && child.tag == 'code') {
      final cls = child.attributes['class'] ?? '';
      const prefix = 'language-';
      if (cls.startsWith(prefix)) {
        final language = cls.substring(prefix.length).trim();
        if (language.isNotEmpty) return language;
      }
    }
  }
  return null;
}

class _Callout extends StatelessWidget {
  const _Callout({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>('lesson-callout-${code.hashCode}'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TdcColors.accent.withValues(alpha: 0.28)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: TdcColors.accent, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'REPÈRE',
                style: TextStyle(
                  color: TdcColors.textMuted,
                  fontFamily: 'Aileron',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(code, style: _monoStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  const _CodePanel({
    required this.code,
    this.language,
    this.title,
    this.authored = false,
  });

  final String code;
  final String? language;
  final String? title;
  final bool authored;

  @override
  Widget build(BuildContext context) {
    final lang = (language == null || language!.trim().isEmpty)
        ? 'CODE'
        : language!.trim().toUpperCase();
    return Container(
      key: ValueKey<String>(
        '${authored ? 'lesson-authored-code' : 'lesson-code'}-${(title ?? lang).hashCode}',
      ),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: Color(0xFF2C2C2C))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? lang,
                    style: const TextStyle(
                      color: TdcColors.textPrimary,
                      fontFamily: 'Aileron',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (title != null)
                  Text(
                    lang,
                    style: const TextStyle(
                      color: TdcColors.textMuted,
                      fontFamily: 'Aileron',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SelectionArea(
              child: Text(code, style: _monoStyle, softWrap: false),
            ),
          ),
        ],
      ),
    );
  }
}
