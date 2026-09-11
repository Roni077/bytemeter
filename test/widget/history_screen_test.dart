import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/app_scaffold.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/native/speed_stream_listener.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/charts/scrollable_bar_chart.dart';
import 'package:bytemeter/src/features/history/history_screen.dart';
import 'package:bytemeter/src/features/history/widgets/app_item_card.dart';
import 'package:bytemeter/src/features/history/widgets/app_list_view.dart';
import 'package:bytemeter/src/features/history/widgets/app_search_modal.dart';
import 'package:bytemeter/src/features/history/widgets/history_filter_bottom_sheet.dart';
import 'package:bytemeter/src/features/history/widgets/history_legend_badge.dart';
import 'package:bytemeter/src/features/history/widgets/hour_list_view.dart';

class MockBridge extends NativeTrafficBridge {
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
      uploadBytes: 200000000,
      downloadBytes: 800000000,
      totalBytes: 1000000000,
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
      UsageData(
        uid: 10002,
        uploadBytes: 20000000,
        downloadBytes: 80000000,
        totalBytes: 100000000,
        startTime: startTime,
        endTime: endTime,
      ),
    ];
  }

  @override
  Future<List<UsageData>> queryHourlyBuckets({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
    int? uid,
  }) async {
    final list = <UsageData>[];
    for (int h = 0; h < 24; h++) {
      list.add(
        UsageData(
          uid: uid,
          uploadBytes: 2000000,
          downloadBytes: 8000000,
          totalBytes: 10000000,
          startTime: startTime.add(Duration(hours: h)),
          endTime: startTime.add(Duration(hours: h + 1)),
        ),
      );
    }
    return list;
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async {
    return const [
      AppInfo(uid: 10001, packageName: 'com.google.android.youtube', label: 'YouTube'),
      AppInfo(uid: 10002, packageName: 'com.whatsapp', label: 'WhatsApp'),
    ];
  }

  @override
  Future<bool> launchApp(String packageName) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MockBridge bridge;
  late NetworkUsageRepository usageRepo;
  late PreferencesRepository prefsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bridge = MockBridge();
    usageRepo = NetworkUsageRepository(bridge: bridge);
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: bridge);
  });

  Widget buildTestWidget({Widget? child}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nativeTrafficBridgeProvider.overrideWithValue(bridge),
        networkUsageRepositoryProvider.overrideWithValue(usageRepo),
        preferencesRepositoryProvider.overrideWithValue(prefsRepo),
        speedStreamListenerProvider.overrideWithValue(
          SpeedStreamListener(mockStream: const Stream.empty()),
        ),
      ],
      child: MaterialApp(
        home: child ?? const HistoryScreen(),
      ),
    );
  }

  testWidgets('HistoryScreen renders 90-day timeline, dual query legend, and apps list',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('History & Analytics'), findsOneWidget);
    expect(find.byType(ScrollableBarChart), findsOneWidget);
    expect(find.byType(HistoryLegendBadge), findsOneWidget);
    expect(find.byType(AppListView), findsOneWidget);
    expect(find.byType(AppItemCard), findsNWidgets(3)); // 2 apps + UID_OTHER_USERS
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
  });

  testWidgets('HistoryScreen switches between Apps Breakdown and 2-Hour Intervals',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Switch to 2-Hour Intervals
    final hourTab = find.text('2-Hour Intervals');
    expect(hourTab, findsOneWidget);
    await tester.tap(hourTab);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(HourListView), findsOneWidget);
    expect(find.text('00:00 – 02:00'), findsOneWidget);

    // Switch back to Apps Breakdown
    final appsTab = find.text('Apps Breakdown');
    expect(appsTab, findsOneWidget);
    await tester.tap(appsTab);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppListView), findsOneWidget);
  });

  testWidgets('AppItemCard expands to reveal Filter Timeline and Open App actions',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final youtubeCard = find.widgetWithText(AppItemCard, 'YouTube');
    expect(youtubeCard, findsOneWidget);

    // Tap to expand
    await tester.tap(youtubeCard);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Filter Timeline'), findsWidgets);
    expect(find.text('Open App'), findsWidgets);

    // Scroll to bring the button into full viewport view and tap
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Filter Timeline').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Scroll back to top to bring HistoryLegendBadge into viewport
    await tester.drag(find.byType(ListView).first, const Offset(0, 300));
    await tester.pumpAndSettle();

    // Verify filter chip is displayed
    expect(find.textContaining('Filtered by: YouTube'), findsOneWidget);
  });

  testWidgets('AppSearchModal filters apps and selects application',
      (WidgetTester tester) async {
    AppInfo? selectedApp;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedApp = await AppSearchModal.show(
                  context: context,
                  installedApps: const [
                    AppInfo(uid: 10001, packageName: 'com.google.android.youtube', label: 'YouTube'),
                    AppInfo(uid: 10002, packageName: 'com.whatsapp', label: 'WhatsApp'),
                  ],
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Select Application'), findsOneWidget);
    expect(find.text('All Applications'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);

    // Tap YouTube
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();

    expect(selectedApp?.label, equals('YouTube'));
  });

  testWidgets('HistoryFilterBottomSheet allows configuring filters and applying',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Filters button
    final filtersBtn = find.text('Filters');
    expect(filtersBtn, findsOneWidget);
    await tester.tap(filtersBtn);
    await tester.pumpAndSettle();

    expect(find.byType(HistoryFilterBottomSheet), findsOneWidget);
    expect(find.text('Dual Query Filters'), findsOneWidget);
    expect(find.text('PRIMARY QUERY'), findsOneWidget);
    expect(find.text('Apply Filters'), findsOneWidget);

    // Tap Apply Filters
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryFilterBottomSheet), findsNothing);
  });

  testWidgets('AppScaffold navigates between Overview and History tabs',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(child: const AppScaffold()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('TODAY\'S USAGE'), findsOneWidget);

    // Tap History destination
    final historyNav = find.text('History');
    expect(historyNav, findsOneWidget);
    await tester.tap(historyNav);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('History & Analytics'), findsOneWidget);
  });
}
