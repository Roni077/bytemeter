import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typographic scales and high-expressive numeric styles.
class AppTypography {
  const AppTypography._();

  /// Primary body & heading text theme builder.
  static TextTheme createTextTheme([Brightness brightness = Brightness.light]) {
    final base = ThemeData(brightness: brightness).textTheme;
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Expressive huge integer portion for Hero gauge (e.g. "24").
  static TextStyle heroIntegerStyle(Color color, {double fontSize = 76}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.0,
      letterSpacing: -2.0,
    );
  }

  /// Expressive decimal portion for Hero gauge (e.g. ".45").
  static TextStyle heroDecimalStyle(Color color, {double fontSize = 32}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color.withValues(alpha: 0.85),
      height: 1.0,
      letterSpacing: -0.5,
    );
  }

  /// Expressive unit badge style for Hero gauge (e.g. "MB/s", "GB").
  static TextStyle heroUnitStyle(Color color, {double fontSize = 16}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 1.0,
    );
  }

  /// Compact numeric label for chart bars and legends.
  static TextStyle chartLabelStyle(Color color, {double fontSize = 11}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.2,
    );
  }
}
