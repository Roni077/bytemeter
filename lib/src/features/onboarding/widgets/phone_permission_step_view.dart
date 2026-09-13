import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../onboarding_controller.dart';
import '../onboarding_state.dart';

/// Step 5: Dedicated onboarding screen for Android Phone State permission (Multi-SIM).
class PhonePermissionStepView extends StatelessWidget {
  const PhonePermissionStepView({
    super.key,
    required this.state,
    required this.controller,
    this.onSkip,
  });

  final OnboardingState state;
  final OnboardingController controller;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isGranted = state.hasPhonePermission;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Glowing Hero Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.sim_card_rounded,
              color: colorScheme.onPrimary,
              size: 42,
            ),
          ),
          const SizedBox(height: 20),

          // Importance Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isGranted ? 'PERMISSION GRANTED' : 'OPTIONAL (MULTI-SIM)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isGranted
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Subtitle
          Text(
            'Multi-SIM Quota Tracking',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Identify dual-SIM card slots and carrier subscriptions to track independent mobile data plans.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Feature Highlights
          _buildFeatureTile(
            context,
            icon: Icons.cell_tower_rounded,
            iconColor: colorScheme.primary,
            title: 'Dual Carrier Identification',
            description:
                'Distinguishes between SIM 1 and SIM 2 network interfaces automatically.',
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            context,
            icon: Icons.calendar_today_rounded,
            iconColor: colorScheme.secondary,
            title: 'Separate Billing Cycles & Budgets',
            description:
                'Configure individual renewal dates, rollover limits, and daily pacing per SIM.',
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            context,
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.green,
            title: 'Never Accesses Calls or Contacts',
            description:
                'ByteMeter only reads the SIM subscriber token. No personal communications are ever accessed.',
          ),
          const SizedBox(height: 20),

          // Status & Action Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isGranted
                  ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                  : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isGranted
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
                width: isGranted ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isGranted
                          ? Icons.check_circle_rounded
                          : Icons.sim_card_outlined,
                      color: isGranted ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isGranted
                            ? 'Multi-SIM Access Active'
                            : 'SIM Access Inactive',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isGranted ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isGranted
                      ? 'SIM subscription identifiers are readable for multi-carrier data plan configuration.'
                      : 'Optional for single-SIM or Wi-Fi only users. Enables dual-carrier data plan differentiation.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: isGranted
                      ? OutlinedButton.icon(
                          onPressed: () {
                            AppHaptics.contextClick();
                            controller.requestPhonePermission();
                          },
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('App Details Settings'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            AppHaptics.contextClick();
                            controller.requestPhonePermission();
                          },
                          icon: const Icon(Icons.sim_card_rounded, size: 18),
                          label: const Text(
                            'Enable Multi-SIM Tracking',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
                if (!isGranted && onSkip != null) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      AppHaptics.selectionTick();
                      onSkip!();
                    },
                    child: Text(
                      'Skip (Single SIM / Wi-Fi Only)',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
