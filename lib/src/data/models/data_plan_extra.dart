import 'package:flutter/foundation.dart';

/// Data class representing an extra addon data booster pack linked to a primary SIM plan.
@immutable
class DataPlanExtra {
  const DataPlanExtra({
    this.id = 0,
    required this.planHashedSubscriberId,
    required this.extraBytes,
    this.usedBytes = 0,
    required this.startDate,
    required this.expiryDate,
    this.isExpired = false,
    this.note = '',
  });

  final int id;
  final String planHashedSubscriberId;
  final int extraBytes;
  final int usedBytes;
  final DateTime startDate;
  final DateTime expiryDate;
  final bool isExpired;
  final String note;

  /// Remaining bytes left in this addon pack.
  int get remainingBytes => (extraBytes - usedBytes).clamp(0, extraBytes);

  /// Fraction of addon pack consumed (0.0 to 1.0).
  double get usageRatio => extraBytes > 0 ? (usedBytes / extraBytes).clamp(0.0, 1.0) : 0.0;

  /// Checks if this addon pack is currently active and within its valid date range.
  bool isValidAt(DateTime now) {
    if (isExpired) return false;
    return now.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        now.isBefore(expiryDate.add(const Duration(seconds: 1)));
  }

  DataPlanExtra copyWith({
    int? id,
    String? planHashedSubscriberId,
    int? extraBytes,
    int? usedBytes,
    DateTime? startDate,
    DateTime? expiryDate,
    bool? isExpired,
    String? note,
  }) {
    return DataPlanExtra(
      id: id ?? this.id,
      planHashedSubscriberId: planHashedSubscriberId ?? this.planHashedSubscriberId,
      extraBytes: extraBytes ?? this.extraBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isExpired: isExpired ?? this.isExpired,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPlanExtra &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          planHashedSubscriberId == other.planHashedSubscriberId &&
          extraBytes == other.extraBytes &&
          usedBytes == other.usedBytes &&
          startDate == other.startDate &&
          expiryDate == other.expiryDate &&
          isExpired == other.isExpired &&
          note == other.note;

  @override
  int get hashCode => Object.hash(
        id,
        planHashedSubscriberId,
        extraBytes,
        usedBytes,
        startDate,
        expiryDate,
        isExpired,
        note,
      );

  @override
  String toString() =>
      'DataPlanExtra(id: $id, plan: $planHashedSubscriberId, extra: $extraBytes B, used: $usedBytes B, valid: $startDate -> $expiryDate)';
}
