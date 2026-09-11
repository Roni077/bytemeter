import 'dart:math';
import '../../core/constants/special_uids.dart';
import '../../core/native/native_traffic_bridge.dart';
import '../../core/utils/date_utils.dart';
import '../models/app_info.dart';
import '../models/app_usage.dart';
import '../models/enums.dart';
import '../models/usage_data.dart';

/// Repository abstracting network statistics queries, app caching, and delta reconciliation.
class NetworkUsageRepository {
  NetworkUsageRepository({
    required this._bridge,
  });

  final NativeTrafficBridge _bridge;

  // In-memory cache of installed apps by UID
  final Map<int, AppInfo> _appCache = <int, AppInfo>{};
  bool _appsLoaded = false;

  /// Fetches all installed apps, caching them in-memory.
  Future<List<AppInfo>> getInstalledApps({bool refresh = false}) async {
    if (_appsLoaded && !refresh && _appCache.isNotEmpty) {
      return _appCache.values.toList(growable: false);
    }

    final apps = await _bridge.getInstalledApps();
    _appCache.clear();
    for (final app in apps) {
      _appCache[app.uid] = app;
    }
    _appsLoaded = true;
    return apps;
  }

  /// Retrieves cached app info for a specific UID, or generates a fallback descriptor.
  Future<AppInfo> getAppInfo(int uid) async {
    if (!_appsLoaded) {
      await getInstalledApps();
    }

    if (_appCache.containsKey(uid)) {
      return _appCache[uid]!;
    }

    // Special UID fallbacks
    if (uid == SpecialUids.uidAll) {
      return const AppInfo(uid: SpecialUids.uidAll, packageName: 'all', label: 'All Applications', isSpecial: true);
    } else if (uid == SpecialUids.uidTethering) {
      return const AppInfo(uid: SpecialUids.uidTethering, packageName: 'tethering', label: 'Tethering & Hotspot', isSpecial: true);
    } else if (uid == SpecialUids.uidRemoved) {
      return const AppInfo(uid: SpecialUids.uidRemoved, packageName: 'removed', label: 'Removed Apps', isSpecial: true);
    } else if (uid == SpecialUids.uidOtherUsers) {
      return const AppInfo(uid: SpecialUids.uidOtherUsers, packageName: 'other_users', label: 'Other Users & System', isSpecial: true);
    }

    return AppInfo(uid: uid, packageName: 'uid_$uid', label: 'UID $uid', isSpecial: uid < 0);
  }

  /// Queries aggregated device traffic for Today (midnight to current time).
  Future<UsageData> getTodayUsage({
    required NetworkType networkType,
    String? subscriberId,
    List<int> excludedUids = const <int>[],
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final start = AppDateUtils.startOfDay(current);
    return getPeriodUsage(
      startTime: start,
      endTime: current,
      networkType: networkType,
      subscriberId: subscriberId,
      excludedUids: excludedUids,
    );
  }

  /// Queries aggregated device traffic for a specific full calendar [date].
  Future<UsageData> getDayUsage({
    required DateTime date,
    required NetworkType networkType,
    String? subscriberId,
    List<int> excludedUids = const <int>[],
  }) async {
    final start = AppDateUtils.startOfDay(date);
    final end = AppDateUtils.endOfDay(date);
    return getPeriodUsage(
      startTime: start,
      endTime: end,
      networkType: networkType,
      subscriberId: subscriberId,
      excludedUids: excludedUids,
    );
  }

  /// Queries aggregated device traffic across a custom time interval.
  Future<UsageData> getPeriodUsage({
    required DateTime startTime,
    required DateTime endTime,
    required NetworkType networkType,
    String? subscriberId,
    List<int> excludedUids = const <int>[],
  }) async {
    if (excludedUids.isEmpty) {
      return _bridge.queryDeviceSummary(
        networkType: networkType,
        subscriberId: subscriberId,
        startTime: startTime,
        endTime: endTime,
      );
    }

    // When zero-rated / excluded UIDs are present, aggregate app buckets and subtract excluded
    final appBuckets = await _bridge.queryAppBuckets(
      networkType: networkType,
      subscriberId: subscriberId,
      startTime: startTime,
      endTime: endTime,
    );

    int totalUp = 0;
    int totalDown = 0;
    for (final bucket in appBuckets) {
      if (bucket.uid != null && !excludedUids.contains(bucket.uid)) {
        totalUp += bucket.uploadBytes;
        totalDown += bucket.downloadBytes;
      }
    }

    return UsageData(
      uploadBytes: totalUp,
      downloadBytes: totalDown,
      totalBytes: totalUp + totalDown,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Fetches daily usage totals for the last 90 calendar days.
  Future<List<UsageData>> getHistory90Days({
    required NetworkType networkType,
    String? subscriberId,
    List<int> excludedUids = const <int>[],
    DateTime? referenceDate,
  }) async {
    final days = AppDateUtils.get90DayRange(referenceDate);
    final results = <UsageData>[];

    for (final day in days) {
      final usage = await getDayUsage(
        date: day,
        networkType: networkType,
        subscriberId: subscriberId,
        excludedUids: excludedUids,
      );
      results.add(usage);
    }

    return results;
  }

  /// Fetches ranked per-app bandwidth consumption for a given time window.
  Future<List<AppUsage>> getAppBreakdown({
    required DateTime startTime,
    required DateTime endTime,
    required NetworkType networkType,
    String? subscriberId,
    List<int> excludedUids = const <int>[],
  }) async {
    final rawBuckets = await _bridge.queryAppBuckets(
      networkType: networkType,
      subscriberId: subscriberId,
      startTime: startTime,
      endTime: endTime,
    );

    final deviceTotal = await _bridge.queryDeviceSummary(
      networkType: networkType,
      subscriberId: subscriberId,
      startTime: startTime,
      endTime: endTime,
    );

    // Reconcile unaccounted device delta to UID_OTHER_USERS
    final reconciledDelta = reconcileDeviceDelta(deviceTotal, rawBuckets);
    final allBuckets = List<UsageData>.from(rawBuckets);
    if (reconciledDelta != null && reconciledDelta.totalBytes > 0) {
      allBuckets.add(reconciledDelta);
    }

    int peakBytes = 0;
    for (final bucket in allBuckets) {
      if (bucket.totalBytes > peakBytes) {
        peakBytes = bucket.totalBytes;
      }
    }

    final appUsages = <AppUsage>[];
    for (final bucket in allBuckets) {
      final uid = bucket.uid ?? SpecialUids.uidUnknown;
      final isExcluded = excludedUids.contains(uid);
      if (isExcluded) continue;

      final appInfo = await getAppInfo(uid);
      final percentage = peakBytes > 0 ? (bucket.totalBytes / peakBytes).clamp(0.0, 1.0) : 0.0;

      appUsages.add(
        AppUsage(
          appInfo: appInfo,
          primaryBytes: bucket.downloadBytes,
          secondaryBytes: bucket.uploadBytes,
          totalBytes: bucket.totalBytes,
          percentage: percentage,
          usageData: bucket,
        ),
      );
    }

    // Sort descending by total data consumed
    appUsages.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return appUsages;
  }

  /// Fetches 2-hour interval time-slot buckets for a given calendar [date].
  Future<List<UsageData>> getHourlyBuckets({
    required DateTime date,
    required NetworkType networkType,
    String? subscriberId,
    int? uid,
  }) async {
    final start = AppDateUtils.startOfDay(date);
    final end = AppDateUtils.endOfDay(date);

    return _bridge.queryHourlyBuckets(
      networkType: networkType,
      subscriberId: subscriberId,
      startTime: start,
      endTime: end,
      uid: uid,
    );
  }

  /// Launches an application by its package name.
  Future<bool> launchApp(String packageName) => _bridge.launchApp(packageName);

  /// Checks if Usage Access permission is granted.
  Future<bool> hasUsagePermission() => _bridge.hasUsagePermission();

  /// Requests Usage Access permission from system settings.
  Future<bool> requestUsagePermission() => _bridge.requestUsagePermission();

  /// Reconciles the difference between device aggregate total and per-UID buckets to [SpecialUids.uidOtherUsers].
  UsageData? reconcileDeviceDelta(UsageData deviceTotal, List<UsageData> appBuckets) {
    int sumUp = 0;
    int sumDown = 0;

    for (final bucket in appBuckets) {
      sumUp += bucket.uploadBytes;
      sumDown += bucket.downloadBytes;
    }

    final deltaUp = max(deviceTotal.uploadBytes - sumUp, 0);
    final deltaDown = max(deviceTotal.downloadBytes - sumDown, 0);
    final totalDelta = deltaUp + deltaDown;

    if (totalDelta <= 0) return null;

    return UsageData(
      uid: SpecialUids.uidOtherUsers,
      uploadBytes: deltaUp,
      downloadBytes: deltaDown,
      totalBytes: totalDelta,
      startTime: deviceTotal.startTime,
      endTime: deviceTotal.endTime,
    );
  }
}
