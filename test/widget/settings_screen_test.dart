import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/app_scaffold.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/native/speed_stream_listener.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/settings/screens/about_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/data_privacy_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/notification_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/permissions_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/theme_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/units_settings_screen.dart';
import 'package:bytemeter/src/features/settings/settings_screen.dart';
import 'package:bytemeter/src/features/settings/widgets/settings_tile.dart';

class MockSettingsBridge extends NativeTrafficBridge {
  MockSettingsBridge({
    this.hasPerm = true,
    this.isIgnoringBattery = true,
    this.serviceRunning = true,
  });

  bool hasPerm;
  bool isIgnoringBattery;
  bool serviceRunning;

  @override
  Future<bool> hasUsagePermission() async => hasPerm;

  @override
  Future<bool> requestUsagePermission() async {
    hasPerm = true;
    return true;
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => isIgnoringBattery;

  @override
  Future<bool> requestIgnoreBatteryOptimizations() async {
    isIgnoringBattery = true;
    return true;
  }

  @override
  Future<bool> isServiceRunning() async => serviceRunning;

  @override
  Future<bool> startForegroundService() async {
    serviceRunning = true;
    return true;
  }

  @override
  Future<bool> stopForegroundService() async {
    serviceRunning = false;
    return true;
  }

  @override
  Future<UsageData> queryDeviceSummary({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return UsageData(
      uploadBytes: 100000000,
      downloadBytes: 400000000,
      totalBytes: 500000000,
      startTime: startTime,
      endTime: endTime,
    );
  }

  @override
  Future<List<UsageData>> queryAppBuckets({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      const [];

  @override
  Future<List<UsageData>> queryHourlyBuckets({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
    int? uid,
  }) async =>
      const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsBridge mockBridge;
  late PreferencesRepository prefsRepo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockBridge = MockSettingsBridge();
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: mockBridge);
  });

  Widget createTestWidget({Widget? child}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nativeTrafficBridgeProvider.overrideWithValue(mockBridge),
        preferencesRepositoryProvider.overrideWithValue(prefsRepo),
        networkUsageRepositoryProvider.overrideWithValue(
          NetworkUsageRepository(bridge: mockBridge),
        ),
        speedStreamListenerProvider.overrideWithValue(
          SpeedStreamListener(mockStream: const Stream.empty()),
        ),
      ],
      child: MaterialApp(
        home: child ?? const SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen Hub Widget Tests', () {
    testWidgets('Renders all 6 settings category tiles and search bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings & Theming'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(SettingsTile), findsNWidgets(6));

      expect(find.text('Theme & Appearance'), findsOneWidget);
      expect(find.text('Status Bar Speed Meter'), findsOneWidget);
      expect(find.text('Units & Calculation Standards'), findsOneWidget);
      expect(find.text('Permissions & System Access'), findsOneWidget);
      expect(find.text('Storage & Data Privacy'), findsOneWidget);
      expect(find.text('About & System Info'), findsOneWidget);
    });

    testWidgets('Search query filters settings tiles dynamically', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter search query 'amoled'
      await tester.enterText(find.byType(TextField), 'amoled');
      await tester.pumpAndSettle();

      expect(find.text('Theme & Appearance'), findsOneWidget);
      expect(find.text('Units & Calculation Standards'), findsNothing);
      expect(find.text('Storage & Data Privacy'), findsNothing);

      // Clear search
      final clearBtn = find.byIcon(Icons.clear_rounded);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsTile), findsNWidgets(6));
    });

    testWidgets('Navigating to ThemeSettingsScreen and back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final themeTile = find.text('Theme & Appearance');
      expect(themeTile, findsOneWidget);
      await tester.tap(themeTile);
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSettingsScreen), findsOneWidget);
      expect(find.text('Live Theme Preview'), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Navigating to NotificationSettingsScreen and back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final notifTile = find.text('Status Bar Speed Meter');
      expect(notifTile, findsOneWidget);
      await tester.tap(notifTile);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.text('Status Bar Meter'), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Navigating to UnitsSettingsScreen and back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final unitsTile = find.text('Units & Calculation Standards');
      expect(unitsTile, findsOneWidget);
      await tester.tap(unitsTile);
      await tester.pumpAndSettle();

      expect(find.byType(UnitsSettingsScreen), findsOneWidget);
      expect(find.text('Live Conversion Playground'), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Navigating to PermissionsSettingsScreen and back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final permsTile = find.text('Permissions & System Access');
      expect(permsTile, findsOneWidget);
      await tester.tap(permsTile);
      await tester.pumpAndSettle();

      expect(find.byType(PermissionsSettingsScreen), findsOneWidget);
      expect(find.text('Permissions & Diagnostics'), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Navigating to DataPrivacySettingsScreen and back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final privacyTile = find.text('Storage & Data Privacy');
      expect(privacyTile, findsOneWidget);
      await tester.tap(privacyTile);
      await tester.pumpAndSettle();

      expect(find.byType(DataPrivacySettingsScreen), findsOneWidget);
      expect(find.text('100% Offline & Private'), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Navigating to AboutSettingsScreen and back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final aboutTile = find.text('About & System Info');
      expect(aboutTile, findsOneWidget);
      await tester.tap(aboutTile);
      await tester.pumpAndSettle();

      expect(find.byType(AboutSettingsScreen), findsOneWidget);
      expect(find.text('About ByteMeter'), findsOneWidget);
      expect(find.text('Architecture & Technology'), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('AppScaffold navigates to SettingsScreen on 4th tab selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(child: const AppScaffold()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Settings tab (index 3)
      final settingsTab = find.text('Settings');
      expect(settingsTab, findsOneWidget);
      await tester.tap(settingsTab);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings & Theming'), findsOneWidget);
    });
  });
}
