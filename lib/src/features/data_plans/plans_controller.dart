import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/data_plan.dart';
import '../../data/models/data_plan_extra.dart';
import '../../data/models/enums.dart';
import '../../data/models/usage_data.dart';
import '../../data/repositories/data_plan_repository.dart';
import '../../data/repositories/network_usage_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import 'plans_state.dart';

/// ViewModel controller managing multi-SIM data plans, rollover boosters,
/// and mathematical data safety / dynamic daily budget allocations.
class PlansController extends StateNotifier<PlansState> {
  PlansController({
    required this.planRepo,
    required this.usageRepo,
    required this.prefsRepo,
  }) : super(PlansState()) {
    loadPlansData();
  }

  final DataPlanRepository planRepo;
  final NetworkUsageRepository usageRepo;
  final PreferencesRepository prefsRepo;

  /// Loads all SIM plans, booster packs, and calculates active quota metrics.
  Future<void> loadPlansData({
    int? selectedIndex,
    DateTime? referenceTime,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final now = referenceTime ?? DateTime.now();
      final dbPlans = await planRepo.getPlans();
      final installedApps = state.installedApps.isNotEmpty
          ? state.installedApps
          : await usageRepo.getInstalledApps();

      // Build effective multi-SIM plans list (Ensure at least Slot 0 and Slot 1 exist)
      final effectivePlans = <DataPlan>[];
      if (dbPlans.isEmpty) {
        effectivePlans.add(_createDefaultUnconfiguredPlan(0, 'SIM 1'));
        effectivePlans.add(_createDefaultUnconfiguredPlan(1, 'SIM 2'));
      } else {
        effectivePlans.addAll(dbPlans);
        // If only SIM 1 is configured, provide SIM 2 slot as unconfigured option
        final hasSlot0 = dbPlans.any((p) => p.simSlotIndex == 0);
        final hasSlot1 = dbPlans.any((p) => p.simSlotIndex == 1);
        if (!hasSlot0) {
          effectivePlans.insert(0, _createDefaultUnconfiguredPlan(0, 'SIM 1'));
        }
        if (!hasSlot1) {
          effectivePlans.add(_createDefaultUnconfiguredPlan(1, 'SIM 2'));
        }
      }

      final maxIndex = math.max<int>(0, effectivePlans.length - 1);
      final activeIndex = (selectedIndex ?? state.selectedPlanIndex).clamp(0, maxIndex);

      final activePlan = effectivePlans.isNotEmpty ? effectivePlans[activeIndex] : null;

      if (activePlan != null && activePlan.quotaBytes > 0) {
        // 1. Calculate active Billing Cycle Window
        final cycleWindow = AppDateUtils.calculateBillingCycleWindow(
          now: now,
          cycleStartDay: activePlan.billingCycleStartDay,
          intervalType: activePlan.cycleInterval,
          customDays: activePlan.customIntervalDays,
        );

        // 2 & 3. Fetch booster packs, cycle cellular usage & today usage concurrently in parallel
        final results = await Future.wait([
          planRepo.getExtraPacks(activePlan.hashedSubscriberId),
          usageRepo.getPeriodUsage(
            startTime: cycleWindow.cycleStart,
            endTime: now,
            networkType: NetworkType.mobile,
            subscriberId: activePlan.hashedSubscriberId,
            excludedUids: activePlan.excludedUids,
          ),
          usageRepo.getTodayUsage(
            networkType: NetworkType.mobile,
            subscriberId: activePlan.hashedSubscriberId,
            excludedUids: activePlan.excludedUids,
            now: now,
          ),
        ]);

        final extraPacks = results[0] as List<DataPlanExtra>;
        final cycleUsage = results[1] as UsageData;
        final todayUsage = results[2] as UsageData;

        // 4. Calculate total quota including active extra packs
        final activeExtraAllowance = extraPacks
            .where((p) => p.isValidAt(now))
            .fold<int>(0, (sum, p) => sum + p.remainingBytes);
        final effectiveTotalQuota = activePlan.quotaBytes + activeExtraAllowance;

        // 5. Data Safety state & Delta calculation
        final safetyState = planRepo.calculateDataSafety(
          usedBytes: cycleUsage.totalBytes,
          totalQuota: effectiveTotalQuota,
          cycleStart: cycleWindow.cycleStart,
          cycleEnd: cycleWindow.cycleEnd,
          now: now,
        );

        final usageRatio = effectiveTotalQuota > 0
            ? (cycleUsage.totalBytes / effectiveTotalQuota)
            : 0.0;
        final delta = double.parse((usageRatio - cycleWindow.elapsedRatio).toStringAsFixed(3));

        // 6. Dynamic Daily Budget
        final dailyBudget = planRepo.calculateDailyBudget(
          totalQuota: effectiveTotalQuota,
          usedBytes: cycleUsage.totalBytes,
          daysRemaining: cycleWindow.daysRemaining,
        );

        final todayRemaining = planRepo.calculateTodayRemainingBudget(
          dailyBudget: dailyBudget,
          todayUsedBytes: todayUsage.totalBytes,
        );

        state = state.copyWith(
          plans: effectivePlans,
          selectedPlanIndex: activeIndex,
          extraPacks: extraPacks,
          activeCycleUsage: cycleUsage,
          todayUsage: todayUsage,
          dataSafetyState: safetyState,
          safetyDelta: delta,
          dailyBudget: dailyBudget,
          todayRemainingBudget: todayRemaining,
          billingCycleWindow: cycleWindow,
          installedApps: installedApps,
          isLoading: false,
        );
      } else {
        // Unconfigured SIM slot
        state = state.copyWith(
          plans: effectivePlans,
          selectedPlanIndex: activeIndex,
          extraPacks: const [],
          activeCycleUsage: UsageData(),
          todayUsage: UsageData(),
          dataSafetyState: DataSafetyState.safe,
          safetyDelta: 0.0,
          dailyBudget: 0,
          todayRemainingBudget: 0,
          billingCycleWindow: null,
          installedApps: installedApps,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load data plan: $e',
      );
    }
  }

  /// Switches active SIM card in carousel.
  Future<void> selectPlan(int index) async {
    if (state.selectedPlanIndex == index && state.plans.isNotEmpty) return;
    AppHaptics.selectionTick();
    await loadPlansData(selectedIndex: index);
  }

  /// Saves or updates a SIM data plan in the SQLite database.
  Future<void> savePlan(DataPlan plan, {String? rawSubscriberId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await planRepo.savePlan(plan, rawSubscriberId: rawSubscriberId);
      AppHaptics.contextClick();
      await loadPlansData(selectedIndex: plan.simSlotIndex);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save plan: $e',
      );
    }
  }

  /// Deletes a SIM data plan and refreshes the list.
  Future<void> deletePlan(String hashedId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await planRepo.deletePlan(hashedId);
      AppHaptics.contextClick();
      await loadPlansData(selectedIndex: 0);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete plan: $e',
      );
    }
  }

  /// Adds a new addon booster data pack to the active plan.
  Future<void> addExtraPack(DataPlanExtra extra) async {
    try {
      await planRepo.addExtraPack(extra);
      AppHaptics.contextClick();
      await loadPlansData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to add booster pack: $e',
      );
    }
  }

  /// Deletes an addon booster data pack.
  Future<void> deleteExtraPack(int id) async {
    try {
      await planRepo.deleteExtraPack(id);
      AppHaptics.contextClick();
      await loadPlansData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete booster pack: $e',
      );
    }
  }

  /// Toggles an application's zero-rated status for the specified plan.
  Future<void> toggleExcludedApp(String planHashedId, int uid) async {
    final currentPlan = state.plans.firstWhere(
      (p) => p.hashedSubscriberId == planHashedId,
      orElse: () => state.selectedPlan!,
    );

    final updatedList = List<int>.from(currentPlan.excludedUids);
    if (updatedList.contains(uid)) {
      updatedList.remove(uid);
    } else {
      updatedList.add(uid);
    }

    final updatedPlan = currentPlan.copyWith(
      excludedUids: updatedList,
      updatedAt: DateTime.now(),
    );

    await savePlan(updatedPlan);
  }

  /// Manually triggers a full refresh of plan metrics and cycle statistics.
  Future<void> refresh() async {
    await loadPlansData();
  }

  DataPlan _createDefaultUnconfiguredPlan(int slotIndex, String defaultName) {
    return DataPlan(
      hashedSubscriberId: 'sim_slot_$slotIndex',
      simSlotIndex: slotIndex,
      carrierName: defaultName,
      quotaBytes: 0,
      billingCycleStartDay: 1,
      cycleInterval: TimeIntervalType.monthly,
      customIntervalDays: 30,
      rolloverEnabled: false,
      cardColorIndex: slotIndex % 6,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

/// Riverpod StateNotifierProvider for [PlansController].
final plansControllerProvider =
    StateNotifierProvider.autoDispose<PlansController, PlansState>((ref) {
  final planRepo = ref.watch(dataPlanRepositoryProvider);
  final usageRepo = ref.watch(networkUsageRepositoryProvider);
  final prefsRepo = ref.watch(preferencesRepositoryProvider);

  return PlansController(
    planRepo: planRepo,
    usageRepo: usageRepo,
    prefsRepo: prefsRepo,
  );
});
