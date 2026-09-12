import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/native/native_traffic_bridge.dart';
import '../models/enums.dart';

/// Immutable state snapshot of all user preferences.
class UserPreferences {
  const UserPreferences({
    this.hasCompletedOnboarding = false,
    this.speedUnitType = SpeedUnitType.bytes,
    this.metricBase = MetricBase.decimal1000,
    this.themeMode = ThemeModePreference.auto,
    this.enableBlur = true,
    this.persistentNotificationEnabled = true,
    this.notificationIconStyle = NotificationIconStyle.combined,
    this.silentSpeedThresholdKb = 0,
    this.aodModeEnabled = false,
    this.homeDefaultNetworkType = NetworkType.mobile,
  });

  final bool hasCompletedOnboarding;
  final SpeedUnitType speedUnitType;
  final MetricBase metricBase;
  final ThemeModePreference themeMode;
  final bool enableBlur;
  final bool persistentNotificationEnabled;
  final NotificationIconStyle notificationIconStyle;
  final int silentSpeedThresholdKb;
  final bool aodModeEnabled;
  final NetworkType homeDefaultNetworkType;

  /// Backward-compatible alias
  NetworkType get overviewDefaultNetworkType => homeDefaultNetworkType;

  UserPreferences copyWith({
    bool? hasCompletedOnboarding,
    SpeedUnitType? speedUnitType,
    MetricBase? metricBase,
    ThemeModePreference? themeMode,
    bool? enableBlur,
    bool? persistentNotificationEnabled,
    NotificationIconStyle? notificationIconStyle,
    int? silentSpeedThresholdKb,
    bool? aodModeEnabled,
    NetworkType? homeDefaultNetworkType,
    NetworkType? overviewDefaultNetworkType,
  }) {
    return UserPreferences(
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      speedUnitType: speedUnitType ?? this.speedUnitType,
      metricBase: metricBase ?? this.metricBase,
      themeMode: themeMode ?? this.themeMode,
      enableBlur: enableBlur ?? this.enableBlur,
      persistentNotificationEnabled:
          persistentNotificationEnabled ?? this.persistentNotificationEnabled,
      notificationIconStyle: notificationIconStyle ?? this.notificationIconStyle,
      silentSpeedThresholdKb: silentSpeedThresholdKb ?? this.silentSpeedThresholdKb,
      aodModeEnabled: aodModeEnabled ?? this.aodModeEnabled,
      homeDefaultNetworkType: homeDefaultNetworkType ??
          overviewDefaultNetworkType ??
          this.homeDefaultNetworkType,
    );
  }
}

/// Reactive settings and user preferences repository backed by [SharedPreferences].
class PreferencesRepository {
  PreferencesRepository({
    required this._prefs,
    this._bridge,
  }) {
    _stateController = StreamController<UserPreferences>.broadcast();
    _currentPreferences = _loadFromPrefs();
  }

  final SharedPreferences _prefs;
  final NativeTrafficBridge? _bridge;
  late final StreamController<UserPreferences> _stateController;
  late UserPreferences _currentPreferences;

  /// Current cached user preferences snapshot.
  UserPreferences get current => _currentPreferences;

  /// Reactive stream of preference changes.
  Stream<UserPreferences> get preferencesStream => _stateController.stream;

  UserPreferences _loadFromPrefs() {
    final hasCompletedOnboarding = _prefs.getBool(AppConstants.prefHasCompletedOnboarding) ?? false;
    final speedUnitBits = _prefs.getBool(AppConstants.prefSpeedUnitBits) ?? false;
    final metric1000 = _prefs.getBool(AppConstants.prefMetricBase1000) ?? true;
    final themeStr = _prefs.getString(AppConstants.prefThemeMode) ?? 'auto';
    final blur = _prefs.getBool(AppConstants.prefEnableBlur) ?? true;
    final notifEnabled = _prefs.getBool(AppConstants.prefPersistentNotification) ?? true;
    final iconStyleStr = _prefs.getString(AppConstants.prefNotificationIconStyle) ?? 'combined';
    final silentKb = _prefs.getInt(AppConstants.prefSilentSpeedThresholdKb) ?? 0;
    final aod = _prefs.getBool(AppConstants.prefAodModeEnabled) ?? false;
    final homeTypeStr = _prefs.getString(AppConstants.prefHomeDefaultType) ??
        _prefs.getString(AppConstants.prefOverviewDefaultType) ??
        'mobile';

    return UserPreferences(
      hasCompletedOnboarding: hasCompletedOnboarding,
      speedUnitType: speedUnitBits ? SpeedUnitType.bits : SpeedUnitType.bytes,
      metricBase: metric1000 ? MetricBase.decimal1000 : MetricBase.binary1024,
      themeMode: ThemeModePreference.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => ThemeModePreference.auto,
      ),
      enableBlur: blur,
      persistentNotificationEnabled: notifEnabled,
      notificationIconStyle: NotificationIconStyle.values.firstWhere(
        (e) => e.name == iconStyleStr,
        orElse: () => NotificationIconStyle.combined,
      ),
      silentSpeedThresholdKb: silentKb,
      aodModeEnabled: aod,
      homeDefaultNetworkType: NetworkType.values.firstWhere(
        (e) => e.name == homeTypeStr,
        orElse: () => NetworkType.mobile,
      ),
    );
  }

  void _emitUpdate(UserPreferences newPrefs) {
    _currentPreferences = newPrefs;
    _stateController.add(newPrefs);
    _syncWithNativeService();
  }

  Future<void> _syncWithNativeService() async {
    if (_bridge != null) {
      await _bridge.updateServiceSettings(
        inBits: _currentPreferences.speedUnitType == SpeedUnitType.bits,
        separateUpDown:
            _currentPreferences.notificationIconStyle == NotificationIconStyle.separateUpDown,
        metric1000: _currentPreferences.metricBase == MetricBase.decimal1000,
        aodMode: _currentPreferences.aodModeEnabled,
        speedThresholdKb: _currentPreferences.silentSpeedThresholdKb,
      );
    }
  }

  /// Sets the speed unit format (Bits vs Bytes).
  Future<void> setSpeedUnitType(SpeedUnitType type) async {
    await _prefs.setBool(AppConstants.prefSpeedUnitBits, type == SpeedUnitType.bits);
    _emitUpdate(_currentPreferences.copyWith(speedUnitType: type));
  }

  /// Sets the metric base (Decimal 1000 vs Binary 1024).
  Future<void> setMetricBase(MetricBase base) async {
    await _prefs.setBool(AppConstants.prefMetricBase1000, base == MetricBase.decimal1000);
    _emitUpdate(_currentPreferences.copyWith(metricBase: base));
  }

  /// Sets the theme mode appearance.
  Future<void> setThemeMode(ThemeModePreference mode) async {
    await _prefs.setString(AppConstants.prefThemeMode, mode.name);
    _emitUpdate(_currentPreferences.copyWith(themeMode: mode));
  }

  /// Enables or disables frosted glass backdrop blur.
  Future<void> setEnableBlur(bool enable) async {
    await _prefs.setBool(AppConstants.prefEnableBlur, enable);
    _emitUpdate(_currentPreferences.copyWith(enableBlur: enable));
  }

  /// Master switch for persistent foreground speed meter notification.
  Future<void> setPersistentNotificationEnabled(bool enable) async {
    await _prefs.setBool(AppConstants.prefPersistentNotification, enable);
    if (enable) {
      await _bridge?.startForegroundService();
    } else {
      await _bridge?.stopForegroundService();
    }
    _emitUpdate(_currentPreferences.copyWith(persistentNotificationEnabled: enable));
  }

  /// Sets the status bar speed notification icon format.
  Future<void> setNotificationIconStyle(NotificationIconStyle style) async {
    await _prefs.setString(AppConstants.prefNotificationIconStyle, style.name);
    _emitUpdate(_currentPreferences.copyWith(notificationIconStyle: style));
  }

  /// Sets the minimum speed in KB/s below which the status icon auto-hides.
  Future<void> setSilentSpeedThresholdKb(int thresholdKb) async {
    await _prefs.setInt(AppConstants.prefSilentSpeedThresholdKb, thresholdKb);
    _emitUpdate(_currentPreferences.copyWith(silentSpeedThresholdKb: thresholdKb));
  }

  /// Sets whether the meter continues polling when the screen is locked.
  Future<void> setAodModeEnabled(bool enable) async {
    await _prefs.setBool(AppConstants.prefAodModeEnabled, enable);
    _emitUpdate(_currentPreferences.copyWith(aodModeEnabled: enable));
  }

  /// Sets the default network type shown on the home dashboard.
  Future<void> setHomeDefaultNetworkType(NetworkType type) async {
    await _prefs.setString(AppConstants.prefHomeDefaultType, type.name);
    _emitUpdate(_currentPreferences.copyWith(homeDefaultNetworkType: type));
  }

  /// Backward-compatible alias for [setHomeDefaultNetworkType].
  Future<void> setOverviewDefaultNetworkType(NetworkType type) async {
    await setHomeDefaultNetworkType(type);
  }

  /// Sets whether the user has completed the first-run onboarding setup wizard.
  Future<void> setHasCompletedOnboarding(bool completed) async {
    await _prefs.setBool(AppConstants.prefHasCompletedOnboarding, completed);
    _emitUpdate(_currentPreferences.copyWith(hasCompletedOnboarding: completed));
  }

  /// Resets all user preferences to factory defaults.
  Future<void> resetToDefaults() async {
    await _prefs.remove(AppConstants.prefSpeedUnitBits);
    await _prefs.remove(AppConstants.prefMetricBase1000);
    await _prefs.remove(AppConstants.prefThemeMode);
    await _prefs.remove(AppConstants.prefEnableBlur);
    await _prefs.remove(AppConstants.prefPersistentNotification);
    await _prefs.remove(AppConstants.prefNotificationIconStyle);
    await _prefs.remove(AppConstants.prefSilentSpeedThresholdKb);
    await _prefs.remove(AppConstants.prefAodModeEnabled);
    await _prefs.remove(AppConstants.prefHomeDefaultType);
    await _prefs.remove(AppConstants.prefOverviewDefaultType);
    _emitUpdate(const UserPreferences());
  }

  void dispose() {
    _stateController.close();
  }
}
