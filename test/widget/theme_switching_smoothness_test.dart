import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/main.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/native/speed_stream_listener.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/core/theme/app_theme.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/navigation/widgets/modern_bottom_nav_bar.dart';

class MockThemeBridge extends NativeTrafficBridge {
  @override
  Future<bool> hasUsagePermission() async => true;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<bool> isServiceRunning() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late SharedPreferences prefs;
  late MockThemeBridge mockBridge;
  late PreferencesRepository prefsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      'theme_mode': 'light',
    });
    prefs = await SharedPreferences.getInstance();
    mockBridge = MockThemeBridge();
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: mockBridge);
  });

  group('Smooth Theme Switching Tests', () {
    testWidgets('AppTheme generates symmetric themes with systemOverlayStyle and chipTheme across all modes',
        (tester) async {
      final modes = [
        ThemeModePreference.light,
        ThemeModePreference.dark,
        ThemeModePreference.amoled,
        ThemeModePreference.auto,
      ];

      for (final mode in modes) {
        final theme = AppTheme.buildTheme(
          preference: mode,
          platformBrightness: Brightness.light,
        );

        expect(theme, isNotNull);
        expect(theme.useMaterial3, isTrue);
        expect(theme.appBarTheme.systemOverlayStyle, isNotNull,
            reason: 'Mode ${mode.name} must have systemOverlayStyle in appBarTheme');
        expect(theme.chipTheme.shape, isNotNull,
            reason: 'Mode ${mode.name} must have chipTheme with defined shape');
        expect(theme.cardTheme.shape, isNotNull,
            reason: 'Mode ${mode.name} must have cardTheme with defined shape');
      }

      // Check AMOLED specific attributes
      final amoledTheme = AppTheme.buildTheme(
        preference: ThemeModePreference.amoled,
        platformBrightness: Brightness.dark,
      );
      expect(amoledTheme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));
      expect(amoledTheme.brightness, equals(Brightness.dark));
      expect(amoledTheme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
          equals(Brightness.light));

      // Check Light specific attributes
      final lightTheme = AppTheme.buildTheme(
        preference: ThemeModePreference.light,
        platformBrightness: Brightness.light,
      );
      expect(lightTheme.brightness, equals(Brightness.light));
      expect(lightTheme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
          equals(Brightness.dark));
    });

    testWidgets('ByteMeterApp configures MaterialApp with 350ms duration and easeInOutCubic curve',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            preferencesRepositoryProvider.overrideWithValue(prefsRepo),
            nativeTrafficBridgeProvider.overrideWithValue(mockBridge),
            networkUsageRepositoryProvider.overrideWithValue(
              NetworkUsageRepository(bridge: mockBridge),
            ),
            speedStreamListenerProvider.overrideWithValue(
              SpeedStreamListener(mockStream: const Stream.empty()),
            ),
          ],
          child: const ByteMeterApp(),
        ),
      );

      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeAnimationDuration, equals(const Duration(milliseconds: 350)));
      expect(materialApp.themeAnimationCurve, equals(Curves.easeInOutCubic));
    });

    testWidgets('Theme transition interpolates smoothly mid-animation without errors',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            preferencesRepositoryProvider.overrideWithValue(prefsRepo),
            nativeTrafficBridgeProvider.overrideWithValue(mockBridge),
            networkUsageRepositoryProvider.overrideWithValue(
              NetworkUsageRepository(bridge: mockBridge),
            ),
            speedStreamListenerProvider.overrideWithValue(
              SpeedStreamListener(mockStream: const Stream.empty()),
            ),
          ],
          child: const ByteMeterApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify initial light theme
      final initialTheme = Theme.of(tester.element(find.byType(ModernBottomNavBar)));
      expect(initialTheme.brightness, equals(Brightness.light));

      // Switch to AMOLED theme
      await prefsRepo.setThemeMode(ThemeModePreference.amoled);
      await tester.pump(); // Frame 0: rebuild begins

      // Advance by 175ms (halfway through the 350ms animation)
      await tester.pump(const Duration(milliseconds: 175));

      // App should be running mid-interpolation without crash or error
      expect(find.byType(ModernBottomNavBar), findsOneWidget);

      // Finish animation
      await tester.pump(const Duration(milliseconds: 200));

      // Verify final AMOLED theme
      final finalTheme = Theme.of(tester.element(find.byType(ModernBottomNavBar)));
      expect(finalTheme.brightness, equals(Brightness.dark));
      expect(finalTheme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));
    });

    testWidgets('ModernBottomNavBar renders smoothly under both Light and AMOLED themes',
        (tester) async {
      Widget buildNavBar({required ThemeModePreference mode}) {
        final theme = AppTheme.buildTheme(
          preference: mode,
          platformBrightness: Brightness.light,
        );

        return ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            preferencesRepositoryProvider.overrideWithValue(prefsRepo),
          ],
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              bottomNavigationBar: ModernBottomNavBar(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        );
      }

      // Test Light
      await tester.pumpWidget(buildNavBar(mode: ThemeModePreference.light));
      await tester.pump();
      expect(find.byType(ModernBottomNavBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);

      // Test AMOLED
      await tester.pumpWidget(buildNavBar(mode: ThemeModePreference.amoled));
      await tester.pump();
      expect(find.byType(ModernBottomNavBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
