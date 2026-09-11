import 'package:flutter/material.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../core/utils/data_size.dart';
import '../../charts/comparative_line_chart.dart';
import '../history_state.dart';

/// List view presenting 12 two-hour time buckets across the selected 24-hour day.
class HourListView extends StatelessWidget {
  const HourListView({
    super.key,
    required this.buckets,
    required this.isLoading,
    required this.isComparisonActive,
    this.primaryLabel,
    this.secondaryLabel,
  });

  final List<HourBucketData> buckets;
  final bool isLoading;
  final bool isComparisonActive;
  final String? primaryLabel;
  final String? secondaryLabel;

  IconData _getTimeIcon(int startHour) {
    if (startHour >= 0 && startHour < 6) {
      return Icons.bedtime_rounded; // Late night
    } else if (startHour >= 6 && startHour < 12) {
      return Icons.wb_sunny_rounded; // Morning
    } else if (startHour >= 12 && startHour < 18) {
      return Icons.wb_sunny_outlined; // Afternoon
    } else {
      return Icons.nights_stay_rounded; // Evening
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading && buckets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final totalTraffic = buckets.fold<int>(0, (sum, b) => sum + b.totalBytes);

    if (totalTraffic <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No Hourly Traffic',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No hourly data recorded on this day under active filters.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: buckets.length,
      itemBuilder: (context, index) {
        final bucket = buckets[index];
        final timeIcon = _getTimeIcon(bucket.startHour);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Time Icon + Interval Label + Total Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        timeIcon,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bucket.timeLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DataSize(bucket.totalBytes).format(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Comparative Line Bar
                ComparativeLineChart(
                  primaryBytes: bucket.primaryBytes,
                  secondaryBytes: bucket.secondaryBytes,
                  primaryColor: isComparisonActive
                      ? AppColorSchemes.cellularColor
                      : AppColorSchemes.downloadColor,
                  secondaryColor: isComparisonActive
                      ? AppColorSchemes.wifiColor
                      : AppColorSchemes.uploadColor,
                  primaryLabel: primaryLabel,
                  secondaryLabel: secondaryLabel,
                  height: 22.0,
                  borderRadius: 6.0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
