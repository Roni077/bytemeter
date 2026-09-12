import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:bytemeter/src/core/theme/color_schemes.dart';
import 'package:bytemeter/src/core/utils/data_size.dart';

/// Comparative Dual Horizontal Line/Bar Chart with dynamic linear gradient text shader mask.
/// Automatically inverts text colors between filled bar sections and empty background.
class ComparativeLineChart extends StatelessWidget {
  const ComparativeLineChart({
    super.key,
    required this.primaryBytes,
    required this.secondaryBytes,
    this.primaryLabel,
    this.secondaryLabel,
    this.primaryColor,
    this.secondaryColor,
    this.height = 36.0,
    this.borderRadius = 10.0,
  });

  /// Left/Primary bandwidth bytes (e.g. Download or Cellular).
  final int primaryBytes;

  /// Right/Secondary bandwidth bytes (e.g. Upload or Wi-Fi).
  final int secondaryBytes;

  /// Optional left label override (defaults to formatted primary bytes).
  final String? primaryLabel;

  /// Optional right label override (defaults to formatted secondary bytes).
  final String? secondaryLabel;

  /// Custom left bar fill color (defaults to [AppColorSchemes.downloadColor] or primary).
  final Color? primaryColor;

  /// Custom right bar fill color (defaults to [AppColorSchemes.uploadColor] or secondary).
  final Color? secondaryColor;

  /// Total height of the comparative bar.
  final double height;

  /// Corner radius of the rounded bar.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final primary = primaryColor ?? AppColorSchemes.downloadColor;
    final secondary = secondaryColor ?? AppColorSchemes.uploadColor;
    final neutralTrack = colorScheme.surfaceContainerHighest;

    final total = primaryBytes + secondaryBytes;
    final double primaryRatio = total > 0 ? (primaryBytes / total).clamp(0.0, 1.0) : 0.0;
    final double secondaryRatio = total > 0 ? (secondaryBytes / total).clamp(0.0, 1.0) : 0.0;

    final leftText = primaryLabel ?? DataSize(primaryBytes).format();
    final rightText = secondaryLabel ?? DataSize(secondaryBytes).format();

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, height),
              painter: _ComparativeChartPainter(
                primaryRatio: primaryRatio,
                secondaryRatio: secondaryRatio,
                leftText: leftText,
                rightText: rightText,
                primaryColor: primary,
                secondaryColor: secondary,
                neutralColor: neutralTrack,
                onPrimaryColor: Colors.white,
                onSecondaryColor: Colors.white,
                onSurfaceColor: colorScheme.onSurface,
                borderRadius: borderRadius,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ComparativeChartPainter extends CustomPainter {
  const _ComparativeChartPainter({
    required this.primaryRatio,
    required this.secondaryRatio,
    required this.leftText,
    required this.rightText,
    required this.primaryColor,
    required this.secondaryColor,
    required this.neutralColor,
    required this.onPrimaryColor,
    required this.onSecondaryColor,
    required this.onSurfaceColor,
    required this.borderRadius,
  });

  final double primaryRatio;
  final double secondaryRatio;
  final String leftText;
  final String rightText;
  final Color primaryColor;
  final Color secondaryColor;
  final Color neutralColor;
  final Color onPrimaryColor;
  final Color onSecondaryColor;
  final Color onSurfaceColor;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Clip to rounded bar container
    canvas.save();
    canvas.clipRRect(rrect);

    // 1. Draw Base Neutral Background
    final bgPaint = Paint()..color = neutralColor;
    canvas.drawRect(rect, bgPaint);

    // 2. Draw Left Primary Bar (Fills from Left -> Right)
    final double leftWidth = size.width * primaryRatio;
    if (leftWidth > 0) {
      final leftPaint = Paint()..color = primaryColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, leftWidth, size.height), leftPaint);
    }

    // 3. Draw Right Secondary Bar (Fills from Right -> Left)
    final double rightWidth = size.width * secondaryRatio;
    if (rightWidth > 0) {
      final rightPaint = Paint()..color = secondaryColor;
      canvas.drawRect(
        Rect.fromLTWH(size.width - rightWidth, 0, rightWidth, size.height),
        rightPaint,
      );
    }

    // 4. Render Left and Right Text Labels with Dynamic Color Inversion
    _drawInvertedText(
      canvas: canvas,
      size: size,
      text: leftText,
      alignLeft: true,
      leftWidth: leftWidth,
      rightWidth: rightWidth,
    );

    _drawInvertedText(
      canvas: canvas,
      size: size,
      text: rightText,
      alignLeft: false,
      leftWidth: leftWidth,
      rightWidth: rightWidth,
    );

    canvas.restore();
  }

  void _drawInvertedText({
    required Canvas canvas,
    required Size size,
    required String text,
    required bool alignLeft,
    required double leftWidth,
    required double rightWidth,
  }) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    try {
      textPainter.layout();

      final double textY = (size.height - textPainter.height) / 2;
      final double textX = alignLeft
          ? 10.0
          : (size.width - textPainter.width - 10.0);

      final textRect = Rect.fromLTWH(textX, textY, textPainter.width, textPainter.height);

      // Construct linear gradient shader mask matching bar boundaries over the text's bounding box
      final textStartRatio = (textRect.left / size.width).clamp(0.0, 1.0);
      final textEndRatio = (textRect.right / size.width).clamp(0.0, 1.0);
      final primarySplit = (leftWidth / size.width).clamp(0.0, 1.0);
      final secondarySplit = ((size.width - rightWidth) / size.width).clamp(0.0, 1.0);

      // Check overlap with primary bar
      if (textStartRatio < primarySplit && textEndRatio > primarySplit) {
        // Spanning the split boundary: apply horizontal gradient shader
        final localSplit = ((primarySplit - textStartRatio) / (textEndRatio - textStartRatio)).clamp(0.0, 1.0);
        final shader = ui.Gradient.linear(
          Offset(textRect.left, 0),
          Offset(textRect.right, 0),
          [onPrimaryColor, onPrimaryColor, onSurfaceColor, onSurfaceColor],
          [0.0, localSplit, (localSplit + 0.01).clamp(0.0, 1.0), 1.0],
        );

        textPainter.text = TextSpan(
          text: text,
          style: style.copyWith(foreground: Paint()..shader = shader),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(textX, textY));
        return;
      }

      Color textColor = onSurfaceColor;
      if (textEndRatio <= primarySplit) {
        textColor = onPrimaryColor;
      } else if (textStartRatio >= secondarySplit) {
        textColor = onSecondaryColor;
      }

      textPainter.text = TextSpan(
        text: text,
        style: style.copyWith(color: textColor),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(textX, textY));
    } finally {
      textPainter.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _ComparativeChartPainter oldDelegate) {
    return oldDelegate.primaryRatio != primaryRatio ||
        oldDelegate.secondaryRatio != secondaryRatio ||
        oldDelegate.leftText != leftText ||
        oldDelegate.rightText != rightText ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.neutralColor != neutralColor ||
        oldDelegate.onPrimaryColor != onPrimaryColor ||
        oldDelegate.onSecondaryColor != onSecondaryColor ||
        oldDelegate.onSurfaceColor != onSurfaceColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}
