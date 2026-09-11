import 'package:flutter/foundation.dart';

/// Instantaneous network transfer rate snapshot emitted from native background ticker.
@immutable
class TrafficSnapshot {
  const TrafficSnapshot({
    required this.uploadBytesPerSec,
    required this.downloadBytesPerSec,
    required this.totalBytesPerSec,
    this.interfaces = const <String>[],
    required this.timestamp,
  });

  /// Factory creating an empty or zero snapshot.
  factory TrafficSnapshot.zero() {
    return TrafficSnapshot(
      uploadBytesPerSec: 0,
      downloadBytesPerSec: 0,
      totalBytesPerSec: 0,
      interfaces: const [],
      timestamp: DateTime.now(),
    );
  }

  /// Deserializes a map received from the native EventChannel stream.
  factory TrafficSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final up = (map['upBytesPerSec'] as num?)?.toInt() ?? 0;
    final down = (map['downBytesPerSec'] as num?)?.toInt() ?? 0;
    final total = (map['totalBytesPerSec'] as num?)?.toInt() ?? (up + down);
    final rawInterfaces = map['interfaces'] as List<dynamic>?;
    final interfaces = rawInterfaces != null
        ? rawInterfaces.map((e) => e.toString()).toList(growable: false)
        : const <String>[];
    final timestampMs = (map['timestamp'] as num?)?.toInt();
    final timestamp = timestampMs != null
        ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
        : DateTime.now();

    return TrafficSnapshot(
      uploadBytesPerSec: up,
      downloadBytesPerSec: down,
      totalBytesPerSec: total,
      interfaces: interfaces,
      timestamp: timestamp,
    );
  }

  final int uploadBytesPerSec;
  final int downloadBytesPerSec;
  final int totalBytesPerSec;
  final List<String> interfaces;
  final DateTime timestamp;

  TrafficSnapshot copyWith({
    int? uploadBytesPerSec,
    int? downloadBytesPerSec,
    int? totalBytesPerSec,
    List<String>? interfaces,
    DateTime? timestamp,
  }) {
    return TrafficSnapshot(
      uploadBytesPerSec: uploadBytesPerSec ?? this.uploadBytesPerSec,
      downloadBytesPerSec: downloadBytesPerSec ?? this.downloadBytesPerSec,
      totalBytesPerSec: totalBytesPerSec ?? this.totalBytesPerSec,
      interfaces: interfaces ?? this.interfaces,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'upBytesPerSec': uploadBytesPerSec,
      'downBytesPerSec': downloadBytesPerSec,
      'totalBytesPerSec': totalBytesPerSec,
      'interfaces': interfaces,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrafficSnapshot &&
          runtimeType == other.runtimeType &&
          uploadBytesPerSec == other.uploadBytesPerSec &&
          downloadBytesPerSec == other.downloadBytesPerSec &&
          totalBytesPerSec == other.totalBytesPerSec &&
          listEquals(interfaces, other.interfaces) &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        uploadBytesPerSec,
        downloadBytesPerSec,
        totalBytesPerSec,
        Object.hashAll(interfaces),
        timestamp,
      );

  @override
  String toString() =>
      'TrafficSnapshot(up: $uploadBytesPerSec B/s, down: $downloadBytesPerSec B/s, total: $totalBytesPerSec B/s, ifaces: $interfaces)';
}
