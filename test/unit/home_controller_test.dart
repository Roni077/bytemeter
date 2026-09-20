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

  group('HomeController - Core Data Loading & Interactions', () {
    test('HomeController loads dual usage state and selects day', () async {
      final controller = HomeController(
        usageRepo: usageRepo,
        prefsRepo: prefsRepo,
      );

      await controller.loadDashboardData(referenceTime: DateTime(2026, 9, 10, 12, 0));

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.hasUsagePermission, isTrue);
      
      // Dual Network Usage
      expect(controller.state.todayMobileUsage.totalBytes, greaterThanOrEqualTo(0));
      expect(controller.state.todayWifiUsage.totalBytes, greaterThanOrEqualTo(0));
      
      // Monthly Usage
      expect(controller.state.totalMonthCellularBytes, greaterThanOrEqualTo(0));
      expect(controller.state.totalMonthWifiBytes, greaterThanOrEqualTo(0));

      // Weekly Breakdown
      expect(controller.state.weekData.length, equals(7));

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
