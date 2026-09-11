import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bytemeter/src/core/constants/special_uids.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/native/speed_stream_listener.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/data/models/traffic_snapshot.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpecialUids Constants & Helpers', () {
    test('Special UID values match Android conventions', () {
      expect(SpecialUids.uidAll, -100);
      expect(SpecialUids.uidUnknown, -99);
      expect(SpecialUids.uidOtherUsers, -98);
      expect(SpecialUids.uidTethering, -5);
      expect(SpecialUids.uidRemoved, -4);
    });

    test('isSpecial returns true for negative UIDs', () {
      expect(SpecialUids.isSpecial(-100), isTrue);
      expect(SpecialUids.isSpecial(-5), isTrue);
      expect(SpecialUids.isSpecial(1000), isFalse);
      expect(SpecialUids.isSpecial(10245), isFalse);
    });
  });

  group('Domain Enums', () {
    test('NetworkType maps to expected indexes', () {
      expect(NetworkType.mobile.typeIndex, 0);
      expect(NetworkType.wifi.typeIndex, 1);
      expect(NetworkType.mobile.displayName, 'Mobile');
      expect(NetworkType.wifi.displayName, 'Wi-Fi');
    });

    test('DataDirection display names', () {
      expect(DataDirection.upload.displayName, 'Upload');
      expect(DataDirection.download.displayName, 'Download');
      expect(DataDirection.bidirectional.displayName, 'Bidirectional');
    });

    test('TimeIntervalType values', () {
      expect(TimeIntervalType.daily.displayName, 'Daily');
      expect(TimeIntervalType.monthly.displayName, 'Monthly');
      expect(TimeIntervalType.custom.displayName, 'Custom');
    });
  });

  group('TrafficSnapshot Model', () {
    test('fromMap parses raw map correctly', () {
      final map = <dynamic, dynamic>{
        'upBytesPerSec': 102400,
        'downBytesPerSec': 512000,
        'totalBytesPerSec': 614400,
        'interfaces': ['wlan0', 'rmnet0'],
        'timestamp': 1700000000000,
      };

      final snapshot = TrafficSnapshot.fromMap(map);
      expect(snapshot.uploadBytesPerSec, 102400);
      expect(snapshot.downloadBytesPerSec, 512000);
      expect(snapshot.totalBytesPerSec, 614400);
      expect(snapshot.interfaces, ['wlan0', 'rmnet0']);
      expect(snapshot.timestamp.millisecondsSinceEpoch, 1700000000000);
    });

    test('zero snapshot initialization', () {
      final zero = TrafficSnapshot.zero();
      expect(zero.uploadBytesPerSec, 0);
      expect(zero.downloadBytesPerSec, 0);
      expect(zero.totalBytesPerSec, 0);
      expect(zero.interfaces, isEmpty);
    });

    test('copyWith updates fields correctly', () {
      final initial = TrafficSnapshot(
        uploadBytesPerSec: 100,
        downloadBytesPerSec: 200,
        totalBytesPerSec: 300,
        interfaces: const ['wlan0'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      final updated = initial.copyWith(uploadBytesPerSec: 500);
      expect(updated.uploadBytesPerSec, 500);
      expect(updated.downloadBytesPerSec, 200);
      expect(updated.interfaces, ['wlan0']);
    });

    test('equality and hashcode', () {
      final s1 = TrafficSnapshot(
        uploadBytesPerSec: 100,
        downloadBytesPerSec: 200,
        totalBytesPerSec: 300,
        interfaces: const ['wlan0'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      final s2 = TrafficSnapshot(
        uploadBytesPerSec: 100,
        downloadBytesPerSec: 200,
        totalBytesPerSec: 300,
        interfaces: const ['wlan0'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });
  });

  group('UsageData Model', () {
    test('forDirection returns appropriate byte count', () {
      final usage = UsageData(
        uploadBytes: 500,
        downloadBytes: 1500,
        totalBytes: 2000,
      );

      expect(usage.forDirection(DataDirection.upload), 500);
      expect(usage.forDirection(DataDirection.download), 1500);
      expect(usage.forDirection(DataDirection.bidirectional), 2000);
    });

    test('fromMap parses map correctly', () {
      final map = <dynamic, dynamic>{
        'upload': 10000,
        'download': 30000,
        'total': 40000,
        'uid': 10123,
        'startTime': 1700000000000,
        'endTime': 1700086400000,
      };

      final data = UsageData.fromMap(map);
      expect(data.uploadBytes, 10000);
      expect(data.downloadBytes, 30000);
      expect(data.totalBytes, 40000);
      expect(data.uid, 10123);
      expect(data.startTime.millisecondsSinceEpoch, 1700000000000);
      expect(data.endTime.millisecondsSinceEpoch, 1700086400000);
    });

    test('copyWith recalculates total if not provided', () {
      final initial = UsageData(uploadBytes: 100, downloadBytes: 200);
      final updated = initial.copyWith(uploadBytes: 300);
      expect(updated.uploadBytes, 300);
      expect(updated.downloadBytes, 200);
      expect(updated.totalBytes, 500);
    });
  });

  group('AppInfo Model', () {
    test('fromMap parses installed application info', () {
      final map = <dynamic, dynamic>{
        'uid': 10050,
        'packageName': 'com.example.app',
        'label': 'Example App',
        'iconBytes': [1, 2, 3, 4],
        'isSpecial': false,
      };

      final app = AppInfo.fromMap(map);
      expect(app.uid, 10050);
      expect(app.packageName, 'com.example.app');
      expect(app.label, 'Example App');
      expect(app.iconBytes, equals(Uint8List.fromList([1, 2, 3, 4])));
      expect(app.isSpecial, isFalse);
    });

    test('special app identification from negative UID', () {
      final map = <dynamic, dynamic>{
        'uid': -100,
        'packageName': 'system.all_apps',
        'label': 'All Apps',
      };

      final app = AppInfo.fromMap(map);
      expect(app.isSpecial, isTrue);
    });
  });

  group('SpeedStreamListener Stream Mapping', () {
    test('emits typed TrafficSnapshot events from dynamic stream', () async {
      final controller = StreamController<dynamic>();
      final listener = SpeedStreamListener(mockStream: controller.stream);

      final events = <TrafficSnapshot>[];
      final sub = listener.speedStream.listen(events.add);

      controller.add(<dynamic, dynamic>{
        'upBytesPerSec': 1000,
        'downBytesPerSec': 5000,
        'totalBytesPerSec': 6000,
        'interfaces': ['wlan0'],
        'timestamp': 1700000000000,
      });

      await Future<void>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.first.uploadBytesPerSec, 1000);
      expect(events.first.downloadBytesPerSec, 5000);
      expect(events.first.totalBytesPerSec, 6000);

      await sub.cancel();
      await controller.close();
    });
  });

  group('NativeTrafficBridge Mock Channel Invocation', () {
    const channel = MethodChannel('com.bytemeter/bridge_test');
    late NativeTrafficBridge bridge;

    setUp(() {
      bridge = NativeTrafficBridge(channel: channel);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'hasUsagePermission':
            return true;
          case 'isIgnoringBatteryOptimizations':
            return true;
          case 'isServiceRunning':
            return false;
          case 'startForegroundService':
            return true;
          case 'queryDeviceSummary':
            return <dynamic, dynamic>{
              'upload': 1048576,
              'download': 2097152,
              'total': 3145728,
            };
          case 'encryptSubscriberId':
            return 'encrypted_token_123';
          case 'decryptSubscriberId':
            return 'sub_id_456';
          case 'hashSubscriberId':
            return 'hash_789';
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('checks permissions successfully', () async {
      final hasPerm = await bridge.hasUsagePermission();
      expect(hasPerm, isTrue);

      final isIgnored = await bridge.isIgnoringBatteryOptimizations();
      expect(isIgnored, isTrue);
    });

    test('queries device summary successfully', () async {
      final summary = await bridge.queryDeviceSummary(
        networkType: NetworkType.wifi,
        startTime: DateTime.fromMillisecondsSinceEpoch(1000),
        endTime: DateTime.fromMillisecondsSinceEpoch(2000),
      );

      expect(summary.uploadBytes, 1048576);
      expect(summary.downloadBytes, 2097152);
      expect(summary.totalBytes, 3145728);
    });

    test('crypto methods invoke properly', () async {
      final enc = await bridge.encryptSubscriberId('test_sub');
      expect(enc, 'encrypted_token_123');

      final dec = await bridge.decryptSubscriberId('encrypted_token_123');
      expect(dec, 'sub_id_456');

      final hash = await bridge.hashSubscriberId('test_sub');
      expect(hash, 'hash_789');
    });
  });
}
