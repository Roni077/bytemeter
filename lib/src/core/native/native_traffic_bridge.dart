import 'package:flutter/services.dart';
import '../../data/models/app_info.dart';
import '../../data/models/enums.dart';
import '../../data/models/usage_data.dart';
import 'platform_channel.dart';

/// Dart bridge interface to native Android background engine and stats queries.
class NativeTrafficBridge {
  NativeTrafficBridge({
    MethodChannel? channel,
  }) : _channel = channel ?? PlatformChannels.bridgeMethodChannel;

  final MethodChannel _channel;

  /// Checks if `PACKAGE_USAGE_STATS` is granted to ByteMeter.
  Future<bool> hasUsagePermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasUsagePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system Usage Access settings screen.
  Future<bool> requestUsagePermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestUsagePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if battery optimization is currently ignored for ByteMeter.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the system dialog to ignore battery optimizations.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if notifications are enabled for ByteMeter.
  Future<bool> hasNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasNotificationPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens system notification settings for ByteMeter.
  Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if `READ_PHONE_STATE` is granted to ByteMeter.
  Future<bool> hasPhonePermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPhonePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens app details settings to grant phone state permission.
  Future<bool> requestPhonePermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPhonePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Starts the persistent foreground speed monitoring service.
  Future<bool> startForegroundService() async {
    try {
      final result = await _channel.invokeMethod<bool>('startForegroundService');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Stops the persistent foreground speed monitoring service.
  Future<bool> stopForegroundService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopForegroundService');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if the foreground service is actively running.
  Future<bool> isServiceRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Updates foreground service notification preferences in real time.
  Future<bool> updateServiceSettings({
    bool? inBits,
    bool? separateUpDown,
    bool? metric1000,
    bool? aodMode,
    int? speedThresholdKb,
    bool? forceFallback,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateServiceSettings',
        <String, dynamic>{
          'inBits': ?inBits,
          'separateUpDown': ?separateUpDown,
          'metric1000': ?metric1000,
          'aodMode': ?aodMode,
          'speedThresholdKb': ?speedThresholdKb,
          'forceFallback': ?forceFallback,
        },
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Queries the aggregated device total network usage for a time period.
  Future<UsageData> queryDeviceSummary({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'queryDeviceSummary',
        <String, dynamic>{
          'networkType': networkType.typeIndex,
          'subscriberId': subscriberId,
          'startTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
        },
      );
      if (result != null) {
        return UsageData.fromMap({
          ...result,
          'startTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
        });
      }
    } on PlatformException {
      // Fallback on platform error
    }
    return UsageData(startTime: startTime, endTime: endTime);
  }

  /// Queries per-UID aggregated usage buckets for a time period.
  Future<List<UsageData>> queryAppBuckets({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final result = await _channel.invokeListMethod<dynamic>(
        'queryAppBuckets',
        <String, dynamic>{
          'networkType': networkType.typeIndex,
          'subscriberId': subscriberId,
          'startTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
        },
      );
      if (result != null) {
        return result
            .whereType<Map<dynamic, dynamic>>()
            .map((map) => UsageData.fromMap(map))
            .toList(growable: false);
      }
    } on PlatformException {
      // Fallback on platform error
    }
    return const [];
  }

  /// Queries hourly or 2-hour interval time-slot buckets for a time period.
  Future<List<UsageData>> queryHourlyBuckets({
    required NetworkType networkType,
    String? subscriberId,
    required DateTime startTime,
    required DateTime endTime,
    int? uid,
  }) async {
    try {
      final result = await _channel.invokeListMethod<dynamic>(
        'queryHourlyBuckets',
        <String, dynamic>{
          'networkType': networkType.typeIndex,
          'subscriberId': subscriberId,
          'startTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
          'uid': uid,
        },
      );
      if (result != null) {
        return result
            .whereType<Map<dynamic, dynamic>>()
            .map((map) => UsageData.fromMap(map))
            .toList(growable: false);
      }
    } on PlatformException {
      // Fallback on platform error
    }
    return const [];
  }

  /// Retrieves all installed apps with metadata, labels, and icon byte arrays.
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result = await _channel.invokeListMethod<dynamic>('getInstalledApps');
      if (result != null) {
        return result
            .whereType<Map<dynamic, dynamic>>()
            .map((map) => AppInfo.fromMap(map))
            .toList(growable: false);
      }
    } on PlatformException {
      // Fallback on platform error
    }
    return const [];
  }

  /// Launches an application by its package name.
  Future<bool> launchApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'launchApp',
        <String, dynamic>{'packageName': packageName},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Encrypts a SIM subscriber ID using Android KeyStore AES-GCM.
  Future<String> encryptSubscriberId(String id) async {
    final result = await _channel.invokeMethod<String>(
      'encryptSubscriberId',
      <String, dynamic>{'id': id},
    );
    return result ?? '';
  }

  /// Decrypts a SIM subscriber ID using Android KeyStore AES-GCM.
  Future<String?> decryptSubscriberId(String encrypted) async {
    return _channel.invokeMethod<String>(
      'decryptSubscriberId',
      <String, dynamic>{'encrypted': encrypted},
    );
  }

  /// Computes the HMAC-SHA256 hash of a subscriber ID for database indexing.
  Future<String> hashSubscriberId(String id) async {
    final result = await _channel.invokeMethod<String>(
      'hashSubscriberId',
      <String, dynamic>{'id': id},
    );
    return result ?? '';
  }
}
