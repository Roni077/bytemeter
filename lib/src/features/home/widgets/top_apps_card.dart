import 'package:flutter/material.dart';
import '../../charts/app_usage_bar_chart.dart';

/// Card displaying the top data-consuming apps for the active day with proportional bars.
class TopAppsCard extends StatelessWidget {
  const TopAppsCard({
    super.key,
    required this.apps,
    this.totalBytes,
    this.onAppTap,
  });

  final List<AppUsageBarData> apps;
  final int? totalBytes;
  final void Function(AppUsageBarData app)? onAppTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.apps_rounded,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'TOP APPS TODAY',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${apps.length} Apps',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content: App Usage Bar Chart or Empty State
            if (apps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.data_usage_rounded,
                        size: 36,
                        color: colorScheme.outline.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No app usage recorded today',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              AppUsageBarChart(
                apps: apps,
                totalBytes: totalBytes,
                maxItems: 5,
                barHeight: 24,
                onAppTap: onAppTap,
              ),
          ],
        ),
      ),
    );
  }
}
