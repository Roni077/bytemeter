import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../onboarding_controller.dart';
import '../onboarding_state.dart';

/// Step 2: Dedicated onboarding screen for Android Usage Access permission.
class UsagePermissionStepView extends StatelessWidget {
  const UsagePermissionStepView({
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
    final isGranted = state.hasUsagePermission;

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
                  colorScheme.primary.withValues(alpha: 0.7),
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
              Icons.data_usage_rounded,
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
                  : colorScheme.errorContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isGranted ? 'PERMISSION GRANTED' : 'ESSENTIAL PERMISSION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isGranted
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onErrorContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Subtitle
          Text(
            'Network Usage Access',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ByteMeter needs system Usage Access to read network socket counters and generate per-app statistics.',
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
            icon: Icons.speed_rounded,
            iconColor: colorScheme.primary,
            title: 'Socket-Level Traffic Stats',
            description:
                'Measures actual cellular and Wi-Fi transfer bytes directly from the Android kernel.',
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            context,
            icon: Icons.pie_chart_outline_rounded,
            iconColor: colorScheme.secondary,
            title: 'App Burn Rate & Breakdown',
            description:
                'Calculates 2-hour burn rates and identifies high-bandwidth consuming background apps.',
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            context,
            icon: Icons.shield_outlined,
            iconColor: Colors.green,
            title: '100% On-Device & Private',
            description:
                'Zero telemetry, zero packet sniffing. Your usage records never leave your phone.',
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
                          : Icons.info_outline_rounded,
                      color: isGranted ? colorScheme.primary : colorScheme.error,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isGranted
                            ? 'Usage Access Active'
                            : 'Authorization Required',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isGranted ? colorScheme.primary : colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isGranted
                      ? 'Network data query engine is authorized and ready to stream live metrics.'
                      : 'Tap below to open Android Settings, select "ByteMeter", and toggle "Permit usage access".',
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
                            controller.requestUsagePermission();
                          },
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Open Usage Settings'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            AppHaptics.contextClick();
                            controller.requestUsagePermission();
                          },
                          icon: const Icon(Icons.security_rounded, size: 18),
                          label: const Text(
                            'Grant Usage Access',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
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
