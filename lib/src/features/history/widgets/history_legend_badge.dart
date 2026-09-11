import 'package:flutter/material.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';
import '../history_state.dart';

/// Interactive legend header displaying active Primary & Secondary query badges,
/// app filter chips with instant clear action, and filter configuration button.
class HistoryLegendBadge extends StatelessWidget {
  const HistoryLegendBadge({
    super.key,
    required this.primaryQuery,
    required this.secondaryQuery,
    required this.isComparisonEnabled,
    required this.onOpenFilters,
    required this.onClearAppFilter,
  });

  final HistoryQuery primaryQuery;
  final HistoryQuery secondaryQuery;
  final bool isComparisonEnabled;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearAppFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasAppFilter = primaryQuery.appUid != null;
    final hasCustomFilters = hasAppFilter ||
        primaryQuery.networkType != NetworkType.mobile ||
        secondaryQuery.networkType != NetworkType.wifi ||
        !isComparisonEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Dual Query Badges + Filter Button
          Row(
            children: [
              // Primary Query Dot & Label
              _buildBadge(
                color: AppColorSchemes.cellularColor,
                label: 'Primary: ${primaryQuery.networkType?.displayName ?? "All Networks"}',
                context: context,
              ),

              const SizedBox(width: 8),

              // Secondary Query Dot & Label (if comparison enabled)
              if (isComparisonEnabled) ...[
                _buildBadge(
                  color: AppColorSchemes.wifiColor,
                  label: 'Secondary: ${secondaryQuery.networkType?.displayName ?? "All Networks"}',
                  context: context,
                ),
              ],

              const Spacer(),

              // Filter Config Button with Active Indicator
              Badge(
                isLabelVisible: hasCustomFilters,
                smallSize: 8,
                backgroundColor: colorScheme.primary,
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.contextClick();
                    onOpenFilters();
                  },
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Filters'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Row 2: Active App Filter Chip (if an app is isolated)
          if (hasAppFilter) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt_rounded,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Filtered by: ${primaryQuery.appInfo?.label ?? "UID ${primaryQuery.appUid}"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      AppHaptics.contextClick();
                      onClearAppFilter();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({
    required Color color,
    required String label,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
