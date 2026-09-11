import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/data/database/app_database.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/models/data_plan.dart';
import 'package:bytemeter/src/data/models/data_plan_extra.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';
import 'package:bytemeter/src/data/repositories/data_plan_repository.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/data_plans/plans_controller.dart';

class FakePlansNativeBridge extends NativeTrafficBridge {
  FakePlansNativeBridge({
    this.mobileCycleUsage = 3000000000, // 3 GB
    this.mobileTodayUsage = 500000000,  // 500 MB
  });

  int mobileCycleUsage;
  int mobileTodayUsage;

  @override
  Future<bool> hasUsagePermission() async => true;

  @override
  Future<UsageData> queryDeviceSummary({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final isToday = endTime.difference(startTime).inHours <= 24;
    final total = isToday ? mobileTodayUsage : mobileCycleUsage;
    return UsageData(
      uploadBytes: (total * 0.2).round(),
      downloadBytes: (total * 0.8).round(),
      totalBytes: total,
      startTime: startTime,
      endTime: endTime,
    );
  }

  @override
  Future<List<UsageData>> queryAppBuckets({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return [
      UsageData(
        uid: 10001,
        uploadBytes: 100000000,
        downloadBytes: 900000000,
        totalBytes: 1000000000,
        startTime: startTime,
        endTime: endTime,
      ),
    ];
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async => [
        const AppInfo(uid: 10001, packageName: 'com.whatsapp', label: 'WhatsApp'),
        const AppInfo(uid: 10002, packageName: 'com.spotify', label: 'Spotify'),
      ];

  @override
  Future<String> hashSubscriberId(String id) async => 'hash_$id';

  @override
  Future<String> encryptSubscriberId(String id) async => 'enc_$id';

  @override
  Future<String?> decryptSubscriberId(String encrypted) async => encrypted.replaceFirst('enc_', '');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DataPlanRepository planRepo;
  late NetworkUsageRepository usageRepo;
  late PreferencesRepository prefsRepo;
  late FakePlansNativeBridge bridge;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bridge = FakePlansNativeBridge();
    db = AppDatabase.inMemory();
    planRepo = DataPlanRepository(dao: db.dataPlansDao, bridge: bridge);
    usageRepo = NetworkUsageRepository(bridge: bridge);
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: bridge);
  });

  tearDown(() async {
    await db.close();
  });

  group('PlansController Unit Tests', () {
    test('Initializes with default unconfigured SIM 1 and SIM 2 slots when DB is empty', () async {
      final controller = PlansController(
        planRepo: planRepo,
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      await controller.loadPlansData(referenceTime: DateTime(2026, 9, 10, 14, 0));

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.plans.length, equals(2));
      expect(controller.state.plans[0].carrierName, equals('SIM 1'));
      expect(controller.state.plans[0].quotaBytes, equals(0));
      expect(controller.state.isConfigured, isFalse);
      expect(controller.state.selectedPlanIndex, equals(0));
      expect(controller.state.installedApps.length, equals(2));
    });

    test('Saving a plan updates state, calculates cycle window, safety, and daily budget', () async {
      final controller = PlansController(
        planRepo: planRepo,
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      final plan = DataPlan(
        hashedSubscriberId: 'hash_sim_0',
        simSlotIndex: 0,
        carrierName: 'Verizon 5G',
        quotaBytes: 10000000000, // 10 GB
        billingCycleStartDay: 1,
        cycleInterval: TimeIntervalType.monthly,
        rolloverEnabled: true,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 10),
      );

      await controller.savePlan(plan);

      final state = controller.state;
      expect(state.isConfigured, isTrue);
      expect(state.selectedPlan?.carrierName, equals('Verizon 5G'));
      expect(state.totalAvailableQuota, equals(10000000000));
      expect(state.activeCycleUsage.totalBytes, equals(3000000000)); // 3 GB
      expect(state.todayUsage.totalBytes, equals(500000000)); // 500 MB
      expect(state.billingCycleWindow, isNotNull);
      expect(state.dailyBudget, isPositive);
      expect(state.todayRemainingBudget, isNonNegative);
    });

    test('Adding and deleting booster addon packs updates available quota and state', () async {
      final controller = PlansController(
        planRepo: planRepo,
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      final plan = DataPlan(
        hashedSubscriberId: 'hash_sim_0',
        simSlotIndex: 0,
        carrierName: 'Jio 5G',
        quotaBytes: 10000000000, // 10 GB
        billingCycleStartDay: 1,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 10),
      );

      await controller.savePlan(plan);

      final booster = DataPlanExtra(
        planHashedSubscriberId: 'hash_sim_0',
        extraBytes: 2000000000, // +2 GB
        startDate: DateTime(2026, 9, 5),
        expiryDate: DateTime(2026, 9, 25),
        note: 'Weekend Booster',
      );

      await controller.addExtraPack(booster);

      expect(controller.state.extraPacks.length, equals(1));
      expect(controller.state.extraPacks.first.note, equals('Weekend Booster'));
      expect(controller.state.totalAvailableQuota, equals(12000000000)); // 10 GB + 2 GB

      // Delete the booster pack
      final packId = controller.state.extraPacks.first.id;
      await controller.deleteExtraPack(packId);

      expect(controller.state.extraPacks.isEmpty, isTrue);
      expect(controller.state.totalAvailableQuota, equals(10000000000));
    });

    test('selectPlan switches carousel index and recalculates metrics', () async {
      final controller = PlansController(
        planRepo: planRepo,
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      await controller.loadPlansData();
      expect(controller.state.selectedPlanIndex, equals(0));

      await controller.selectPlan(1);
      expect(controller.state.selectedPlanIndex, equals(1));
      expect(controller.state.selectedPlan?.simSlotIndex, equals(1));
    });

    test('toggleExcludedApp toggles zero-rated app in plan configuration', () async {
      final controller = PlansController(
        planRepo: planRepo,
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      final plan = DataPlan(
        hashedSubscriberId: 'hash_sim_0',
        simSlotIndex: 0,
        carrierName: 'Airtel',
        quotaBytes: 5000000000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await controller.savePlan(plan);
      expect(controller.state.selectedPlan?.excludedUids.isEmpty, isTrue);

      // Add UID 10001 (WhatsApp)
      await controller.toggleExcludedApp('hash_sim_0', 10001);
      expect(controller.state.selectedPlan?.excludedUids.contains(10001), isTrue);

      // Remove UID 10001
      await controller.toggleExcludedApp('hash_sim_0', 10001);
      expect(controller.state.selectedPlan?.excludedUids.contains(10001), isFalse);
    });

    test('deletePlan deletes plan and resets slot to unconfigured state', () async {
      final controller = PlansController(
        planRepo: planRepo,
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      final plan = DataPlan(
        hashedSubscriberId: 'hash_sim_0',
        simSlotIndex: 0,
        carrierName: 'T-Mobile',
        quotaBytes: 15000000000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await controller.savePlan(plan);
      expect(controller.state.isConfigured, isTrue);

      await controller.deletePlan('hash_sim_0');
      expect(controller.state.isConfigured, isFalse);
    });
  });
}
