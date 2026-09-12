import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';

enum PermissionImportance {
  essential,
  recommended,
  optional,
}

/// Interactive Material 3 card representing a requested Android system permission.
class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isGranted,
    required this.importance,
    required this.onRequest,
    this.actionLabel,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isGranted;
  final PermissionImportance importance;
  final VoidCallback onRequest;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final badgeColor = switch (importance) {
      PermissionImportance.essential => isGranted ? colorScheme.primary : colorScheme.error,
      PermissionImportance.recommended => isGranted ? colorScheme.primary : colorScheme.tertiary,
      PermissionImportance.optional => isGranted ? colorScheme.primary : colorScheme.secondary,
    };

    final badgeText = switch (importance) {
      PermissionImportance.essential => 'REQUIRED',
      PermissionImportance.recommended => 'RECOMMENDED',
      PermissionImportance.optional => 'OPTIONAL',
    };

    return Card(
      elevation: 0,
      color: isGranted
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isGranted
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isGranted ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isGranted
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                // Title and badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action / Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isGranted
                          ? Icons.check_circle_rounded
                          : Icons.pending_outlined,
                      size: 16,
                      color: isGranted ? colorScheme.primary : colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isGranted ? 'Permission Active' : 'Not Granted',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isGranted ? colorScheme.primary : colorScheme.outline,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (!isGranted) ...[
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      AppHaptics.contextClick();
                      onRequest();
                    },
                    child: Text(
                      actionLabel ?? 'Grant Access',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ] else ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: () {
                      AppHaptics.contextClick();
                      onRequest();
                    },
                    icon: const Icon(Icons.settings_outlined, size: 14),
                    label: const Text(
                      'Settings',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
