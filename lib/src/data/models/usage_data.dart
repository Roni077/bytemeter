import 'package:flutter/foundation.dart';
import 'enums.dart';

/// Aggregated or bucketed network traffic data for a timespan or specific application UID.
@immutable
class UsageData {
  UsageData({
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    int? totalBytes,
    this.uid,
    DateTime? startTime,
    DateTime? endTime,
  })  : totalBytes = totalBytes ?? (uploadBytes + downloadBytes),
        startTime = startTime ?? DateTime.fromMillisecondsSinceEpoch(0),
        endTime = endTime ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Deserializes a map received from native network stats queries.
  factory UsageData.fromMap(Map<dynamic, dynamic> map) {
    final upload = (map['upload'] as num?)?.toInt() ?? 0;
    final download = (map['download'] as num?)?.toInt() ?? 0;
    final total = (map['total'] as num?)?.toInt() ?? (upload + download);
    final uid = (map['uid'] as num?)?.toInt();
    final startMs = (map['startTime'] as num?)?.toInt();
    final endMs = (map['endTime'] as num?)?.toInt();

    return UsageData(
      uploadBytes: upload,
      downloadBytes: download,
      totalBytes: total,
      uid: uid,
      startTime: startMs != null ? DateTime.fromMillisecondsSinceEpoch(startMs) : DateTime.fromMillisecondsSinceEpoch(0),
      endTime: endMs != null ? DateTime.fromMillisecondsSinceEpoch(endMs) : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final int uploadBytes;
  final int downloadBytes;
  final int totalBytes;
  final int? uid;
  final DateTime startTime;
  final DateTime endTime;

  /// Returns the byte amount corresponding to the specified directional filter.
  int forDirection(DataDirection direction) {
    switch (direction) {
      case DataDirection.upload:
        return uploadBytes;
      case DataDirection.download:
        return downloadBytes;
      case DataDirection.bidirectional:
        return totalBytes;
    }
  }

  UsageData copyWith({
    int? uploadBytes,
    int? downloadBytes,
    int? totalBytes,
    int? uid,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final up = uploadBytes ?? this.uploadBytes;
    final down = downloadBytes ?? this.downloadBytes;
    return UsageData(
      uploadBytes: up,
      downloadBytes: down,
      totalBytes: totalBytes ?? (up + down),
      uid: uid ?? this.uid,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'upload': uploadBytes,
      'download': downloadBytes,
      'total': totalBytes,
      'uid': uid,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageData &&
          runtimeType == other.runtimeType &&
          uploadBytes == other.uploadBytes &&
          downloadBytes == other.downloadBytes &&
          totalBytes == other.totalBytes &&
          uid == other.uid &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => Object.hash(
        uploadBytes,
        downloadBytes,
        totalBytes,
        uid,
        startTime,
        endTime,
      );

  @override
  String toString() =>
      'UsageData(uid: $uid, up: $uploadBytes, down: $downloadBytes, total: $totalBytes, range: $startTime -> $endTime)';
}
