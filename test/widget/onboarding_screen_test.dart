import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/features/onboarding/onboarding_screen.dart';
import 'package:bytemeter/src/features/onboarding/widgets/permission_card.dart';

class MockOnboardingBridge extends NativeTrafficBridge {
  bool usageGranted = false;
  bool notifGranted = false;
  bool batteryIgnored = false;
  bool phoneGranted = false;
  bool serviceStarted = false;

  @override
  Future<bool> hasUsagePermission() async => usageGranted;

  @override
  Future<bool> requestUsagePermission() async {
    usageGranted = true;
    return true;
  }

  @override
  Future<bool> hasNotificationPermission() async => notifGranted;

  @override
  Future<bool> requestNotificationPermission() async {
    notifGranted = true;
    return true;
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => batteryIgnored;

  @override
  Future<bool> requestIgnoreBatteryOptimizations() async {
    batteryIgnored = true;
    return true;
  }

  @override
  Future<bool> hasPhonePermission() async => phoneGranted;

  @override
  Future<bool> requestPhonePermission() async {
    phoneGranted = true;
    return true;
  }

  @override
  Future<bool> startForegroundService() async {
    serviceStarted = true;
    return true;
  }

  @override
  Future<bool> isServiceRunning() async => serviceStarted;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MockOnboardingBridge bridge;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bridge = MockOnboardingBridge();
  });

  Widget createTestWidget({bool isReplay = false}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nativeTrafficBridgeProvider.overrideWithValue(bridge),
      ],
      child: MaterialApp(
        home: OnboardingScreen(isReplay: isReplay),
      ),
    );
  }

  group('OnboardingScreen Widget Tests', () {
    testWidgets('Renders Welcome step with 4 pillars and Get Started button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ByteMeter'), findsOneWidget);
      expect(find.text('Sub-Second Speed Meter'), findsOneWidget);
      expect(find.text('Per-App Traffic Breakdown'), findsOneWidget);
      expect(find.text('Multi-SIM Quota Safety'), findsOneWidget);
      expect(find.text('100% Offline & Private'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Advances through wizard steps via Continue button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Get Started -> Step 2: Permissions
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Required Permissions'), findsOneWidget);
      expect(find.byType(PermissionCard), findsNWidgets(4));
      expect(find.text('Usage Access (Essential)'), findsOneWidget);

      // Tap Grant Access on Usage Access
      final grantButton = find.widgetWithText(FilledButton, 'Grant Access').first;
      await tester.tap(grantButton);
      await tester.pumpAndSettle();

      // Tap Continue -> Step 3: Quick Preferences
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Preferences'), findsOneWidget);
      expect(find.text('SPEED UNIT DISPLAY'), findsOneWidget);
      expect(find.text('METRIC UNIT BASE'), findsOneWidget);
      expect(find.text('Persistent Speed Meter'), findsOneWidget);

      // Tap Continue -> Step 4: Ready
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('You\'re Ready to Go!'), findsOneWidget);
      expect(find.text('Start Using ByteMeter'), findsOneWidget);
    });

    testWidgets('Skip button navigates directly to final launch step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('You\'re Ready to Go!'), findsOneWidget);
      expect(find.text('Start Using ByteMeter'), findsOneWidget);
    });

    testWidgets('Tapping launch button completes onboarding and saves preference', (tester) async {
      await tester.pumpWidget(createTestWidget(isReplay: true));
      await tester.pumpAndSettle();

      // Skip to end
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Tap launch
      await tester.tap(find.text('Start Using ByteMeter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(prefs.getBool('has_completed_onboarding'), isTrue);
    });
  });
}
