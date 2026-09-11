import 'package:flutter/foundation.dart';
import 'app_info.dart';
import 'usage_data.dart';

/// Aggregated usage metrics for a specific application target in ranked usage lists.
@immutable
class AppUsage implements Comparable<AppUsage> {
  const AppUsage({
    required this.appInfo,
    required this.primaryBytes,
    this.secondaryBytes = 0,
    int? totalBytes,
    this.percentage = 0.0,
    this.usageData,
  }) : totalBytes = totalBytes ?? (primaryBytes + secondaryBytes);

  final AppInfo appInfo;
  final int primaryBytes;
  final int secondaryBytes;
  final int totalBytes;
  final double percentage;
  final UsageData? usageData;

  AppUsage copyWith({
    AppInfo? appInfo,
    int? primaryBytes,
    int? secondaryBytes,
    int? totalBytes,
    double? percentage,
    UsageData? usageData,
  }) {
    final prim = primaryBytes ?? this.primaryBytes;
    final sec = secondaryBytes ?? this.secondaryBytes;
    return AppUsage(
      appInfo: appInfo ?? this.appInfo,
      primaryBytes: prim,
      secondaryBytes: sec,
      totalBytes: totalBytes ?? (prim + sec),
      percentage: percentage ?? this.percentage,
      usageData: usageData ?? this.usageData,
    );
  }

  @override
  int compareTo(AppUsage other) => other.totalBytes.compareTo(totalBytes); // Descending by total

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUsage &&
          runtimeType == other.runtimeType &&
          appInfo == other.appInfo &&
          primaryBytes == other.primaryBytes &&
          secondaryBytes == other.secondaryBytes &&
          totalBytes == other.totalBytes &&
          percentage == other.percentage;

  @override
  int get hashCode => Object.hash(appInfo, primaryBytes, secondaryBytes, totalBytes, percentage);

  @override
  String toString() =>
      'AppUsage(${appInfo.label} [${appInfo.uid}]: primary=$primaryBytes, sec=$secondaryBytes, total=$totalBytes, pct=${(percentage * 100).toStringAsFixed(1)}%)';
}
