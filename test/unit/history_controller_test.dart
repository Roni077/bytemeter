import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/history/history_controller.dart';
import 'package:bytemeter/src/features/history/history_state.dart';

class FakeNativeBridge extends NativeTrafficBridge {
  FakeNativeBridge({
    this.deviceUsageTotal = 500000000,
    this.installedAppsList = const [],
    this.hasPermission = true,
  });

  int deviceUsageTotal;
  List<AppInfo> installedAppsList;
  bool hasPermission;

  @override
  Future<bool> hasUsagePermission() async => hasPermission;

  @override
  Future<UsageData> queryDeviceSummary({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final factor = networkType == NetworkType.mobile ? 1.0 : 1.5;
    final total = (deviceUsageTotal * factor).round();
    return UsageData(
      uploadBytes: (total * 0.3).round(),
      downloadBytes: (total * 0.7).round(),
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
        uploadBytes: 30000000,
        downloadBytes: 120000000,
        totalBytes: 150000000,
        startTime: startTime,
        endTime: endTime,
      ),
      UsageData(
        uid: 10002,
        uploadBytes: 10000000,
        downloadBytes: 90000000,
        totalBytes: 100000000,
        startTime: startTime,
        endTime: endTime,
      ),
      UsageData(
        uid: 10003,
        uploadBytes: 5000000,
        downloadBytes: 25000000,
        totalBytes: 30000000,
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
      final slotStart = startTime.add(Duration(hours: h));
      final slotEnd = slotStart.add(const Duration(hours: 1));
      list.add(
        UsageData(
          uid: uid,
          uploadBytes: 1000000,
          downloadBytes: 4000000,
          totalBytes: 5000000,
          startTime: slotStart,
          endTime: slotEnd,
        ),
      );
    }
    return list;
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async => installedAppsList;

  @override
  Future<bool> launchApp(String packageName) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNativeBridge bridge;
  late NetworkUsageRepository usageRepo;
  late PreferencesRepository prefsRepo;
  late SharedPreferences prefs;

  final testApps = [
    const AppInfo(uid: 10001, packageName: 'com.google.android.youtube', label: 'YouTube'),
    const AppInfo(uid: 10002, packageName: 'com.whatsapp', label: 'WhatsApp'),
    const AppInfo(uid: 10003, packageName: 'com.spotify.music', label: 'Spotify'),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bridge = FakeNativeBridge(installedAppsList: testApps);
    usageRepo = NetworkUsageRepository(bridge: bridge);
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: bridge);
  });

  group('History Models & State', () {
    test('HistoryQuery displays formatted labels and copyWith works correctly', () {
      const query = HistoryQuery(
        networkType: NetworkType.mobile,
        direction: DataDirection.download,
        appUid: 10001,
        appInfo: AppInfo(uid: 10001, packageName: 'com.youtube', label: 'YouTube'),
      );

      expect(query.isAllApps, isFalse);
      expect(query.label, contains('Mobile'));
      expect(query.label, contains('Download'));
      expect(query.label, contains('YouTube'));

      final updated = query.copyWith(
        networkType: () => NetworkType.wifi,
        direction: DataDirection.bidirectional,
        appUid: () => null,
        appInfo: () => null,
      );

      expect(updated.networkType, equals(NetworkType.wifi));
      expect(updated.direction, equals(DataDirection.bidirectional));
      expect(updated.isAllApps, isTrue);
    });

    test('HourBucketData formats time labels correctly', () {
      const bucket = HourBucketData(
        startHour: 14,
        endHour: 16,
        primaryBytes: 5000000,
        secondaryBytes: 2000000,
        totalBytes: 7000000,
      );

      expect(bucket.timeLabel, equals('14:00 – 16:00'));
      expect(bucket.totalBytes, equals(7000000));
    });
  });

  group('HistoryController Unit Tests', () {
    test('Loads 90-day timeline cache, app breakdown, and 12 hourly intervals', () async {
      final controller = HistoryController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      await controller.loadInitialData(
        referenceDate: DateTime(2026, 9, 10, 14, 0),
      );

      expect(controller.state.isLoadingTimeline, isFalse);
      expect(controller.state.isLoadingDetails, isFalse);
      expect(controller.state.timelineData.length, equals(90));
      expect(controller.state.appBreakdown.length, equals(4)); // 3 installed apps + 1 reconciled delta (UID_OTHER_USERS)
      expect(controller.state.hourlyBuckets.length, equals(12));
      expect(controller.state.installedApps.length, equals(3));
    });

    test('selectDate updates selected date and refreshes details', () async {
      final controller = HistoryController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      await controller.loadInitialData(
        referenceDate: DateTime(2026, 9, 10, 14, 0),
      );

      final newDate = DateTime(2026, 9, 5);
      await controller.selectDate(newDate);

      expect(controller.state.selectedDate.year, equals(2026));
      expect(controller.state.selectedDate.month, equals(9));
      expect(controller.state.selectedDate.day, equals(5));
      expect(controller.state.appBreakdown.isNotEmpty, isTrue);
    });

    test('updatePrimaryQuery and updateSecondaryQuery recalculate graph data', () async {
      final controller = HistoryController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      await controller.loadInitialData(
        referenceDate: DateTime(2026, 9, 10, 14, 0),
      );

      const newPrimary = HistoryQuery(
        networkType: NetworkType.wifi,
        direction: DataDirection.download,
      );

      await controller.updatePrimaryQuery(newPrimary);
      expect(controller.state.primaryQuery.networkType, equals(NetworkType.wifi));
      expect(controller.state.primaryQuery.direction, equals(DataDirection.download));

      const newSecondary = HistoryQuery(
        networkType: NetworkType.mobile,
        direction: DataDirection.upload,
      );

      await controller.updateSecondaryQuery(newSecondary, isComparisonEnabled: true);
      expect(controller.state.secondaryQuery.networkType, equals(NetworkType.mobile));
      expect(controller.state.isComparisonEnabled, isTrue);
    });

    test('setQuickFilterApp isolates a specific app across 90-day timeline', () async {
      final controller = HistoryController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      await controller.loadInitialData(
        referenceDate: DateTime(2026, 9, 10, 14, 0),
      );

      final targetApp = testApps.first; // YouTube
      await controller.setQuickFilterApp(targetApp);

      expect(controller.state.primaryQuery.appUid, equals(targetApp.uid));
      expect(controller.state.primaryQuery.appInfo, equals(targetApp));
      expect(controller.state.hasAppFilter, isTrue);

      // Clear app filter
      await controller.clearAppFilter();
      expect(controller.state.primaryQuery.appUid, isNull);
      expect(controller.state.hasAppFilter, isFalse);
    });

    test('switchViewTab toggles between Apps Breakdown and 2-Hour Intervals', () {
      final controller = HistoryController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      controller.switchViewTab(HistoryViewTab.hours);
      expect(controller.state.activeTab, equals(HistoryViewTab.hours));

      controller.switchViewTab(HistoryViewTab.apps);
      expect(controller.state.activeTab, equals(HistoryViewTab.apps));
    });

    test('launchApp delegates to repository bridge', () async {
      final controller = HistoryController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      final launched = await controller.launchApp('com.whatsapp');
      expect(launched, isTrue);
    });
  });
}
