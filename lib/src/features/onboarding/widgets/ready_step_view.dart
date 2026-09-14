import 'package:flutter/material.dart';
import '../onboarding_state.dart';

/// Step 4: Final verification and launch summary before entering the main app.
class ReadyStepView extends StatelessWidget {
  const ReadyStepView({
    super.key,
    required this.state,
    required this.onLaunch,
  });

  final OnboardingState state;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // Checkmark celebration badge
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: colorScheme.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'You\'re Ready to Go!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ByteMeter is configured and prepared to deliver precision network insights.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Setup Checklist Summary Card
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryItem(
                    context,
                    icon: state.hasUsagePermission
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    iconColor: state.hasUsagePermission
                        ? colorScheme.primary
                        : colorScheme.error,
                    title: 'Usage Access Permission',
                    subtitle: state.hasUsagePermission
                        ? 'Granted & Active'
                        : 'Action required in settings',
                  ),
                  const Divider(height: 20),
                  _buildSummaryItem(
                    context,
                    icon: state.hasNotificationPermission
                        ? Icons.check_circle_rounded
                        : Icons.notifications_off_outlined,
                    iconColor: state.hasNotificationPermission
                        ? colorScheme.primary
                        : colorScheme.outline,
                    title: 'Status Bar Notification',
                    subtitle: state.hasNotificationPermission
                        ? 'Enabled & Authorized'
                        : 'Optional (Disabled)',
                  ),
                  const Divider(height: 20),
                  _buildSummaryItem(
                    context,
                    icon: Icons.speed_rounded,
                    iconColor: colorScheme.tertiary,
                    title: 'Speed Display Format',
                    subtitle:
                        '${state.speedUnitType.displayName} · ${state.metricBase.displayName}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Launch Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: state.isCompleting ? null : onLaunch,
              icon: state.isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(
                state.isCompleting ? 'Launching...' : 'Launch ByteMeter',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
