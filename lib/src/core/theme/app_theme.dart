import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'app_dimens.dart';
import 'color_schemes.dart';
import 'typography.dart';

/// AppTheme builder supporting Material You DynamicColor, Light, Dark, and AMOLED modes.
class AppTheme {
  const AppTheme._();

  /// Builds a [ThemeData] instance according to the user's [preference] and optional [dynamicLight]/[dynamicDark] schemes.
  static ThemeData buildTheme({
    required ThemeModePreference preference,
    required Brightness platformBrightness,
    ColorScheme? dynamicLight,
    ColorScheme? dynamicDark,
  }) {
    switch (preference) {
      case ThemeModePreference.light:
        return _createTheme(dynamicLight ?? AppColorSchemes.lightColorScheme, Brightness.light);
      case ThemeModePreference.dark:
        return _createTheme(dynamicDark ?? AppColorSchemes.darkColorScheme, Brightness.dark);
      case ThemeModePreference.amoled:
        return _createAmoledTheme(dynamicDark);
      case ThemeModePreference.auto:
        final isDark = platformBrightness == Brightness.dark;
        final scheme = isDark
            ? (dynamicDark ?? AppColorSchemes.darkColorScheme)
            : (dynamicLight ?? AppColorSchemes.lightColorScheme);
        return _createTheme(scheme, isDark ? Brightness.dark : Brightness.light);
    }
  }

  static ThemeData _createTheme(ColorScheme colorScheme, Brightness brightness) {
    final textTheme = AppTypography.createTextTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: brightness,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusLg,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusMd,
        ),
      ),
    );
  }

  static ThemeData _createAmoledTheme(ColorScheme? dynamicDark) {
    final baseDark = dynamicDark ?? AppColorSchemes.darkColorScheme;
    final amoledScheme = AppColorSchemes.amoledColorScheme.copyWith(
      primary: baseDark.primary,
      onPrimary: baseDark.onPrimary,
      primaryContainer: baseDark.primaryContainer.withValues(alpha: 0.6),
      onPrimaryContainer: baseDark.onPrimaryContainer,
      secondary: baseDark.secondary,
      tertiary: baseDark.tertiary,
      surface: AppColorSchemes.amoledSurface,
      onSurface: AppColorSchemes.amoledColorScheme.onSurface,
      surfaceContainerLowest: AppColorSchemes.amoledColorScheme.surfaceContainerLowest,
      surfaceContainerLow: AppColorSchemes.amoledColorScheme.surfaceContainerLow,
      surfaceContainer: AppColorSchemes.amoledColorScheme.surfaceContainer,
      surfaceContainerHigh: AppColorSchemes.amoledColorScheme.surfaceContainerHigh,
      surfaceContainerHighest: AppColorSchemes.amoledColorScheme.surfaceContainerHighest,
    );

    final textTheme = AppTypography.createTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: amoledScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: amoledScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: amoledScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: amoledScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusLg,
          side: BorderSide(
            color: amoledScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusMd,
        ),
      ),
    );
  }
}
