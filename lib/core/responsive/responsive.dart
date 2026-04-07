// ============================================================
// responsive.dart — Utilitaires de responsive design TutoDeCode
// Breakpoints : mobile < 600 | tablet 600–1024 | desktop > 1024
// ============================================================

import 'package:flutter/material.dart';

/// Points de rupture unifiés de l'application.
abstract class TdcBreakpoints {
  static const double mobile  = 600;
  static const double tablet  = 1024;

  static bool isMobile(BuildContext ctx)  => MediaQuery.of(ctx).size.width < mobile;
  static bool isTablet(BuildContext ctx)  => MediaQuery.of(ctx).size.width >= mobile && MediaQuery.of(ctx).size.width < tablet;
  static bool isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= tablet;
}

/// Widget utilitaire qui construit un layout différent selon la taille d'écran.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= TdcBreakpoints.tablet) return desktop;
    if (w >= TdcBreakpoints.mobile) return tablet ?? desktop;
    return mobile;
  }
}

/// Builder fonctionnel avec accès au type d'écran.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType type) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final type = w >= TdcBreakpoints.tablet
        ? ScreenType.desktop
        : w >= TdcBreakpoints.mobile
            ? ScreenType.tablet
            : ScreenType.mobile;
    return builder(context, type);
  }
}

enum ScreenType { mobile, tablet, desktop }

extension ScreenTypeExt on ScreenType {
  bool get isMobile  => this == ScreenType.mobile;
  bool get isTablet  => this == ScreenType.tablet;
  bool get isDesktop => this == ScreenType.desktop;
  bool get isSmall   => this == ScreenType.mobile || this == ScreenType.tablet;
}

/// Helper pour les tailles de texte adaptatives.
abstract class TdcText {
  static double scale(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    if (w >= TdcBreakpoints.tablet) return base; // Desktop : taille normale
    if (w >= TdcBreakpoints.mobile) return base * 0.95; // Tablette : legère reduction
    return base * 0.85; // Mobile : reduction plus forte
  }

  static double h1(BuildContext ctx) => scale(ctx, 28);
  static double h2(BuildContext ctx) => scale(ctx, 22);
  static double h3(BuildContext ctx) => scale(ctx, 18);
  static double bodyLarge(BuildContext ctx) => scale(ctx, 16);
  static double body(BuildContext ctx) => scale(ctx, 14);
  static double bodySmall(BuildContext ctx) => scale(ctx, 12);
  static double caption(BuildContext ctx) => scale(ctx, 11);
  static double label(BuildContext ctx) => scale(ctx, 10);
  
  // Tailles fixes pour éléments UI spécifiques
  static double button(BuildContext ctx) => scale(ctx, 14);
}

/// Helper pour les espacements et dimensions adaptatives.
abstract class TdcAdaptive {
  static double space(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    if (w >= TdcBreakpoints.tablet) return base;
    if (w >= TdcBreakpoints.mobile) return base * 0.8;
    return base * 0.65;
  }

  static double icon(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    if (w >= TdcBreakpoints.tablet) return base;
    if (w >= TdcBreakpoints.mobile) return base * 0.9;
    return base * 0.85;
  }

  static double padding(BuildContext ctx, double base) => space(ctx, base);
  
  static double radius(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    if (w >= TdcBreakpoints.tablet) return base;
    return base * 0.9;
  }
}
