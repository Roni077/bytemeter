import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bytemeter/src/core/theme/color_schemes.dart';
import 'package:bytemeter/src/core/theme/typography.dart';
import 'package:bytemeter/src/core/utils/data_size.dart';

/// Circular Arc Progress Chart for Extra Addon Packs showing consumed vs total allowance.
class ExtraPackProgressChart extends StatefulWidget {
  const ExtraPackProgressChart({
    super.key,
    required this.usedBytes,
    required this.totalBytes,
    this.name = 'Addon Pack',
    this.size = 140.0,
    this.strokeWidth = 12.0,
    this.expiryLabel,
  });

  /// Bytes consumed from this extra pack.
  final int usedBytes;

  /// Total quota bytes of this extra pack.
  final int totalBytes;

  /// Display name of the extra pack (e.g. "+5 GB Booster").
  final String name;

  /// Diameter size of the circular chart.
  final double size;

  /// Stroke width of the progress arc.
  final double strokeWidth;

  /// Optional expiration label (e.g. "Expires in 5 days").
  final String? expiryLabel;

  @override
  State<ExtraPackProgressChart> createState() => _ExtraPackProgressChartState();
}

class _ExtraPackProgressChartState extends State<ExtraPackProgressChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final targetRatio = widget.totalBytes > 0
        ? (widget.usedBytes / widget.totalBytes).clamp(0.0, 1.0)
        : 0.0;

    _progressAnimation = Tween<double>(begin: 0.0, end: targetRatio).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant ExtraPackProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.usedBytes != oldWidget.usedBytes ||
        widget.totalBytes != oldWidget.totalBytes) {
      final newRatio = widget.totalBytes > 0
          ? (widget.usedBytes / widget.totalBytes).clamp(0.0, 1.0)
          : 0.0;
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: newRatio,
      ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final remainingBytes = math.max(0, widget.totalBytes - widget.usedBytes);
    final remainingRatio = widget.totalBytes > 0
        ? (remainingBytes / widget.totalBytes)
        : 0.0;

    // Warning color if remaining data is below 15%
    final isLow = remainingRatio <= 0.15;
    final isExhausted = remainingBytes == 0;

    final Color activeColor = isExhausted
        ? AppColorSchemes.unsafeColor
        : (isLow ? AppColorSchemes.neutralColor : colorScheme.primary);

    final Color containerColor = isExhausted
        ? colorScheme.errorContainer
        : (isLow ? colorScheme.secondaryContainer : colorScheme.primaryContainer);

    final parts = DataSize(remainingBytes).toParts();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Canvas Circular Progress Arc
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _ExtraPackArcPainter(
                      progress: _progressAnimation.value,
                      strokeWidth: widget.strokeWidth,
                      activeColor: activeColor,
                      containerColor: containerColor,
                      trackColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),

              // Center Information
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LEFT',
                      style: AppTypography.chartLabelStyle(
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 10,
                      ).copyWith(letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            parts.first,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (parts.second.isNotEmpty)
                            Text(
                              parts.second,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      parts.third,
                      style: AppTypography.heroUnitStyle(
                        activeColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Pack Name
        Text(
          widget.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        // Optional Expiry Label
        if (widget.expiryLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.expiryLabel!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLow ? activeColor : colorScheme.onSurfaceVariant,
              fontWeight: isLow ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExtraPackArcPainter extends CustomPainter {
  const _ExtraPackArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.containerColor,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color activeColor;
  final Color containerColor;
  final Color trackColor;

  // 240 degree sweep arc (-210 degrees to +30 degrees)
  static const double startAngle = -math.pi * 1.15;
  static const double totalSweepAngle = math.pi * 1.30;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Draw Background Track Arc
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweepAngle,
      false,
      trackPaint,
    );

    // 2. Draw Active Progress Arc
    if (progress > 0) {
      final sweep = (totalSweepAngle * progress).clamp(0.01, totalSweepAngle);

      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + totalSweepAngle,
          colors: [
            containerColor,
            activeColor,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExtraPackArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.containerColor != containerColor ||
        oldDelegate.trackColor != trackColor;
  }
}
