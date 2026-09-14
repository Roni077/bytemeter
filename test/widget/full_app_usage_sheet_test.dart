import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/home/widgets/full_app_usage_sheet.dart';

class MockNativeTrafficBridge extends Fake implements NativeTrafficBridge {
  @override
  Future<Uint8List?> getAppIcon(String packageName) async => null;

  @override
  Future<List<AppInfo>> getInstalledApps() async {
    return [
      const AppInfo(uid: 10001, packageName: 'com.google.android.youtube', label: 'YouTube'),
      const AppInfo(uid: 10002, packageName: 'com.whatsapp', label: 'WhatsApp'),
      const AppInfo(uid: 10003, packageName: 'org.telegram.messenger', label: 'Telegram'),
    ];
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
        downloadBytes: 150000000,
        totalBytes: 200000000,
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
      UsageData(
        uid: 10003,
        uploadBytes: 10000000,
        downloadBytes: 40000000,
        totalBytes: 50000000,
        startTime: startTime,
        endTime: endTime,
      ),
    ];
  }

  @override
  Future<UsageData> queryDeviceSummary({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return UsageData(
      uploadBytes: 80000000,
      downloadBytes: 270000000,
      totalBytes: 350000000,
      startTime: startTime,
      endTime: endTime,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNativeTrafficBridge mockBridge;
  late NetworkUsageRepository usageRepo;
  late PreferencesRepository prefsRepo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockBridge = MockNativeTrafficBridge();
    usageRepo = NetworkUsageRepository(bridge: mockBridge);
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: mockBridge);
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        preferencesRepositoryProvider.overrideWithValue(prefsRepo),
        networkUsageRepositoryProvider.overrideWithValue(usageRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: FullAppUsageSheet(
            networkType: NetworkType.mobile,
            date: DateTime(2026, 9, 14),
          ),
        ),
      ),
    );
  }

  group('FullAppUsageSheet Widget Tests', () {
    testWidgets('Renders header, search field, sort button, and loaded apps', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('All Applications Today'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.sort_rounded), findsOneWidget);

      // Verify all 3 mocked apps appear
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
    });

    testWidgets('Filters applications via search query', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);

      // Search for 'Tele'
      await tester.enterText(find.byType(TextField), 'Tele');
      await tester.pumpAndSettle();

      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('YouTube'), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
    });

    testWidgets('Displays empty state when search matches nothing', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonexistentAppXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No matching applications found'), findsOneWidget);
    });
  });
}
