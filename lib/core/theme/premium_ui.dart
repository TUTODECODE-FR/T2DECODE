import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';

/// Composants d'interface "Ultra-Premium" pour décourager les clones basiques.
class TdcPremium {
  
  /// Une carte avec effet de verre (Glassmorphism) et bordure lumineuse.
  static Widget glassCard({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return GlassContainer(
      height: height,
      width: width,
      gradient: LinearGradient(
        colors: [
          TdcColors.surface.withOpacity(0.7),
          TdcColors.surfaceAlt.withOpacity(0.4),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: LinearGradient(
        colors: [
          TdcColors.accent.withOpacity(0.5),
          TdcColors.border.withOpacity(0.1),
          TdcColors.info.withOpacity(0.3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      blur: 15,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      borderWidth: 1.5,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98), curve: Curves.easeOutCubic);
  }

  /// Fond de page avec particules ou dégradés animés.
  static Widget animatedBackground({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: TdcColors.bg),
        ),
        // Orbe lumineux animé 1
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TdcColors.accent.withOpacity(0.05),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
            .move(begin: const Offset(-20, -20), end: const Offset(20, 20), duration: 5.seconds, curve: Curves.easeInOut),
        ),
        // Orbe lumineux animé 2
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TdcColors.info.withOpacity(0.03),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
            .move(begin: const Offset(30, 30), end: const Offset(-30, -30), duration: 7.seconds, curve: Curves.easeInOut),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  /// Titre de section avec effet de dégradé et micro-animation.
  static Widget sectionTitle(BuildContext context, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: TdcColors.accent)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.3)),
        const SizedBox(width: 12),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: [TdcColors.textPrimary, TdcColors.accent],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).moveX(begin: -10);
  }
}
