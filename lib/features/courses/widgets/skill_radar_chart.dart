// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class SkillRadarChart extends StatelessWidget {
  final Map<String, double> data;
  final double radius;
  final Color color;

  const SkillRadarChart({
    super.key,
    required this.data,
    this.radius = 100,
    this.color = TdcColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: radius * 2.5,
      height: radius * 2.5,
      child: CustomPaint(
        painter: _RadarPainter(
          data: data,
          radius: radius,
          color: color,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> data;
  final double radius;
  final Color color;

  _RadarPainter({
    required this.data,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final int sides = data.length;
    final double angle = (2 * pi) / sides;
    
    final Paint gridPaint = Paint()
      ..color = TdcColors.border.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw grid (concentric polygons)
    for (int step = 1; step <= 5; step++) {
      final double r = radius * (step / 5);
      final Path path = Path();
      for (int i = 0; i < sides; i++) {
        final double x = center.dx + r * cos(i * angle - pi / 2);
        final double y = center.dy + r * sin(i * angle - pi / 2);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (int i = 0; i < sides; i++) {
      final double x = center.dx + radius * cos(i * angle - pi / 2);
      final double y = center.dy + radius * sin(i * angle - pi / 2);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Draw data polygon
    final Path dataPath = Path();
    final List<Offset> points = [];
    int i = 0;
    data.forEach((key, value) {
      final double r = radius * value.clamp(0.0, 1.0);
      final double x = center.dx + r * cos(i * angle - pi / 2);
      final double y = center.dy + r * sin(i * angle - pi / 2);
      points.add(Offset(x, y));
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
      i++;
    });
    dataPath.close();

    final Paint fillPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Draw points
    final Paint pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    for (final point in points) {
      canvas.drawCircle(point, 4.0, pointPaint);
    }

    // Draw labels
    i = 0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    data.forEach((key, value) {
      final double labelR = radius + 20; // offset for text
      final double x = center.dx + labelR * cos(i * angle - pi / 2);
      final double y = center.dy + labelR * sin(i * angle - pi / 2);
      
      textPainter.text = TextSpan(
        text: key,
        style: const TextStyle(
          color: TdcColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      
      final Offset textOffset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
      i++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
