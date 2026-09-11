import 'package:flutter/foundation.dart';
import '../../data/models/app_info.dart';
import '../../data/models/app_usage.dart';
import '../../data/models/enums.dart';
import '../../data/models/usage_data.dart';
import '../charts/scrollable_bar_chart.dart';

/// Tab selection for history detail breakdown views.
enum HistoryViewTab {
  apps('Apps Breakdown'),
  hours('2-Hour Intervals');

  const HistoryViewTab(this.displayName);

  final String displayName;
}

/// Query configuration for primary or secondary timeline filtering and comparison.
@immutable
class HistoryQuery {
  const HistoryQuery({
    this.networkType = NetworkType.mobile,
    this.direction = DataDirection.bidirectional,
    this.appUid,
    this.appInfo,
  });

  /// Network interface filter (null represents All/Combined networks).
  final NetworkType? networkType;

  /// Traffic flow direction filter.
  final DataDirection direction;

  /// Application UID filter (null represents All Applications).
  final int? appUid;

  /// Cached app metadata when [appUid] is active.
  final AppInfo? appInfo;

  /// Whether this query covers all installed applications.
  bool get isAllApps => appUid == null;

  /// User-facing descriptive summary label.
  String get label {
    final netLabel = networkType != null ? networkType!.displayName : 'All Networks';
    final dirLabel = direction == DataDirection.bidirectional ? '' : ' (${direction.displayName})';
    final appLabel = appInfo != null
        ? ' · ${appInfo!.label}'
        : (appUid != null ? ' · UID $appUid' : '');
    return '$netLabel$dirLabel$appLabel';
  }

  HistoryQuery copyWith({
    NetworkType? Function()? networkType,
    DataDirection? direction,
    int? Function()? appUid,
    AppInfo? Function()? appInfo,
  }) {
    return HistoryQuery(
      networkType: networkType != null ? networkType() : this.networkType,
      direction: direction ?? this.direction,
      appUid: appUid != null ? appUid() : this.appUid,
      appInfo: appInfo != null ? appInfo() : this.appInfo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryQuery &&
          runtimeType == other.runtimeType &&
          networkType == other.networkType &&
          direction == other.direction &&
          appUid == other.appUid &&
          appInfo == other.appInfo;

  @override
  int get hashCode => Object.hash(networkType, direction, appUid, appInfo);

  @override
  String toString() => 'HistoryQuery(net: $networkType, dir: $direction, app: $appUid)';
}

/// Aggregated usage for a 2-hour time slot bucket (e.g. 14:00 - 16:00).
@immutable
class HourBucketData {
  const HourBucketData({
    required this.startHour,
    required this.endHour,
    required this.primaryBytes,
    this.secondaryBytes = 0,
    required this.totalBytes,
    this.usageData,
  });

  final int startHour;
  final int endHour;
  final int primaryBytes;
  final int secondaryBytes;
  final int totalBytes;
  final UsageData? usageData;

  String get timeLabel =>
      '${startHour.toString().padLeft(2, '0')}:00 – ${endHour.toString().padLeft(2, '0')}:00';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HourBucketData &&
          runtimeType == other.runtimeType &&
          startHour == other.startHour &&
          endHour == other.endHour &&
          primaryBytes == other.primaryBytes &&
          secondaryBytes == other.secondaryBytes &&
          totalBytes == other.totalBytes;

  @override
  int get hashCode => Object.hash(startHour, endHour, primaryBytes, secondaryBytes, totalBytes);
}

/// Immutable state for the History screen.
@immutable
class HistoryState {
  const HistoryState({
    this.timelineData = const <DailyHistoryData>[],
    required this.selectedDate,
    this.primaryQuery = const HistoryQuery(
      networkType: NetworkType.mobile,
      direction: DataDirection.bidirectional,
    ),
    this.secondaryQuery = const HistoryQuery(
      networkType: NetworkType.wifi,
      direction: DataDirection.bidirectional,
    ),
    this.isComparisonEnabled = true,
    this.appBreakdown = const <AppUsage>[],
    this.hourlyBuckets = const <HourBucketData>[],
    this.activeTab = HistoryViewTab.apps,
    this.installedApps = const <AppInfo>[],
    this.isLoadingTimeline = false,
    this.isLoadingDetails = false,
    this.errorMessage,
  });

  /// 90 consecutive days of daily historical usage records.
  final List<DailyHistoryData> timelineData;

  /// Currently selected calendar date in the timeline.
  final DateTime selectedDate;

  /// Primary query filter configuration.
  final HistoryQuery primaryQuery;

  /// Secondary comparison query filter configuration.
  final HistoryQuery secondaryQuery;

  /// Whether dual-query comparison is enabled.
  final bool isComparisonEnabled;

  /// Ranked application bandwidth consumption for [selectedDate].
  final List<AppUsage> appBreakdown;

  /// 12 two-hour time buckets for [selectedDate].
  final List<HourBucketData> hourlyBuckets;

  /// Currently active sub-tab (Apps vs. Hours).
  final HistoryViewTab activeTab;

  /// Cached list of installed applications for search modal.
  final List<AppInfo> installedApps;

  /// Loading state for the 90-day timeline graph.
  final bool isLoadingTimeline;

  /// Loading state for date-specific breakdown details.
  final bool isLoadingDetails;

  /// Error message if an operation failed.
  final String? errorMessage;

  /// Total bytes consumed on [selectedDate] matching active primary query.
  int get selectedDatePrimaryBytes {
    final dayData = timelineData.where(
      (d) =>
          d.date.year == selectedDate.year &&
          d.date.month == selectedDate.month &&
          d.date.day == selectedDate.day,
    );
    if (dayData.isEmpty) return 0;
    return dayData.first.primaryQueryBytes ?? dayData.first.cellularBytes;
  }

  /// Total bytes consumed on [selectedDate] matching active secondary query.
  int get selectedDateSecondaryBytes {
    if (!isComparisonEnabled) return 0;
    final dayData = timelineData.where(
      (d) =>
          d.date.year == selectedDate.year &&
          d.date.month == selectedDate.month &&
          d.date.day == selectedDate.day,
    );
    if (dayData.isEmpty) return 0;
    return dayData.first.secondaryQueryBytes ?? dayData.first.wifiBytes;
  }

  /// Combined total bytes for [selectedDate].
  int get selectedDateTotalBytes {
    if (isComparisonEnabled) {
      return selectedDatePrimaryBytes + selectedDateSecondaryBytes;
    }
    return selectedDatePrimaryBytes;
  }

  /// Whether a specific application filter is currently applied to the primary query.
  bool get hasAppFilter => primaryQuery.appUid != null;

  HistoryState copyWith({
    List<DailyHistoryData>? timelineData,
    DateTime? selectedDate,
    HistoryQuery? primaryQuery,
    HistoryQuery? secondaryQuery,
    bool? isComparisonEnabled,
    List<AppUsage>? appBreakdown,
    List<HourBucketData>? hourlyBuckets,
    HistoryViewTab? activeTab,
    List<AppInfo>? installedApps,
    bool? isLoadingTimeline,
    bool? isLoadingDetails,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      timelineData: timelineData ?? this.timelineData,
      selectedDate: selectedDate ?? this.selectedDate,
      primaryQuery: primaryQuery ?? this.primaryQuery,
      secondaryQuery: secondaryQuery ?? this.secondaryQuery,
      isComparisonEnabled: isComparisonEnabled ?? this.isComparisonEnabled,
      appBreakdown: appBreakdown ?? this.appBreakdown,
      hourlyBuckets: hourlyBuckets ?? this.hourlyBuckets,
      activeTab: activeTab ?? this.activeTab,
      installedApps: installedApps ?? this.installedApps,
      isLoadingTimeline: isLoadingTimeline ?? this.isLoadingTimeline,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
