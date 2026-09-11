import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/native/speed_stream_listener.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/settings/screens/about_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/data_privacy_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/notification_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/permissions_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/theme_settings_screen.dart';
import 'package:bytemeter/src/features/settings/screens/units_settings_screen.dart';

class MockSubScreenBridge extends NativeTrafficBridge {
  MockSubScreenBridge({
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSubScreenBridge mockBridge;
  late PreferencesRepository prefsRepo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockBridge = MockSubScreenBridge();
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: mockBridge);
  });

  Widget createTestWidget({required Widget child}) {
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
        home: child,
      ),
    );
  }

  group('Nested Sub-Screens Individual Widget Tests', () {
    testWidgets('ThemeSettingsScreen modifies theme mode and blur toggle', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(child: const ThemeSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Live Theme Preview'), findsOneWidget);

      // Tap AMOLED Black
      final amoledTile = find.text('AMOLED Black');
      expect(amoledTile, findsOneWidget);
      await tester.tap(amoledTile);
      await tester.pumpAndSettle();
      expect(prefsRepo.current.themeMode, equals(ThemeModePreference.amoled));

      // Tap Light Material
      final lightTile = find.text('Light Material');
      expect(lightTile, findsOneWidget);
      await tester.tap(lightTile);
      await tester.pumpAndSettle();
      expect(prefsRepo.current.themeMode, equals(ThemeModePreference.light));

      // Toggle blur
      final blurSwitch = find.byType(Switch).first;
      await tester.tap(blurSwitch);
      await tester.pumpAndSettle();
      expect(prefsRepo.current.enableBlur, isFalse);
    });

    testWidgets('NotificationSettingsScreen interacts with icon style, slider, and switches', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(child: const NotificationSettingsScreen()));
      await tester.pumpAndSettle();

      // Tap Separate Up/Down
      final separateBtn = find.text('Separate Up/Down');
      expect(separateBtn, findsOneWidget);
      await tester.tap(separateBtn);
      await tester.pumpAndSettle();
      expect(prefsRepo.current.notificationIconStyle, equals(NotificationIconStyle.separateUpDown));

      // Tap AOD Switch
      final aodSwitch = find.text('Always-On Display (AOD) Updates');
      expect(aodSwitch, findsOneWidget);
      await tester.tap(aodSwitch);
      await tester.pumpAndSettle();
      expect(prefsRepo.current.aodModeEnabled, isTrue);
    });

    testWidgets('UnitsSettingsScreen changes units, base, default network, and playground presets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(child: const UnitsSettingsScreen()));
      await tester.pumpAndSettle();

      // Tap Bits
      final bitsBtn = find.text('Bits (Mbps, kbps)');
      expect(bitsBtn, findsOneWidget);
      await tester.tap(bitsBtn);
      await tester.pumpAndSettle();
      expect(prefsRepo.current.speedUnitType, equals(SpeedUnitType.bits));

      // Tap Binary 1024
      final binaryBtn = find.text('Binary (1024)').first;
      expect(binaryBtn, findsOneWidget);
      await tester.tap(binaryBtn);
      await tester.pumpAndSettle();
      expect(prefsRepo.current.metricBase, equals(MetricBase.binary1024));

      // Tap Wi-Fi Network
      final wifiBtn = find.text('Wi-Fi Network');
      expect(wifiBtn, findsOneWidget);
      await tester.tap(wifiBtn);
      await tester.pumpAndSettle();
      expect(prefsRepo.current.homeDefaultNetworkType, equals(NetworkType.wifi));

      // Tap Playground preset
      final preset500mb = find.text('500 MB');
      expect(preset500mb, findsOneWidget);
      await tester.tap(preset500mb);
      await tester.pumpAndSettle();
      expect(find.text('500 MB'), findsWidgets);
    });

    testWidgets('PermissionsSettingsScreen triggers diagnostic ping and permission requests', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      mockBridge.hasPerm = false;
      mockBridge.isIgnoringBattery = false;

      await tester.pumpWidget(createTestWidget(child: const PermissionsSettingsScreen()));
      await tester.pumpAndSettle();

      // Tap Open Settings (Usage)
      final openUsageBtn = find.text('Open Settings');
      expect(openUsageBtn, findsOneWidget);
      await tester.tap(openUsageBtn);
      await tester.pumpAndSettle();
      expect(mockBridge.hasPerm, isTrue);

      // Tap Allow Exemption (Battery)
      final allowExemptionBtn = find.text('Allow Exemption');
      expect(allowExemptionBtn, findsOneWidget);
      await tester.tap(allowExemptionBtn);
      await tester.pumpAndSettle();
      expect(mockBridge.isIgnoringBattery, isTrue);

      // Tap Run Diagnostic Ping
      final pingBtn = find.text('Run Diagnostic Ping');
      expect(pingBtn, findsOneWidget);
      await tester.tap(pingBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('Native Bridge OK'), findsOneWidget);
    });

    testWidgets('DataPrivacySettingsScreen shows offline info and resets preferences via dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Mutate preferences first
      await prefsRepo.setSpeedUnitType(SpeedUnitType.bits);
      expect(prefsRepo.current.speedUnitType, equals(SpeedUnitType.bits));

      await tester.pumpWidget(createTestWidget(child: const DataPrivacySettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('100% Offline & Private'), findsOneWidget);
      expect(find.text('Drift SQLite Engine'), findsOneWidget);

      // Tap Reset Settings to Default
      final resetBtn = find.text('Reset Settings to Default');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Reset Settings?'), findsOneWidget);

      // Tap Reset in dialog
      final confirmReset = find.widgetWithText(FilledButton, 'Reset');
      expect(confirmReset, findsOneWidget);
      await tester.tap(confirmReset);
      await tester.pumpAndSettle();

      expect(prefsRepo.current.speedUnitType, equals(SpeedUnitType.bytes));
    });

    testWidgets('AboutSettingsScreen renders hero info, tech badges, and licenses button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(child: const AboutSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ByteMeter ⚡'), findsOneWidget);
      expect(find.text('Flutter 3.x'), findsOneWidget);
      expect(find.text('Riverpod MVVM'), findsOneWidget);
      expect(find.text('Drift SQLite'), findsOneWidget);
      expect(find.text('Open Source Licenses'), findsOneWidget);
    });
  });
}
