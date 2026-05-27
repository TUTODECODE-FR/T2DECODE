// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class LabGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderRadius;

  const LabGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          width: 1,
          color: borderColor ?? TdcColors.border.withValues(alpha: 0.5),
        ),
        color: TdcColors.surfaceAlt.withValues(alpha: 0.3),
      ),
      child: child,
    );
  }
}

class LabNotice extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? color;

  const LabNotice({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? TdcColors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(),
                    style: TextStyle(
                        color: tint,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(
                        color: TdcColors.textSecondary,
                        fontSize: 12,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LabMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const LabMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: TdcColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class LabTerminal extends StatelessWidget {
  final List<String> logs;
  final String title;

  const LabTerminal({
    super.key,
    required this.logs,
    this.title = 'CONSOLE SORTIE',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TdcColors.bg,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              border: const Border(bottom: BorderSide(color: TdcColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: TdcColors.accent, size: 14),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: TdcColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildDot(TdcColors.dangerDim),
                    const SizedBox(width: 4),
                    _buildDot(TdcColors.warningDim),
                    const SizedBox(width: 4),
                    _buildDot(TdcColors.successDim),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1} ',
                        style: TextStyle(
                          color: TdcColors.textMuted.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Text(
                        '> ',
                        style: TextStyle(
                          color: TdcColors.accent,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          logs[index],
                          style: const TextStyle(
                            color: TdcColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: TdcColors.border),
        shape: BoxShape.circle,
      ),
    );
  }
}
