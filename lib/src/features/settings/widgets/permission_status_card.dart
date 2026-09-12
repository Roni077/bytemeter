import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';

/// Card widget displaying Android system permissions and battery optimization exemption status.
class PermissionStatusCard extends StatelessWidget {
  const PermissionStatusCard({
    super.key,
    required this.hasUsagePermission,
    required this.isIgnoringBatteryOptimizations,
    required this.onRequestUsagePermission,
    required this.onRequestBatteryExemption,
    this.hasNotificationPermission = true,
    this.hasPhonePermission = false,
    this.onRequestNotificationPermission,
    this.onRequestPhonePermission,
  });

  final bool hasUsagePermission;
  final bool isIgnoringBatteryOptimizations;
  final VoidCallback onRequestUsagePermission;
  final VoidCallback onRequestBatteryExemption;
  final bool hasNotificationPermission;
  final bool hasPhonePermission;
  final VoidCallback? onRequestNotificationPermission;
  final VoidCallback? onRequestPhonePermission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Permissions & System Access',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Usage Access Permission Item
            _buildPermissionItem(
              context: context,
              icon: Icons.data_usage_rounded,
              title: 'Usage Data Access',
              subtitle:
                  'Required to query per-app and device network traffic from Android NetworkStatsManager.',
              isGranted: hasUsagePermission,
              grantedLabel: 'Granted',
              actionLabel: 'Open Settings',
              onAction: () {
                AppHaptics.contextClick();
                onRequestUsagePermission();
              },
            ),

            const Divider(height: 24),

            // 2. Notification Permission Item
            _buildPermissionItem(
              context: context,
              icon: Icons.notifications_active_outlined,
              title: 'Status Bar Notifications',
              subtitle:
                  'Required on Android 13+ to show live download & upload speeds on the status bar.',
              isGranted: hasNotificationPermission,
              grantedLabel: 'Allowed',
              actionLabel: 'Allow',
              onAction: () {
                AppHaptics.contextClick();
                onRequestNotificationPermission?.call();
              },
            ),

            const Divider(height: 24),

            // 3. Battery Optimization Exemption Item
            _buildPermissionItem(
              context: context,
              icon: Icons.battery_charging_full_rounded,
              title: 'Battery Optimization Exemption',
              subtitle:
                  'Prevents Android Doze mode and task killers from halting background speed monitoring.',
              isGranted: isIgnoringBatteryOptimizations,
              grantedLabel: 'Unrestricted',
              actionLabel: 'Allow Exemption',
              onAction: () {
                AppHaptics.contextClick();
                onRequestBatteryExemption();
              },
            ),

            const Divider(height: 24),

            // 4. Phone State Access Item
            _buildPermissionItem(
              context: context,
              icon: Icons.sim_card_outlined,
              title: 'Phone State Access (Optional)',
              subtitle:
                  'Identifies multi-carrier SIM slots for accurate mobile data plan quota tracking.',
              isGranted: hasPhonePermission,
              grantedLabel: 'Granted',
              actionLabel: 'Grant Access',
              onAction: () {
                AppHaptics.contextClick();
                onRequestPhonePermission?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required String grantedLabel,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final badgeBg = isGranted
        ? colorScheme.primaryContainer
        : colorScheme.errorContainer.withValues(alpha: 0.6);
    final badgeFg = isGranted
        ? colorScheme.onPrimaryContainer
        : colorScheme.onErrorContainer;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: isGranted ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 14,
                          color: badgeFg,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isGranted ? grantedLabel : 'Required',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: badgeFg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isGranted) ...[
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
