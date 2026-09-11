import 'package:flutter/material.dart';
import '../../../data/models/app_info.dart';
import '../../../data/models/app_usage.dart';
import 'app_item_card.dart';

/// Ranked list view of all bandwidth-consuming applications on the selected day.
class AppListView extends StatelessWidget {
  const AppListView({
    super.key,
    required this.apps,
    required this.isLoading,
    required this.isComparisonActive,
    this.primaryLabel,
    this.secondaryLabel,
    required this.onQuickFilter,
    required this.onLaunchApp,
  });

  final List<AppUsage> apps;
  final bool isLoading;
  final bool isComparisonActive;
  final String? primaryLabel;
  final String? secondaryLabel;
  final void Function(AppInfo app) onQuickFilter;
  final void Function(String packageName) onLaunchApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading && apps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (apps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.data_usage_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No App Traffic Recorded',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No application usage recorded for this date under active filters.',
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
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final appUsage = apps[index];
        return AppItemCard(
          key: ValueKey(appUsage.appInfo.uid),
          appUsage: appUsage,
          rank: index + 1,
          isComparisonActive: isComparisonActive,
          primaryLabel: primaryLabel,
          secondaryLabel: secondaryLabel,
          onQuickFilter: onQuickFilter,
          onLaunchApp: onLaunchApp,
        );
      },
    );
  }
}
