import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../onboarding_controller.dart';
import '../onboarding_state.dart';
import 'permission_card.dart';

/// Step 2: Interactive Android System Permission Handler Wizard.
class PermissionsStepView extends StatelessWidget {
  const PermissionsStepView({
    super.key,
    required this.state,
    required this.controller,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Permissions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${state.grantedCount}/4 permissions granted',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                tooltip: 'Refresh Statuses',
                icon: state.isLoadingPermissions
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                onPressed: state.isLoadingPermissions
                    ? null
                    : () {
                        AppHaptics.selectionTick();
                        controller.refreshPermissionStatuses();
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Privacy Info Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ByteMeter needs system permissions to query local network stats. Your data remains strictly on your phone.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Usage Access Permission (Essential)
          PermissionCard(
            title: 'Usage Access (Essential)',
            description:
                'Required to read network socket traffic, per-app data usage, and calculate burn rates.',
            icon: Icons.data_usage_rounded,
            isGranted: state.hasUsagePermission,
            importance: PermissionImportance.essential,
            onRequest: controller.requestUsagePermission,
            actionLabel: 'Grant Access',
          ),
          const SizedBox(height: 12),

          // 2. Notification Permission (Essential on Android 13+)
          PermissionCard(
            title: 'Post Notifications (Status Bar)',
            description:
                'Required to display live upload and download speed numbers in your notification shade and status bar.',
            icon: Icons.notifications_active_outlined,
            isGranted: state.hasNotificationPermission,
            importance: PermissionImportance.essential,
            onRequest: controller.requestNotificationPermission,
            actionLabel: 'Allow Notifications',
          ),
          const SizedBox(height: 12),

          // 3. Battery Optimization Exemption (Recommended)
          PermissionCard(
            title: 'Battery Saver Exemption (Recommended)',
            description:
                'Prevents aggressive OEM background cleaners (MIUI, OneUI, ColorOS) from stopping speed monitoring.',
            icon: Icons.battery_charging_full_rounded,
            isGranted: state.isIgnoringBatteryOptimizations,
            importance: PermissionImportance.recommended,
            onRequest: controller.requestBatteryExemption,
            actionLabel: 'Disable Optimization',
          ),
          const SizedBox(height: 12),

          // 4. Phone State (Optional)
          PermissionCard(
            title: 'Phone State Access (Optional)',
            description:
                'Identifies active SIM slot carriers and subscriptions for multi-SIM data quota tracking.',
            icon: Icons.sim_card_rounded,
            isGranted: state.hasPhonePermission,
            importance: PermissionImportance.optional,
            onRequest: controller.requestPhonePermission,
            actionLabel: 'Grant Phone State',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
