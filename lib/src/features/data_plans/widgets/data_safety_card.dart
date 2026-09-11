import 'package:flutter/material.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../data/models/enums.dart';

/// Interactive insight card detailing current data safety pacing, burn rate delta, and recommendations.
class DataSafetyCard extends StatelessWidget {
  const DataSafetyCard({
    super.key,
    required this.safetyState,
    required this.delta,
    required this.usageRatio,
    required this.elapsedRatio,
  });

  final DataSafetyState safetyState;
  final double delta;
  final double usageRatio;
  final double elapsedRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final safetyColor = AppColorSchemes.getSafetyColor(safetyState);

    final badgeLabel = safetyState.displayName.toUpperCase();
    final advice = _getAdviceText(safetyState);
    final deltaLabel = _getDeltaLabel(delta);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: safetyColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Shield Icon, Title, and Safety Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: safetyColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getSafetyIcon(safetyState),
                    color: safetyColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Data Safety Pacing',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: safetyColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Pacing Delta Text
            Text(
              deltaLabel,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 4),

            // Conversational Advice
            Text(
              advice,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 16),

            // Dual Comparative Progress Bars (Usage vs Time Elapsed)
            _buildComparativeMetric(
              context: context,
              label: 'Data Quota Used',
              ratio: usageRatio,
              color: safetyColor,
              percentLabel: '${(usageRatio * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 10),
            _buildComparativeMetric(
              context: context,
              label: 'Cycle Time Elapsed',
              ratio: elapsedRatio,
              color: colorScheme.primary,
              percentLabel: '${(elapsedRatio * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparativeMetric({
    required BuildContext context,
    required String label,
    required double ratio,
    required Color color,
    required String percentLabel,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final clampedRatio = ratio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              percentLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            color: colorScheme.surfaceContainerHighest,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedRatio,
              child: Container(
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getSafetyIcon(DataSafetyState state) {
    switch (state) {
      case DataSafetyState.safe:
        return Icons.shield_rounded;
      case DataSafetyState.neutral:
        return Icons.warning_amber_rounded;
      case DataSafetyState.unsafe:
        return Icons.gpp_bad_rounded;
    }
  }

  String _getDeltaLabel(double delta) {
    if (delta <= -0.01) {
      return '${(delta.abs() * 100).toStringAsFixed(1)}% under target pace';
    } else if (delta <= 0.05) {
      return 'On track with cycle time';
    } else {
      return '+${(delta * 100).toStringAsFixed(1)}% ahead of target pace';
    }
  }

  String _getAdviceText(DataSafetyState state) {
    switch (state) {
      case DataSafetyState.safe:
        return 'Great pacing! You are burning data slower than the elapsed billing cycle duration.';
      case DataSafetyState.neutral:
        return 'Pacing is slightly fast. Monitor background streaming apps to avoid exhausting data early.';
      case DataSafetyState.unsafe:
        return 'High consumption pace! You risk exhausting your quota before the next billing cycle reset.';
    }
  }
}
