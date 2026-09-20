import 'package:flutter/foundation.dart';
import '../../data/models/traffic_snapshot.dart';
import '../../data/models/usage_data.dart';
import '../charts/weekly_bar_chart.dart';

/// Immutable UI state for the ByteMeter Home dashboard.
@immutable
class HomeState {
  HomeState({
    UsageData? todayMobileUsage,
    UsageData? todayWifiUsage,
    this.totalMonthCellularBytes = 0,
    this.totalMonthWifiBytes = 0,
    this.weekData = const <WeeklyDayData>[],
    this.selectedDayIndex,
    TrafficSnapshot? currentSpeed,
    this.hasUsagePermission = true,
    this.isLoading = false,
    this.isTodayUsageLoading = false,
    this.isWeeklyLoading = false,
    this.isMonthlyLoading = false,
    this.errorMessage,
  })  : todayMobileUsage = todayMobileUsage ?? UsageData(),
        todayWifiUsage = todayWifiUsage ?? UsageData(),
        currentSpeed = currentSpeed ?? TrafficSnapshot.zero();

  /// Today's cellular bandwidth usage.
  final UsageData todayMobileUsage;

  /// Today's Wi-Fi bandwidth usage.
  final UsageData todayWifiUsage;

  /// Total cellular bandwidth consumed across the current month.
  final int totalMonthCellularBytes;

  /// Total Wi-Fi bandwidth consumed across the current month.
  final int totalMonthWifiBytes;

  /// 7-day Monday through Sunday stacked usage breakdown for the current week.
  final List<WeeklyDayData> weekData;

  /// Highlighted day index in the weekly bar chart (0 = Monday ... 6 = Sunday).
  final int? selectedDayIndex;

  /// Instantaneous sub-second transfer rate snapshot.
  final TrafficSnapshot currentSpeed;

  /// Whether Android Usage Access permission has been granted.
  final bool hasUsagePermission;

  /// Whether any dashboard metric is actively loading or refreshing.
  final bool isLoading;

  /// Whether today's primary usage metric is actively loading.
  final bool isTodayUsageLoading;

  /// Whether the weekly stacked bar chart breakdown is actively loading.
  final bool isWeeklyLoading;

  /// Whether the monthly usage totals are actively loading.
  final bool isMonthlyLoading;

  /// Optional error message if an operation failed.
  final String? errorMessage;

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
    UsageData? todayMobileUsage,
    UsageData? todayWifiUsage,
    int? totalMonthCellularBytes,
    int? totalMonthWifiBytes,
    List<WeeklyDayData>? weekData,
    int? selectedDayIndex,
    bool clearSelectedDay = false,
    TrafficSnapshot? currentSpeed,
    bool? hasUsagePermission,
    bool? isLoading,
    bool? isTodayUsageLoading,
    bool? isWeeklyLoading,
    bool? isMonthlyLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    final nextTodayLoading = isTodayUsageLoading ?? this.isTodayUsageLoading;
    final nextWeeklyLoading = isWeeklyLoading ?? this.isWeeklyLoading;
    final nextMonthlyLoading = isMonthlyLoading ?? this.isMonthlyLoading;
    final nextOverallLoading = isLoading ??
        (nextTodayLoading || nextWeeklyLoading || nextMonthlyLoading);

    return HomeState(
      todayMobileUsage: todayMobileUsage ?? this.todayMobileUsage,
      todayWifiUsage: todayWifiUsage ?? this.todayWifiUsage,
      totalMonthCellularBytes: totalMonthCellularBytes ?? this.totalMonthCellularBytes,
      totalMonthWifiBytes: totalMonthWifiBytes ?? this.totalMonthWifiBytes,
      weekData: weekData ?? this.weekData,
      selectedDayIndex: clearSelectedDay ? null : (selectedDayIndex ?? this.selectedDayIndex),
      currentSpeed: currentSpeed ?? this.currentSpeed,
      hasUsagePermission: hasUsagePermission ?? this.hasUsagePermission,
      isLoading: nextOverallLoading,
      isTodayUsageLoading: nextTodayLoading,
      isWeeklyLoading: nextWeeklyLoading,
      isMonthlyLoading: nextMonthlyLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          runtimeType == other.runtimeType &&
          todayMobileUsage == other.todayMobileUsage &&
          todayWifiUsage == other.todayWifiUsage &&
          totalMonthCellularBytes == other.totalMonthCellularBytes &&
          totalMonthWifiBytes == other.totalMonthWifiBytes &&
          listEquals(weekData, other.weekData) &&
          selectedDayIndex == other.selectedDayIndex &&
          currentSpeed == other.currentSpeed &&
          hasUsagePermission == other.hasUsagePermission &&
          isLoading == other.isLoading &&
          isTodayUsageLoading == other.isTodayUsageLoading &&
          isWeeklyLoading == other.isWeeklyLoading &&
          isMonthlyLoading == other.isMonthlyLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        todayMobileUsage,
        todayWifiUsage,
        totalMonthCellularBytes,
        totalMonthWifiBytes,
        Object.hashAll(weekData),
        selectedDayIndex,
        currentSpeed,
        hasUsagePermission,
        isLoading,
        isTodayUsageLoading,
        isWeeklyLoading,
        isMonthlyLoading,
        errorMessage,
      );

  @override
  String toString() {
    return 'HomeState(todayMobile: $todayMobileUsage, todayWifi: $todayWifiUsage, monthCell: $totalMonthCellularBytes, monthWifi: $totalMonthWifiBytes, loading: $isLoading, todayLoading: $isTodayUsageLoading, weeklyLoading: $isWeeklyLoading, monthlyLoading: $isMonthlyLoading)';
  }
}

/// Backward compatibility alias
typedef OverviewState = HomeState;
