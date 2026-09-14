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
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    // Selectively watch only themeMode and onboarding status to avoid full-tree rebuilds
    // when unrelated preferences (such as speed units, notification styles, or metric bases) update.
    final themeMode = ref.watch(
      preferencesStreamProvider.select(
        (asyncPrefs) => asyncPrefs.valueOrNull?.themeMode ?? prefsRepo.current.themeMode,
      ),
    );
    final hasCompletedOnboarding = ref.watch(
      preferencesStreamProvider.select(
        (asyncPrefs) =>
            asyncPrefs.valueOrNull?.hasCompletedOnboarding ??
            prefsRepo.current.hasCompletedOnboarding,
      ),
    );
    final platformBrightness = MediaQuery.platformBrightnessOf(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? dynamicLight, ColorScheme? dynamicDark) {
        final themeData = AppTheme.buildTheme(
          preference: themeMode,
          platformBrightness: platformBrightness,
          dynamicLight: dynamicLight,
          dynamicDark: dynamicDark,
        );

        return MaterialApp(
          title: 'ByteMeter',
          debugShowCheckedModeBanner: false,
          theme: themeData,
          themeAnimationDuration: const Duration(milliseconds: 350),
          themeAnimationCurve: Curves.easeInOutCubic,
          home: hasCompletedOnboarding
              ? const AppScaffold()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
