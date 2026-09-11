import 'package:flutter/services.dart';

/// Centralized tactile haptic feedback controller.
class AppHaptics {
  const AppHaptics._();

  /// Subtle click for selection changes and filter toggles.
  static Future<void> contextClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Light impact for toggle switches and button taps.
  static Future<void> toggleTick() async {
    await HapticFeedback.lightImpact();
  }

  /// Light selection tick for pill selectors and tabs.
  static Future<void> selectionTick() async {
    await HapticFeedback.selectionClick();
  }

  /// Medium impact for long-press actions and expand triggers.
  static Future<void> longPress() async {
    await HapticFeedback.mediumImpact();
  }

  /// Frequent light tick for continuous fling scrolling past consecutive day bars.
  static Future<void> segmentFrequentTick() async {
    await HapticFeedback.selectionClick();
  }

  /// Heavy warning vibration when quota threshold is exceeded.
  static Future<void> warning() async {
    await HapticFeedback.heavyImpact();
  }
}
