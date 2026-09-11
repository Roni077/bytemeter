import 'package:flutter/foundation.dart';
import 'enums.dart';

/// Data class representing a cellular carrier SIM data plan and quota configuration.
@immutable
class DataPlan {
  const DataPlan({
    required this.hashedSubscriberId,
    this.encryptedSubscriberId,
    this.simSlotIndex = 0,
    this.carrierName = '',
    required this.quotaBytes,
    this.billingCycleStartDay = 1,
    this.cycleInterval = TimeIntervalType.monthly,
    this.customIntervalDays = 30,
    this.rolloverEnabled = false,
    this.excludedUids = const <int>[],
    this.cardColorIndex = 0,
    this.customNote = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String hashedSubscriberId;
  final String? encryptedSubscriberId;
  final int simSlotIndex;
  final String carrierName;
  final int quotaBytes;
  final int billingCycleStartDay;
  final TimeIntervalType cycleInterval;
  final int customIntervalDays;
  final bool rolloverEnabled;
  final List<int> excludedUids;
  final int cardColorIndex;
  final String customNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Remaining quota bytes before quota exhaustion.
  int remainingBytes(int usedBytes) => (quotaBytes - usedBytes).clamp(0, quotaBytes);

  /// Whether data usage has exceeded the total quota limit.
  bool isExceeded(int usedBytes) => usedBytes > quotaBytes;

  /// Proportion of quota used (0.0 to 1.0+).
  double usageRatio(int usedBytes) {
    if (quotaBytes <= 0) return 0.0;
    return (usedBytes / quotaBytes).clamp(0.0, 10.0);
  }

  /// Whether a specific application UID is zero-rated / excluded from this data plan.
  bool isAppExcluded(int uid) => excludedUids.contains(uid);

  DataPlan copyWith({
    String? hashedSubscriberId,
    String? encryptedSubscriberId,
    int? simSlotIndex,
    String? carrierName,
    int? quotaBytes,
    int? billingCycleStartDay,
    TimeIntervalType? cycleInterval,
    int? customIntervalDays,
    bool? rolloverEnabled,
    List<int>? excludedUids,
    int? cardColorIndex,
    String? customNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DataPlan(
      hashedSubscriberId: hashedSubscriberId ?? this.hashedSubscriberId,
      encryptedSubscriberId: encryptedSubscriberId ?? this.encryptedSubscriberId,
      simSlotIndex: simSlotIndex ?? this.simSlotIndex,
      carrierName: carrierName ?? this.carrierName,
      quotaBytes: quotaBytes ?? this.quotaBytes,
      billingCycleStartDay: billingCycleStartDay ?? this.billingCycleStartDay,
      cycleInterval: cycleInterval ?? this.cycleInterval,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      excludedUids: excludedUids ?? this.excludedUids,
      cardColorIndex: cardColorIndex ?? this.cardColorIndex,
      customNote: customNote ?? this.customNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPlan &&
          runtimeType == other.runtimeType &&
          hashedSubscriberId == other.hashedSubscriberId &&
          encryptedSubscriberId == other.encryptedSubscriberId &&
          simSlotIndex == other.simSlotIndex &&
          carrierName == other.carrierName &&
          quotaBytes == other.quotaBytes &&
          billingCycleStartDay == other.billingCycleStartDay &&
          cycleInterval == other.cycleInterval &&
          customIntervalDays == other.customIntervalDays &&
          rolloverEnabled == other.rolloverEnabled &&
          listEquals(excludedUids, other.excludedUids) &&
          cardColorIndex == other.cardColorIndex &&
          customNote == other.customNote &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        hashedSubscriberId,
        encryptedSubscriberId,
        simSlotIndex,
        carrierName,
        quotaBytes,
        billingCycleStartDay,
        cycleInterval,
        customIntervalDays,
        rolloverEnabled,
        Object.hashAll(excludedUids),
        cardColorIndex,
        customNote,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'DataPlan($carrierName [SIM $simSlotIndex], quota: $quotaBytes B, startDay: $billingCycleStartDay, interval: $cycleInterval)';
}
