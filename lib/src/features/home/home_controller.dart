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
import 'home_state.dart';

/// StateNotifier ViewModel orchestrating the Home Dashboard metrics,
/// predictive mathematical models, live speed updates, and weekly analytics.
class HomeController extends StateNotifier<HomeState> {
  HomeController({
    required this.usageRepo,
    required this.prefsRepo,
  }) : super(HomeState(
          selectedNetworkType: prefsRepo.current.homeDefaultNetworkType,
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

      // Launch independent queries concurrently
      final hasPermFuture = usageRepo.hasUsagePermission();
      final todayUsageFuture = usageRepo.getTodayUsage(
        networkType: state.selectedNetworkType,
        now: now,
      );
      final trendFuture = calculate7DayTrend(
        now: now,
        networkType: state.selectedNetworkType,
      );
      final weekDataFuture = _loadWeeklyBreakdown(now: now);
      final topAppsFuture = _loadTopApps(
        now: now,
        networkType: state.selectedNetworkType,
      );

      final hasPerm = await hasPermFuture;
      if (hasPerm != state.hasUsagePermission) {
        state = state.copyWith(hasUsagePermission: hasPerm);
      }
      final todayUsage = await todayUsageFuture;

      final predictedBytesFuture = calculate4WeekPrediction(
        now: now,
        networkType: state.selectedNetworkType,
        todayUsageBytes: todayUsage.totalBytes,
      );

      final results = await Future.wait([
        predictedBytesFuture,
        trendFuture,
        weekDataFuture,
        topAppsFuture,
      ]);

      final predictedBytes = results[0] as int;
      final trendPercentage = results[1] as double;
      final weekData = results[2] as List<WeeklyDayData>;
      final topApps = results[3] as List<AppUsageBarData>;

      // Determine today's weekday index (0 = Mon ... 6 = Sun)
      final currentWeekdayIndex = now.weekday - 1;

      state = state.copyWith(
        todayUsage: todayUsage,
        predictedBytes: predictedBytes,
        trendPercentage: trendPercentage,
        weekData: weekData,
        selectedDayIndex: state.selectedDayIndex ?? currentWeekdayIndex,
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
    await prefsRepo.setHomeDefaultNetworkType(networkType);
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

    // Concurrently query all 4 historical weeks in parallel to eliminate sequential IPC delays
    final weekFutures = List.generate(4, (index) {
      final i = index + 1;
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

      return Future.wait([
        usageRepo.getPeriodUsage(
          startTime: pastStart,
          endTime: pastEnd,
          networkType: networkType,
          subscriberId: subscriberId,
        ),
        usageRepo.getPeriodUsage(
          startTime: pastStart,
          endTime: pastElapsed,
          networkType: networkType,
          subscriberId: subscriberId,
        ),
      ]);
    });

    final weekResults = await Future.wait(weekFutures);
    for (final pair in weekResults) {
      fullDaySum += pair[0].totalBytes;
      elapsedDaySum += pair[1].totalBytes;
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
    // Run last24h and prior6Days queries in parallel
    final usages = await Future.wait([
      usageRepo.getPeriodUsage(
        startTime: now.subtract(const Duration(hours: 24)),
        endTime: now,
        networkType: networkType,
        subscriberId: subscriberId,
      ),
      usageRepo.getPeriodUsage(
        startTime: now.subtract(const Duration(hours: 24 * 7)),
        endTime: now.subtract(const Duration(hours: 24)),
        networkType: networkType,
        subscriberId: subscriberId,
      ),
    ]);

    final last24h = usages[0];
    final prior6Days = usages[1];

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

    final weekDayFutures = List.generate(7, (d) async {
      final dayDate = monday.add(Duration(days: d));

      if (dayDate.isAfter(todayMidnight)) {
        // Future days in current week have 0 usage
        return WeeklyDayData(
          date: dayDate,
          cellularBytes: 0,
          wifiBytes: 0,
        );
      } else {
        final usages = await Future.wait([
          usageRepo.getDayUsage(date: dayDate, networkType: NetworkType.mobile),
          usageRepo.getDayUsage(date: dayDate, networkType: NetworkType.wifi),
        ]);

        return WeeklyDayData(
          date: dayDate,
          cellularBytes: usages[0].totalBytes,
          wifiBytes: usages[1].totalBytes,
        );
      }
    });

    return Future.wait(weekDayFutures);
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

    final top5 = breakdown.take(5).toList();
    // Resolve icons only for the 5 top apps rendered on the dashboard
    return Future.wait(
      top5.map((app) async {
        final infoWithIcon = await usageRepo.getAppInfo(app.appInfo.uid, loadIcon: true);
        return AppUsageBarData(
          uid: infoWithIcon.uid,
          appName: infoWithIcon.label,
          packageName: infoWithIcon.packageName,
          bytes: app.totalBytes,
          iconBytes: infoWithIcon.iconBytes,
        );
      }),
    );
  }
}

/// Riverpod StateNotifierProvider for [HomeController].
final homeControllerProvider =
    StateNotifierProvider.autoDispose<HomeController, HomeState>((ref) {
  final usageRepo = ref.watch(networkUsageRepositoryProvider);
  final prefsRepo = ref.watch(preferencesRepositoryProvider);
  return HomeController(usageRepo: usageRepo, prefsRepo: prefsRepo);
});

/// Backward compatibility alias
typedef OverviewController = HomeController;
final overviewControllerProvider = homeControllerProvider;
