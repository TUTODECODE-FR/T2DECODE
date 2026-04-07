import 'package:flutter/material.dart';

// ============================================================
// TUTO DECODE — THEME "NOIR & BEIGE" (TUTODECODE.ORG)
// ============================================================

abstract class TdcColors {
  // FONDS — Noir profond
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF000000);
  static const surfaceAlt = Color(0xFF0A0A0A);
  static const surfaceHover = Color(0xFF111111);
  static const surfaceElevated = Color(0xFF0F0F0F);

  // ACCENT PRINCIPAL — Beige TutoDeCode
  static const accent = Color(0xFFF5EBDA);
  static const accentDim = Color(0x1AF5EBDA);
  static const accentGlow = Color(0x0FF5EBDA);
  static const accentBright = Color(0xFFF8F0E3);

  // ACCENTS SECONDAIRES (neutres, sobres)
  static const coral = Color(0xFFD7CDBF);
  static const coralDim = Color(0x1AD7CDBF);
  static const electric = Color(0xFFCFC5B6);
  static const electricDim = Color(0x1ACFC5B6);
  static const cosmos = Color(0xFFBDB4A7);
  static const cosmosDim = Color(0x1ABDB4A7);

  // STATUTS (mutés)
  static const success = Color(0xFFBFD6B3);
  static const successDim = Color(0x1ABFD6B3);
  static const warning = Color(0xFFE0C79C);
  static const warningDim = Color(0x1AE0C79C);
  static const danger = Color(0xFFE0AFA6);
  static const dangerDim = Color(0x1AE0AFA6);
  static const info = Color(0xFFB9C8D9);
  static const infoDim = Color(0x1AB9C8D9);

  // CATÉGORIES SPÉCIALISÉES
  static const network = Color(0xFFCFC5B6);
  static const networkDim = Color(0x1ACFC5B6);
  static const security = Color(0xFFBDB4A7);
  static const securityDim = Color(0x1ABDB4A7);
  static const system = Color(0xFFD7CDBF);
  static const systemDim = Color(0x1AD7CDBF);
  static const cloud = Color(0xFFCBC1B2);
  static const cloudDim = Color(0x1ACBC1B2);
  static const crypto = Color(0xFFE0C79C);
  static const cryptoDim = Color(0x1AE0C79C);

  // NIVEAUX
  static const levelBeginner = Color(0xFFD7CDBF);
  static const levelIntermediate = Color(0xFFCFC5B6);
  static const levelAdvanced = Color(0xFFE0C79C);
  static const levelExpert = Color(0xFFE0AFA6);

  // BORDURES
  static const border = Color(0xFF1A1A1A);
  static const borderSubtle = Color(0xFF141414);
  static const borderAccent = Color(0xFF2A2A2A);
  static const borderFocus = Color(0xFF2E2E2E);

  // TEXTE
  static const textPrimary = Color(0xFFF5EBDA);
  static const textSecondary = Color(0xFFD7CDBF);
  static const textTertiary = Color(0xFFB1A89E);
  static const textMuted = Color(0xFF88827A);
  static const textAccent = Color(0xFFF5EBDA);
}

abstract class TdcLightColors {
  // Thème "clair" aligné sur l'identité noir & beige.
  static const bg = TdcColors.bg;
  static const surface = TdcColors.surface;
  static const surfaceAlt = TdcColors.surfaceAlt;
  static const surfaceHover = TdcColors.surfaceHover;
  static const surfaceElevated = TdcColors.surfaceElevated;

  static const accent = TdcColors.accent;
  static const accentDim = TdcColors.accentDim;
  static const accentGlow = TdcColors.accentGlow;
  static const accentBright = TdcColors.accentBright;

  static const coral = TdcColors.coral;
  static const coralDim = TdcColors.coralDim;
  static const electric = TdcColors.electric;
  static const electricDim = TdcColors.electricDim;
  static const cosmos = TdcColors.cosmos;
  static const cosmosDim = TdcColors.cosmosDim;

  static const success = TdcColors.success;
  static const successDim = TdcColors.successDim;
  static const warning = TdcColors.warning;
  static const warningDim = TdcColors.warningDim;
  static const danger = TdcColors.danger;
  static const dangerDim = TdcColors.dangerDim;
  static const info = TdcColors.info;
  static const infoDim = TdcColors.infoDim;

  static const network = TdcColors.network;
  static const networkDim = TdcColors.networkDim;
  static const security = TdcColors.security;
  static const securityDim = TdcColors.securityDim;
  static const system = TdcColors.system;
  static const systemDim = TdcColors.systemDim;
  static const cloud = TdcColors.cloud;
  static const cloudDim = TdcColors.cloudDim;
  static const crypto = TdcColors.crypto;
  static const cryptoDim = TdcColors.cryptoDim;

  static const levelBeginner = TdcColors.levelBeginner;
  static const levelIntermediate = TdcColors.levelIntermediate;
  static const levelAdvanced = TdcColors.levelAdvanced;
  static const levelExpert = TdcColors.levelExpert;

  static const border = TdcColors.border;
  static const borderSubtle = TdcColors.borderSubtle;
  static const borderAccent = TdcColors.borderAccent;
  static const borderFocus = TdcColors.borderFocus;

  static const textPrimary = TdcColors.textPrimary;
  static const textSecondary = TdcColors.textSecondary;
  static const textTertiary = TdcColors.textTertiary;
  static const textMuted = TdcColors.textMuted;
  static const textAccent = TdcColors.textAccent;
}

abstract class TdcSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract class TdcRadius {
  static const sm = BorderRadius.zero;
  static const md = BorderRadius.zero;
  static const lg = BorderRadius.zero;
  static const xl = BorderRadius.zero;
}

const double kDesktopContentMaxWidth = 1100.0;
const double kPanelMaxWidth = 920.0;

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
  final textTheme = base.textTheme;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Aileron',
    scaffoldBackgroundColor: TdcColors.bg,
    primaryColor: TdcColors.accent,
    textTheme: textTheme.copyWith(
      displayLarge: textTheme.displayLarge
          ?.copyWith(color: TdcColors.textPrimary, fontWeight: FontWeight.bold),
      titleLarge: textTheme.titleLarge?.copyWith(
          color: TdcColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold),
      titleMedium: textTheme.titleMedium?.copyWith(
          color: TdcColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600),
      bodyLarge: textTheme.bodyLarge
          ?.copyWith(color: TdcColors.textPrimary, fontSize: 15),
      bodyMedium: textTheme.bodyMedium
          ?.copyWith(color: TdcColors.textSecondary, fontSize: 14),
      bodySmall: textTheme.bodySmall
          ?.copyWith(color: TdcColors.textMuted, fontSize: 12),
      labelSmall: textTheme.labelSmall?.copyWith(
          color: TdcColors.textMuted, fontSize: 11, letterSpacing: 1.2),
    ),
    colorScheme: const ColorScheme.dark(
      primary: TdcColors.accent,
      secondary: TdcColors.coral,
      surface: TdcColors.surface,
      error: TdcColors.danger,
      onPrimary: Color(0xFF000000),
      onSurface: TdcColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: TdcColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: TdcRadius.sm,
        side: BorderSide(color: TdcColors.border),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TdcColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: TdcColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
      ),
      iconTheme: IconThemeData(color: TdcColors.textSecondary),
    ),
    dividerTheme: const DividerThemeData(
      color: TdcColors.border,
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: TdcRadius.sm,
        border: Border.all(color: TdcColors.border),
      ),
      textStyle: const TextStyle(color: TdcColors.textSecondary, fontSize: 12),
      waitDuration: const Duration(milliseconds: 500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TdcColors.accent,
        foregroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: TdcRadius.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: TdcSpacing.xl, vertical: TdcSpacing.md),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TdcColors.textPrimary,
        side: const BorderSide(color: TdcColors.border),
        shape: const RoundedRectangleBorder(borderRadius: TdcRadius.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: TdcSpacing.lg, vertical: TdcSpacing.md),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 1.1,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TdcColors.textMuted,
      ),
    ),
    iconTheme: const IconThemeData(color: TdcColors.textMuted, size: 20),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TdcColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: TdcSpacing.md, vertical: TdcSpacing.sm + 2),
      border: OutlineInputBorder(
        borderRadius: TdcRadius.md,
        borderSide: const BorderSide(color: TdcColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: TdcRadius.md,
        borderSide: const BorderSide(color: TdcColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: TdcRadius.md,
        borderSide: const BorderSide(color: TdcColors.accent, width: 2),
      ),
      hintStyle: const TextStyle(color: TdcColors.textMuted),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(TdcColors.borderFocus),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      radius: const Radius.circular(4),
      thickness: WidgetStateProperty.all(5),
      thumbVisibility: WidgetStateProperty.all(true),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: TdcColors.textPrimary,
      iconColor: TdcColors.textSecondary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: TdcColors.bg,
      labelStyle: const TextStyle(color: TdcColors.textSecondary, fontSize: 12),
      side: const BorderSide(color: TdcColors.border),
      shape: const RoundedRectangleBorder(borderRadius: TdcRadius.sm),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return TdcColors.accent;
        return TdcColors.surfaceElevated;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return TdcColors.accentDim;
        return TdcColors.surfaceAlt;
      }),
      trackOutlineColor: WidgetStateProperty.all(TdcColors.border),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TdcColors.accent,
      linearTrackColor: TdcColors.surfaceElevated,
    ),
  );
}

ThemeData buildAppLightTheme() {
  return buildAppTheme();
}
