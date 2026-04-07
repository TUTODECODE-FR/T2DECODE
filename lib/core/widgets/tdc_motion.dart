// ============================================================
// tdc_motion.dart — Fond animé, bordures dégradé, halos, motion
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Fond de page avec dégradé qui respire lentement.
class TdcAnimatedPageScrim extends StatefulWidget {
  final Widget child;

  const TdcAnimatedPageScrim({super.key, required this.child});

  @override
  State<TdcAnimatedPageScrim> createState() => _TdcAnimatedPageScrimState();
}

class _TdcAnimatedPageScrimState extends State<TdcAnimatedPageScrim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 22))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          color: TdcColors.bg,
          child: widget.child,
        );
      },
    );
  }
}

/// Contour dégradé animé (rotation douce, effet type CSS conic).
class TdcAnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double stroke;

  const TdcAnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.stroke = 1.5,
  });

  @override
  State<TdcAnimatedGradientBorder> createState() =>
      _TdcAnimatedGradientBorderState();
}

class _TdcAnimatedGradientBorderState extends State<TdcAnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        var h = constraints.maxHeight;
        if (!h.isFinite || h <= 0) {
          h = constraints.minHeight.isFinite && constraints.minHeight > 0
              ? constraints.minHeight
              : 120.0;
        }
        if (w <= 0) return widget.child;
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -w * 0.35,
                top: -h * 0.35,
                width: w * 1.7,
                height: h * 1.7,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _ctrl.value * math.pi * 2,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              TdcColors.border,
                              TdcColors.accent,
                              TdcColors.border,
                              TdcColors.accent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(widget.stroke),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        widget.borderRadius - widget.stroke),
                    child: ColoredBox(
                      color: TdcColors.surface,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Halo doux derrière un bloc (spotlight).
class TdcSoftGlow extends StatelessWidget {
  final Widget child;
  final Color color;
  final double blur;

  const TdcSoftGlow({
    super.key,
    required this.child,
    this.color = TdcColors.accent,
    this.blur = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: -4,
          right: -4,
          top: 0,
          bottom: -12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.12), blurRadius: blur)
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

extension TdcMotionExt on Widget {
  /// Légère pulsation (logo, picto).
  Widget tdcBreath({Duration period = const Duration(milliseconds: 2600)}) {
    return animate(onPlay: (c) => c.repeat(reverse: true)).scale(
      duration: period,
      begin: const Offset(1, 1),
      end: const Offset(1.028, 1.028),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Oscillation verticale très douce.
  Widget tdcFloatY(
      {double amount = 5,
      Duration period = const Duration(milliseconds: 4000)}) {
    return animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
      duration: period,
      begin: -amount,
      end: amount,
      curve: Curves.easeInOutSine,
    );
  }
}
