import 'package:flutter/material.dart';
import 'package:bytemeter/src/data/models/enums.dart';

/// Semantic color schemes and tonal palettes for ByteMeter.
class AppColorSchemes {
  const AppColorSchemes._();

  // Primary brand seed: Expressive Electric Blue / Cyan
  static const Color brandSeed = Color(0xFF0D6EFD);

  // Network Specific Semantic Colors
  static const Color cellularColor = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color cellularContainer = Color(0xFFDBEAFE);
  static const Color onCellularContainer = Color(0xFF1E40AF);

  static const Color wifiColor = Color(0xFF0D9488); // Teal Cyan
  static const Color wifiContainer = Color(0xFFCCFBF1);
  static const Color onWifiContainer = Color(0xFF115E59);

  static const Color uploadColor = Color(0xFF8B5CF6); // Expressive Violet
  static const Color downloadColor = Color(0xFF0284C7); // Sky Blue

  static const Color safeColor = Color(0xFF10B981); // Emerald Green
  static const Color neutralColor = Color(0xFFF59E0B); // Amber Yellow
  static const Color unsafeColor = Color(0xFFEF4444); // Crimson Red

  // AMOLED Pure Pitch Black Surface
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF000000);
  static const Color amoledSurfaceContainer = Color(0xFF121212);
  static const Color amoledSurfaceContainerHigh = Color(0xFF1E1E1E);

  /// Default M3 Light ColorScheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF005AC1),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD8E2FF),
    onPrimaryContainer: Color(0xFF001A41),
    secondary: Color(0xFF575E71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDBE2F9),
    onSecondaryContainer: Color(0xFF141B2C),
    tertiary: Color(0xFF006A60),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF73F8E7),
    onTertiaryContainer: Color(0xFF00201C),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFDFBFF),
    onSurface: Color(0xFF1A1B1F),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3F3FA),
    surfaceContainer: Color(0xFFEDEDF4),
    surfaceContainerHigh: Color(0xFFE7E8EE),
    surfaceContainerHighest: Color(0xFFE1E2E8),
    outline: Color(0xFF74777F),
    outlineVariant: Color(0xFFC4C6D0),
  );

  /// Default M3 Dark ColorScheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFADC6FF),
    onPrimary: Color(0xFF002E69),
    primaryContainer: Color(0xFF004494),
    onPrimaryContainer: Color(0xFFD8E2FF),
    secondary: Color(0xFFBFC6DC),
    onSecondary: Color(0xFF293041),
    secondaryContainer: Color(0xFF3F4759),
    onSecondaryContainer: Color(0xFFDBE2F9),
    tertiary: Color(0xFF53DBCB),
    onTertiary: Color(0xFF003731),
    tertiaryContainer: Color(0xFF005048),
    onTertiaryContainer: Color(0xFF73F8E7),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF121316),
    onSurface: Color(0xFFE3E2E6),
    surfaceContainerLowest: Color(0xFF0D0E11),
    surfaceContainerLow: Color(0xFF1A1F1F),
    surfaceContainer: Color(0xFF1E1F23),
    surfaceContainerHigh: Color(0xFF292A2D),
    surfaceContainerHighest: Color(0xFF333538),
    outline: Color(0xFF8E9099),
    outlineVariant: Color(0xFF44474F),
  );

  /// AMOLED Pure Pitch Black ColorScheme
  static const ColorScheme amoledColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFADC6FF),
    onPrimary: Color(0xFF002E69),
    primaryContainer: Color(0xFF102A50),
    onPrimaryContainer: Color(0xFFD8E2FF),
    secondary: Color(0xFFBFC6DC),
    onSecondary: Color(0xFF293041),
    secondaryContainer: Color(0xFF1C2230),
    onSecondaryContainer: Color(0xFFDBE2F9),
    tertiary: Color(0xFF53DBCB),
    onTertiary: Color(0xFF003731),
    tertiaryContainer: Color(0xFF0D332F),
    onTertiaryContainer: Color(0xFF73F8E7),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: amoledSurface,
    onSurface: Color(0xFFF0F0F0),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0A0A0A),
    surfaceContainer: Color(0xFF121212),
    surfaceContainerHigh: Color(0xFF1A1A1A),
    surfaceContainerHighest: Color(0xFF242424),
    outline: Color(0xFF60636C),
    outlineVariant: Color(0xFF303238),
  );

  /// Returns the accent color for a specific [NetworkType].
  static Color getNetworkColor(ColorScheme scheme, NetworkType type) {
    switch (type) {
      case NetworkType.mobile:
        return scheme.primary;
      case NetworkType.wifi:
        return scheme.tertiary;
    }
  }

  /// Returns the container background color for a specific [NetworkType].
  static Color getNetworkContainerColor(ColorScheme scheme, NetworkType type) {
    switch (type) {
      case NetworkType.mobile:
        return scheme.primaryContainer;
      case NetworkType.wifi:
        return scheme.tertiaryContainer;
    }
  }

  /// Returns the on-container text color for a specific [NetworkType].
  static Color getOnNetworkContainerColor(ColorScheme scheme, NetworkType type) {
    switch (type) {
      case NetworkType.mobile:
        return scheme.onPrimaryContainer;
      case NetworkType.wifi:
        return scheme.onTertiaryContainer;
    }
  }

  /// Returns the color for a [DataSafetyState].
  static Color getSafetyColor(DataSafetyState state) {
    switch (state) {
      case DataSafetyState.safe:
        return safeColor;
      case DataSafetyState.neutral:
        return neutralColor;
      case DataSafetyState.unsafe:
        return unsafeColor;
    }
  }
}
