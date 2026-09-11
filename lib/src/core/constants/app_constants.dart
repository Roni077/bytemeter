/// System-wide constants, thresholds, and keys for ByteMeter.
class AppConstants {
  const AppConstants._();

  // Speed and Polling
  static const int defaultPollingIntervalMs = 1000;
  static const int defaultHistoryDepthDays = 90;
  static const int defaultSilentSpeedThresholdKb = 0;

  // Prediction and Safety
  static const int predictionLookbackWeeks = 4;
  static const double safeRatioThreshold = 0.0;
  static const double neutralRatioThreshold = 0.1;
  static const double quotaWarningRatio = 0.95;

  // Preferences Keys
  static const String prefSpeedUnitBits = 'speed_unit_bits';
  static const String prefMetricBase1000 = 'metric_base_1000';
  static const String prefThemeMode = 'theme_mode';
  static const String prefEnableBlur = 'enable_blur';
  static const String prefPersistentNotification = 'persistent_notification_enabled';
  static const String prefNotificationIconStyle = 'notification_icon_style';
  static const String prefSilentSpeedThresholdKb = 'silent_speed_threshold_kb';
  static const String prefAodModeEnabled = 'aod_mode_enabled';
  static const String prefHomeDefaultType = 'home_default_type';
  static const String prefOverviewDefaultType = 'overview_default_type';

  // Database
  static const String databaseName = 'bytemeter_db.sqlite';
}
