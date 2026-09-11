import 'package:bytemeter/src/core/constants/special_uids.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/data/models/usage_data.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NetworkUsageRepository repository;

  setUp(() {
    repository = NetworkUsageRepository(bridge: NativeTrafficBridge());
  });

  group('NetworkUsageRepository - UID Reconciliation', () {
    test('Reconciles unaccounted difference to UID_OTHER_USERS (-98)', () {
      final deviceTotal = UsageData(
        uploadBytes: 1500,
        downloadBytes: 8500,
        totalBytes: 10000,
      );

      final appBuckets = [
        UsageData(uid: 10045, uploadBytes: 500, downloadBytes: 4000),
        UsageData(uid: 10089, uploadBytes: 400, downloadBytes: 2500),
        // Sum: upload = 900, download = 6500, total = 7400
      ];

      final reconciled = repository.reconcileDeviceDelta(deviceTotal, appBuckets);

      expect(reconciled, isNotNull);
      expect(reconciled!.uid, equals(SpecialUids.uidOtherUsers));
      expect(reconciled.uploadBytes, equals(600)); // 1500 - 900
      expect(reconciled.downloadBytes, equals(2000)); // 8500 - 6500
      expect(reconciled.totalBytes, equals(2600)); // 600 + 2000
    });

    test('Returns null when app buckets perfectly match device aggregate total', () {
      final deviceTotal = UsageData(
        uploadBytes: 1000,
        downloadBytes: 4000,
        totalBytes: 5000,
      );

      final appBuckets = [
        UsageData(uid: 10045, uploadBytes: 600, downloadBytes: 2500),
        UsageData(uid: 10089, uploadBytes: 400, downloadBytes: 1500),
      ];

      final reconciled = repository.reconcileDeviceDelta(deviceTotal, appBuckets);
      expect(reconciled, isNull);
    });

    test('Special UID constants identification', () {
      expect(SpecialUids.isSpecial(SpecialUids.uidAll), isTrue);
      expect(SpecialUids.isSpecial(SpecialUids.uidTethering), isTrue);
      expect(SpecialUids.isSpecial(SpecialUids.uidRemoved), isTrue);
      expect(SpecialUids.isSpecial(SpecialUids.uidOtherUsers), isTrue);
      expect(SpecialUids.isSpecial(10045), isFalse);
    });
  });
}
