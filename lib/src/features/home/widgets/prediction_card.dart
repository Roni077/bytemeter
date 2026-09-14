import 'package:flutter/material.dart';
import '../../../core/utils/data_size.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';

/// Card displaying the 4-week weighted end-of-day data prediction and remaining forecast.
class PredictionCard extends StatelessWidget {
  const PredictionCard({
    super.key,
    required this.predictedBytes,
    required this.todayBytes,
    this.metricBase = MetricBase.decimal1000,
    this.isLoading = false,
  });

  final int predictedBytes;
  final int todayBytes;
  final MetricBase metricBase;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final predictedSize = DataSize(predictedBytes);
    final remainingBytes = (predictedBytes - todayBytes).clamp(0, double.maxFinite.toInt());
    final remainingSize = DataSize(remainingBytes);
    final parts = predictedSize.toParts(base: metricBase);

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
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    size: 20,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'END-OF-DAY FORECAST',
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
                  onPressed: () => _showPredictionInfoDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isLoading && predictedBytes == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 140,
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
              // Large 3-Part Formatted Prediction Value
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    parts.first,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (parts.second.isNotEmpty)
                    Text(
                      parts.second,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    parts.third,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Remaining to consume subtitle
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      remainingBytes > 0
                          ? '+${remainingSize.format(base: metricBase)} expected by midnight'
                          : 'On track with predicted budget',
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

  void _showPredictionInfoDialog(BuildContext context) {
    AppHaptics.contextClick();
    showDialog<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return AlertDialog(
          icon: Icon(Icons.auto_graph_rounded, color: colorScheme.primary, size: 28),
          title: const Text('4-Week Weighted Prediction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ByteMeter projects your end-of-day bandwidth consumption using a weighted hour-ratio algorithm:',
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
                  'Prediction = TodayUsage + (Last24h × (Σ FullDay / Σ ElapsedDay - 1))',
                  style: textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• Compares today against the same weekday across the past 4 weeks.\n'
                '• Weights afternoon and evening peak hours based on your personal historical habits.\n'
                '• Automatically adjusts as you consume data throughout the day.',
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
