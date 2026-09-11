import '../../data/models/enums.dart';
import '../../data/repositories/preferences_repository.dart';

/// Immutable UI state for the Settings and Permissions feature.
class SettingsState {
  const SettingsState({
    this.preferences = const UserPreferences(),
    this.hasUsagePermission = false,
    this.isIgnoringBatteryOptimizations = false,
    this.isServiceRunning = false,
    this.isLoading = false,
    this.errorMessage,
    this.appVersion = '1.0.0',
  });

  final UserPreferences preferences;
  final bool hasUsagePermission;
  final bool isIgnoringBatteryOptimizations;
  final bool isServiceRunning;
  final bool isLoading;
  final String? errorMessage;
  final String appVersion;

  SettingsState copyWith({
    UserPreferences? preferences,
    bool? hasUsagePermission,
    bool? isIgnoringBatteryOptimizations,
    bool? isServiceRunning,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? appVersion,
  }) {
    return SettingsState(
      preferences: preferences ?? this.preferences,
      hasUsagePermission: hasUsagePermission ?? this.hasUsagePermission,
      isIgnoringBatteryOptimizations:
          isIgnoringBatteryOptimizations ?? this.isIgnoringBatteryOptimizations,
      isServiceRunning: isServiceRunning ?? this.isServiceRunning,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      appVersion: appVersion ?? this.appVersion,
    );
  }

  SpeedUnitType get speedUnitType => preferences.speedUnitType;
  MetricBase get metricBase => preferences.metricBase;
  ThemeModePreference get themeMode => preferences.themeMode;
  bool get enableBlur => preferences.enableBlur;
  bool get persistentNotificationEnabled => preferences.persistentNotificationEnabled;
  NotificationIconStyle get notificationIconStyle => preferences.notificationIconStyle;
  int get silentSpeedThresholdKb => preferences.silentSpeedThresholdKb;
  bool get aodModeEnabled => preferences.aodModeEnabled;
  NetworkType get overviewDefaultNetworkType => preferences.overviewDefaultNetworkType;
}
