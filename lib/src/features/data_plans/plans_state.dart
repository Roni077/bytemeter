import 'package:flutter/foundation.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/app_info.dart';
import '../../data/models/data_plan.dart';
import '../../data/models/data_plan_extra.dart';
import '../../data/models/enums.dart';
import '../../data/models/usage_data.dart';

/// Immutable UI state for the Multi-SIM Data Plans screen and controllers.
@immutable
class PlansState {
  PlansState({
    this.plans = const <DataPlan>[],
    this.selectedPlanIndex = 0,
    this.extraPacks = const <DataPlanExtra>[],
    UsageData? activeCycleUsage,
    UsageData? todayUsage,
    this.dataSafetyState = DataSafetyState.safe,
    this.safetyDelta = 0.0,
    this.dailyBudget = 0,
    this.todayRemainingBudget = 0,
    this.billingCycleWindow,
    this.installedApps = const <AppInfo>[],
    this.isLoading = false,
    this.errorMessage,
  })  : activeCycleUsage = activeCycleUsage ?? UsageData(),
        todayUsage = todayUsage ?? UsageData();

  /// All known or configured SIM data plans.
  final List<DataPlan> plans;

  /// Index of currently selected SIM plan in carousel (0 = SIM 1, 1 = SIM 2, etc.).
  final int selectedPlanIndex;

  /// Active booster addon packs linked to the selected SIM plan.
  final List<DataPlanExtra> extraPacks;

  /// Data usage in the current billing cycle for the selected plan.
  final UsageData activeCycleUsage;

  /// Data usage today for the selected plan.
  final UsageData todayUsage;

  /// Health safety indicator (Safe, Neutral, Unsafe).
  final DataSafetyState dataSafetyState;

  /// Calculated data safety pacing delta: (Used/Quota) - (TimeElapsed/CycleDuration).
  final double safetyDelta;

  /// Dynamic daily budget allowance for remaining days in cycle.
  final int dailyBudget;

  /// Remaining data allowance for today against the daily budget.
  final int todayRemainingBudget;

  /// Current billing cycle start/end bounds and time progression.
  final BillingCycleWindow? billingCycleWindow;

  /// Cached list of installed applications for zero-rated exclusion selection.
  final List<AppInfo> installedApps;

  /// Whether metrics or plans are actively loading.
  final bool isLoading;

  /// Error message, if any.
  final String? errorMessage;

  /// Currently active [DataPlan], if present.
  DataPlan? get selectedPlan {
    if (selectedPlanIndex >= 0 && selectedPlanIndex < plans.length) {
      return plans[selectedPlanIndex];
    }
    return null;
  }

  /// Whether the selected SIM slot has a configured quota plan.
  bool get isConfigured => selectedPlan != null && selectedPlan!.quotaBytes > 0;

  /// Total available quota in bytes (Plan base quota + active addon packs remaining allowance).
  int get totalAvailableQuota {
    final baseQuota = selectedPlan?.quotaBytes ?? 0;
    final now = DateTime.now();
    final extraAllowance = extraPacks
        .where((p) => p.isValidAt(now))
        .fold<int>(0, (sum, p) => sum + p.remainingBytes);
    return baseQuota + extraAllowance;
  }

  /// Total data used in current billing cycle.
  int get totalCycleUsedBytes => activeCycleUsage.totalBytes;

  /// Proportion of total available quota used (0.0 to 1.0+).
  double get totalUsageRatio {
    final total = totalAvailableQuota;
    if (total <= 0) return 0.0;
    return (totalCycleUsedBytes / total).clamp(0.0, 10.0);
  }

  /// Remaining quota bytes in current billing cycle.
  int get remainingCycleBytes {
    final total = totalAvailableQuota;
    return (total - totalCycleUsedBytes).clamp(0, total);
  }

  PlansState copyWith({
    List<DataPlan>? plans,
    int? selectedPlanIndex,
    List<DataPlanExtra>? extraPacks,
    UsageData? activeCycleUsage,
    UsageData? todayUsage,
    DataSafetyState? dataSafetyState,
    double? safetyDelta,
    int? dailyBudget,
    int? todayRemainingBudget,
    BillingCycleWindow? billingCycleWindow,
    List<AppInfo>? installedApps,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlansState(
      plans: plans ?? this.plans,
      selectedPlanIndex: selectedPlanIndex ?? this.selectedPlanIndex,
      extraPacks: extraPacks ?? this.extraPacks,
      activeCycleUsage: activeCycleUsage ?? this.activeCycleUsage,
      todayUsage: todayUsage ?? this.todayUsage,
      dataSafetyState: dataSafetyState ?? this.dataSafetyState,
      safetyDelta: safetyDelta ?? this.safetyDelta,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      todayRemainingBudget: todayRemainingBudget ?? this.todayRemainingBudget,
      billingCycleWindow: billingCycleWindow ?? this.billingCycleWindow,
      installedApps: installedApps ?? this.installedApps,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlansState &&
          runtimeType == other.runtimeType &&
          listEquals(plans, other.plans) &&
          selectedPlanIndex == other.selectedPlanIndex &&
          listEquals(extraPacks, other.extraPacks) &&
          activeCycleUsage == other.activeCycleUsage &&
          todayUsage == other.todayUsage &&
          dataSafetyState == other.dataSafetyState &&
          safetyDelta == other.safetyDelta &&
          dailyBudget == other.dailyBudget &&
          todayRemainingBudget == other.todayRemainingBudget &&
          billingCycleWindow == other.billingCycleWindow &&
          listEquals(installedApps, other.installedApps) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(plans),
        selectedPlanIndex,
        Object.hashAll(extraPacks),
        activeCycleUsage,
        todayUsage,
        dataSafetyState,
        safetyDelta,
        dailyBudget,
        todayRemainingBudget,
        billingCycleWindow,
        Object.hashAll(installedApps),
        isLoading,
        errorMessage,
      );
}
