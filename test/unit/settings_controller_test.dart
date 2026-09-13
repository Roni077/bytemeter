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
    this.notifPermission = true,
    this.phonePermission = false,
    this.serviceRunning = false,
  });

  bool hasPermission;
  bool isIgnoringBattery;
  bool notifPermission;
  bool phonePermission;
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
  Future<bool> hasNotificationPermission() async => notifPermission;

  @override
  Future<bool> requestNotificationPermission() async {
    notifPermission = true;
    return true;
  }

  @override
  Future<bool> hasPhonePermission() async => phonePermission;

  @override
  Future<bool> requestPhonePermission() async {
    phonePermission = true;
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

      await controller.setHomeDefaultNetworkType(NetworkType.wifi);
      expect(controller.state.homeDefaultNetworkType, equals(NetworkType.wifi));
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

    test('runDiagnosticSelfTest performs bridge latency check and updates state', () async {
      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);
      await controller.runDiagnosticSelfTest();

      expect(controller.state.isDiagnosticRunning, isFalse);
      expect(controller.state.diagnosticPingLatencyMs, isNotNull);
      expect(controller.state.lastDiagnosticMessage, contains('Native Bridge OK'));
    });

    test('resetPreferencesToDefault resets state and repository to default values', () async {
      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);

      // Mutate settings first
      await controller.setSpeedUnitType(SpeedUnitType.bits);
      await controller.setThemeMode(ThemeModePreference.amoled);
      await controller.setEnableBlur(false);

      expect(controller.state.speedUnitType, equals(SpeedUnitType.bits));
      expect(controller.state.themeMode, equals(ThemeModePreference.amoled));
      expect(controller.state.enableBlur, isFalse);

      // Reset
      await controller.resetPreferencesToDefault();

      expect(controller.state.speedUnitType, equals(SpeedUnitType.bytes));
      expect(controller.state.themeMode, equals(ThemeModePreference.auto));
      expect(controller.state.enableBlur, isTrue);
      expect(prefsRepo.current.speedUnitType, equals(SpeedUnitType.bytes));
    });

    test('ensureServiceRunningIfAllowed boots foreground service when authorized and enabled', () async {
      bridge.hasPermission = true;
      bridge.serviceRunning = false;

      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);
      expect(controller.state.isServiceRunning, isFalse);

      await controller.ensureServiceRunningIfAllowed();

      expect(bridge.serviceRunning, isTrue);
      expect(controller.state.isServiceRunning, isTrue);
    });

    test('ensureServiceRunningIfAllowed respects missing permission or disabled setting', () async {
      // 1. Missing permission
      bridge.hasPermission = false;
      bridge.serviceRunning = false;

      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);
      await controller.ensureServiceRunningIfAllowed();
      expect(bridge.serviceRunning, isFalse);
      expect(controller.state.isServiceRunning, isFalse);

      // 2. Disabled setting
      bridge.hasPermission = true;
      await controller.setPersistentNotificationEnabled(false);
      expect(bridge.serviceRunning, isFalse);

      await controller.ensureServiceRunningIfAllowed();
      expect(bridge.serviceRunning, isFalse);
      expect(controller.state.isServiceRunning, isFalse);
    });

    test('setPersistentNotificationEnabled guards against rapid concurrent toggling', () async {
      bridge.hasPermission = true;
      bridge.serviceRunning = false;

      final controller = SettingsController(prefsRepo: prefsRepo, bridge: bridge);
      expect(controller.state.isTogglingService, isFalse);

      // Launch two concurrent toggle calls
      final future1 = controller.setPersistentNotificationEnabled(true);
      final future2 = controller.setPersistentNotificationEnabled(false);

      await Future.wait([future1, future2]);

      expect(controller.state.isTogglingService, isFalse);
      expect(controller.state.isServiceRunning, isTrue);
      expect(prefsRepo.current.persistentNotificationEnabled, isTrue);
    });
  });
}

