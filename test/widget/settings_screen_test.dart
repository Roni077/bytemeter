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
import 'package:bytemeter/src/features/settings/notification_settings_screen.dart';
import 'package:bytemeter/src/features/settings/settings_screen.dart';
import 'package:bytemeter/src/features/settings/widgets/about_app_card.dart';
import 'package:bytemeter/src/features/settings/widgets/permission_status_card.dart';
import 'package:bytemeter/src/features/settings/widgets/theme_mode_selector.dart';
import 'package:bytemeter/src/features/settings/widgets/unit_settings_card.dart';

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

  group('SettingsScreen Widget Tests', () {
    testWidgets('Renders all core cards and settings sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings & Theming'), findsOneWidget);
      expect(find.byType(PermissionStatusCard), findsOneWidget);
      expect(find.byType(ThemeModeSelector), findsOneWidget);
      expect(find.byType(UnitSettingsCard), findsOneWidget);
      expect(find.byType(AboutAppCard), findsOneWidget);
      expect(find.text('Frosted Glass Blur (Haze)'), findsOneWidget);
      expect(find.text('Status Bar Speed Meter'), findsOneWidget);
    });

    testWidgets('Tapping theme selector updates theme preference', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap AMOLED Black
      final amoledOption = find.text('AMOLED Black');
      expect(amoledOption, findsOneWidget);
      await tester.tap(amoledOption);
      await tester.pumpAndSettle();

      expect(prefsRepo.current.themeMode, equals(ThemeModePreference.amoled));

      // Tap Light Material
      final lightOption = find.text('Light Material');
      expect(lightOption, findsOneWidget);
      await tester.tap(lightOption);
      await tester.pumpAndSettle();

      expect(prefsRepo.current.themeMode, equals(ThemeModePreference.light));
    });

    testWidgets('Toggling unit and standard formats updates preferences', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Bits
      final bitsBtn = find.text('Bits (Mbps, kbps)');
      expect(bitsBtn, findsOneWidget);
      await tester.tap(bitsBtn);
      await tester.pumpAndSettle();

      expect(prefsRepo.current.speedUnitType, equals(SpeedUnitType.bits));

      // Tap Binary 1024
      final binaryBtn = find.text('Binary (1024)');
      expect(binaryBtn, findsOneWidget);
      await tester.tap(binaryBtn);
      await tester.pumpAndSettle();

      expect(prefsRepo.current.metricBase, equals(MetricBase.binary1024));
    });

    testWidgets('Navigating to NotificationSettingsScreen and modifying settings', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Status Bar Speed Meter tile
      final notifTile = find.text('Status Bar Speed Meter');
      expect(notifTile, findsOneWidget);
      await tester.tap(notifTile);
      await tester.pumpAndSettle();

      // Verify NotificationSettingsScreen is shown
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.text('Status Bar Meter'), findsOneWidget);
      expect(find.text('Live Status Bar Meter'), findsOneWidget);
      expect(find.text('Status Bar Icon Style'), findsOneWidget);
      expect(find.text('Auto-Hide Threshold'), findsOneWidget);
      expect(find.text('Always-On Display (AOD) Updates'), findsOneWidget);

      // Select Separate Up/Down icon style
      final separateBtn = find.text('Separate Up/Down');
      expect(separateBtn, findsOneWidget);
      await tester.tap(separateBtn);
      await tester.pumpAndSettle();

      expect(prefsRepo.current.notificationIconStyle, equals(NotificationIconStyle.separateUpDown));

      // Pop back
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
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
