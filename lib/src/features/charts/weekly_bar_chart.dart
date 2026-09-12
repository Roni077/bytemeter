import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:bytemeter/src/core/theme/color_schemes.dart';
import 'package:bytemeter/src/core/theme/typography.dart';
import 'package:bytemeter/src/core/utils/data_size.dart';
import 'package:bytemeter/src/core/utils/haptics.dart';

/// Single day data entry for [WeeklyBarChart].
class WeeklyDayData {
  const WeeklyDayData({
    required this.date,
    required this.cellularBytes,
    required this.wifiBytes,
  });

  final DateTime date;
  final int cellularBytes;
  final int wifiBytes;

  int get totalBytes => cellularBytes + wifiBytes;
}

/// Interactive Weekly Mon-Sun Bar Chart with stacked rounded dual-bars,
/// dashed reference grid lines, touch hit-testing, squeeze bounce animations,
/// and interactive legend toggles.
class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({
    super.key,
    required this.weekData,
    this.selectedDayIndex,
    this.onDaySelected,
    this.height = 240.0,
  });

  /// 7-day data sequence (Monday through Sunday).
  final List<WeeklyDayData> weekData;

  /// Currently selected day index (0 = Monday ... 6 = Sunday).
  final int? selectedDayIndex;

  /// Callback when user taps a specific day bar.
  final void Function(int dayIndex, WeeklyDayData data)? onDaySelected;

  /// Height of the entire chart card.
  final double height;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  bool _showCellular = true;
  bool _showWifi = true;

  // Squeeze bounce animation controller
  late final AnimationController _squeezeController;
  late final Animation<double> _squeezeWidthAnimation;
  late final Animation<double> _bounceHeightAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedDayIndex ?? _defaultTodayIndex();

    _squeezeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _squeezeWidthAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.75)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.75, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_squeezeController);

    _bounceHeightAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_squeezeController);
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDayIndex != null &&
        widget.selectedDayIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = widget.selectedDayIndex!;
      });
    }
  }

  @override
  void dispose() {
    _squeezeController.dispose();
    super.dispose();
  }

  int _defaultTodayIndex() {
    final now = DateTime.now();
    // In Dart weekday is 1=Mon ... 7=Sun
    return (now.weekday - 1).clamp(0, 6);
  }

  void _handleTapDown(TapDownDetails details, double chartWidth, double chartHeight) {
    if (widget.weekData.isEmpty) return;

    final partitionWidth = chartWidth / math.max(widget.weekData.length, 7);
    final tappedIndex = (details.localPosition.dx / partitionWidth).floor().clamp(0, widget.weekData.length - 1);

    setState(() {
      _selectedIndex = tappedIndex;
    });

    _squeezeController.forward(from: 0.0);
    AppHaptics.contextClick();

    if (widget.onDaySelected != null && tappedIndex < widget.weekData.length) {
      widget.onDaySelected!(tappedIndex, widget.weekData[tappedIndex]);
    }
  }

  void _toggleCellular() {
    setState(() {
      _showCellular = !_showCellular;
      if (!_showCellular && !_showWifi) _showWifi = true;
    });
    AppHaptics.toggleTick();
  }

  void _toggleWifi() {
    setState(() {
      _showWifi = !_showWifi;
      if (!_showWifi && !_showCellular) _showCellular = true;
    });
    AppHaptics.toggleTick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedData = (widget.weekData.isNotEmpty && _selectedIndex < widget.weekData.length)
        ? widget.weekData[_selectedIndex]
        : null;

    final selectedTotalBytes = selectedData != null
        ? (_showCellular ? selectedData.cellularBytes : 0) +
            (_showWifi ? selectedData.wifiBytes : 0)
        : 0;

    return SizedBox(
      height: widget.height,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title + Selected Day Total DataSize
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WEEKLY USAGE',
                        style: AppTypography.chartLabelStyle(
                          colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ).copyWith(letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 2),
                      if (selectedData != null)
                        Text(
                          DateFormat('EEEE, MMM d').format(selectedData.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        Text(
                          'This Week',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Formatted usage badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    DataSize(selectedTotalBytes).format(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Interactive Legend Toggles
            Row(
              children: [
                _buildLegendPill(
                  label: 'Cellular',
                  color: AppColorSchemes.cellularColor,
                  isActive: _showCellular,
                  onTap: _toggleCellular,
                ),
                const SizedBox(width: 8),
                _buildLegendPill(
                  label: 'Wi-Fi',
                  color: AppColorSchemes.wifiColor,
                  isActive: _showWifi,
                  onTap: _toggleWifi,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Canvas Chart Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => _handleTapDown(
                      details,
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                    child: AnimatedBuilder(
                      animation: _squeezeController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _WeeklyBarChartPainter(
                            weekData: widget.weekData,
                            selectedIndex: _selectedIndex,
                            showCellular: _showCellular,
                            showWifi: _showWifi,
                            colorScheme: colorScheme,
                            squeezeWidthFactor: _squeezeWidthAnimation.value,
                            bounceHeightFactor: _bounceHeightAnimation.value,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildLegendPill({
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : color.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? color : color.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Canvas painter rendering stacked rounded bars, dashed grid lines, and labels.
class _WeeklyBarChartPainter extends CustomPainter {
  const _WeeklyBarChartPainter({
    required this.weekData,
    required this.selectedIndex,
    required this.showCellular,
    required this.showWifi,
    required this.colorScheme,
    required this.squeezeWidthFactor,
    required this.bounceHeightFactor,
  });

  final List<WeeklyDayData> weekData;
  final int selectedIndex;
  final bool showCellular;
  final bool showWifi;
  final ColorScheme colorScheme;
  final double squeezeWidthFactor;
  final double bounceHeightFactor;

  static const List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static final Paint _cellularPaint = Paint()
    ..color = AppColorSchemes.cellularColor
    ..style = PaintingStyle.fill;

  static final Paint _wifiPaint = Paint()
    ..color = AppColorSchemes.wifiColor
    ..style = PaintingStyle.fill;

  static final Paint _cellularInactivePaint = Paint()
    ..color = AppColorSchemes.cellularColor.withValues(alpha: 0.4)
    ..style = PaintingStyle.fill;

  static final Paint _wifiInactivePaint = Paint()
    ..color = AppColorSchemes.wifiColor.withValues(alpha: 0.4)
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (weekData.isEmpty) return;

    const double labelHeight = 24.0;
    final chartHeight = size.height - labelHeight;
    final int count = math.max(weekData.length, 7);
    final double partitionWidth = size.width / count;
    final double barMaxWidth = partitionWidth * 0.58;

    // Calculate maximum total usage across the week for relative scaling
    int maxBytes = 1;
    for (final day in weekData) {
      final total = (showCellular ? day.cellularBytes : 0) +
          (showWifi ? day.wifiBytes : 0);
      if (total > maxBytes) {
        maxBytes = total;
      }
    }

    // 1. Draw dashed horizontal grid lines (25%, 50%, 75%, 100%)
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 4; i++) {
      final y = chartHeight - (chartHeight * (i / 4.0));
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Baseline
    final baselinePaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      baselinePaint,
    );

    // 2. Selection halo paint
    final haloPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    try {
      for (int i = 0; i < count; i++) {
        final isSelected = i == selectedIndex;
        final centerX = (i * partitionWidth) + (partitionWidth / 2);

        final barWidth = isSelected
            ? barMaxWidth * squeezeWidthFactor
            : barMaxWidth;

        final dayData = i < weekData.length ? weekData[i] : null;
        final cellBytes = (dayData != null && showCellular) ? dayData.cellularBytes : 0;
        final wifiBytes = (dayData != null && showWifi) ? dayData.wifiBytes : 0;
        final totalBytes = cellBytes + wifiBytes;

        final double totalBarHeight = (totalBytes > 0)
            ? ((totalBytes / maxBytes) * (chartHeight - 8.0)).clamp(4.0, chartHeight - 8.0) *
                (isSelected ? bounceHeightFactor : 1.0)
            : 3.0; // Minimal pill for zero usage

        final double cellRatio = totalBytes > 0 ? (cellBytes / totalBytes) : 0.0;
        final double cellHeight = totalBarHeight * cellRatio;
        final double wifiHeight = totalBarHeight - cellHeight;

        final double barLeft = centerX - (barWidth / 2);
        final double barBottom = chartHeight;

        // Selection background halo pill
        if (isSelected) {
          final selectionHaloRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              (i * partitionWidth) + 2,
              2,
              partitionWidth - 4,
              chartHeight - 2,
            ),
            const Radius.circular(12),
          );
          canvas.drawRRect(selectionHaloRect, haloPaint);
        }

        // Draw Cellular segment (Bottom)
        if (cellHeight > 0) {
          final cellRect = RRect.fromRectAndCorners(
            Rect.fromLTWH(barLeft, barBottom - cellHeight, barWidth, cellHeight),
            bottomLeft: const Radius.circular(6),
            bottomRight: const Radius.circular(6),
            topLeft: wifiHeight == 0 ? const Radius.circular(6) : Radius.zero,
            topRight: wifiHeight == 0 ? const Radius.circular(6) : Radius.zero,
          );
          canvas.drawRRect(
            cellRect,
            isSelected ? _cellularPaint : _cellularInactivePaint,
          );
        }

        // Draw Wi-Fi segment (Top, stacked on top of cellular)
        if (wifiHeight > 0) {
          final wifiRect = RRect.fromRectAndCorners(
            Rect.fromLTWH(
              barLeft,
              barBottom - totalBarHeight,
              barWidth,
              wifiHeight,
            ),
            topLeft: const Radius.circular(6),
            topRight: const Radius.circular(6),
            bottomLeft: cellHeight == 0 ? const Radius.circular(6) : Radius.zero,
            bottomRight: cellHeight == 0 ? const Radius.circular(6) : Radius.zero,
          );
          canvas.drawRRect(
            wifiRect,
            isSelected ? _wifiPaint : _wifiInactivePaint,
          );
        }

        // 3. Draw Day of Week Label below baseline
        final dayLabel = i < dayNames.length ? dayNames[i] : 'D$i';
        textPainter.text = TextSpan(
          text: dayLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(centerX - (textPainter.width / 2), chartHeight + 6),
        );
      }
    } finally {
      textPainter.dispose();
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double currentX = start.dx;

    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(math.min(currentX + dashWidth, end.dx), start.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.showCellular != showCellular ||
        oldDelegate.showWifi != showWifi ||
        oldDelegate.squeezeWidthFactor != squeezeWidthFactor ||
        oldDelegate.bounceHeightFactor != bounceHeightFactor ||
        oldDelegate.weekData != weekData ||
        oldDelegate.colorScheme != colorScheme;
  }
}
