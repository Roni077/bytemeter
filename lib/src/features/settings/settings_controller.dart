import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/native/native_traffic_bridge.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/preferences_repository.dart';
import 'settings_state.dart';

/// StateNotifier ViewModel orchestrating user preferences, dynamic theming,
/// status bar speed notification configuration, and Android system permissions.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController({
    required this.prefsRepo,
    required this.bridge,
  }) : super(SettingsState(preferences: prefsRepo.current)) {
    _prefsSubscription = prefsRepo.preferencesStream.listen((updatedPrefs) {
      state = state.copyWith(preferences: updatedPrefs);
    });
    loadInitialState();
  }

  final PreferencesRepository prefsRepo;
  final NativeTrafficBridge bridge;
  StreamSubscription<UserPreferences>? _prefsSubscription;

  @override
  void dispose() {
    _prefsSubscription?.cancel();
    super.dispose();
  }

  /// Loads permissions status and foreground service state from native Android layer.
  Future<void> loadInitialState() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final hasPerm = await bridge.hasUsagePermission();
      final ignoringBattery = await bridge.isIgnoringBatteryOptimizations();
      final serviceRunning = await bridge.isServiceRunning();

      state = state.copyWith(
        preferences: prefsRepo.current,
        hasUsagePermission: hasPerm,
        isIgnoringBatteryOptimizations: ignoringBattery,
        isServiceRunning: serviceRunning,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings: $e',
      );
    }
  }

  /// Refreshes permission and service statuses (e.g. on AppLifecycle resumed).
  Future<void> refreshPermissionStatuses() async {
    try {
      final hasPerm = await bridge.hasUsagePermission();
      final ignoringBattery = await bridge.isIgnoringBatteryOptimizations();
      final serviceRunning = await bridge.isServiceRunning();

      state = state.copyWith(
        hasUsagePermission: hasPerm,
        isIgnoringBatteryOptimizations: ignoringBattery,
        isServiceRunning: serviceRunning,
      );
    } catch (_) {
      // Non-fatal permission refresh error
    }
  }

  /// Updates speed unit format (Bits vs Bytes).
  Future<void> setSpeedUnitType(SpeedUnitType type) async {
    await prefsRepo.setSpeedUnitType(type);
    state = state.copyWith(preferences: prefsRepo.current);
  }

  /// Updates metric base (Decimal 1000 vs Binary 1024).
  Future<void> setMetricBase(MetricBase base) async {
    await prefsRepo.setMetricBase(base);
    state = state.copyWith(preferences: prefsRepo.current);
  }

  /// Updates app theme mode appearance.
  Future<void> setThemeMode(ThemeModePreference mode) async {
    await prefsRepo.setThemeMode(mode);
    state = state.copyWith(preferences: prefsRepo.current);
  }

  /// Enables or disables frosted glass backdrop blur.
  Future<void> setEnableBlur(bool enable) async {
    await prefsRepo.setEnableBlur(enable);
    state = state.copyWith(preferences: prefsRepo.current);
  }

  /// Master switch for persistent foreground speed notification.
  Future<void> setPersistentNotificationEnabled(bool enable) async {
    await prefsRepo.setPersistentNotificationEnabled(enable);
    final running = await bridge.isServiceRunning();
    state = state.copyWith(
      preferences: prefsRepo.current,
      isServiceRunning: running,
    );
  }

  /// Updates status bar notification icon style.
  Future<void> setNotificationIconStyle(NotificationIconStyle style) async {
    await prefsRepo.setNotificationIconStyle(style);
    state = state.copyWith(preferences: prefsRepo.current);
  }

  /// Updates minimum speed in KB/s below which the status icon auto-hides.
  Future<void> setSilentSpeedThresholdKb(int thresholdKb) async {
    await prefsRepo.setSilentSpeedThresholdKb(thresholdKb);
    state = state.copyWith(preferences: prefsRepo.current);
  }

  /// Sets whether the speed meter continues polling when screen is locked.
  Future<void> setAodModeEnabled(bool enable) async {
    await prefsRepo.setAodModeEnabled(enable);
    state = state.copyWith(preferences: prefsRepo.current);
  }

  /// Sets default network type shown on Overview dashboard.
  Future<void> setOverviewDefaultNetworkType(NetworkType type) async {
    await prefsRepo.setOverviewDefaultNetworkType(type);
    state = state.copyWith(preferences: prefsRepo.current);
  }

  /// Requests Android Usage Access permission.
  Future<bool> requestUsagePermission() async {
    final result = await bridge.requestUsagePermission();
    await refreshPermissionStatuses();
    return result;
  }

  /// Requests battery optimization exemption.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    final result = await bridge.requestIgnoreBatteryOptimizations();
    await refreshPermissionStatuses();
    return result;
  }
}

/// Riverpod StateNotifierProvider for [SettingsController].
final settingsControllerProvider =
    StateNotifierProvider.autoDispose<SettingsController, SettingsState>((ref) {
  final prefsRepo = ref.watch(preferencesRepositoryProvider);
  final bridge = ref.watch(nativeTrafficBridgeProvider);
  return SettingsController(prefsRepo: prefsRepo, bridge: bridge);
});
