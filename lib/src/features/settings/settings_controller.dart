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
      final results = await Future.wait([
        bridge.hasUsagePermission(),
        bridge.hasNotificationPermission(),
        bridge.isIgnoringBatteryOptimizations(),
        bridge.hasPhonePermission(),
        bridge.isServiceRunning(),
      ]);
      final hasPerm = results[0];
      final hasNotif = results[1];
      final ignoringBattery = results[2];
      final hasPhone = results[3];
      final serviceRunning = results[4];

      state = state.copyWith(
        preferences: prefsRepo.current,
        hasUsagePermission: hasPerm,
        hasNotificationPermission: hasNotif,
        isIgnoringBatteryOptimizations: ignoringBattery,
        hasPhonePermission: hasPhone,
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
      final results = await Future.wait([
        bridge.hasUsagePermission(),
        bridge.hasNotificationPermission(),
        bridge.isIgnoringBatteryOptimizations(),
        bridge.hasPhonePermission(),
        bridge.isServiceRunning(),
      ]);
      final hasPerm = results[0];
      final hasNotif = results[1];
      final ignoringBattery = results[2];
      final hasPhone = results[3];
      final serviceRunning = results[4];

      state = state.copyWith(
        hasUsagePermission: hasPerm,
        hasNotificationPermission: hasNotif,
        isIgnoringBatteryOptimizations: ignoringBattery,
        hasPhonePermission: hasPhone,
        isServiceRunning: serviceRunning,
      );
    } catch (_) {
      // Non-fatal permission refresh error
    }
  }

  /// Ensures foreground speed meter service is active if authorized and enabled.
  Future<void> ensureServiceRunningIfAllowed() async {
    await prefsRepo.ensureServiceRunningIfAllowed();
    final running = await bridge.isServiceRunning();
    if (running != state.isServiceRunning) {
      state = state.copyWith(isServiceRunning: running);
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

  /// Master switch for persistent foreground speed notification with re-entrancy guard.
  Future<void> setPersistentNotificationEnabled(bool enable) async {
    if (state.isTogglingService) return;
    state = state.copyWith(isTogglingService: true);
    try {
      await prefsRepo.setPersistentNotificationEnabled(enable);
      final running = await bridge.isServiceRunning();
      state = state.copyWith(
        preferences: prefsRepo.current,
        isServiceRunning: running,
      );
    } finally {
      state = state.copyWith(isTogglingService: false);
    }
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

  /// Sets default network type shown on Home dashboard.
  Future<void> setHomeDefaultNetworkType(NetworkType type) async {
    await prefsRepo.setHomeDefaultNetworkType(type);
    state = state.copyWith(preferences: prefsRepo.current);
  }

  /// Backward-compatible alias for [setHomeDefaultNetworkType].
  Future<void> setOverviewDefaultNetworkType(NetworkType type) async {
    await setHomeDefaultNetworkType(type);
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

  /// Requests notification permissions.
  Future<bool> requestNotificationPermission() async {
    final result = await bridge.requestNotificationPermission();
    await refreshPermissionStatuses();
    return result;
  }

  /// Requests phone state permissions.
  Future<bool> requestPhonePermission() async {
    final result = await bridge.requestPhonePermission();
    await refreshPermissionStatuses();
    return result;
  }

  /// Runs a live roundtrip diagnostic ping to test native bridge communication.
  Future<void> runDiagnosticSelfTest() async {
    state = state.copyWith(isDiagnosticRunning: true);
    final stopwatch = Stopwatch()..start();
    try {
      final results = await Future.wait([
        bridge.hasUsagePermission(),
        bridge.isServiceRunning(),
        bridge.isIgnoringBatteryOptimizations(),
      ]);
      final hasPerm = results[0];
      final serviceRunning = results[1];
      final ignoringBattery = results[2];
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      state = state.copyWith(
        hasUsagePermission: hasPerm,
        isServiceRunning: serviceRunning,
        isIgnoringBatteryOptimizations: ignoringBattery,
        diagnosticPingLatencyMs: latency,
        lastDiagnosticMessage:
            'Native Bridge OK · ${latency}ms roundtrip · Service: ${serviceRunning ? "Active" : "Idle"}',
        isDiagnosticRunning: false,
      );
    } catch (e) {
      stopwatch.stop();
      state = state.copyWith(
        diagnosticPingLatencyMs: stopwatch.elapsedMilliseconds,
        lastDiagnosticMessage: 'Diagnostic error: $e',
        isDiagnosticRunning: false,
      );
    }
  }

  /// Resets all preferences to factory defaults.
  Future<void> resetPreferencesToDefault() async {
    await prefsRepo.resetToDefaults();
    state = state.copyWith(preferences: prefsRepo.current);
  }
}

/// Riverpod StateNotifierProvider for [SettingsController].
final settingsControllerProvider =
    StateNotifierProvider.autoDispose<SettingsController, SettingsState>((ref) {
  final prefsRepo = ref.watch(preferencesRepositoryProvider);
  final bridge = ref.watch(nativeTrafficBridgeProvider);
  return SettingsController(prefsRepo: prefsRepo, bridge: bridge);
});
