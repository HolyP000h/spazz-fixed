import 'package:flutter/material.dart';

/// Spazz Design System
/// Comprehensive color palette, typography, and spacing constants
class SpazzTheme {
  // ✖ Background Colors
  static const Color bgPrimary = Color(0xFF0A0A0F);      // Main background
  static const Color bgSecondary = Color(0xFF13131A);    // Card/secondary background
  static const Color bgTertiary = Color(0xFF1E1E2E);     // Tertiary background

  // ✖ Primary Colors (Neon Purple & Cyan Gradient)
  static const Color accentPurple = Color(0xFF7C3AED);   // Primary accent
  static const Color accentCyan = Color(0xFF06B6D4);     // Secondary accent
  static const Color accentOrange = Color(0xFFFF6B35);   // Warning/Hunt state

  // ✖ Semantic Colors
  static const Color successGreen = Color(0xFF10B981);   // Success state
  static const Color warningYellow = Color(0xFFFCD34D); // Warning
  static const Color errorRed = Color(0xFFEF4444);       // Error state
  static const Color coldBlue = Color(0xFF3B82F6);       // Cold hunt state
  static const Color warmRed = Color(0xFFDC2626);        // Warm hunt state

  // ✖ Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF888899);  // Muted text
  static const Color textTertiary = Color(0xFF666680);   // Lighter muted

  // ✖ Border Colors
  static const Color borderDark = Color(0xFF2A2A3A);

  // ✖ Typography
  static const String fontFamily = 'Inter';

  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: 1.0,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: 2.0,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textTertiary,
  );

  // ✖ Spacing
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing10 = 10;
  static const double spacing12 = 12;
  static const double spacing14 = 14;
  static const double spacing16 = 16;
  static const double spacing18 = 18;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;

  // ✖ Border Radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXL = 20;
  static const double radiusRound = 999;

  // ✖ Component Heights
  static const double buttonHeight = 48;
  static const double inputHeight = 48;

  // ✖ Gradients
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [accentPurple, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientWarm = LinearGradient(
    colors: [accentOrange, warmRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientCold = LinearGradient(
    colors: [coldBlue, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✖ Shadows
  static const BoxShadow shadowSmall = BoxShadow(
    color: Colors.black26,
    offset: Offset(0, 2),
    blurRadius: 4,
  );

  static const BoxShadow shadowMedium = BoxShadow(
    color: Colors.black38,
    offset: Offset(0, 4),
    blurRadius: 8,
  );

  // ✖ Material Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgPrimary,
    primaryColor: accentPurple,
    colorScheme: const ColorScheme.dark(
      primary: accentPurple,
      secondary: accentCyan,
      surface: bgSecondary,
      error: errorRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgSecondary,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgTertiary,
      contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: accentPurple, width: 2),
      ),
      hintStyle: const TextStyle(color: textTertiary),
      labelStyle: const TextStyle(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPurple,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: borderDark),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentPurple,
      ),
    ),
  );
}
