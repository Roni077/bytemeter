import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/data/database/app_database.dart';
import 'package:bytemeter/src/data/models/data_plan.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/repositories/data_plan_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DataPlanRepository repository;

  setUp(() {
    db = AppDatabase.inMemory();
    repository = DataPlanRepository(
      dao: db.dataPlansDao,
      bridge: NativeTrafficBridge(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DataPlanRepository - Data Safety Mathematical Model', () {
    final cycleStart = DateTime(2026, 9, 1);
    final cycleEnd = DateTime(2026, 9, 30, 23, 59, 59);

    test('Usage under 10% is always Safe regardless of elapsed time', () {
      final state = repository.calculateDataSafety(
        usedBytes: 50000000, // 5% of 1 GB
        totalQuota: 1000000000,
        cycleStart: cycleStart,
        cycleEnd: cycleEnd,
        now: DateTime(2026, 9, 28), // 93% time elapsed
      );
      expect(state, equals(DataSafetyState.safe));
    });

    test('Usage above 95% is always Unsafe regardless of elapsed time', () {
      final state = repository.calculateDataSafety(
        usedBytes: 960000000, // 96% of 1 GB
        totalQuota: 1000000000,
        cycleStart: cycleStart,
        cycleEnd: cycleEnd,
        now: DateTime(2026, 9, 2), // 6% time elapsed
      );
      expect(state, equals(DataSafetyState.unsafe));
    });

    test('Pacing ahead of schedule (Delta <= 0.0) is Safe', () {
      // 30% used at 50% time elapsed -> Delta = 0.30 - 0.50 = -0.20
      final state = repository.calculateDataSafety(
        usedBytes: 300000000,
        totalQuota: 1000000000,
        cycleStart: cycleStart,
        cycleEnd: cycleEnd,
        now: DateTime(2026, 9, 15, 12, 0), // ~50% elapsed
      );
      expect(state, equals(DataSafetyState.safe));
    });

    test('Slight burn overshoot (0 < Delta <= 0.10) is Neutral', () {
      // 55% used at 50% time elapsed -> Delta = 0.55 - 0.50 = +0.05
      final state = repository.calculateDataSafety(
        usedBytes: 550000000,
        totalQuota: 1000000000,
        cycleStart: cycleStart,
        cycleEnd: cycleEnd,
        now: DateTime(2026, 9, 15, 12, 0), // ~50% elapsed
      );
      expect(state, equals(DataSafetyState.neutral));
    });

    test('Significant burn overshoot (Delta > 0.10) is Unsafe', () {
      // 75% used at 50% time elapsed -> Delta = 0.75 - 0.50 = +0.25
      final state = repository.calculateDataSafety(
        usedBytes: 750000000,
        totalQuota: 1000000000,
        cycleStart: cycleStart,
        cycleEnd: cycleEnd,
        now: DateTime(2026, 9, 15, 12, 0), // ~50% elapsed
      );
      expect(state, equals(DataSafetyState.unsafe));
    });
  });

  group('DataPlanRepository - Dynamic Daily Budget Math', () {
    test('Calculates even daily budget distribution across remaining days', () {
      // 10 GB quota, 2 GB used -> 8 GB remaining. 9 days remaining -> divisor = 10 -> 800 MB/day
      final dailyBudget = repository.calculateDailyBudget(
        totalQuota: 10000,
        usedBytes: 2000,
        daysRemaining: 9,
      );
      expect(dailyBudget, equals(800));
    });

    test('0 days remaining (final cycle day) uses divisor of 1', () {
      final dailyBudget = repository.calculateDailyBudget(
        totalQuota: 10000,
        usedBytes: 8500,
        daysRemaining: 0,
      );
      expect(dailyBudget, equals(1500));
    });

    test('Exhausted quota returns 0 budget', () {
      final dailyBudget = repository.calculateDailyBudget(
        totalQuota: 10000,
        usedBytes: 12000,
        daysRemaining: 5,
      );
      expect(dailyBudget, equals(0));
    });

    test('calculateTodayRemainingBudget clamps at 0', () {
      expect(
        repository.calculateTodayRemainingBudget(dailyBudget: 500, todayUsedBytes: 200),
        equals(300),
      );
      expect(
        repository.calculateTodayRemainingBudget(dailyBudget: 500, todayUsedBytes: 600),
        equals(0),
      );
    });
  });

  group('DataPlanRepository - Rollover Booster Logic', () {
    final plan = DataPlan(
      hashedSubscriberId: 'hash_sim_1',
      quotaBytes: 10000000000, // 10 GB
      rolloverEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('Generates rollover extra pack when rollover is enabled and unspent bytes exist', () {
      final rollover = repository.processEndOfCycleRollover(
        plan: plan,
        cycleUsedBytes: 6000000000, // 6 GB used -> 4 GB unspent
        nextCycleStart: DateTime(2026, 10, 1),
        nextCycleEnd: DateTime(2026, 10, 31, 23, 59, 59),
      );

      expect(rollover, isNotNull);
      expect(rollover!.extraBytes, equals(4000000000));
      expect(rollover.usedBytes, equals(0));
      expect(rollover.planHashedSubscriberId, equals('hash_sim_1'));
      expect(rollover.note, contains('Rollover'));
    });

    test('Returns null when rollover is disabled on the plan', () {
      final rollover = repository.processEndOfCycleRollover(
        plan: plan.copyWith(rolloverEnabled: false),
        cycleUsedBytes: 6000000000,
        nextCycleStart: DateTime(2026, 10, 1),
        nextCycleEnd: DateTime(2026, 10, 31),
      );
      expect(rollover, isNull);
    });

    test('Returns null when quota was fully exhausted', () {
      final rollover = repository.processEndOfCycleRollover(
        plan: plan,
        cycleUsedBytes: 10500000000, // 10.5 GB used
        nextCycleStart: DateTime(2026, 10, 1),
        nextCycleEnd: DateTime(2026, 10, 31),
      );
      expect(rollover, isNull);
    });
  });
}
