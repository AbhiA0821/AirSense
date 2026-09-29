import 'package:flutter/material.dart';

/// Professional 3D-Inspired Design System & Color Palette
/// Strict compliance with Environmental Intelligence System specifications
class AppTheme {
  // Background surfaces
  static const Color bgDark = Color(0xFF060A12);
  static const Color bgPrimary = Color(0xFF060A12);
  static const Color bgSecondary = Color(0xFF0A1020);
  static const Color bgCard = Color(0xFF101827);
  static const Color bgCardElevated = Color(0xFF151F32);
  static const Color bgCardHigh = Color(0xFF1B2940);
  static const Color bgCardSubtle = Color(0xFF0D1524);
  static const Color bgCardHover = Color(0xFF162236);

  // Borders & Dividers
  static const Color borderMedium = Color(0xFF26364D);
  static const Color borderColor = Color(0xFF26364D);
  static const Color borderSubtle = Color(0x3326364D);
  static const Color borderHighlight = Color(0x5522D3EE);

  // AI & Brand Accent Colors
  static const Color accentPrimary = Color(0xFF22D3EE);   // Cyan AI Primary
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentSecondary = Color(0xFF6366F1); // Indigo AI Secondary
  static const Color accentPurple = Color(0xFF6366F1);
  static const Color accentBlue = Color(0xFF38BDF8);      // Tech Blue

  // Environmental Severity Indicators
  static const Color accentSuccess = Color(0xFF10B981);   // Good AQI (0-50)
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color good = Color(0xFF10B981);

  static const Color accentWarning = Color(0xFFF59E0B);   // Moderate AQI (51-100)
  static const Color moderate = Color(0xFFF59E0B);

  static const Color accentCritical = Color(0xFFEF4444);  // Critical / Unhealthy (151+)
  static const Color critical = Color(0xFFEF4444);

  // Typography Palette
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // 3D Depth & Elevation Helpers
  static List<BoxShadow> get depthLow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: const Color(0xFF22D3EE).withValues(alpha: 0.03),
      blurRadius: 1,
      offset: const Offset(0, -1),
    ),
  ];

  static List<BoxShadow> get depthMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF22D3EE).withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, -1),
    ),
  ];

  static List<BoxShadow> get depthHigh => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.65),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
      blurRadius: 3,
      offset: const Offset(0, -1),
    ),
  ];

  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = 12.0,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? bgCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? borderMedium,
        width: borderWidth,
      ),
      boxShadow: shadows ?? depthLow,
    );
  }

  static BoxDecoration elevatedCardDecoration({
    Color? color,
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = 14.0,
  }) {
    return BoxDecoration(
      color: color ?? bgCardElevated,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? borderMedium,
        width: borderWidth,
      ),
      boxShadow: depthMedium,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: accentPrimary,
      cardColor: bgCard,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: bgCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: accentPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderMedium),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: const Color(0xFF060A12),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
