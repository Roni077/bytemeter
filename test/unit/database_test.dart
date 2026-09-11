import 'package:bytemeter/src/data/database/app_database.dart';
import 'package:bytemeter/src/data/models/data_plan.dart';
import 'package:bytemeter/src/data/models/data_plan_extra.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift SQLite Database - DataPlans CRUD & Reactive Streams', () {
    test('Insert and fetch a DataPlan with excluded UIDs list', () async {
      final now = DateTime.now();
      final plan = DataPlan(
        hashedSubscriberId: 'hash_sim_alpha',
        encryptedSubscriberId: 'enc_data_123',
        simSlotIndex: 0,
        carrierName: 'Carrier Alpha',
        quotaBytes: 5000000000, // 5 GB
        billingCycleStartDay: 10,
        cycleInterval: TimeIntervalType.monthly,
        customIntervalDays: 30,
        rolloverEnabled: true,
        excludedUids: const [10045, 10089, -5], // Zero-rated UIDs
        cardColorIndex: 2,
        customNote: 'Primary Unlimited Plan',
        createdAt: now,
        updatedAt: now,
      );

      await db.dataPlansDao.insertOrUpdatePlan(plan);

      final fetched = await db.dataPlansDao.getPlanByHashedId('hash_sim_alpha');
      expect(fetched, isNotNull);
      expect(fetched!.carrierName, equals('Carrier Alpha'));
      expect(fetched.quotaBytes, equals(5000000000));
      expect(fetched.billingCycleStartDay, equals(10));
      expect(fetched.cycleInterval, equals(TimeIntervalType.monthly));
      expect(fetched.rolloverEnabled, isTrue);
      expect(fetched.excludedUids, equals([10045, 10089, -5]));
      expect(fetched.cardColorIndex, equals(2));
      expect(fetched.customNote, equals('Primary Unlimited Plan'));
    });

    test('watchAllPlans emits updates when plans are inserted or modified', () async {
      final emittedEvents = <List<DataPlan>>[];
      final subscription = db.dataPlansDao.watchAllPlans().listen(emittedEvents.add);

      // Initial query emission
      await pumpEventQueue();
      expect(emittedEvents.length, equals(1));
      expect(emittedEvents.first, isEmpty);

      final now = DateTime.now();
      await db.dataPlansDao.insertOrUpdatePlan(
        DataPlan(
          hashedSubscriberId: 'sim_1',
          quotaBytes: 1000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await pumpEventQueue();
      expect(emittedEvents.length, equals(2));
      expect(emittedEvents.last.length, equals(1));

      await db.dataPlansDao.insertOrUpdatePlan(
        DataPlan(
          hashedSubscriberId: 'sim_2',
          simSlotIndex: 1,
          quotaBytes: 2000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await pumpEventQueue();
      expect(emittedEvents.length, equals(3));
      expect(emittedEvents.last.length, equals(2));

      await subscription.cancel();
    });


    test('Addon packs and cascading delete verification', () async {
      final now = DateTime.now();
      final plan = DataPlan(
        hashedSubscriberId: 'sim_cascade_test',
        quotaBytes: 10000,
        createdAt: now,
        updatedAt: now,
      );
      await db.dataPlansDao.insertOrUpdatePlan(plan);

      final extra1 = DataPlanExtra(
        planHashedSubscriberId: 'sim_cascade_test',
        extraBytes: 2000,
        startDate: now,
        expiryDate: now.add(const Duration(days: 7)),
        note: 'Weekend Pass',
      );
      final extraId = await db.dataPlansDao.insertExtraPack(extra1);
      expect(extraId, greaterThan(0));

      final packs = await db.dataPlansDao.getExtraPacks('sim_cascade_test');
      expect(packs.length, equals(1));
      expect(packs.first.extraBytes, equals(2000));

      // Update extra pack
      await db.dataPlansDao.updateExtraPack(packs.first.copyWith(usedBytes: 500));
      final updatedPacks = await db.dataPlansDao.getExtraPacks('sim_cascade_test');
      expect(updatedPacks.first.usedBytes, equals(500));

      // Delete plan -> verify cascading delete of extra packs
      await db.dataPlansDao.deletePlan('sim_cascade_test');
      final remainingPlans = await db.dataPlansDao.getAllPlans();
      expect(remainingPlans, isEmpty);

      final remainingPacks = await db.dataPlansDao.getExtraPacks('sim_cascade_test');
      expect(remainingPacks, isEmpty);
    });
  });
}
