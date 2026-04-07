// ============================================================
// tdc_widgets.dart — Composants UI réutilisables TutoDeCode
// Hover, animations, motion
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'tdc_motion.dart';

// ─────────────────────────────────────────────────────────────
// TdcCard — Carte avec hover, scale au clic, ombre dynamique
// ─────────────────────────────────────────────────────────────
class TdcCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool showHoverBorder;
  final double borderRadius;

  const TdcCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.showHoverBorder = true,
    this.borderRadius = 0,
  });

  @override
  State<TdcCard> createState() => _TdcCardState();
}

class _TdcCardState extends State<TdcCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            offset: Offset(0, _hovered && widget.onTap != null ? -0.02 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: widget.padding ?? const EdgeInsets.all(TdcSpacing.lg),
              decoration: BoxDecoration(
                color: _hovered && widget.onTap != null
                    ? TdcColors.surfaceAlt
                    : TdcColors.bg,
                borderRadius:
                    BorderRadius.all(Radius.circular(widget.borderRadius)),
                border: Border.all(
                  color:
                      _hovered && widget.showHoverBorder && widget.onTap != null
                          ? TdcColors.borderAccent
                          : TdcColors.border,
                  width: 1,
                ),
                boxShadow: const [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TdcSectionTitle — Titre de section avec pastille animée
// ─────────────────────────────────────────────────────────────
class TdcSectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final double? fontSize;

  const TdcSectionTitle(this.text, {super.key, this.trailing, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              color: TdcColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: fontSize ?? 11,
              letterSpacing: 2.6,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TdcStatusBadge — Badge de statut coloré
// ─────────────────────────────────────────────────────────────
class TdcStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const TdcStatusBadge(
      {super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: TdcRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TdcInfoRow — Ligne label/valeur uniformisée
// ─────────────────────────────────────────────────────────────
class TdcInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool copyable;

  const TdcInfoRow(
      {super.key,
      required this.label,
      required this.value,
      this.icon,
      this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: TdcColors.textMuted),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: Text(label,
                style:
                    const TextStyle(color: TdcColors.textMuted, fontSize: 13)),
          ),
          Flexible(
            flex: 3,
            child: MouseRegion(
              cursor: copyable ? SystemMouseCursors.click : MouseCursor.defer,
              child: GestureDetector(
                onTap: copyable ? () {} : null,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TdcFadeSlide — Entrée fade + slide + léger scale
// ─────────────────────────────────────────────────────────────
class TdcFadeSlide extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final double offsetY;

  const TdcFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 20,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
        .slideY(
            begin: offsetY / 100,
            end: 0,
            duration: 380.ms,
            curve: Curves.easeOutCubic)
        .scale(
            begin: const Offset(0.96, 0.96),
            duration: 400.ms,
            curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────
// TdcEmptyState — État vide standardisé
// ─────────────────────────────────────────────────────────────
class TdcEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const TdcEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: TdcColors.textMuted),
          ).tdcFloatY(amount: 4, period: 3500.ms),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style:
                    const TextStyle(color: TdcColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TdcPageWrapper — Largeur max + fond animé
// ─────────────────────────────────────────────────────────────
class TdcPageWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const TdcPageWrapper({
    super.key,
    required this.child,
    this.maxWidth = kDesktopContentMaxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return TdcAnimatedPageScrim(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(TdcSpacing.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TdcKeyboardShortcut — Tag raccourci clavier
// ─────────────────────────────────────────────────────────────
class TdcKeyboardShortcut extends StatelessWidget {
  final String keys;
  const TdcKeyboardShortcut(this.keys, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: TdcRadius.sm,
        border: Border.all(color: TdcColors.border),
      ),
      child: Text(keys,
          style: const TextStyle(
              color: TdcColors.textMuted,
              fontSize: 10,
              fontFamily: 'monospace')),
    );
  }
}
