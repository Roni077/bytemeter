import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/features/onboarding/onboarding_screen.dart';

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

    testWidgets('Advances through wizard steps via Continue button across dedicated permission screens', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 0: Welcome -> Tap Get Started -> Step 1: Usage Access
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Network Usage Access'), findsOneWidget);
      expect(find.text('Grant Usage Access'), findsOneWidget);

      // Tap Grant Access on Usage Access
      final grantUsageButton = find.widgetWithText(FilledButton, 'Grant Usage Access');
      await tester.ensureVisible(grantUsageButton);
      await tester.tap(grantUsageButton);
      await tester.pumpAndSettle();
      expect(bridge.usageGranted, isTrue);

      // Step 1 -> Tap Continue -> Step 2: Notifications
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Live Speed Notification'), findsOneWidget);
      expect(find.text('Allow Notifications'), findsOneWidget);

      // Tap Allow Notifications
      final allowNotifButton = find.widgetWithText(FilledButton, 'Allow Notifications');
      await tester.ensureVisible(allowNotifButton);
      await tester.tap(allowNotifButton);
      await tester.pumpAndSettle();
      expect(bridge.notifGranted, isTrue);

      // Step 2 -> Tap Continue -> Step 3: Battery Optimization
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Uninterrupted Speed Meter'), findsOneWidget);
      expect(find.text('Disable Restrictions'), findsOneWidget);

      // Tap Disable Restrictions
      final exemptButton = find.widgetWithText(FilledButton, 'Disable Restrictions');
      await tester.ensureVisible(exemptButton);
      await tester.tap(exemptButton);
      await tester.pumpAndSettle();
      expect(bridge.batteryIgnored, isTrue);

      // Step 3 -> Tap Continue -> Step 4: Phone State (Multi-SIM)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Multi-SIM Quota Tracking'), findsOneWidget);
      expect(find.text('Enable Multi-SIM Tracking'), findsOneWidget);

      // Tap Enable Multi-SIM Tracking
      final simButton = find.widgetWithText(FilledButton, 'Enable Multi-SIM Tracking');
      await tester.ensureVisible(simButton);
      await tester.tap(simButton);
      await tester.pumpAndSettle();
      expect(bridge.phoneGranted, isTrue);

      // Step 4 -> Tap Continue -> Step 5: Quick Preferences
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Preferences'), findsOneWidget);
      expect(find.text('SPEED UNIT DISPLAY'), findsOneWidget);
      expect(find.text('Bits per second'), findsOneWidget);
      expect(find.text('Bytes per second'), findsOneWidget);
      expect(find.text('METRIC UNIT BASE'), findsOneWidget);
      expect(find.text('Persistent Speed Meter'), findsOneWidget);

      // Step 5 -> Tap Continue -> Step 6: Ready
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('You\'re Ready to Go!'), findsOneWidget);
      expect(find.text('Start Using ByteMeter'), findsOneWidget);
    });

    testWidgets('In-page skip allows advancing past optional steps', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to Step 1 (Usage)
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Go to Step 2 (Notification)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Go to Step 3 (Battery Optimization)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Uninterrupted Speed Meter'), findsOneWidget);

      // Tap "Keep Default Restrictions" -> advances to Step 4 (Phone State)
      final keepDefaultBtn = find.text('Keep Default Restrictions');
      await tester.ensureVisible(keepDefaultBtn);
      await tester.tap(keepDefaultBtn);
      await tester.pumpAndSettle();
      expect(find.text('Multi-SIM Quota Tracking'), findsOneWidget);

      // Tap "Skip (Single SIM / Wi-Fi Only)" -> advances to Step 5 (Quick Preferences)
      final skipSimBtn = find.text('Skip (Single SIM / Wi-Fi Only)');
      await tester.ensureVisible(skipSimBtn);
      await tester.tap(skipSimBtn);
      await tester.pumpAndSettle();
      expect(find.text('Quick Preferences'), findsOneWidget);
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
