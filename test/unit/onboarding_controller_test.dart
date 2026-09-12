import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/onboarding/onboarding_controller.dart';

class FakeOnboardingBridge extends NativeTrafficBridge {
  FakeOnboardingBridge({
    this.usageGranted = false,
    this.notifGranted = false,
    this.batteryIgnored = false,
    this.phoneGranted = false,
    this.serviceRunning = false,
  });

  bool usageGranted;
  bool notifGranted;
  bool batteryIgnored;
  bool phoneGranted;
  bool serviceRunning;

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
  }) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingController Unit Tests', () {
    late SharedPreferences prefs;
    late PreferencesRepository prefsRepo;
    late FakeOnboardingBridge bridge;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      bridge = FakeOnboardingBridge();
      prefsRepo = PreferencesRepository(prefs: prefs, bridge: bridge);
    });

    tearDown(() {
      prefsRepo.dispose();
    });

    test('Initializes with default state and synchronizes permission queries', () async {
      final controller = OnboardingController(bridge: bridge, prefsRepo: prefsRepo);
      await controller.refreshPermissionStatuses();

      expect(controller.state.currentPage, equals(0));
      expect(controller.state.totalPages, equals(4));
      expect(controller.state.hasUsagePermission, isFalse);
      expect(controller.state.hasNotificationPermission, isFalse);
      expect(controller.state.isIgnoringBatteryOptimizations, isFalse);
      expect(controller.state.hasPhonePermission, isFalse);
      expect(controller.state.grantedCount, equals(0));
      expect(controller.state.hasRequiredPermissions, isFalse);
    });

    test('Permission requests update controller state and granted count', () async {
      final controller = OnboardingController(bridge: bridge, prefsRepo: prefsRepo);

      await controller.requestUsagePermission();
      expect(controller.state.hasUsagePermission, isTrue);
      expect(controller.state.grantedCount, equals(1));
      expect(controller.state.hasRequiredPermissions, isTrue);

      await controller.requestNotificationPermission();
      expect(controller.state.hasNotificationPermission, isTrue);
      expect(controller.state.grantedCount, equals(2));

      await controller.requestBatteryExemption();
      expect(controller.state.isIgnoringBatteryOptimizations, isTrue);
      expect(controller.state.grantedCount, equals(3));

      await controller.requestPhonePermission();
      expect(controller.state.hasPhonePermission, isTrue);
      expect(controller.state.grantedCount, equals(4));
      expect(controller.state.allPermissionsGranted, isTrue);
    });

    test('Page navigation updates currentPage within bounds', () {
      final controller = OnboardingController(bridge: bridge, prefsRepo: prefsRepo);

      controller.setPage(2);
      expect(controller.state.currentPage, equals(2));

      // Out of bounds checks
      controller.setPage(-1);
      expect(controller.state.currentPage, equals(2));

      controller.setPage(10);
      expect(controller.state.currentPage, equals(2));
    });

    test('Quick preference mutators update controller state and persistent repository', () async {
      final controller = OnboardingController(bridge: bridge, prefsRepo: prefsRepo);

      await controller.setSpeedUnit(SpeedUnitType.bits);
      expect(controller.state.speedUnitType, equals(SpeedUnitType.bits));
      expect(prefsRepo.current.speedUnitType, equals(SpeedUnitType.bits));

      await controller.setMetricBase(MetricBase.binary1024);
      expect(controller.state.metricBase, equals(MetricBase.binary1024));
      expect(prefsRepo.current.metricBase, equals(MetricBase.binary1024));

      await controller.setThemeMode(ThemeModePreference.dark);
      expect(controller.state.themeMode, equals(ThemeModePreference.dark));
      expect(prefsRepo.current.themeMode, equals(ThemeModePreference.dark));

      await controller.setPersistentNotification(false);
      expect(controller.state.persistentNotificationEnabled, isFalse);
      expect(prefsRepo.current.persistentNotificationEnabled, isFalse);

      await controller.setDefaultNetworkType(NetworkType.wifi);
      expect(controller.state.homeDefaultNetworkType, equals(NetworkType.wifi));
      expect(prefsRepo.current.homeDefaultNetworkType, equals(NetworkType.wifi));
    });

    test('completeOnboarding sets hasCompletedOnboarding flag and starts service if authorized', () async {
      bridge.usageGranted = true;
      final controller = OnboardingController(bridge: bridge, prefsRepo: prefsRepo);
      await controller.refreshPermissionStatuses();

      expect(prefsRepo.current.hasCompletedOnboarding, isFalse);

      await controller.completeOnboarding();

      expect(prefsRepo.current.hasCompletedOnboarding, isTrue);
      expect(bridge.serviceRunning, isTrue);
    });
  });
}
