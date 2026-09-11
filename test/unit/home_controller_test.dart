import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/traffic_snapshot.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:bytemeter/src/data/repositories/preferences_repository.dart';
import 'package:bytemeter/src/features/home/home_controller.dart';

class FakeNativeBridge extends NativeTrafficBridge {
  FakeNativeBridge({
    this.deviceUsageTotal = 1000000000, // 1 GB
    this.installedAppsList = const [],
    this.hasPermission = true,
  });

  int deviceUsageTotal;
  List<AppInfo> installedAppsList;
  bool hasPermission;

  @override
  Future<bool> hasUsagePermission() async => hasPermission;

  @override
  Future<bool> requestUsagePermission() async {
    hasPermission = true;
    return true;
  }

  @override
  Future<UsageData> queryDeviceSummary({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (deviceUsageTotal == 0) {
      return UsageData(
        uploadBytes: 0,
        downloadBytes: 0,
        totalBytes: 0,
        startTime: startTime,
        endTime: endTime,
      );
    }
    final diffHours = endTime.difference(startTime).inHours;
    final total = diffHours > 0 ? diffHours * 10000000 : deviceUsageTotal;
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
        uploadBytes: 20000000,
        downloadBytes: 80000000,
        totalBytes: 100000000,
        startTime: startTime,
        endTime: endTime,
      ),
      UsageData(
        uid: 10002,
        uploadBytes: 10000000,
        downloadBytes: 40000000,
        totalBytes: 50000000,
        startTime: startTime,
        endTime: endTime,
      ),
    ];
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async => installedAppsList;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNativeBridge bridge;
  late NetworkUsageRepository usageRepo;
  late PreferencesRepository prefsRepo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bridge = FakeNativeBridge(
      installedAppsList: const [
        AppInfo(uid: 10001, packageName: 'com.whatsapp', label: 'WhatsApp'),
        AppInfo(uid: 10002, packageName: 'com.youtube', label: 'YouTube'),
      ],
    );
    usageRepo = NetworkUsageRepository(bridge: bridge);
    prefsRepo = PreferencesRepository(prefs: prefs, bridge: bridge);
  });

  group('HomeController - Mathematical Models & Analytics', () {
    test('4-Week Weighted Prediction with Historical Data', () async {
      final controller = HomeController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      final now = DateTime(2026, 9, 10, 14, 0, 0); // 2:00 PM (14 hours elapsed)
      const todayUsageBytes = 500000000; // 500 MB

      final prediction = await controller.calculate4WeekPrediction(
        now: now,
        networkType: NetworkType.mobile,
        todayUsageBytes: todayUsageBytes,
      );

      // Prediction should be greater than or equal to current usage
      expect(prediction, greaterThanOrEqualTo(todayUsageBytes));
    });

    test('4-Week Weighted Prediction with zero historical data falls back to linear time extrapolation', () async {
      final emptyBridge = FakeNativeBridge(deviceUsageTotal: 0);
      final emptyUsageRepo = NetworkUsageRepository(bridge: emptyBridge);
      final controller = HomeController(
        usageRepo: emptyUsageRepo,
        prefsRepo: prefsRepo,
      );

      final now = DateTime(2026, 9, 10, 12, 0, 0); // Midday (12h elapsed = 720 min -> factor 2.0)
      const todayUsageBytes = 200000000; // 200 MB

      final prediction = await controller.calculate4WeekPrediction(
        now: now,
        networkType: NetworkType.mobile,
        todayUsageBytes: todayUsageBytes,
      );

      // Midday with factor 1440 / 720 = 2.0 => 400 MB
      expect(prediction, equals(400000000));
    });

    test('7-Day Moving Trend Percentage Calculation', () async {
      final controller = HomeController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      final now = DateTime(2026, 9, 10, 15, 0, 0);
      final trend = await controller.calculate7DayTrend(
        now: now,
        networkType: NetworkType.mobile,
      );

      // Trend should be computed as a double precision value
      expect(trend, isA<double>());
    });

    test('HomeController loads state, handles network changes, and selects day', () async {
      final controller = HomeController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      await controller.loadDashboardData(referenceTime: DateTime(2026, 9, 10, 12, 0));

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.hasUsagePermission, isTrue);
      expect(controller.state.weekData.length, equals(7));
      expect(controller.state.topApps.isNotEmpty, isTrue);

      // Toggle to Wi-Fi
      await controller.setNetworkType(NetworkType.wifi);
      expect(controller.state.selectedNetworkType, equals(NetworkType.wifi));

      // Select specific day in week
      controller.selectDay(2); // Wednesday
      expect(controller.state.selectedDayIndex, equals(2));

      // Inject live speed snapshot
      final snapshot = TrafficSnapshot(
        uploadBytesPerSec: 1500000,
        downloadBytesPerSec: 5000000,
        totalBytesPerSec: 6500000,
        timestamp: DateTime.now(),
      );
      controller.updateLiveSpeed(snapshot);
      expect(controller.state.currentSpeed.totalBytesPerSec, equals(6500000));
    });
  });
}
