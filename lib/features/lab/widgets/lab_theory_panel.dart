// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Shared Theory Panel pour les Simulateurs
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/utils/markdown_sanitizer.dart';

class LabTheoryPanel extends StatelessWidget {
  final String title;
  final String markdownContent;
  final Color accentColor;

  const LabTheoryPanel({
    super.key,
    required this.title,
    required this.markdownContent,
    required this.accentColor,
  });

  static void show(BuildContext context, {
    required String title,
    required String markdownContent,
    required Color accentColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LabTheoryPanel(
        title: title,
        markdownContent: markdownContent,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: TdcColors.bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: TdcColors.border),
          left: BorderSide(color: TdcColors.border),
          right: BorderSide(color: TdcColors.border),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TdcColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.menu_book, color: accentColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: TdcColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Fermer',
                ),
              ],
            ),
          ),
          
          const Divider(color: TdcColors.border, height: 1),
          
          // Content
          Expanded(
            child: Markdown(
              data: MarkdownSanitizer.sanitize(markdownContent),
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: TdcColors.textSecondary, fontSize: 15, height: 1.6),
                h1: TextStyle(color: accentColor, fontSize: 24, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: TdcColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                h3: const TextStyle(color: TdcColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                code: TextStyle(
                  color: accentColor,
                  backgroundColor: TdcColors.surfaceAlt,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                codeblockDecoration: BoxDecoration(
                  color: TdcColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TdcColors.border),
                ),
                blockquoteDecoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  border: Border(left: BorderSide(color: accentColor, width: 4)),
                ),
                blockquote: const TextStyle(color: TdcColors.textSecondary, fontStyle: FontStyle.italic),
                listBullet: const TextStyle(color: TdcColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
