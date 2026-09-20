import 'package:flutter/foundation.dart';
import '../../data/models/app_info.dart';
import '../../data/models/app_usage.dart';

/// Filter to select between all apps, system apps, and user apps.
enum AppFilterType {
  all('All Apps'),
  system('System Apps'),
  user('User Apps');

  const AppFilterType(this.displayName);
  final String displayName;
}

/// Immutable state for the App Data Usages screen.
@immutable
class HistoryState {
  const HistoryState({
    required this.selectedDate,
    this.appFilter = AppFilterType.all,
    this.appBreakdown = const <AppUsage>[],
    this.installedApps = const <AppInfo>[],
    this.isLoadingDetails = false,
    this.errorMessage,
  });

  /// Currently selected calendar date.
  final DateTime selectedDate;

  /// Active application category filter.
  final AppFilterType appFilter;

  /// Ranked application bandwidth consumption for [selectedDate].
  final List<AppUsage> appBreakdown;

  /// Cached list of installed applications.
  final List<AppInfo> installedApps;

  /// Loading state for date-specific breakdown details.
  final bool isLoadingDetails;

  /// Error message if an operation failed.
  final String? errorMessage;

  HistoryState copyWith({
    DateTime? selectedDate,
    AppFilterType? appFilter,
    List<AppUsage>? appBreakdown,
    List<AppInfo>? installedApps,
    bool? isLoadingDetails,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      selectedDate: selectedDate ?? this.selectedDate,
      appFilter: appFilter ?? this.appFilter,
      appBreakdown: appBreakdown ?? this.appBreakdown,
      installedApps: installedApps ?? this.installedApps,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
