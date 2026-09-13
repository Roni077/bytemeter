import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../onboarding_controller.dart';
import '../onboarding_state.dart';

/// Step 4: Dedicated onboarding screen for Android Battery Saver exemption.
class BatteryOptimizationStepView extends StatelessWidget {
  const BatteryOptimizationStepView({
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
    final isExempt = state.isIgnoringBatteryOptimizations;

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
                  colorScheme.tertiary,
                  colorScheme.tertiary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.tertiary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.battery_charging_full_rounded,
              color: colorScheme.onTertiary,
              size: 42,
            ),
          ),
          const SizedBox(height: 20),

          // Importance Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isExempt
                  ? colorScheme.primaryContainer
                  : colorScheme.tertiaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isExempt ? 'EXEMPTION ACTIVE' : 'RECOMMENDED',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isExempt
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Subtitle
          Text(
            'Uninterrupted Speed Meter',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Exempt ByteMeter from background restrictions to prevent OEM task cleaners from killing the live meter.',
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
            icon: Icons.shield_moon_outlined,
            iconColor: colorScheme.tertiary,
            title: 'OEM Task Killer Protection',
            description:
                'Stops Xiaomi (HyperOS/MIUI), Samsung (OneUI), and OnePlus from terminating the background speed meter.',
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            context,
            icon: Icons.eco_rounded,
            iconColor: Colors.green,
            title: 'Zero Screen-Off Battery Impact',
            description:
                'ByteMeter sleeps while screen is turned off unless AOD mode is manually enabled.',
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            context,
            icon: Icons.restart_alt_rounded,
            iconColor: colorScheme.primary,
            title: 'Automatic Reboot Recovery',
            description:
                'Speed monitoring restores instantly on phone restart without needing manual app launches.',
          ),
          const SizedBox(height: 20),

          // Status & Action Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isExempt
                  ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                  : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isExempt
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
                width: isExempt ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isExempt
                          ? Icons.check_circle_rounded
                          : Icons.battery_alert_rounded,
                      color: isExempt ? colorScheme.primary : colorScheme.tertiary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isExempt
                            ? 'Battery Saver Exemption Active'
                            : 'Standard Restrictions Active',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isExempt ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isExempt
                      ? 'Background service is authorized to run uninterrupted without OEM task killer termination.'
                      : 'Granting exemption allows Android to bypass aggressive background sleep rules for the speed meter.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: isExempt
                      ? OutlinedButton.icon(
                          onPressed: () {
                            AppHaptics.contextClick();
                            controller.requestBatteryExemption();
                          },
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Battery Settings'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            AppHaptics.contextClick();
                            controller.requestBatteryExemption();
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text(
                            'Disable Restrictions',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
                if (!isExempt && onSkip != null) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      AppHaptics.selectionTick();
                      onSkip!();
                    },
                    child: Text(
                      'Keep Default Restrictions',
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
