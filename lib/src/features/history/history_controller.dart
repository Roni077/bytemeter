import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/app_info.dart';
import '../../data/models/app_usage.dart';
import '../../data/models/enums.dart';
import '../../data/models/usage_data.dart';
import '../../data/repositories/network_usage_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../charts/scrollable_bar_chart.dart';
import 'history_state.dart';

/// ViewModel orchestrating 90-day timeline queries, dual comparison filters,
/// ranked per-app bandwidth usage, and 2-hour interval time buckets.
class HistoryController extends StateNotifier<HistoryState> {
  HistoryController({
    required this.usageRepo,
    required this.prefsRepo,
  }) : super(HistoryState(
          selectedDate: AppDateUtils.startOfDay(DateTime.now()),
        )) {
    loadInitialData();
  }

  final NetworkUsageRepository usageRepo;
  final PreferencesRepository prefsRepo;

  /// Loads installed apps, 90-day timeline history, and day breakdown details concurrently.
  Future<void> loadInitialData({
    bool refresh = false,
    DateTime? referenceDate,
  }) async {
    state = state.copyWith(
      isLoadingTimeline: true,
      isLoadingDetails: true,
      clearError: true,
    );

    try {
      final now = referenceDate ?? DateTime.now();
      final todayMidnight = AppDateUtils.startOfDay(now);

      // 1. Cache installed apps
      final apps = await usageRepo.getInstalledApps(refresh: refresh);

      // 2. Load 90-day timeline data
      final timeline = await _build90DayTimeline(
        referenceDate: todayMidnight,
        primaryQuery: state.primaryQuery,
        secondaryQuery: state.secondaryQuery,
        isComparisonEnabled: state.isComparisonEnabled,
      );

      state = state.copyWith(
        installedApps: apps,
        timelineData: timeline,
        selectedDate: todayMidnight,
        isLoadingTimeline: false,
      );

      // 3. Load breakdown details for selected date
      await loadDetailsForSelectedDate(todayMidnight);
    } catch (e) {
      state = state.copyWith(
        isLoadingTimeline: false,
        isLoadingDetails: false,
        errorMessage: 'Failed to load history data: $e',
      );
    }
  }

  Timer? _dateSelectDebounce;

  @override
  void dispose() {
    _dateSelectDebounce?.cancel();
    super.dispose();
  }

  /// Updates the centered/selected date and fetches day-specific app and hour breakdowns.
  Future<void> selectDate(DateTime date, {bool debounce = false}) async {
    final normalizedDate = AppDateUtils.startOfDay(date);
    if (state.selectedDate.year == normalizedDate.year &&
        state.selectedDate.month == normalizedDate.month &&
        state.selectedDate.day == normalizedDate.day &&
        state.appBreakdown.isNotEmpty) {
      return;
    }

    state = state.copyWith(selectedDate: normalizedDate);

    if (debounce) {
      _dateSelectDebounce?.cancel();
      final completer = Completer<void>();
      _dateSelectDebounce = Timer(const Duration(milliseconds: 150), () async {
        await loadDetailsForSelectedDate(normalizedDate);
        if (!completer.isCompleted) completer.complete();
      });
      return completer.future;
    } else {
      _dateSelectDebounce?.cancel();
      await loadDetailsForSelectedDate(normalizedDate);
    }
  }

  /// Loads ranked app breakdown and 2-hour interval buckets for [date].
  Future<void> loadDetailsForSelectedDate(DateTime date) async {
    state = state.copyWith(isLoadingDetails: true, clearError: true);

    try {
      final start = AppDateUtils.startOfDay(date);
      final end = AppDateUtils.endOfDay(date);

      // A. Load Per-App Breakdown
      final appBreakdown = await _loadAppBreakdownForDate(
        start: start,
        end: end,
        primaryQuery: state.primaryQuery,
        secondaryQuery: state.secondaryQuery,
        isComparisonEnabled: state.isComparisonEnabled,
      );

      // B. Load 2-Hour Interval Buckets (12 slots)
      final hourlyBuckets = await _loadHourlyBucketsForDate(
        date: start,
        primaryQuery: state.primaryQuery,
        secondaryQuery: state.secondaryQuery,
        isComparisonEnabled: state.isComparisonEnabled,
      );

      state = state.copyWith(
        appBreakdown: appBreakdown,
        hourlyBuckets: hourlyBuckets,
        isLoadingDetails: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingDetails: false,
        errorMessage: 'Failed to load date details: $e',
      );
    }
  }

  /// Updates the primary timeline filter and recalculates the 90-day history graph.
  Future<void> updatePrimaryQuery(HistoryQuery query) async {
    if (state.primaryQuery == query) return;

    state = state.copyWith(
      primaryQuery: query,
      isLoadingTimeline: true,
      isLoadingDetails: true,
    );

    final timeline = await _build90DayTimeline(
      referenceDate: state.selectedDate,
      primaryQuery: query,
      secondaryQuery: state.secondaryQuery,
      isComparisonEnabled: state.isComparisonEnabled,
    );

    state = state.copyWith(
      timelineData: timeline,
      isLoadingTimeline: false,
    );

    await loadDetailsForSelectedDate(state.selectedDate);
  }

  /// Updates the secondary comparison query and comparison enabled state.
  Future<void> updateSecondaryQuery(
    HistoryQuery query, {
    bool? isComparisonEnabled,
  }) async {
    final enabled = isComparisonEnabled ?? state.isComparisonEnabled;
    if (state.secondaryQuery == query && state.isComparisonEnabled == enabled) return;

    state = state.copyWith(
      secondaryQuery: query,
      isComparisonEnabled: enabled,
      isLoadingTimeline: true,
      isLoadingDetails: true,
    );

    final timeline = await _build90DayTimeline(
      referenceDate: state.selectedDate,
      primaryQuery: state.primaryQuery,
      secondaryQuery: query,
      isComparisonEnabled: enabled,
    );

    state = state.copyWith(
      timelineData: timeline,
      isLoadingTimeline: false,
    );

    await loadDetailsForSelectedDate(state.selectedDate);
  }

  /// Isolates the entire 90-day history timeline and breakdown to a specific application.
  Future<void> setQuickFilterApp(AppInfo app) async {
    final updatedPrimary = state.primaryQuery.copyWith(
      appUid: () => app.uid,
      appInfo: () => app,
    );
    await updatePrimaryQuery(updatedPrimary);
  }

  /// Clears active application filter, restoring All Applications view.
  Future<void> clearAppFilter() async {
    final updatedPrimary = state.primaryQuery.copyWith(
      appUid: () => null,
      appInfo: () => null,
    );
    await updatePrimaryQuery(updatedPrimary);
  }

  /// Resets primary and secondary filters to default system settings.
  Future<void> resetFilters() async {
    state = state.copyWith(
      primaryQuery: const HistoryQuery(
        networkType: NetworkType.mobile,
        direction: DataDirection.bidirectional,
      ),
      secondaryQuery: const HistoryQuery(
        networkType: NetworkType.wifi,
        direction: DataDirection.bidirectional,
      ),
      isComparisonEnabled: true,
      isLoadingTimeline: true,
    );

    final timeline = await _build90DayTimeline(
      referenceDate: state.selectedDate,
      primaryQuery: state.primaryQuery,
      secondaryQuery: state.secondaryQuery,
      isComparisonEnabled: state.isComparisonEnabled,
    );

    state = state.copyWith(
      timelineData: timeline,
      isLoadingTimeline: false,
    );

    await loadDetailsForSelectedDate(state.selectedDate);
  }

  /// Switches active sub-tab between Apps Breakdown and 2-Hour Intervals.
  void switchViewTab(HistoryViewTab tab) {
    if (state.activeTab == tab) return;
    state = state.copyWith(activeTab: tab);
  }

  /// Launches an external application by package name.
  Future<bool> launchApp(String packageName) {
    return usageRepo.launchApp(packageName);
  }

  // ===========================================================================
  // PRIVATE COMPUTATION & REPOSITORY PIPELINES
  // ===========================================================================

  /// Builds 90 consecutive daily data points with query-specific byte mapping.
  Future<List<DailyHistoryData>> _build90DayTimeline({
    required DateTime referenceDate,
    required HistoryQuery primaryQuery,
    required HistoryQuery secondaryQuery,
    required bool isComparisonEnabled,
  }) async {
    final days = AppDateUtils.get90DayRange(referenceDate);
    final results = <DailyHistoryData>[];

    // Optimize: when not querying a single app, use high-speed batch platform call
    if (primaryQuery.appUid == null && (!isComparisonEnabled || secondaryQuery.appUid == null)) {
      final batchData = await usageRepo.getCombinedTimeline90Days(
        referenceDate: referenceDate,
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

        for (final day in days) {
          final key = day.year * 10000 + day.month * 100 + day.day;
          final item = batchMap[key];

          final cellUp = (item?['cellUpload'] as num?)?.toInt() ?? 0;
          final cellDown = (item?['cellDownload'] as num?)?.toInt() ?? 0;
          final cellTot = (item?['cellTotal'] as num?)?.toInt() ?? (cellUp + cellDown);

          final wifiUp = (item?['wifiUpload'] as num?)?.toInt() ?? 0;
          final wifiDown = (item?['wifiDownload'] as num?)?.toInt() ?? 0;
          final wifiTot = (item?['wifiTotal'] as num?)?.toInt() ?? (wifiUp + wifiDown);

          final mobileUsage = UsageData(
            uploadBytes: cellUp,
            downloadBytes: cellDown,
            totalBytes: cellTot,
            startTime: day,
            endTime: AppDateUtils.endOfDay(day),
          );
          final wifiUsage = UsageData(
            uploadBytes: wifiUp,
            downloadBytes: wifiDown,
            totalBytes: wifiTot,
            startTime: day,
            endTime: AppDateUtils.endOfDay(day),
          );

          final cellBytes = _filterUsageByDirection(mobileUsage, primaryQuery.direction);
          final wifiBytes = _filterUsageByDirection(wifiUsage, primaryQuery.direction);

          int primaryBytes;
          if (primaryQuery.networkType == NetworkType.mobile) {
            primaryBytes = cellBytes;
          } else if (primaryQuery.networkType == NetworkType.wifi) {
            primaryBytes = wifiBytes;
          } else {
            primaryBytes = cellBytes + wifiBytes;
          }

          int? secondaryBytes;
          if (isComparisonEnabled) {
            final secCell = _filterUsageByDirection(mobileUsage, secondaryQuery.direction);
            final secWifi = _filterUsageByDirection(wifiUsage, secondaryQuery.direction);

            if (secondaryQuery.networkType == NetworkType.mobile) {
              secondaryBytes = secCell;
            } else if (secondaryQuery.networkType == NetworkType.wifi) {
              secondaryBytes = secWifi;
            } else {
              secondaryBytes = secCell + secWifi;
            }
          }

          results.add(
            DailyHistoryData(
              date: day,
              cellularBytes: cellBytes,
              wifiBytes: wifiBytes,
              primaryQueryBytes: primaryBytes,
              secondaryQueryBytes: isComparisonEnabled ? secondaryBytes : null,
            ),
          );
        }

        return results;
      }
    }

    // Fallback: parallel day querying (for app-specific filters or fallback)
    final dayFutures = days.map((day) async {
      int cellBytes = 0;
      int wifiBytes = 0;
      int primaryBytes = 0;
      int secondaryBytes = 0;

      if (primaryQuery.appUid != null || (isComparisonEnabled && secondaryQuery.appUid != null)) {
        // App-specific timeline queries
        primaryBytes = await _queryBytesForCustomQuery(
          query: primaryQuery,
          date: day,
        );

        if (isComparisonEnabled) {
          secondaryBytes = await _queryBytesForCustomQuery(
            query: secondaryQuery,
            date: day,
          );
        }

        return DailyHistoryData(
          date: day,
          cellularBytes: primaryBytes,
          wifiBytes: secondaryBytes,
          primaryQueryBytes: primaryBytes,
          secondaryQueryBytes: isComparisonEnabled ? secondaryBytes : 0,
        );
      } else {
        // Aggregate device timeline queries
        final usages = await Future.wait([
          usageRepo.getDayUsage(
            date: day,
            networkType: NetworkType.mobile,
          ),
          usageRepo.getDayUsage(
            date: day,
            networkType: NetworkType.wifi,
          ),
        ]);

        final mobileUsage = usages[0];
        final wifiUsage = usages[1];

        cellBytes = _filterUsageByDirection(mobileUsage, primaryQuery.direction);
        wifiBytes = _filterUsageByDirection(wifiUsage, primaryQuery.direction);

        // Map primary query
        if (primaryQuery.networkType == NetworkType.mobile) {
          primaryBytes = cellBytes;
        } else if (primaryQuery.networkType == NetworkType.wifi) {
          primaryBytes = wifiBytes;
        } else {
          primaryBytes = cellBytes + wifiBytes;
        }

        // Map secondary query
        if (isComparisonEnabled) {
          final secCell = _filterUsageByDirection(mobileUsage, secondaryQuery.direction);
          final secWifi = _filterUsageByDirection(wifiUsage, secondaryQuery.direction);

          if (secondaryQuery.networkType == NetworkType.mobile) {
            secondaryBytes = secCell;
          } else if (secondaryQuery.networkType == NetworkType.wifi) {
            secondaryBytes = secWifi;
          } else {
            secondaryBytes = secCell + secWifi;
          }
        }

        return DailyHistoryData(
          date: day,
          cellularBytes: cellBytes,
          wifiBytes: wifiBytes,
          primaryQueryBytes: primaryBytes,
          secondaryQueryBytes: isComparisonEnabled ? secondaryBytes : null,
        );
      }
    });

    return Future.wait(dayFutures);
  }

  /// Calculates total bytes for a specific custom query on a calendar day.
  Future<int> _queryBytesForCustomQuery({
    required HistoryQuery query,
    required DateTime date,
  }) async {
    final start = AppDateUtils.startOfDay(date);

    if (query.networkType == null) {
      // Both Mobile & Wi-Fi
      final mobileBuckets = await usageRepo.getHourlyBuckets(
        date: start,
        networkType: NetworkType.mobile,
        uid: query.appUid,
      );
      final wifiBuckets = await usageRepo.getHourlyBuckets(
        date: start,
        networkType: NetworkType.wifi,
        uid: query.appUid,
      );

      int total = 0;
      for (final b in [...mobileBuckets, ...wifiBuckets]) {
        total += _filterUsageByDirection(b, query.direction);
      }
      return total;
    } else {
      final buckets = await usageRepo.getHourlyBuckets(
        date: start,
        networkType: query.networkType!,
        uid: query.appUid,
      );

      int total = 0;
      for (final b in buckets) {
        total += _filterUsageByDirection(b, query.direction);
      }
      return total;
    }
  }

  /// Loads and formats ranked app breakdown for a given date window.
  Future<List<AppUsage>> _loadAppBreakdownForDate({
    required DateTime start,
    required DateTime end,
    required HistoryQuery primaryQuery,
    required HistoryQuery secondaryQuery,
    required bool isComparisonEnabled,
  }) async {
    // 1. Query primary buckets
    List<AppUsage> primaryApps = [];
    if (primaryQuery.networkType == null) {
      final mobileApps = await usageRepo.getAppBreakdown(
        startTime: start,
        endTime: end,
        networkType: NetworkType.mobile,
      );
      final wifiApps = await usageRepo.getAppBreakdown(
        startTime: start,
        endTime: end,
        networkType: NetworkType.wifi,
      );
      primaryApps = _mergeAppUsageLists(mobileApps, wifiApps);
    } else {
      primaryApps = await usageRepo.getAppBreakdown(
        startTime: start,
        endTime: end,
        networkType: primaryQuery.networkType!,
      );
    }

    // Filter by specific app if quick-filter is active
    if (primaryQuery.appUid != null) {
      primaryApps = primaryApps
          .where((app) => app.appInfo.uid == primaryQuery.appUid)
          .toList(growable: false);
    }

    if (!isComparisonEnabled) {
      return primaryApps;
    }

    // 2. Query secondary comparison buckets if dual comparison is active
    List<AppUsage> secondaryApps = [];
    if (secondaryQuery.networkType == null) {
      final secMobile = await usageRepo.getAppBreakdown(
        startTime: start,
        endTime: end,
        networkType: NetworkType.mobile,
      );
      final secWifi = await usageRepo.getAppBreakdown(
        startTime: start,
        endTime: end,
        networkType: NetworkType.wifi,
      );
      secondaryApps = _mergeAppUsageLists(secMobile, secWifi);
    } else {
      secondaryApps = await usageRepo.getAppBreakdown(
        startTime: start,
        endTime: end,
        networkType: secondaryQuery.networkType!,
      );
    }

    final secondaryMap = {for (final a in secondaryApps) a.appInfo.uid: a};
    final combined = <AppUsage>[];

    // Merge primary and secondary into side-by-side comparative AppUsage objects
    for (final pApp in primaryApps) {
      final sApp = secondaryMap[pApp.appInfo.uid];
      final primBytes = _filterAppBytesByDirection(pApp, primaryQuery.direction);
      final secBytes = sApp != null ? _filterAppBytesByDirection(sApp, secondaryQuery.direction) : 0;
      final total = primBytes + secBytes;

      combined.add(
        AppUsage(
          appInfo: pApp.appInfo,
          primaryBytes: primBytes,
          secondaryBytes: secBytes,
          totalBytes: total,
          percentage: pApp.percentage,
        ),
      );
    }

    // Include any apps only present in secondary query
    for (final sApp in secondaryApps) {
      if (!primaryApps.any((p) => p.appInfo.uid == sApp.appInfo.uid)) {
        if (primaryQuery.appUid == null || sApp.appInfo.uid == primaryQuery.appUid) {
          final secBytes = _filterAppBytesByDirection(sApp, secondaryQuery.direction);
          combined.add(
            AppUsage(
              appInfo: sApp.appInfo,
              primaryBytes: 0,
              secondaryBytes: secBytes,
              totalBytes: secBytes,
              percentage: sApp.percentage,
            ),
          );
        }
      }
    }

    // Calculate maximum usage for percentage scaling
    int maxTotal = 1;
    for (final app in combined) {
      if (app.totalBytes > maxTotal) {
        maxTotal = app.totalBytes;
      }
    }

    final ranked = combined.map((app) {
      final pct = (app.totalBytes / maxTotal).clamp(0.0, 1.0);
      return app.copyWith(percentage: pct);
    }).toList();

    ranked.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return ranked;
  }

  /// Loads 12 two-hour time buckets (00:00-02:00, 02:00-04:00, etc.) for a specific day.
  Future<List<HourBucketData>> _loadHourlyBucketsForDate({
    required DateTime date,
    required HistoryQuery primaryQuery,
    required HistoryQuery secondaryQuery,
    required bool isComparisonEnabled,
  }) async {
    final start = AppDateUtils.startOfDay(date);

    // 1. Query primary hourly buckets
    List<UsageData> primaryHourly = [];
    if (primaryQuery.networkType == null) {
      final mBuckets = await usageRepo.getHourlyBuckets(
        date: start,
        networkType: NetworkType.mobile,
        uid: primaryQuery.appUid,
      );
      final wBuckets = await usageRepo.getHourlyBuckets(
        date: start,
        networkType: NetworkType.wifi,
        uid: primaryQuery.appUid,
      );
      primaryHourly = _mergeHourlyBuckets(mBuckets, wBuckets);
    } else {
      primaryHourly = await usageRepo.getHourlyBuckets(
        date: start,
        networkType: primaryQuery.networkType!,
        uid: primaryQuery.appUid,
      );
    }

    // 2. Query secondary hourly buckets if comparison active
    List<UsageData> secondaryHourly = [];
    if (isComparisonEnabled) {
      if (secondaryQuery.networkType == null) {
        final secMBuckets = await usageRepo.getHourlyBuckets(
          date: start,
          networkType: NetworkType.mobile,
          uid: secondaryQuery.appUid,
        );
        final secWBuckets = await usageRepo.getHourlyBuckets(
          date: start,
          networkType: NetworkType.wifi,
          uid: secondaryQuery.appUid,
        );
        secondaryHourly = _mergeHourlyBuckets(secMBuckets, secWBuckets);
      } else {
        secondaryHourly = await usageRepo.getHourlyBuckets(
          date: start,
          networkType: secondaryQuery.networkType!,
          uid: secondaryQuery.appUid,
        );
      }
    }

    // 3. Aggregate into 12 two-hour bins
    final List<HourBucketData> slots = [];
    for (int slot = 0; slot < 12; slot++) {
      final startH = slot * 2;
      final endH = startH + 2;

      int primBytes = 0;
      int secBytes = 0;

      // Sum primary buckets matching this 2-hour window
      for (final b in primaryHourly) {
        final bHour = b.startTime.hour;
        if (bHour >= startH && bHour < endH) {
          primBytes += _filterUsageByDirection(b, primaryQuery.direction);
        }
      }

      // Sum secondary buckets
      if (isComparisonEnabled) {
        for (final b in secondaryHourly) {
          final bHour = b.startTime.hour;
          if (bHour >= startH && bHour < endH) {
            secBytes += _filterUsageByDirection(b, secondaryQuery.direction);
          }
        }
      }

      slots.add(
        HourBucketData(
          startHour: startH,
          endHour: endH,
          primaryBytes: primBytes,
          secondaryBytes: secBytes,
          totalBytes: isComparisonEnabled ? (primBytes + secBytes) : primBytes,
        ),
      );
    }

    return slots;
  }

  int _filterUsageByDirection(UsageData data, DataDirection direction) {
    switch (direction) {
      case DataDirection.download:
        return data.downloadBytes;
      case DataDirection.upload:
        return data.uploadBytes;
      case DataDirection.bidirectional:
        return data.totalBytes;
    }
  }

  int _filterAppBytesByDirection(AppUsage app, DataDirection direction) {
    switch (direction) {
      case DataDirection.download:
        return app.primaryBytes;
      case DataDirection.upload:
        return app.secondaryBytes;
      case DataDirection.bidirectional:
        return app.totalBytes;
    }
  }

  List<AppUsage> _mergeAppUsageLists(List<AppUsage> list1, List<AppUsage> list2) {
    final Map<int, AppUsage> map = {};
    for (final app in list1) {
      map[app.appInfo.uid] = app;
    }
    for (final app in list2) {
      final existing = map[app.appInfo.uid];
      if (existing != null) {
        map[app.appInfo.uid] = existing.copyWith(
          primaryBytes: existing.primaryBytes + app.primaryBytes,
          secondaryBytes: existing.secondaryBytes + app.secondaryBytes,
          totalBytes: existing.totalBytes + app.totalBytes,
        );
      } else {
        map[app.appInfo.uid] = app;
      }
    }
    return map.values.toList();
  }

  List<UsageData> _mergeHourlyBuckets(List<UsageData> list1, List<UsageData> list2) {
    final Map<int, UsageData> map = {};
    for (final b in list1) {
      map[b.startTime.hour] = b;
    }
    for (final b in list2) {
      final existing = map[b.startTime.hour];
      if (existing != null) {
        map[b.startTime.hour] = existing.copyWith(
          uploadBytes: existing.uploadBytes + b.uploadBytes,
          downloadBytes: existing.downloadBytes + b.downloadBytes,
          totalBytes: existing.totalBytes + b.totalBytes,
        );
      } else {
        map[b.startTime.hour] = b;
      }
    }
    return map.values.toList();
  }
}

/// Riverpod StateNotifierProvider for [HistoryController].
final historyControllerProvider =
    StateNotifierProvider.autoDispose<HistoryController, HistoryState>((ref) {
  final usageRepo = ref.watch(networkUsageRepositoryProvider);
  final prefsRepo = ref.watch(preferencesRepositoryProvider);
  return HistoryController(usageRepo: usageRepo, prefsRepo: prefsRepo);
});
