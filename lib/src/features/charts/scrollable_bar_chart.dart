import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:bytemeter/src/core/theme/color_schemes.dart';
import 'package:bytemeter/src/core/theme/typography.dart';
import 'package:bytemeter/src/core/utils/data_size.dart';
import 'package:bytemeter/src/core/utils/haptics.dart';

/// Single day data entry for [ScrollableBarChart].
class DailyHistoryData {
  const DailyHistoryData({
    required this.date,
    required this.cellularBytes,
    required this.wifiBytes,
    this.primaryQueryBytes,
    this.secondaryQueryBytes,
  });

  final DateTime date;
  final int cellularBytes;
  final int wifiBytes;

  /// Optional query-specific filtered bytes (e.g. for dual query mode)
  final int? primaryQueryBytes;
  final int? secondaryQueryBytes;

  int get totalBytes => (primaryQueryBytes != null || secondaryQueryBytes != null)
      ? (primaryQueryBytes ?? 0) + (secondaryQueryBytes ?? 0)
      : cellularBytes + wifiBytes;
}

/// 90-Day Fling-Scrollable History Bar Chart with exponential velocity fling physics,
/// spring snap alignment to center selector needle, dynamic viewport max scaling,
/// and segment boundary haptic clicks.
class ScrollableBarChart extends StatefulWidget {
  const ScrollableBarChart({
    super.key,
    required this.historyData,
    this.selectedDate,
    this.onDateSelected,
    this.height = 260.0,
    this.barWidth = 32.0,
    this.barSpacing = 16.0,
  });

  /// Up to 90 consecutive days of historical usage.
  final List<DailyHistoryData> historyData;

  /// Currently selected/centered date.
  final DateTime? selectedDate;

  /// Callback when a date is snapped or selected in the center.
  final void Function(DateTime date, DailyHistoryData data)? onDateSelected;

  final double height;
  final double barWidth;
  final double barSpacing;

  @override
  State<ScrollableBarChart> createState() => _ScrollableBarChartState();
}

class _ScrollableBarChartState extends State<ScrollableBarChart> {
  late final ScrollController _scrollController;
  late final ValueNotifier<int> _centeredIndexNotifier;
  int _lastHapticIndex = -1;
  bool _isSnapping = false;
  Timer? _scrollDebounceTimer;

  double get _itemExtent => widget.barWidth + widget.barSpacing;

  @override
  void initState() {
    super.initState();
    _centeredIndexNotifier = ValueNotifier<int>(0);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initial center positioning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialDate();
    });
  }

  @override
  void didUpdateWidget(covariant ScrollableBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != null &&
        widget.selectedDate != oldWidget.selectedDate) {
      _scrollToDate(widget.selectedDate!);
    }
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _centeredIndexNotifier.dispose();
    super.dispose();
  }

  void _scrollToInitialDate() {
    if (widget.historyData.isEmpty || !_scrollController.hasClients) return;

    int targetIndex = widget.historyData.length - 1; // Default to most recent (today)
    if (widget.selectedDate != null) {
      final found = widget.historyData.indexWhere(
        (d) =>
            d.date.year == widget.selectedDate!.year &&
            d.date.month == widget.selectedDate!.month &&
            d.date.day == widget.selectedDate!.day,
      );
      if (found != -1) targetIndex = found;
    }

    _scrollToIndex(targetIndex, animate: false);
  }

  void _scrollToDate(DateTime date) {
    if (widget.historyData.isEmpty || !_scrollController.hasClients) return;

    final found = widget.historyData.indexWhere(
      (d) =>
          d.date.year == date.year &&
          d.date.month == date.month &&
          d.date.day == date.day,
    );
    if (found != -1 && found != _centeredIndexNotifier.value) {
      _scrollToIndex(found, animate: true);
    }
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    if (!_scrollController.hasClients || widget.historyData.isEmpty) return;

    final targetOffset = index * _itemExtent;
    _centeredIndexNotifier.value = index;
    if (animate) {
      _isSnapping = true;
      _scrollController
          .animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            _isSnapping = false;
            _notifySelection(index);
          });
    } else {
      _scrollController.jumpTo(targetOffset);
      _notifySelection(index);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.historyData.isEmpty) return;

    final offset = _scrollController.offset;
    final exactIndex = offset / _itemExtent;
    final centerIndex = exactIndex.round().clamp(0, widget.historyData.length - 1);

    if (centerIndex != _lastHapticIndex) {
      _lastHapticIndex = centerIndex;
      AppHaptics.segmentFrequentTick();
    }

    if (centerIndex != _centeredIndexNotifier.value) {
      _centeredIndexNotifier.value = centerIndex;
      if (!_isSnapping) {
        _scrollDebounceTimer?.cancel();
        _scrollDebounceTimer = Timer(const Duration(milliseconds: 150), () {
          _notifySelection(centerIndex);
        });
      }
    }
  }

  void _notifySelection(int index) {
    if (index >= 0 && index < widget.historyData.length) {
      final data = widget.historyData[index];
      widget.onDateSelected?.call(data.date, data);
    }
  }

  void _snapToNearest() {
    if (!_scrollController.hasClients || widget.historyData.isEmpty || _isSnapping) return;

    final currentOffset = _scrollController.offset;
    final nearestIndex = (currentOffset / _itemExtent).round().clamp(0, widget.historyData.length - 1);
    final targetOffset = nearestIndex * _itemExtent;

    _scrollDebounceTimer?.cancel();

    if ((targetOffset - currentOffset).abs() > 0.5) {
      _isSnapping = true;
      _scrollController
          .animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            _isSnapping = false;
            _notifySelection(nearestIndex);
          });
    } else {
      _notifySelection(nearestIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floating Center Info Badge Header (Isolated Rebuild)
            ValueListenableBuilder<int>(
              valueListenable: _centeredIndexNotifier,
              builder: (context, centeredIndex, _) {
                final centeredData = (widget.historyData.isNotEmpty &&
                        centeredIndex < widget.historyData.length)
                    ? widget.historyData[centeredIndex]
                    : null;
                final centeredTotalBytes = centeredData?.totalBytes ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '90-DAY TIMELINE',
                              style: AppTypography.chartLabelStyle(
                                colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ).copyWith(letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 2),
                            if (centeredData != null)
                              Text(
                                DateFormat('EEEE, MMM d, y').format(centeredData.date),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              Text(
                                'Select Day',
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DataSize(centeredTotalBytes).format(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Scrollable Timeline Canvas Area with Center Pointer
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final halfWidth = constraints.maxWidth / 2;
                  final paddingLeft = halfWidth - (widget.barWidth / 2);
                  final paddingRight = halfWidth - (widget.barWidth / 2);

                  // Calculate max visible usage for dynamic scaling
                  final visibleStartIndex = math.max(
                    0,
                    ((_scrollController.hasClients ? _scrollController.offset : 0) / _itemExtent).floor() - 2,
                  );
                  final visibleEndIndex = math.min(
                    widget.historyData.length - 1,
                    visibleStartIndex + (constraints.maxWidth / _itemExtent).ceil() + 4,
                  );

                  int maxVisibleBytes = 1;
                  for (int i = visibleStartIndex; i <= visibleEndIndex; i++) {
                    if (i >= 0 && i < widget.historyData.length) {
                      final total = widget.historyData[i].totalBytes;
                      if (total > maxVisibleBytes) {
                        maxVisibleBytes = total;
                      }
                    }
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Scrollable Bar List
                      NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification) {
                            _snapToNearest();
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.only(
                                left: paddingLeft,
                                right: paddingRight,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final data = widget.historyData[index];
                                    return ValueListenableBuilder<int>(
                                      valueListenable: _centeredIndexNotifier,
                                      builder: (context, centeredIndex, _) {
                                        final isCentered = index == centeredIndex;
                                        return RepaintBoundary(
                                          child: GestureDetector(
                                            onTap: () => _scrollToIndex(index, animate: true),
                                            child: Container(
                                              width: widget.barWidth,
                                              margin: EdgeInsets.only(
                                                right: index == widget.historyData.length - 1
                                                    ? 0
                                                    : widget.barSpacing,
                                              ),
                                              child: _HistoryBarItem(
                                                data: data,
                                                maxBytes: maxVisibleBytes,
                                                isCentered: isCentered,
                                                barWidth: widget.barWidth,
                                                availableBarHeight: constraints.maxHeight - 26.0,
                                                colorScheme: colorScheme,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  childCount: widget.historyData.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Center Indicator Needle Line
                      IgnorePointer(
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Container(
                                width: 3,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 1.5,
                                  color: colorScheme.primary.withValues(alpha: 0.35),
                                ),
                              ),
                              const SizedBox(height: 28), // Label area spacing
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single bar column displaying stacked Cellular & Wi-Fi segments and day number.
class _HistoryBarItem extends StatelessWidget {
  const _HistoryBarItem({
    required this.data,
    required this.maxBytes,
    required this.isCentered,
    required this.barWidth,
    required this.availableBarHeight,
    required this.colorScheme,
  });

  final DailyHistoryData data;
  final int maxBytes;
  final bool isCentered;
  final double barWidth;
  final double availableBarHeight;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    const double labelHeight = 26.0;
    final totalBytes = data.totalBytes;
    final cellBytes = data.primaryQueryBytes ?? data.cellularBytes;
    final wifiBytes = data.secondaryQueryBytes ?? data.wifiBytes;

    final double totalBarHeight = (totalBytes > 0 && maxBytes > 0)
        ? ((totalBytes / maxBytes) * (availableBarHeight - 12.0)).clamp(4.0, availableBarHeight - 12.0)
        : 3.0;

    final double cellRatio = totalBytes > 0 ? (cellBytes / totalBytes) : 0.0;
    final double wifiRatio = totalBytes > 0 ? (wifiBytes / totalBytes) : 0.0;
    final double cellHeight = totalBarHeight * cellRatio;
    final double wifiHeight = totalBarHeight * wifiRatio;

    final cellColor = isCentered
        ? AppColorSchemes.cellularColor
        : AppColorSchemes.cellularColor.withValues(alpha: 0.45);

    final wifiColor = isCentered
        ? AppColorSchemes.wifiColor
        : AppColorSchemes.wifiColor.withValues(alpha: 0.45);

    return Column(
      children: [
        // Bar Column
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: isCentered ? barWidth : barWidth * 0.88,
              height: totalBarHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  children: [
                    // Wi-Fi / Secondary (Top)
                    if (wifiHeight > 0)
                      Expanded(
                        flex: (wifiHeight * 100).round(),
                        child: Container(color: wifiColor),
                      ),
                    // Cellular / Primary (Bottom)
                    if (cellHeight > 0)
                      Expanded(
                        flex: (cellHeight * 100).round(),
                        child: Container(color: cellColor),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Day Number / Month Label
        SizedBox(
          height: labelHeight - 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('d').format(data.date),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCentered ? FontWeight.w800 : FontWeight.w500,
                  color: isCentered
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
