import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/data_size.dart';
import '../../../data/models/enums.dart';

class NetworkUsageSummaryCard extends ConsumerWidget {
  const NetworkUsageSummaryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.todayBytes,
    required this.weekBytes,
    required this.monthBytes,
  });

  final String title;
  final IconData icon;
  final int todayBytes;
  final int weekBytes;
  final int monthBytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final metricBase = prefsRepo.current.metricBase;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn(
                  context,
                  label: 'Today',
                  bytes: todayBytes,
                  metricBase: metricBase,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _buildStatColumn(
                  context,
                  label: 'This Week',
                  bytes: weekBytes,
                  metricBase: metricBase,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _buildStatColumn(
                  context,
                  label: 'This Month',
                  bytes: monthBytes,
                  metricBase: metricBase,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required int bytes,
    required MetricBase metricBase,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    final formatted = DataSize(bytes).format(base: metricBase, decimals: 1);
    final parts = formatted.split(' ');
    final value = parts.isNotEmpty ? parts[0] : '0';
    final unit = parts.length > 1 ? parts[1] : 'B';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
