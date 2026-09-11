import 'dart:math';
import '../../core/native/native_traffic_bridge.dart';
import '../database/daos/data_plans_dao.dart';
import '../models/data_plan.dart';
import '../models/data_plan_extra.dart';
import '../models/enums.dart';

/// Repository managing multi-SIM data plans, rollover packs, and budget/safety mathematical models.
class DataPlanRepository {
  DataPlanRepository({
    required this._dao,
    required this._bridge,
  });

  final DataPlansDao _dao;
  final NativeTrafficBridge _bridge;

  /// Streams all configured SIM data plans.
  Stream<List<DataPlan>> watchPlans() => _dao.watchAllPlans();

  /// Fetches all configured SIM data plans.
  Future<List<DataPlan>> getPlans() => _dao.getAllPlans();

  /// Retrieves a data plan by its hashed subscriber ID.
  Future<DataPlan?> getPlanByHashedId(String hashedId) => _dao.getPlanByHashedId(hashedId);

  /// Streams a specific data plan by its hashed subscriber ID.
  Stream<DataPlan?> watchPlanByHashedId(String hashedId) => _dao.watchPlanByHashedId(hashedId);

  /// Saves or updates a SIM data plan, ensuring the subscriber ID is encrypted and hashed.
  Future<void> savePlan(DataPlan plan, {String? rawSubscriberId}) async {
    String hashedId = plan.hashedSubscriberId;
    String? encryptedId = plan.encryptedSubscriberId;

    if (rawSubscriberId != null && rawSubscriberId.isNotEmpty) {
      hashedId = await _bridge.hashSubscriberId(rawSubscriberId);
      encryptedId = await _bridge.encryptSubscriberId(rawSubscriberId);
    }

    final updatedPlan = plan.copyWith(
      hashedSubscriberId: hashedId,
      encryptedSubscriberId: encryptedId,
      updatedAt: DateTime.now(),
    );

    await _dao.insertOrUpdatePlan(updatedPlan);
  }

  /// Deletes a data plan and all associated addon booster packs.
  Future<int> deletePlan(String hashedId) => _dao.deletePlan(hashedId);

  /// Streams addon extra packs for a specific SIM plan.
  Stream<List<DataPlanExtra>> watchExtraPacks(String planHashedId) =>
      _dao.watchExtraPacks(planHashedId);

  /// Fetches addon extra packs for a specific SIM plan.
  Future<List<DataPlanExtra>> getExtraPacks(String planHashedId) =>
      _dao.getExtraPacks(planHashedId);

  /// Inserts a new addon booster pack.
  Future<int> addExtraPack(DataPlanExtra extra) => _dao.insertExtraPack(extra);

  /// Updates an existing addon booster pack.
  Future<bool> updateExtraPack(DataPlanExtra extra) => _dao.updateExtraPack(extra);

  /// Deletes an addon booster pack by its primary ID.
  Future<int> deleteExtraPack(int id) => _dao.deleteExtraPack(id);

  // --- Mathematical Safety & Budget Algorithms ---

  /// Computes the Data Safety health indicator based on relative data burn rate vs. cycle progression.
  /// Formula: Δ = (DataUsed / TotalQuota) - (TimeElapsed / TotalCycleDuration)
  DataSafetyState calculateDataSafety({
    required int usedBytes,
    required int totalQuota,
    required DateTime cycleStart,
    required DateTime cycleEnd,
    DateTime? now,
  }) {
    if (totalQuota <= 0) return DataSafetyState.neutral;

    final current = now ?? DateTime.now();
    final totalCycleMs = cycleEnd.difference(cycleStart).inMilliseconds;
    if (totalCycleMs <= 0) return DataSafetyState.neutral;

    final elapsedMs = current.difference(cycleStart).inMilliseconds.clamp(0, totalCycleMs);
    final timeRatio = elapsedMs / totalCycleMs;
    final usageRatio = (usedBytes / totalQuota).clamp(0.0, 10.0);

    // Over-quota or > 95% used is always unsafe
    if (usageRatio >= 0.95) {
      return DataSafetyState.unsafe;
    }

    // Very low consumption (< 10%) is always safe
    if (usageRatio < 0.10) {
      return DataSafetyState.safe;
    }

    final delta = usageRatio - timeRatio;

    if (delta <= 0.0) {
      return DataSafetyState.safe;
    } else if (delta <= 0.10) {
      return DataSafetyState.neutral;
    } else {
      return DataSafetyState.unsafe;
    }
  }

  /// Calculates dynamic daily budget allowance evenly distributed over remaining days.
  /// Formula: DailyBudget = max(TotalQuota - UsedBytes, 0) / (DaysRemaining + 1)
  int calculateDailyBudget({
    required int totalQuota,
    required int usedBytes,
    required int daysRemaining,
  }) {
    final remainingBytes = max(totalQuota - usedBytes, 0);
    final divisor = max(daysRemaining + 1, 1);
    return (remainingBytes / divisor).round();
  }

  /// Calculates remaining allowance for today against the daily budget.
  int calculateTodayRemainingBudget({
    required int dailyBudget,
    required int todayUsedBytes,
  }) {
    return max(dailyBudget - todayUsedBytes, 0);
  }

  /// Generates an end-of-cycle rollover booster pack if rollover is enabled and unspent data remains.
  DataPlanExtra? processEndOfCycleRollover({
    required DataPlan plan,
    required int cycleUsedBytes,
    required DateTime nextCycleStart,
    required DateTime nextCycleEnd,
  }) {
    if (!plan.rolloverEnabled) return null;

    final unspentBytes = plan.quotaBytes - cycleUsedBytes;
    if (unspentBytes <= 0) return null;

    return DataPlanExtra(
      planHashedSubscriberId: plan.hashedSubscriberId,
      extraBytes: unspentBytes,
      usedBytes: 0,
      startDate: nextCycleStart,
      expiryDate: nextCycleEnd,
      note: 'Rollover from previous cycle',
    );
  }
}
