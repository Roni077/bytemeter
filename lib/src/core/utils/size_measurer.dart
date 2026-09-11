import 'package:flutter/widgets.dart';

/// Text layout measurement utility for custom canvas graphics and dynamic text fitting.
class SizeMeasurer {
  const SizeMeasurer._();

  /// Measures the rendered pixel width and height of a given text [text] and [style].
  static Size measureText({
    required String text,
    required TextStyle style,
    double maxFontSize = 14.0,
    double minFontSize = 8.0,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
    )..layout();

    return textPainter.size;
  }

  /// Calculates the largest legible font size fitting within [maxWidth] using a binary search loop.
  static double findOptimalFontSize({
    required String text,
    required TextStyle baseStyle,
    required double maxWidth,
    double minFontSize = 8.0,
    double maxFontSize = 14.0,
    int maxIterations = 8,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (maxWidth <= 0) return minFontSize;

    double low = minFontSize;
    double high = maxFontSize;
    double bestFit = minFontSize;

    for (int i = 0; i < maxIterations; i++) {
      final mid = (low + high) / 2.0;
      final painter = TextPainter(
        text: TextSpan(text: text, style: baseStyle.copyWith(fontSize: mid)),
        textDirection: textDirection,
      )..layout();

      if (painter.width <= maxWidth) {
        bestFit = mid;
        low = mid;
      } else {
        high = mid;
      }

      if ((high - low).abs() < 0.25) break;
    }

    return bestFit;
  }
}
