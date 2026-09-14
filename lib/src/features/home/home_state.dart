import 'package:flutter/foundation.dart';
import '../../data/models/enums.dart';
import '../../data/models/traffic_snapshot.dart';
import '../../data/models/usage_data.dart';
import '../charts/app_usage_bar_chart.dart';
import '../charts/weekly_bar_chart.dart';

/// Immutable UI state for the ByteMeter Home dashboard.
@immutable
class HomeState {
  HomeState({
    this.selectedNetworkType = NetworkType.mobile,
    UsageData? todayUsage,
    this.predictedBytes = 0,
    this.trendPercentage = 0.0,
    this.weekData = const <WeeklyDayData>[],
    this.selectedDayIndex,
    this.topApps = const <AppUsageBarData>[],
    TrafficSnapshot? currentSpeed,
    this.hasUsagePermission = true,
    this.isLoading = false,
    this.isTodayUsageLoading = false,
    this.isTopAppsLoading = false,
    this.isWeeklyLoading = false,
    this.isForecastLoading = false,
    this.errorMessage,
  })  : todayUsage = todayUsage ?? UsageData(),
        currentSpeed = currentSpeed ?? TrafficSnapshot.zero();

  /// Currently selected network interface (Mobile Cellular vs. Wi-Fi).
  final NetworkType selectedNetworkType;

  /// Today's aggregated bandwidth usage.
  final UsageData todayUsage;

  /// End-of-day predicted bandwidth consumption in bytes.
  final int predictedBytes;

  /// 7-day moving average trend percentage (+X% or -X%).
  final double trendPercentage;

  /// 7-day Monday through Sunday stacked usage breakdown for the current week.
  final List<WeeklyDayData> weekData;

  /// Highlighted day index in the weekly bar chart (0 = Monday ... 6 = Sunday).
  final int? selectedDayIndex;

  /// Top bandwidth-consuming apps today.
  final List<AppUsageBarData> topApps;

  /// Instantaneous sub-second transfer rate snapshot.
  final TrafficSnapshot currentSpeed;

  /// Whether Android Usage Access permission has been granted.
  final bool hasUsagePermission;

  /// Whether any dashboard metric is actively loading or refreshing.
  final bool isLoading;

  /// Whether today's primary usage metric is actively loading.
  final bool isTodayUsageLoading;

  /// Whether the top applications preview is actively loading.
  final bool isTopAppsLoading;

  /// Whether the weekly stacked bar chart breakdown is actively loading.
  final bool isWeeklyLoading;

  /// Whether predictive end-of-day forecast and trend metrics are actively loading.
  final bool isForecastLoading;

  /// Optional error message if an operation failed.
  final String? errorMessage;

  /// Whether today's trend indicates an accelerated burn rate compared to baseline.
  bool get isTrendAccelerated => trendPercentage > 0.05;

  /// Whether today's trend indicates a decelerated burn rate compared to baseline.
  bool get isTrendDecelerated => trendPercentage < -0.05;

  /// Total bandwidth consumed across the entire current week.
  int get totalWeekBytes =>
      weekData.fold<int>(0, (sum, day) => sum + day.totalBytes);

  /// Total cellular bandwidth consumed across the current week.
  int get totalWeekCellularBytes =>
      weekData.fold<int>(0, (sum, day) => sum + day.cellularBytes);

  /// Total Wi-Fi bandwidth consumed across the current week.
  int get totalWeekWifiBytes =>
      weekData.fold<int>(0, (sum, day) => sum + day.wifiBytes);

  HomeState copyWith({
    NetworkType? selectedNetworkType,
    UsageData? todayUsage,
    int? predictedBytes,
    double? trendPercentage,
    List<WeeklyDayData>? weekData,
    int? selectedDayIndex,
    bool clearSelectedDay = false,
    List<AppUsageBarData>? topApps,
    TrafficSnapshot? currentSpeed,
    bool? hasUsagePermission,
    bool? isLoading,
    bool? isTodayUsageLoading,
    bool? isTopAppsLoading,
    bool? isWeeklyLoading,
    bool? isForecastLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    final nextTodayLoading = isTodayUsageLoading ?? this.isTodayUsageLoading;
    final nextAppsLoading = isTopAppsLoading ?? this.isTopAppsLoading;
    final nextWeeklyLoading = isWeeklyLoading ?? this.isWeeklyLoading;
    final nextForecastLoading = isForecastLoading ?? this.isForecastLoading;
    final nextOverallLoading = isLoading ??
        (nextTodayLoading || nextAppsLoading || nextWeeklyLoading || nextForecastLoading);

    return HomeState(
      selectedNetworkType: selectedNetworkType ?? this.selectedNetworkType,
      todayUsage: todayUsage ?? this.todayUsage,
      predictedBytes: predictedBytes ?? this.predictedBytes,
      trendPercentage: trendPercentage ?? this.trendPercentage,
      weekData: weekData ?? this.weekData,
      selectedDayIndex: clearSelectedDay ? null : (selectedDayIndex ?? this.selectedDayIndex),
      topApps: topApps ?? this.topApps,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      hasUsagePermission: hasUsagePermission ?? this.hasUsagePermission,
      isLoading: nextOverallLoading,
      isTodayUsageLoading: nextTodayLoading,
      isTopAppsLoading: nextAppsLoading,
      isWeeklyLoading: nextWeeklyLoading,
      isForecastLoading: nextForecastLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          runtimeType == other.runtimeType &&
          selectedNetworkType == other.selectedNetworkType &&
          todayUsage == other.todayUsage &&
          predictedBytes == other.predictedBytes &&
          trendPercentage == other.trendPercentage &&
          listEquals(weekData, other.weekData) &&
          selectedDayIndex == other.selectedDayIndex &&
          listEquals(topApps, other.topApps) &&
          currentSpeed == other.currentSpeed &&
          hasUsagePermission == other.hasUsagePermission &&
          isLoading == other.isLoading &&
          isTodayUsageLoading == other.isTodayUsageLoading &&
          isTopAppsLoading == other.isTopAppsLoading &&
          isWeeklyLoading == other.isWeeklyLoading &&
          isForecastLoading == other.isForecastLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        selectedNetworkType,
        todayUsage,
        predictedBytes,
        trendPercentage,
        Object.hashAll(weekData),
        selectedDayIndex,
        Object.hashAll(topApps),
        currentSpeed,
        hasUsagePermission,
        isLoading,
        isTodayUsageLoading,
        isTopAppsLoading,
        isWeeklyLoading,
        isForecastLoading,
        errorMessage,
      );

  @override
  String toString() {
    return 'HomeState(network: $selectedNetworkType, today: $todayUsage, predicted: $predictedBytes, trend: $trendPercentage%, loading: $isLoading, todayLoading: $isTodayUsageLoading, appsLoading: $isTopAppsLoading, weeklyLoading: $isWeeklyLoading, forecastLoading: $isForecastLoading)';
  }
}

/// Backward compatibility alias
typedef OverviewState = HomeState;
