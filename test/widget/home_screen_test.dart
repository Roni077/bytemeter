import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/speed_stream_listener.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/home/home_screen.dart';
import 'package:bytemeter/src/features/home/widgets/permission_banner.dart';
import 'package:bytemeter/src/features/home/widgets/weekly_chart_card.dart';

class MockBridge extends NativeTrafficBridge {
  MockBridge({this.hasPerm = true});
  bool hasPerm;

  @override
  Future<bool> hasUsagePermission() async => hasPerm;

  @override
  Future<bool> requestUsagePermission() async {
    hasPerm = true;
    return true;
  }

  @override
  Future<UsageData> queryDeviceSummary({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return UsageData(
      uploadBytes: 250000000,
      downloadBytes: 750000000,
      totalBytes: 1000000000, // 1 GB
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
        downloadBytes: 200000000,
        totalBytes: 250000000,
        startTime: startTime,
        endTime: endTime,
      ),
    ];
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async {
    return const [
      AppInfo(uid: 10001, packageName: 'com.whatsapp', label: 'WhatsApp'),
    ];
  }
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
    bridge = MockBridge(hasPerm: true);
    usageRepo = NetworkUsageRepository(bridge: bridge);
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: bridge);
  });

  Widget buildTestWidget({bool hasPermission = true}) {
    bridge.hasPerm = hasPermission;

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
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('HomeScreen renders full dashboard components', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify header and core widgets based on the new refactored layout
    expect(find.text('ByteMeter'), findsOneWidget);
    expect(find.byType(WeeklyChartCard), findsOneWidget);
    expect(find.byType(PermissionBanner), findsNothing);
  });

  testWidgets('PermissionBanner renders when Usage Access is missing', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(hasPermission: false));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PermissionBanner), findsOneWidget);
    expect(find.text('Usage Access Required'), findsOneWidget);
    expect(find.text('Grant Permission'), findsOneWidget);

    // Tap Grant Permission
    await tester.tap(find.text('Grant Permission'));
    await tester.pump(const Duration(milliseconds: 100));
  });
}

