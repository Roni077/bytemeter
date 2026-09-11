import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:bytemeter/src/core/utils/data_size.dart';
import 'package:bytemeter/src/core/utils/size_measurer.dart';

/// Single app item data entry for [AppUsageBarChart].
class AppUsageBarData {
  const AppUsageBarData({
    required this.uid,
    required this.appName,
    required this.packageName,
    required this.bytes,
    this.iconBytes,
    this.color,
  });

  final int uid;
  final String appName;
  final String packageName;
  final int bytes;
  final Uint8List? iconBytes;
  final Color? color;
}

/// Proportional Horizontal App Usage Bar Chart with dynamic binary-search text fitting
/// ensuring numeric labels fit cleanly inside or immediately outside bars without clipping.
class AppUsageBarChart extends StatelessWidget {
  const AppUsageBarChart({
    super.key,
    required this.apps,
    this.totalBytes,
    this.onAppTap,
    this.maxItems = 5,
    this.barHeight = 24.0,
  });

  /// Ranked list of app data usage items.
  final List<AppUsageBarData> apps;

  /// Optional total reference bytes across all apps (defaults to maximum single app or sum).
  final int? totalBytes;

  /// Callback when an app row is tapped.
  final void Function(AppUsageBarData app)? onAppTap;

  /// Maximum number of apps to display.
  final int maxItems;

  /// Height of the horizontal progress bar.
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayApps = apps.take(maxItems).toList();
    final maxAppBytes = totalBytes ??
        displayApps.map((a) => a.bytes).fold<int>(1, (max, v) => v > max ? v : max);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < displayApps.length; i++) ...[
          _AppUsageRow(
            app: displayApps[i],
            maxBytes: maxAppBytes,
            barHeight: barHeight,
            onTap: onAppTap != null ? () => onAppTap!(displayApps[i]) : null,
          ),
          if (i < displayApps.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AppUsageRow extends StatelessWidget {
  const _AppUsageRow({
    required this.app,
    required this.maxBytes,
    required this.barHeight,
    this.onTap,
  });

  final AppUsageBarData app;
  final int maxBytes;
  final double barHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final barColor = app.color ?? colorScheme.primary;
    final ratio = maxBytes > 0 ? (app.bytes / maxBytes).clamp(0.0, 1.0) : 0.0;
    final formattedSize = DataSize(app.bytes).format();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: App Icon + App Name
            Row(
              children: [
                // App Icon / Silhouette
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: app.iconBytes != null && app.iconBytes!.isNotEmpty
                        ? Image.memory(
                            app.iconBytes!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.android_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.android_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 8),

                // App Label
                Expanded(
                  child: Text(
                    app.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Bottom Row: Custom Canvas Proportional Bar with Binary-Search Text Fitting
            LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, barHeight),
                  painter: _AppUsageBarPainter(
                    ratio: ratio,
                    formattedSize: formattedSize,
                    barColor: barColor,
                    trackColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    onPrimaryColor: Colors.white,
                    onSurfaceColor: colorScheme.onSurface,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppUsageBarPainter extends CustomPainter {
  const _AppUsageBarPainter({
    required this.ratio,
    required this.formattedSize,
    required this.barColor,
    required this.trackColor,
    required this.onPrimaryColor,
    required this.onSurfaceColor,
  });

  final double ratio;
  final String formattedSize;
  final Color barColor;
  final Color trackColor;
  final Color onPrimaryColor;
  final Color onSurfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final totalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      radius,
    );

    // 1. Draw Background Track
    final trackPaint = Paint()..color = trackColor;
    canvas.drawRRect(totalRect, trackPaint);

    // 2. Draw Proportional Active Bar
    final double activeWidth = (size.width * ratio).clamp(size.height, size.width);
    final activeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, activeWidth, size.height),
      radius,
    );
    final barPaint = Paint()..color = barColor;
    canvas.drawRRect(activeRect, barPaint);

    // 3. Binary Search Text Fitting
    const baseStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    final optimalFontSize = SizeMeasurer.findOptimalFontSize(
      text: formattedSize,
      baseStyle: baseStyle,
      maxWidth: activeWidth - 16.0,
      minFontSize: 9.0,
      maxFontSize: 11.0,
    );

    final style = baseStyle.copyWith(fontSize: optimalFontSize);
    final textSize = SizeMeasurer.measureText(text: formattedSize, style: style);

    final bool fitsInside = (activeWidth >= textSize.width + 18.0);

    if (fitsInside) {
      // Draw text inside the bar, right-aligned with onPrimary color
      final textPainter = TextPainter(
        text: TextSpan(text: formattedSize, style: style.copyWith(color: onPrimaryColor)),
        textDirection: TextDirection.ltr,
      )..layout();

      final textX = activeWidth - textPainter.width - 10.0;
      final textY = (size.height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    } else {
      // Draw text outside the bar, immediately to the right with onSurface color
      final textPainter = TextPainter(
        text: TextSpan(text: formattedSize, style: style.copyWith(color: onSurfaceColor)),
        textDirection: TextDirection.ltr,
      )..layout();

      final textX = (activeWidth + 8.0).clamp(0.0, size.width - textPainter.width);
      final textY = (size.height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant _AppUsageBarPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.formattedSize != formattedSize ||
        oldDelegate.barColor != barColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.onPrimaryColor != onPrimaryColor ||
        oldDelegate.onSurfaceColor != onSurfaceColor;
  }
}
