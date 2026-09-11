import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/enums.dart';
import '../../data/models/traffic_snapshot.dart';
import '../../data/repositories/network_usage_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../charts/app_usage_bar_chart.dart';
import '../charts/weekly_bar_chart.dart';
import 'overview_state.dart';

/// StateNotifier ViewModel orchestrating the Overview Dashboard metrics,
/// predictive mathematical models, live speed updates, and weekly analytics.
class OverviewController extends StateNotifier<OverviewState> {
  OverviewController({
    required this.usageRepo,
    required this.prefsRepo,
  }) : super(OverviewState(
          selectedNetworkType: prefsRepo.current.overviewDefaultNetworkType,
        )) {
    loadDashboardData();
  }

  final NetworkUsageRepository usageRepo;
  final PreferencesRepository prefsRepo;

  /// Loads or refreshes all dashboard metrics concurrently.
  Future<void> loadDashboardData({
    bool refresh = false,
    DateTime? referenceTime,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final now = referenceTime ?? DateTime.now();
      final hasPerm = await usageRepo.hasUsagePermission();

      // Today usage
      final todayUsage = await usageRepo.getTodayUsage(
        networkType: state.selectedNetworkType,
        now: now,
      );

      // 4-Week weighted prediction
      final predictedBytes = await calculate4WeekPrediction(
        now: now,
        networkType: state.selectedNetworkType,
        todayUsageBytes: todayUsage.totalBytes,
      );

      // 7-Day moving average trend
      final trendPercentage = await calculate7DayTrend(
        now: now,
        networkType: state.selectedNetworkType,
      );

      // Weekly Mon-Sun breakdown
      final weekData = await _loadWeeklyBreakdown(now: now);

      // Top apps today
      final topApps = await _loadTopApps(
        now: now,
        networkType: state.selectedNetworkType,
      );

      // Determine today's weekday index (0 = Mon ... 6 = Sun)
      final currentWeekdayIndex = now.weekday - 1;

      state = state.copyWith(
        todayUsage: todayUsage,
        predictedBytes: predictedBytes,
        trendPercentage: trendPercentage,
        weekData: weekData,
        selectedDayIndex: currentWeekdayIndex,
        topApps: topApps,
        hasUsagePermission: hasPerm,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard metrics: $e',
      );
    }
  }

  /// Changes the active network interface and reloads interface-specific metrics.
  Future<void> setNetworkType(NetworkType networkType) async {
    if (state.selectedNetworkType == networkType) return;

    state = state.copyWith(selectedNetworkType: networkType);
    await prefsRepo.setOverviewDefaultNetworkType(networkType);
    await loadDashboardData();
  }

  /// Updates the currently selected/highlighted day in the weekly bar chart.
  void selectDay(int? dayIndex) {
    state = state.copyWith(selectedDayIndex: dayIndex);
  }

  /// Checks and updates Android Usage Access permission state.
  Future<bool> checkPermissions() async {
    final hasPerm = await usageRepo.hasUsagePermission();
    state = state.copyWith(hasUsagePermission: hasPerm);
    return hasPerm;
  }

  /// Requests Usage Access permission from Android Settings.
  Future<bool> requestUsagePermission() async {
    final requested = await usageRepo.requestUsagePermission();
    await checkPermissions();
    return requested;
  }

  /// Injects an instantaneous sub-second speed snapshot from the platform stream.
  void updateLiveSpeed(TrafficSnapshot snapshot) {
    state = state.copyWith(currentSpeed: snapshot);
  }

  /// Launches an application by package name.
  Future<bool> launchApp(String packageName) {
    return usageRepo.launchApp(packageName);
  }

  /// Mathematical Model 1: 4-Week Weighted Hour-Ratio Prediction
  ///
  /// $$\text{Prediction} = \text{TodayUsage} + \left(\text{Last24hUsage} \times \left(\frac{\sum_{i=1}^4 \text{FullDayUsage}_{t-i\cdot 7d}}{\sum_{i=1}^4 \text{ElapsedDayUsage}_{t-i\cdot 7d}} - 1\right)\right)$$
  ///
  /// Fallback: If historical data is zero, extrapolates linearly: $\text{TodayUsage} \times \frac{1440}{\text{ElapsedMinutes}}$.
  Future<int> calculate4WeekPrediction({
    required DateTime now,
    required NetworkType networkType,
    required int todayUsageBytes,
    String? subscriberId,
  }) async {
    int fullDaySum = 0;
    int elapsedDaySum = 0;

    for (int i = 1; i <= 4; i++) {
      final pastDate = now.subtract(Duration(days: i * 7));
      final pastStart = AppDateUtils.startOfDay(pastDate);
      final pastEnd = AppDateUtils.endOfDay(pastDate);
      final pastElapsed = DateTime(
        pastDate.year,
        pastDate.month,
        pastDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      final fullDay = await usageRepo.getPeriodUsage(
        startTime: pastStart,
        endTime: pastEnd,
        networkType: networkType,
        subscriberId: subscriberId,
      );

      final elapsedDay = await usageRepo.getPeriodUsage(
        startTime: pastStart,
        endTime: pastElapsed,
        networkType: networkType,
        subscriberId: subscriberId,
      );

      fullDaySum += fullDay.totalBytes;
      elapsedDaySum += elapsedDay.totalBytes;
    }

    if (elapsedDaySum > 0 && fullDaySum >= elapsedDaySum) {
      final double ratio = fullDaySum / elapsedDaySum;
      final last24h = await usageRepo.getPeriodUsage(
        startTime: now.subtract(const Duration(hours: 24)),
        endTime: now,
        networkType: networkType,
        subscriberId: subscriberId,
      );

      final predicted = todayUsageBytes + (last24h.totalBytes * (ratio - 1)).round();
      return math.max(predicted, todayUsageBytes);
    }

    // Fallback: Linear extrapolation based on minutes elapsed today
    final int elapsedMinutes = math.max(now.hour * 60 + now.minute, 1);
    final double extrapolationFactor = 1440.0 / elapsedMinutes;
    final fallbackPrediction = (todayUsageBytes * extrapolationFactor).round();
    return math.max(fallbackPrediction, todayUsageBytes);
  }

  /// Mathematical Model 2: 7-Day Moving Trend Percentage
  ///
  /// $$\text{Trend \%} = \left(\frac{\text{HourlyAvg}_{\text{last 24h}}}{\max(\text{HourlyAvg}_{\text{prior 6 days}}, 1.0)} - 1\right) \times 100$$
  Future<double> calculate7DayTrend({
    required DateTime now,
    required NetworkType networkType,
    String? subscriberId,
  }) async {
    final last24h = await usageRepo.getPeriodUsage(
      startTime: now.subtract(const Duration(hours: 24)),
      endTime: now,
      networkType: networkType,
      subscriberId: subscriberId,
    );

    final prior6Days = await usageRepo.getPeriodUsage(
      startTime: now.subtract(const Duration(hours: 24 * 7)),
      endTime: now.subtract(const Duration(hours: 24)),
      networkType: networkType,
      subscriberId: subscriberId,
    );

    final double hourlyAvgLast24h = last24h.totalBytes / 24.0;
    final double hourlyAvgPrior6Days = prior6Days.totalBytes / 144.0; // 6 days * 24h = 144h

    if (hourlyAvgPrior6Days <= 0 && hourlyAvgLast24h <= 0) {
      return 0.0;
    }

    final double baseline = math.max(hourlyAvgPrior6Days, 1.0);
    final double trend = ((hourlyAvgLast24h / baseline) - 1.0) * 100.0;
    return double.parse(trend.toStringAsFixed(1));
  }

  /// Loads 7-day Monday through Sunday stacked usage for the active week.
  Future<List<WeeklyDayData>> _loadWeeklyBreakdown({
    required DateTime now,
  }) async {
    final int currentWeekday = now.weekday; // 1 = Monday ... 7 = Sunday
    final monday = AppDateUtils.startOfDay(now.subtract(Duration(days: currentWeekday - 1)));
    final todayMidnight = AppDateUtils.startOfDay(now);

    final weekDays = <WeeklyDayData>[];

    for (int d = 0; d < 7; d++) {
      final dayDate = monday.add(Duration(days: d));

      if (dayDate.isAfter(todayMidnight)) {
        // Future days in current week have 0 usage
        weekDays.add(WeeklyDayData(
          date: dayDate,
          cellularBytes: 0,
          wifiBytes: 0,
        ));
      } else {
        final cellUsage = await usageRepo.getDayUsage(
          date: dayDate,
          networkType: NetworkType.mobile,
        );
        final wifiUsage = await usageRepo.getDayUsage(
          date: dayDate,
          networkType: NetworkType.wifi,
        );

        weekDays.add(WeeklyDayData(
          date: dayDate,
          cellularBytes: cellUsage.totalBytes,
          wifiBytes: wifiUsage.totalBytes,
        ));
      }
    }

    return weekDays;
  }

  /// Loads top bandwidth consuming applications today.
  Future<List<AppUsageBarData>> _loadTopApps({
    required DateTime now,
    required NetworkType networkType,
  }) async {
    final breakdown = await usageRepo.getAppBreakdown(
      startTime: AppDateUtils.startOfDay(now),
      endTime: now,
      networkType: networkType,
    );

    return breakdown.take(5).map((app) {
      return AppUsageBarData(
        uid: app.appInfo.uid,
        appName: app.appInfo.label,
        packageName: app.appInfo.packageName,
        bytes: app.totalBytes,
        iconBytes: app.appInfo.iconBytes,
      );
    }).toList(growable: false);
  }
}

/// Riverpod StateNotifierProvider for [OverviewController].
final overviewControllerProvider =
    StateNotifierProvider.autoDispose<OverviewController, OverviewState>((ref) {
  final usageRepo = ref.watch(networkUsageRepositoryProvider);
  final prefsRepo = ref.watch(preferencesRepositoryProvider);
  return OverviewController(usageRepo: usageRepo, prefsRepo: prefsRepo);
});
