import 'package:flutter/material.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/pressable_card.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../charts/app_usage_bar_chart.dart';

/// Card displaying the top data-consuming apps for the active day with proportional bars.
class TopAppsCard extends StatelessWidget {
  const TopAppsCard({
    super.key,
    required this.apps,
    this.totalBytes,
    this.onAppTap,
    this.onViewAll,
    this.isLoading = false,
  });

  final List<AppUsageBarData> apps;
  final int? totalBytes;
  final void Function(AppUsageBarData app)? onAppTap;
  final VoidCallback? onViewAll;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PressableCard(
      onTap: onViewAll,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimens.sm),
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
                  if (onViewAll != null)
                    InkWell(
                      onTap: onViewAll,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      '${apps.length} Apps',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Content: Loading Skeleton, App Usage Bar Chart or Empty State
              if (isLoading && apps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const ShimmerBox(
                              width: 24,
                              height: 24,
                              borderRadius: BorderRadius.all(Radius.circular(6)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ShimmerBox(
                                width: double.infinity,
                                height: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (apps.isEmpty)
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
      ),
    );
  }
}
