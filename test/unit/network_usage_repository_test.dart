import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';

import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';

class MockNativeTrafficBridge extends Fake implements NativeTrafficBridge {
  int getAppIconCalls = 0;
  int getInstalledAppsCalls = 0;
  int getAppInfoByUidCalls = 0;
  final Map<String, Uint8List?> iconResponses = {};
  Completer<Uint8List?>? delayCompleter;

  @override
  Future<Uint8List?> getAppIcon(String packageName) async {
    getAppIconCalls++;
    if (delayCompleter != null) {
      await delayCompleter!.future;
    }
    return iconResponses[packageName];
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async {
    getInstalledAppsCalls++;
    return [
      const AppInfo(uid: 10001, packageName: 'com.google.android.youtube', label: 'YouTube'),
      const AppInfo(uid: 10002, packageName: 'com.whatsapp', label: 'WhatsApp'),
    ];
  }

  @override
  Future<AppInfo?> getAppInfoByUid(int uid) async {
    getAppInfoByUidCalls++;
    if (uid == 10001) {
      return const AppInfo(uid: 10001, packageName: 'com.google.android.youtube', label: 'YouTube');
    } else if (uid == 10002) {
      return const AppInfo(uid: 10002, packageName: 'com.whatsapp', label: 'WhatsApp');
    }
    return null;
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
        uid: 10002,
        uploadBytes: 1000,
        downloadBytes: 2000,
        totalBytes: 3000,
        startTime: startTime,
        endTime: endTime,
      ),
      UsageData(
        uid: 10001,
        uploadBytes: 5000,
        downloadBytes: 15000,
        totalBytes: 20000,
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
      uploadBytes: 6000,
      downloadBytes: 17000,
      totalBytes: 23000,
      startTime: startTime,
      endTime: endTime,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> queryCombinedTimeline({
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return [
      {
        'startTime': startTime.millisecondsSinceEpoch,
        'cellTotal': 10000,
        'wifiTotal': 20000,
      }
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNativeTrafficBridge mockBridge;
  late NetworkUsageRepository repo;
  final dummyPng = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  setUp(() {
    mockBridge = MockNativeTrafficBridge();
    repo = NetworkUsageRepository(bridge: mockBridge);
  });

  group('NetworkUsageRepository App Icon Lazy Loading & Caching', () {
    test('Special, system, and uid_ package names return null without calling bridge', () async {
      expect(await repo.getAppIcon(''), isNull);
      expect(await repo.getAppIcon('system.all_apps'), isNull);
      expect(await repo.getAppIcon('uid_1000'), isNull);
      expect(mockBridge.getAppIconCalls, 0);
    });

    test('Loads icon from bridge and caches it in-memory', () async {
      mockBridge.iconResponses['com.whatsapp'] = dummyPng;

      expect(repo.getCachedAppIcon('com.whatsapp'), isNull);

      final icon1 = await repo.getAppIcon('com.whatsapp');
      expect(icon1, equals(dummyPng));
      expect(mockBridge.getAppIconCalls, 1);
      expect(repo.getCachedAppIcon('com.whatsapp'), equals(dummyPng));

      // Second call should come directly from in-memory cache
      final icon2 = await repo.getAppIcon('com.whatsapp');
      expect(icon2, equals(dummyPng));
      expect(mockBridge.getAppIconCalls, 1);
    });

    test('Deduplicates in-flight concurrent requests for the same package', () async {
      mockBridge.delayCompleter = Completer<Uint8List?>();
      mockBridge.iconResponses['com.google.android.youtube'] = dummyPng;

      // Trigger 3 concurrent requests before the bridge responds
      final future1 = repo.getAppIcon('com.google.android.youtube');
      final future2 = repo.getAppIcon('com.google.android.youtube');
      final future3 = repo.getAppIcon('com.google.android.youtube');

      expect(mockBridge.getAppIconCalls, 1);

      // Resolve the delay
      mockBridge.delayCompleter!.complete(dummyPng);

      final results = await Future.wait([future1, future2, future3]);
      expect(results[0], equals(dummyPng));
      expect(results[1], equals(dummyPng));
      expect(results[2], equals(dummyPng));
      expect(mockBridge.getAppIconCalls, 1);
    });

    test('Caches failed package names and does not re-query bridge', () async {
      mockBridge.iconResponses['com.nonexistent.app'] = null;

      final res1 = await repo.getAppIcon('com.nonexistent.app');
      expect(res1, isNull);
      expect(mockBridge.getAppIconCalls, 1);

      // Subsequent call should immediately return null without bridge call
      final res2 = await repo.getAppIcon('com.nonexistent.app');
      expect(res2, isNull);
      expect(mockBridge.getAppIconCalls, 1);
    });

    test('getInstalledApps enriches apps with previously cached icon bytes', () async {
      mockBridge.iconResponses['com.whatsapp'] = dummyPng;
      await repo.getAppIcon('com.whatsapp');

      final apps = await repo.getInstalledApps();
      final whatsapp = apps.firstWhere((a) => a.packageName == 'com.whatsapp');
      expect(whatsapp.iconBytes, equals(dummyPng));

      final youtube = apps.firstWhere((a) => a.packageName == 'com.google.android.youtube');
      expect(youtube.iconBytes, isNull);
    });
  });

  group('NetworkUsageRepository Progressive & On-Demand Data Loading', () {
    test('getTopAppUsages returns top N apps sorted descending by totalBytes', () async {
      final now = DateTime.now();
      final topApps = await repo.getTopAppUsages(
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        networkType: NetworkType.mobile,
        limit: 1,
      );

      expect(topApps.length, equals(1));
      expect(topApps.first.appInfo.uid, equals(10001)); // highest usage (20,000 bytes)
      expect(topApps.first.totalBytes, equals(20000));
    });

    test('getAppInfo resolves single UID on-demand without querying getInstalledApps', () async {
      expect(mockBridge.getInstalledAppsCalls, 0);

      final appInfo = await repo.getAppInfo(10001);
      expect(appInfo.packageName, equals('com.google.android.youtube'));
      expect(mockBridge.getAppInfoByUidCalls, 1);
      expect(mockBridge.getInstalledAppsCalls, 0); // Must NOT enumerate all apps!
    });

    test('getCombinedTimelineRange fetches batch timeline query', () async {
      final now = DateTime.now();
      final timeline = await repo.getCombinedTimelineRange(
        startTime: now.subtract(const Duration(days: 7)),
        endTime: now,
      );

      expect(timeline.isNotEmpty, isTrue);
      expect(timeline.first['cellTotal'], equals(10000));
    });
  });
}
