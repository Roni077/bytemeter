import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app_scaffold.dart';
import 'src/core/providers/core_providers.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ByteMeterApp(),
    ),
  );
}

/// Root application widget configuring Material You dynamic theme and reactive preferences.
class ByteMeterApp extends ConsumerWidget {
  const ByteMeterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch preferences stream so theme or unit changes immediately rebuild UI
    final prefsAsync = ref.watch(preferencesStreamProvider);
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final currentPrefs = prefsAsync.valueOrNull ?? prefsRepo.current;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? dynamicLight, ColorScheme? dynamicDark) {
        final themeData = AppTheme.buildTheme(
          preference: currentPrefs.themeMode,
          platformBrightness: platformBrightness,
          dynamicLight: dynamicLight,
          dynamicDark: dynamicDark,
        );

        return MaterialApp(
          title: 'ByteMeter',
          debugShowCheckedModeBanner: false,
          theme: themeData,
          home: currentPrefs.hasCompletedOnboarding
              ? const AppScaffold()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
