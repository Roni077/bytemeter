import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/enums.dart';
import '../../data/models/traffic_snapshot.dart';
import '../../data/repositories/network_usage_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../charts/weekly_bar_chart.dart';
import 'home_state.dart';

/// StateNotifier ViewModel orchestrating the Home Dashboard metrics,
/// predictive mathematical models, live speed updates, and weekly analytics.
class HomeController extends StateNotifier<HomeState> {
  HomeController({
    required this.usageRepo,
    required this.prefsRepo,
  }) : super(HomeState()) {
    loadDashboardData();
  }

  final NetworkUsageRepository usageRepo;
  final PreferencesRepository prefsRepo;

  /// Loads dashboard metrics using a progressive pipeline:
  /// - Tier 1: Today's Usage (Mobile & Wi-Fi) & Permissions
  /// - Tier 2: Weekly Breakdown
  /// - Tier 3: Monthly Breakdown
  Future<void> loadDashboardData({
    bool refresh = false,
    DateTime? referenceTime,
  }) async {
    final now = referenceTime ?? DateTime.now();
    final currentWeekdayIndex = now.weekday - 1;

    state = state.copyWith(
      isLoading: true,
      isTodayUsageLoading: true,
      isWeeklyLoading: true,
      isMonthlyLoading: true,
      clearError: true,
    );

    try {
      // -----------------------------------------------------------------------
      // TIER 1: CRITICAL IMMEDIATE HERO LOAD (< 30ms)
      // -----------------------------------------------------------------------
      final hasPerm = await usageRepo.hasUsagePermission();
      if (hasPerm != state.hasUsagePermission) {
        state = state.copyWith(hasUsagePermission: hasPerm);
      }
      if (hasPerm) {
        unawaited(prefsRepo.ensureServiceRunningIfAllowed());
      }
      final todayUsages = await Future.wait([
        usageRepo.getTodayUsage(networkType: NetworkType.mobile, now: now),
        usageRepo.getTodayUsage(networkType: NetworkType.wifi, now: now),
      ]);

      state = state.copyWith(
        todayMobileUsage: todayUsages[0],
        todayWifiUsage: todayUsages[1],
        selectedDayIndex: state.selectedDayIndex ?? currentWeekdayIndex,
        isTodayUsageLoading: false,
      );

      final weeklyFuture = _loadWeeklyBreakdown(now: now).then((weekData) {
        if (mounted) {
          state = state.copyWith(
            weekData: weekData,
            isWeeklyLoading: false,
          );
        }
      }).catchError((e) {
        if (mounted) {
          state = state.copyWith(isWeeklyLoading: false);
        }
      });

      final startOfMonth = DateTime(now.year, now.month, 1);
      final monthFuture = Future.wait([
        usageRepo.getPeriodUsage(startTime: startOfMonth, endTime: now, networkType: NetworkType.mobile),
        usageRepo.getPeriodUsage(startTime: startOfMonth, endTime: now, networkType: NetworkType.wifi),
      ]).then((monthUsages) {
        if (mounted) {
          state = state.copyWith(
            totalMonthCellularBytes: monthUsages[0].totalBytes,
            totalMonthWifiBytes: monthUsages[1].totalBytes,
            isMonthlyLoading: false,
          );
        }
      }).catchError((e) {
        if (mounted) {
          state = state.copyWith(isMonthlyLoading: false);
        }
      });

      await Future.wait([weeklyFuture, monthFuture]);
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          isTodayUsageLoading: false,
          isWeeklyLoading: false,
          isMonthlyLoading: false,
          errorMessage: 'Failed to load dashboard metrics: $e',
        );
      }
    }
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


  /// Loads 7-day Monday through Sunday stacked usage for the active week using batch range query.
  Future<List<WeeklyDayData>> _loadWeeklyBreakdown({
    required DateTime now,
  }) async {
    final int currentWeekday = now.weekday; // 1 = Monday ... 7 = Sunday
    final monday = AppDateUtils.startOfDay(now.subtract(Duration(days: currentWeekday - 1)));
    final sunday = AppDateUtils.endOfDay(monday.add(const Duration(days: 6)));
    final todayMidnight = AppDateUtils.startOfDay(now);

    // High-performance single batch query
    final batchData = await usageRepo.getCombinedTimelineRange(
      startTime: monday,
      endTime: sunday,
    );

    if (batchData.isNotEmpty) {
      final batchMap = <int, Map<String, dynamic>>{};
      for (final item in batchData) {
        final sTime = (item['startTime'] as num?)?.toInt();
        if (sTime != null) {
          final dayDate = DateTime.fromMillisecondsSinceEpoch(sTime);
          final key = dayDate.year * 10000 + dayDate.month * 100 + dayDate.day;
          batchMap[key] = item;
        }
      }

      return List.generate(7, (d) {
        final dayDate = monday.add(Duration(days: d));
        if (dayDate.isAfter(todayMidnight)) {
          return WeeklyDayData(date: dayDate, cellularBytes: 0, wifiBytes: 0);
        }
        final key = dayDate.year * 10000 + dayDate.month * 100 + dayDate.day;
        final item = batchMap[key];
        final cellTot = (item?['cellTotal'] as num?)?.toInt() ??
            (((item?['cellUpload'] as num?)?.toInt() ?? 0) + ((item?['cellDownload'] as num?)?.toInt() ?? 0));
        final wifiTot = (item?['wifiTotal'] as num?)?.toInt() ??
            (((item?['wifiUpload'] as num?)?.toInt() ?? 0) + ((item?['wifiDownload'] as num?)?.toInt() ?? 0));

        return WeeklyDayData(
          date: dayDate,
          cellularBytes: cellTot,
          wifiBytes: wifiTot,
        );
      });
    }

    // Fallback: parallel day querying if batch range query is unsupported in test/fallback
    final weekDayFutures = List.generate(7, (d) async {
      final dayDate = monday.add(Duration(days: d));

      if (dayDate.isAfter(todayMidnight)) {
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
