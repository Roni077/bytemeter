import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';

/// Card displaying the 7-day moving average trend percentage and burn rate indicator.
class TrendCard extends StatelessWidget {
  const TrendCard({
    super.key,
    required this.trendPercentage,
    this.isLoading = false,
  });

  final double trendPercentage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAccelerated = trendPercentage > 0.05;
    final isDecelerated = trendPercentage < -0.05;

    // Badge styling based on burn rate direction
    final Color badgeColor;
    final Color badgeTextColor;
    final IconData trendIcon;
    final String trendPrefix;

    if (isAccelerated) {
      badgeColor = colorScheme.errorContainer.withValues(alpha: 0.8);
      badgeTextColor = colorScheme.onErrorContainer;
      trendIcon = Icons.arrow_upward_rounded;
      trendPrefix = '+';
    } else if (isDecelerated) {
      badgeColor = Colors.green.withValues(alpha: 0.2);
      badgeTextColor = Colors.green.shade700;
      trendIcon = Icons.arrow_downward_rounded;
      trendPrefix = '';
    } else {
      badgeColor = colorScheme.surfaceContainerHighest;
      badgeTextColor = colorScheme.onSurfaceVariant;
      trendIcon = Icons.remove_rounded;
      trendPrefix = '';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Icon and Info Tooltip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.speed_rounded,
                    size: 20,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '7-DAY BURN RATE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                  onPressed: () => _showTrendInfoDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isLoading && trendPercentage == 0.0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 130,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Large Trend Percentage Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(trendIcon, size: 20, color: badgeTextColor),
                        const SizedBox(width: 4),
                        Text(
                          '$trendPrefix${trendPercentage.abs().toStringAsFixed(1)}%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: badgeTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Comparison Subtitle
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isAccelerated
                          ? 'Higher burn rate than prior 6-day average'
                          : (isDecelerated
                              ? 'Lower burn rate than prior 6-day average'
                              : 'Consistent with 6-day historical baseline'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTrendInfoDialog(BuildContext context) {
    AppHaptics.contextClick();
    showDialog<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return AlertDialog(
          icon: Icon(Icons.speed_rounded, color: colorScheme.tertiary, size: 28),
          title: const Text('7-Day Moving Trend Indicator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculates the percentage difference between your latest 24-hour hourly burn rate and your prior 6-day hourly baseline:',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Trend % = ((HourlyAvg_24h / HourlyAvg_prior6d) - 1) × 100',
                  style: textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• Positive (+) indicates bandwidth usage is accelerating.\n'
                '• Negative (-) indicates you are conserving data compared to your normal habits.\n'
                '• Helps detect unexpected background app downloads or streaming spikes early.',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got It'),
            ),
          ],
        );
      },
    );
  }
}
