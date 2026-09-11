import 'dart:async';
import 'package:flutter/services.dart';
import '../../data/models/traffic_snapshot.dart';
import 'platform_channel.dart';

/// Stream listener bridging the native 1-second live speed EventChannel into typed [TrafficSnapshot] events.
class SpeedStreamListener {
  SpeedStreamListener({
    EventChannel? eventChannel,
    Stream<dynamic>? mockStream,
  }) : _stream = mockStream ??
            (eventChannel ?? PlatformChannels.speedEventChannel).receiveBroadcastStream();

  final Stream<dynamic> _stream;

  /// Exposes a broadcast stream of real-time speed snapshots.
  Stream<TrafficSnapshot> get speedStream {
    return _stream
        .where((event) => event is Map<dynamic, dynamic>)
        .map((event) => TrafficSnapshot.fromMap(event as Map<dynamic, dynamic>))
        .handleError((Object error, StackTrace stackTrace) {
      // Gracefully handle stream errors
    });
  }
}
