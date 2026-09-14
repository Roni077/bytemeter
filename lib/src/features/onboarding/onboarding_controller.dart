import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/native/native_traffic_bridge.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/preferences_repository.dart';
import 'onboarding_state.dart';

/// Provider for the [OnboardingController] coordinating first-run setup and permissions.
final onboardingControllerProvider =
    StateNotifierProvider.autoDispose<OnboardingController, OnboardingState>((ref) {
  final bridge = ref.watch(nativeTrafficBridgeProvider);
  final prefsRepo = ref.watch(preferencesRepositoryProvider);
  return OnboardingController(bridge: bridge, prefsRepo: prefsRepo);
});

/// ViewModel controller driving the Onboarding & Setup wizard.
class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController({
    required this.bridge,
    required this.prefsRepo,
  }) : super(const OnboardingState()) {
    _init();
  }

  final NativeTrafficBridge bridge;
  final PreferencesRepository prefsRepo;

  void _init() {
    final currentPrefs = prefsRepo.current;
    state = state.copyWith(
      speedUnitType: currentPrefs.speedUnitType,
      metricBase: currentPrefs.metricBase,
      themeMode: currentPrefs.themeMode,
      enableBlur: currentPrefs.enableBlur,
      persistentNotificationEnabled: currentPrefs.persistentNotificationEnabled,
      homeDefaultNetworkType: currentPrefs.homeDefaultNetworkType,
    );
    refreshPermissionStatuses();
  }

  /// Refreshes all Android platform permission checks in parallel.
  Future<void> refreshPermissionStatuses() async {
    state = state.copyWith(isLoadingPermissions: true);
    try {
      final results = await Future.wait([
        bridge.hasUsagePermission(),
        bridge.hasNotificationPermission(),
        bridge.isIgnoringBatteryOptimizations(),
        bridge.hasPhonePermission(),
      ]);

      state = state.copyWith(
        hasUsagePermission: results[0],
        hasNotificationPermission: results[1],
        isIgnoringBatteryOptimizations: results[2],
        hasPhonePermission: results[3],
        isLoadingPermissions: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingPermissions: false);
    }
  }

  /// Dispatches the system Usage Access settings intent.
  Future<void> requestUsagePermission() async {
    await bridge.requestUsagePermission();
    await refreshPermissionStatuses();
  }

  /// Dispatches the system notification settings intent.
  Future<void> requestNotificationPermission() async {
    await bridge.requestNotificationPermission();
    await refreshPermissionStatuses();
  }

  /// Dispatches the Battery Optimization exemption dialog.
  Future<void> requestBatteryExemption() async {
    await bridge.requestIgnoreBatteryOptimizations();
    await refreshPermissionStatuses();
  }

  /// Dispatches the application details settings intent for Phone state access.
  Future<void> requestPhonePermission() async {
    await bridge.requestPhonePermission();
    await refreshPermissionStatuses();
  }

  /// Updates the active page index in the onboarding wizard.
  void setPage(int index) {
    if (index >= 0 && index < state.totalPages) {
      state = state.copyWith(currentPage: index);
    }
  }

  /// Configures the speed unit representation (Bytes vs Bits).
  Future<void> setSpeedUnit(SpeedUnitType type) async {
    await prefsRepo.setSpeedUnitType(type);
    state = state.copyWith(speedUnitType: type);
  }

  /// Configures the metric scaling base (1000 Decimal vs 1024 Binary).
  Future<void> setMetricBase(MetricBase base) async {
    await prefsRepo.setMetricBase(base);
    state = state.copyWith(metricBase: base);
  }

  /// Configures the application visual theme.
  Future<void> setThemeMode(ThemeModePreference mode) async {
    await prefsRepo.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  /// Toggles the persistent speed meter notification.
  Future<void> setPersistentNotification(bool enabled) async {
    await prefsRepo.setPersistentNotificationEnabled(enabled);
    state = state.copyWith(persistentNotificationEnabled: enabled);
  }

  /// Configures the default overview network interface.
  Future<void> setDefaultNetworkType(NetworkType type) async {
    await prefsRepo.setHomeDefaultNetworkType(type);
    state = state.copyWith(homeDefaultNetworkType: type);
  }

  /// Marks the onboarding wizard as completed and starts monitoring if authorized.
  Future<void> completeOnboarding() async {
    state = state.copyWith(isCompleting: true);
    await prefsRepo.setHasCompletedOnboarding(true);

    if (state.persistentNotificationEnabled && state.hasNotificationPermission) {
      await bridge.startForegroundService();
    }
    state = state.copyWith(isCompleting: false);
  }
}
