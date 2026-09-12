import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/main.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/features/home/home_screen.dart';
import 'package:bytemeter/src/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('ByteMeterApp displays OnboardingScreen on fresh install', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ByteMeterApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to ByteMeter'), findsOneWidget);
  });

  testWidgets('ByteMeterApp displays HomeScreen when onboarding is completed', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ByteMeterApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
