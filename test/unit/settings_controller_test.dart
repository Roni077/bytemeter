import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/settings/settings_controller.dart';

class FakeSettingsBridge extends NativeTrafficBridge {
  FakeSettingsBridge({
    this.hasPermission = true,
    this.isIgnoringBattery = false,
    this.serviceRunning = false,
  });

  bool hasPermission;
  bool isIgnoringBattery;
  bool serviceRunning;
  int updateSettingsCalls = 0;

  @override
  Future<bool> hasUsagePermission() async => hasPermission;

  @override
  Future<bool> requestUsagePermission() async {
    hasPermission = true;
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
  Future<bool> isServiceRunning() async => serviceRunning;

  @override
  Future<bool> updateServiceSettings({
    bool? inBits,
    bool? separateUpDown,
    bool? metric1000,
    bool? aodMode,
    int? speedThresholdKb,
    bool? forceFallback,
  }) async {
    updateSettingsCalls++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSettingsBridge bridge;
  late PreferencesRepository prefsRepo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bridge = FakeSettingsBridge(
      hasPermission: true,
      isIgnoringBattery: false,
      serviceRunning: false,
    );
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: bridge);
  });

  group('SettingsController Unit Tests', () {
    test('Loads initial state and synchronizes with native bridge', () async {
      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);

      // Wait for initial async state load
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.hasUsagePermission, isTrue);
      expect(controller.state.isIgnoringBatteryOptimizations, isFalse);
      expect(controller.state.isServiceRunning, isFalse);
      expect(controller.state.speedUnitType, equals(SpeedUnitType.bytes));
      expect(controller.state.metricBase, equals(MetricBase.decimal1000));
      expect(controller.state.themeMode, equals(ThemeModePreference.auto));
      expect(controller.state.enableBlur, isTrue);
      expect(controller.state.persistentNotificationEnabled, isTrue);
    });

    test('Modifying unit formats updates state and persistent preferences', () async {
      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);

      await controller.setSpeedUnitType(SpeedUnitType.bits);
      expect(controller.state.speedUnitType, equals(SpeedUnitType.bits));
      expect(prefsRepo.current.speedUnitType, equals(SpeedUnitType.bits));

      await controller.setMetricBase(MetricBase.binary1024);
      expect(controller.state.metricBase, equals(MetricBase.binary1024));
      expect(prefsRepo.current.metricBase, equals(MetricBase.binary1024));

      await controller.setOverviewDefaultNetworkType(NetworkType.wifi);
      expect(controller.state.overviewDefaultNetworkType, equals(NetworkType.wifi));
    });

    test('Modifying theme mode and blur updates state', () async {
      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);

      await controller.setThemeMode(ThemeModePreference.amoled);
      expect(controller.state.themeMode, equals(ThemeModePreference.amoled));

      await controller.setThemeMode(ThemeModePreference.dark);
      expect(controller.state.themeMode, equals(ThemeModePreference.dark));

      await controller.setEnableBlur(false);
      expect(controller.state.enableBlur, isFalse);
    });

    test('Persistent notification and status bar options start/stop service', () async {
      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);

      await controller.setPersistentNotificationEnabled(true);
      expect(bridge.serviceRunning, isTrue);

      await controller.setNotificationIconStyle(NotificationIconStyle.separateUpDown);
      expect(controller.state.notificationIconStyle, equals(NotificationIconStyle.separateUpDown));

      await controller.setSilentSpeedThresholdKb(25);
      expect(controller.state.silentSpeedThresholdKb, equals(25));

      await controller.setAodModeEnabled(true);
      expect(controller.state.aodModeEnabled, isTrue);

      await controller.setPersistentNotificationEnabled(false);
      expect(bridge.serviceRunning, isFalse);
    });

    test('Permission requests invoke native platform bridge and refresh status', () async {
      bridge.hasPermission = false;
      bridge.isIgnoringBattery = false;

      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);
      await controller.loadInitialState();

      expect(controller.state.hasUsagePermission, isFalse);
      expect(controller.state.isIgnoringBatteryOptimizations, isFalse);

      final reqUsage = await controller.requestUsagePermission();
      expect(reqUsage, isTrue);
      expect(controller.state.hasUsagePermission, isTrue);

      final reqBattery = await controller.requestIgnoreBatteryOptimizations();
      expect(reqBattery, isTrue);
      expect(controller.state.isIgnoringBatteryOptimizations, isTrue);
    });
  });
}
