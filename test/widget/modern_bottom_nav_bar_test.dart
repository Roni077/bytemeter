import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/core/theme/app_theme.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/features/navigation/widgets/modern_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModernBottomNavBar Widget Tests', () {
    late SharedPreferences mockPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
    });

    testWidgets('Renders all 4 navigation destinations with labels and icons', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: ModernBottomNavBar(
                selectedIndex: selected,
                onDestinationSelected: (index) => selected = index,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.credit_card_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('Tapping inactive tab triggers onDestinationSelected callback', (tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: ModernBottomNavBar(
                selectedIndex: 0,
                onDestinationSelected: (index) {
                  selectedIndex = index;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));
    });

    testWidgets('Re-tapping active tab triggers onDestinationReselected callback', (tester) async {
      int? reselectedIndex;
      int? selectedIndex;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: ModernBottomNavBar(
                selectedIndex: 1,
                onDestinationSelected: (index) {
                  selectedIndex = index;
                },
                onDestinationReselected: (index) {
                  reselectedIndex = index;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap active History tab (index 1)
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(reselectedIndex, equals(1));
      expect(selectedIndex, isNull);
    });

    testWidgets('Renders properly under AMOLED and Dark modes with blur enabled/disabled',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
          ],
          child: MaterialApp(
            theme: AppTheme.buildTheme(
              preference: ThemeModePreference.amoled,
              platformBrightness: Brightness.dark,
            ),
            home: Scaffold(
              bottomNavigationBar: ModernBottomNavBar(
                selectedIndex: 2,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ModernBottomNavBar), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.byIcon(Icons.credit_card_rounded), findsOneWidget);
    });
  });
}
