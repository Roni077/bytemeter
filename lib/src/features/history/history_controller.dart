import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/app_usage.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/network_usage_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import 'history_state.dart';

/// ViewModel orchestrating App Data Usages breakdown.
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

  /// Loads installed apps and day breakdown details concurrently.
  Future<void> loadInitialData({
    bool refresh = false,
    DateTime? referenceDate,
  }) async {
    state = state.copyWith(
      isLoadingDetails: true,
      clearError: true,
    );

    try {
      final now = referenceDate ?? DateTime.now();
      final todayMidnight = AppDateUtils.startOfDay(now);

      // 1. Cache installed apps
      final apps = await usageRepo.getInstalledApps(refresh: refresh);

      state = state.copyWith(
        installedApps: apps,
        selectedDate: todayMidnight,
      );

      // 2. Load breakdown details for selected date
      await loadDetailsForSelectedDate(todayMidnight);
    } catch (e) {
      state = state.copyWith(
        isLoadingDetails: false,
        errorMessage: 'Failed to load app data usages: $e',
      );
    }
  }

  Timer? _dateSelectDebounce;

  @override
  void dispose() {
    _dateSelectDebounce?.cancel();
    super.dispose();
  }

  /// Updates the centered/selected date and fetches day-specific app breakdowns.
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

  Future<void> adjustDateByDays(int offset) async {
    final newDate = state.selectedDate.add(Duration(days: offset));
    // Don't allow future dates
    if (newDate.isAfter(DateTime.now())) return;
    await selectDate(newDate);
  }

  /// Changes the active app filter (All, System, User) and reloads the view.
  Future<void> setAppFilter(AppFilterType filter) async {
    if (state.appFilter == filter) return;
    state = state.copyWith(appFilter: filter);
    await loadDetailsForSelectedDate(state.selectedDate);
  }

  /// Loads ranked app breakdown for [date].
  Future<void> loadDetailsForSelectedDate(DateTime date) async {
    state = state.copyWith(isLoadingDetails: true, clearError: true);

    try {
      final start = AppDateUtils.startOfDay(date);
      final end = AppDateUtils.endOfDay(date);

      // Load Per-App Breakdown for both networks
      final appBreakdown = await _loadAppBreakdownForDate(
        start: start,
        end: end,
      );

      state = state.copyWith(
        appBreakdown: appBreakdown,
        isLoadingDetails: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingDetails: false,
        errorMessage: 'Failed to load date details: $e',
      );
    }
  }

  /// Launches an external application by package name.
  Future<bool> launchApp(String packageName) {
    return usageRepo.launchApp(packageName);
  }

  // ===========================================================================
  // PRIVATE COMPUTATION & REPOSITORY PIPELINES
  // ===========================================================================

  /// Loads and formats ranked app breakdown for a given date window, mapping Mobile to primary and Wi-Fi to secondary.
  Future<List<AppUsage>> _loadAppBreakdownForDate({
    required DateTime start,
    required DateTime end,
  }) async {
    final primaryApps = await usageRepo.getAppBreakdown(
      startTime: start,
      endTime: end,
      networkType: NetworkType.mobile,
    );

    final secondaryApps = await usageRepo.getAppBreakdown(
      startTime: start,
      endTime: end,
      networkType: NetworkType.wifi,
    );

    final secondaryMap = {for (final a in secondaryApps) a.appInfo.uid: a};
    final combined = <AppUsage>[];

    // Merge primary and secondary into side-by-side comparative AppUsage objects
    for (final pApp in primaryApps) {
      final sApp = secondaryMap[pApp.appInfo.uid];
      final primBytes = pApp.totalBytes;
      final secBytes = sApp != null ? sApp.totalBytes : 0;
      final total = primBytes + secBytes;

      combined.add(
        AppUsage(
          appInfo: pApp.appInfo,
          primaryBytes: primBytes,
          secondaryBytes: secBytes,
          totalBytes: total,
          percentage: 0.0,
        ),
      );
    }

    // Include any apps only present in secondary query
    for (final sApp in secondaryApps) {
      if (!primaryApps.any((p) => p.appInfo.uid == sApp.appInfo.uid)) {
        final secBytes = sApp.totalBytes;
        combined.add(
          AppUsage(
            appInfo: sApp.appInfo,
            primaryBytes: 0,
            secondaryBytes: secBytes,
            totalBytes: secBytes,
            percentage: 0.0,
          ),
        );
      }
    }

    // Filter by AppFilterType
    final filtered = combined.where((app) {
      if (state.appFilter == AppFilterType.system) {
        return app.appInfo.isSystemApp;
      } else if (state.appFilter == AppFilterType.user) {
        return !app.appInfo.isSystemApp;
      }
      return true; // All
    }).toList();

    // Calculate maximum usage for percentage scaling
    int maxTotal = 1;
    for (final app in filtered) {
      if (app.totalBytes > maxTotal) {
        maxTotal = app.totalBytes;
      }
    }

    final ranked = filtered.map((app) {
      final pct = (app.totalBytes / maxTotal).clamp(0.0, 1.0);
      return app.copyWith(percentage: pct);
    }).toList();

    ranked.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return ranked;
  }
}

/// Riverpod StateNotifierProvider for [HistoryController].
final historyControllerProvider =
    StateNotifierProvider.autoDispose<HistoryController, HistoryState>((ref) {
  final usageRepo = ref.watch(networkUsageRepositoryProvider);
  final prefsRepo = ref.watch(preferencesRepositoryProvider);
  return HistoryController(usageRepo: usageRepo, prefsRepo: prefsRepo);
});
