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
    );
    try {
      textPainter.layout();
      return textPainter.size;
    } finally {
      textPainter.dispose();
    }
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

    final painter = TextPainter(textDirection: textDirection);
    try {
      // Fast-path 1: Check if text already fits cleanly at maxFontSize
      painter.text = TextSpan(text: text, style: baseStyle.copyWith(fontSize: maxFontSize));
      painter.layout();
      if (painter.width <= maxWidth) {
        return maxFontSize;
      }

      // Fast-path 2: Check if even minFontSize exceeds maxWidth
      painter.text = TextSpan(text: text, style: baseStyle.copyWith(fontSize: minFontSize));
      painter.layout();
      if (painter.width >= maxWidth) {
        return minFontSize;
      }

      double low = minFontSize;
      double high = maxFontSize;
      double bestFit = minFontSize;

      for (int i = 0; i < maxIterations; i++) {
        final mid = (low + high) / 2.0;
        painter.text = TextSpan(text: text, style: baseStyle.copyWith(fontSize: mid));
        painter.layout();

        if (painter.width <= maxWidth) {
          bestFit = mid;
          low = mid;
        } else {
          high = mid;
        }

        if ((high - low).abs() < 0.25) break;
      }

      return bestFit;
    } finally {
      painter.dispose();
    }
  }
}
