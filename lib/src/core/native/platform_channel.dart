import 'package:flutter/services.dart';

/// Platform channel identifiers and instances for ByteMeter.
class PlatformChannels {
  const PlatformChannels._();

  static const String methodChannelName = 'com.bytemeter/bridge';
  static const String eventChannelName = 'com.bytemeter/speed_stream';

  static const MethodChannel bridgeMethodChannel = MethodChannel(methodChannelName);
  static const EventChannel speedEventChannel = EventChannel(eventChannelName);
}
