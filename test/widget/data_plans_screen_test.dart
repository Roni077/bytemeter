import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/app_scaffold.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/data/database/app_database.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/models/data_plan.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';
import 'package:bytemeter/src/data/repositories/data_plan_repository.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/data_plans/data_plans_screen.dart';
import 'package:bytemeter/src/features/data_plans/plan_config_screen.dart';
import 'package:bytemeter/src/features/data_plans/widgets/add_extra_pack_dialog.dart';
import 'package:bytemeter/src/features/data_plans/widgets/daily_budget_card.dart';
import 'package:bytemeter/src/features/data_plans/widgets/data_safety_card.dart';
import 'package:bytemeter/src/features/data_plans/widgets/sim_card_pager.dart';

class MockWidgetNativeBridge extends NativeTrafficBridge {
  @override
  Future<bool> hasUsagePermission() async => true;

  @override
  Future<UsageData> queryDeviceSummary({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return UsageData(
      uploadBytes: 500000000,
      downloadBytes: 2500000000,
      totalBytes: 3000000000,
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
        uploadBytes: 50000000,
        downloadBytes: 250000000,
        totalBytes: 300000000,
        startTime: startTime,
        endTime: endTime,
      ),
    ];
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async => [
        const AppInfo(uid: 10001, packageName: 'com.whatsapp', label: 'WhatsApp'),
      ];

  @override
  Future<String> hashSubscriberId(String id) async => 'hash_$id';

  @override
  Future<String> encryptSubscriberId(String id) async => 'enc_$id';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DataPlanRepository planRepo;
  late NetworkUsageRepository usageRepo;
  late PreferencesRepository prefsRepo;
  late MockWidgetNativeBridge bridge;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bridge = MockWidgetNativeBridge();
    db = AppDatabase.inMemory();
    planRepo = DataPlanRepository(dao: db.dataPlansDao, bridge: bridge);
    usageRepo = NetworkUsageRepository(bridge: bridge);
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: bridge);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp({Widget child = const DataPlansScreen()}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        preferencesRepositoryProvider.overrideWithValue(prefsRepo),
        networkUsageRepositoryProvider.overrideWithValue(usageRepo),
        dataPlanRepositoryProvider.overrideWithValue(planRepo),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: child,
      ),
    );
  }

  group('DataPlansScreen Widget Tests', () {
    testWidgets('Renders unconfigured state with SIM carousel and onboarding guide', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Data Plans'), findsOneWidget);
      expect(find.byType(SimCardPager), findsOneWidget);
      expect(find.textContaining('SIM 1 Not Configured'), findsOneWidget);
      expect(find.text('Multi-SIM Tracking & Safety'), findsOneWidget);
      expect(find.textContaining('Configure SIM 1 Plan'), findsOneWidget);
    });

    testWidgets('Renders configured SIM plan with DataSafetyCard, DailyBudgetCard, and Booster section',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Pre-populate a plan in the database
      final plan = DataPlan(
        hashedSubscriberId: 'hash_sim_0',
        simSlotIndex: 0,
        carrierName: 'Airtel 5G',
        quotaBytes: 20000000000, // 20 GB
        billingCycleStartDay: 1,
        cycleInterval: TimeIntervalType.monthly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await planRepo.savePlan(plan);

      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Airtel 5G'), findsOneWidget);
      expect(find.byType(DataSafetyCard), findsOneWidget);
      expect(find.byType(DailyBudgetCard), findsOneWidget);
      expect(find.text('Booster Packs'), findsOneWidget);
      expect(find.text('Data Safety Pacing'), findsOneWidget);
      expect(find.text('Daily Data Budget'), findsOneWidget);
    });

    testWidgets('PlanConfigScreen allows configuring plan fields and saving', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(
          child: const PlanConfigScreen(initialSlotIndex: 0),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Set Up SIM Plan'), findsOneWidget);
      expect(find.text('CARRIER NAME'), findsOneWidget);
      expect(find.text('DATA QUOTA LIMIT'), findsOneWidget);

      // Select preset chip "Jio"
      final jioChip = find.widgetWithText(ActionChip, 'Jio');
      expect(jioChip, findsOneWidget);
      await tester.tap(jioChip);
      await tester.pump(const Duration(milliseconds: 100));

      // Enter quota amount
      final quotaInput = find.widgetWithText(TextFormField, 'Total Quota Amount');
      await tester.enterText(quotaInput, '50');
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Save button
      final saveBtn = find.widgetWithText(FilledButton, 'Save');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 200));

      // Verify plan was saved into DB
      final savedPlans = await planRepo.getPlans();
      expect(savedPlans.isNotEmpty, isTrue);
      expect(savedPlans.first.carrierName, equals('Jio'));
      expect(savedPlans.first.quotaBytes, equals(50 * 1024 * 1024 * 1024));
    });

    testWidgets('AddExtraPackDialog validates and submits booster pack', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AddExtraPackDialog.show(
                        context,
                        planHashedSubscriberId: 'hash_sim_0',
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Open Dialog'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Add Booster Pack'), findsOneWidget);
      expect(find.text('Data Allowance'), findsOneWidget);

      // Submit booster pack
      final addBtn = find.widgetWithText(FilledButton, 'Add Booster');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Sheet is dismissed
      expect(find.text('Add Booster Pack'), findsNothing);
    });

    testWidgets('AppScaffold navigates to DataPlansScreen on tab 2 selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(child: const AppScaffold()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Home'), findsWidgets);

      // Tap Plans tab in bottom navigation bar
      final plansNav = find.text('Plans');
      expect(plansNav, findsOneWidget);
      await tester.tap(plansNav);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(DataPlansScreen), findsOneWidget);
      expect(find.text('Data Plans'), findsOneWidget);
    });
  });
}
