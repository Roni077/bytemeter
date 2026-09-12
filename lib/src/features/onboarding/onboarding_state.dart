import '../../data/models/enums.dart';

/// Immutable state snapshot tracking the user's progress through the Onboarding
/// & Setup wizard, including real-time native permission statuses and quick configuration.
class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.totalPages = 4,
    this.hasUsagePermission = false,
    this.hasNotificationPermission = false,
    this.isIgnoringBatteryOptimizations = false,
    this.hasPhonePermission = false,
    this.isLoadingPermissions = false,
    this.speedUnitType = SpeedUnitType.bytes,
    this.metricBase = MetricBase.decimal1000,
    this.themeMode = ThemeModePreference.auto,
    this.enableBlur = true,
    this.persistentNotificationEnabled = true,
    this.homeDefaultNetworkType = NetworkType.mobile,
    this.isCompleting = false,
  });

  final int currentPage;
  final int totalPages;
  final bool hasUsagePermission;
  final bool hasNotificationPermission;
  final bool isIgnoringBatteryOptimizations;
  final bool hasPhonePermission;
  final bool isLoadingPermissions;
  final SpeedUnitType speedUnitType;
  final MetricBase metricBase;
  final ThemeModePreference themeMode;
  final bool enableBlur;
  final bool persistentNotificationEnabled;
  final NetworkType homeDefaultNetworkType;
  final bool isCompleting;

  /// Whether the critical permission (Usage Access) has been granted.
  bool get hasRequiredPermissions => hasUsagePermission;

  /// Total count of permissions granted out of 4.
  int get grantedCount =>
      (hasUsagePermission ? 1 : 0) +
      (hasNotificationPermission ? 1 : 0) +
      (isIgnoringBatteryOptimizations ? 1 : 0) +
      (hasPhonePermission ? 1 : 0);

  /// Whether all 4 permissions (essential + recommended + optional) are granted.
  bool get allPermissionsGranted => grantedCount == 4;

  OnboardingState copyWith({
    int? currentPage,
    int? totalPages,
    bool? hasUsagePermission,
    bool? hasNotificationPermission,
    bool? isIgnoringBatteryOptimizations,
    bool? hasPhonePermission,
    bool? isLoadingPermissions,
    SpeedUnitType? speedUnitType,
    MetricBase? metricBase,
    ThemeModePreference? themeMode,
    bool? enableBlur,
    bool? persistentNotificationEnabled,
    NetworkType? homeDefaultNetworkType,
    bool? isCompleting,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasUsagePermission: hasUsagePermission ?? this.hasUsagePermission,
      hasNotificationPermission:
          hasNotificationPermission ?? this.hasNotificationPermission,
      isIgnoringBatteryOptimizations:
          isIgnoringBatteryOptimizations ?? this.isIgnoringBatteryOptimizations,
      hasPhonePermission: hasPhonePermission ?? this.hasPhonePermission,
      isLoadingPermissions: isLoadingPermissions ?? this.isLoadingPermissions,
      speedUnitType: speedUnitType ?? this.speedUnitType,
      metricBase: metricBase ?? this.metricBase,
      themeMode: themeMode ?? this.themeMode,
      enableBlur: enableBlur ?? this.enableBlur,
      persistentNotificationEnabled:
          persistentNotificationEnabled ?? this.persistentNotificationEnabled,
      homeDefaultNetworkType:
          homeDefaultNetworkType ?? this.homeDefaultNetworkType,
      isCompleting: isCompleting ?? this.isCompleting,
    );
  }
}
