import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/data_size.dart';
import '../../../core/utils/haptics.dart';
import '../onboarding_controller.dart';
import '../onboarding_state.dart';

/// Step 3: Dedicated onboarding screen for Android Notification permission.
class NotificationPermissionStepView extends ConsumerWidget {
  const NotificationPermissionStepView({
    super.key,
    required this.state,
    required this.controller,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isGranted = state.hasNotificationPermission;
    final speedSnapshot = ref.watch(speedStreamProvider).valueOrNull;
    final todayTotalsAsync = ref.watch(todayNetworkTotalsProvider);
    final todayTotals = todayTotalsAsync.valueOrNull;
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final prefs = prefsRepo.current;

    final downStr = DataSize(speedSnapshot?.downloadBytesPerSec ?? 0).format(
      base: prefs.metricBase,
      unitType: prefs.speedUnitType,
      isRate: true,
      decimals: 1,
    );
    final upStr = DataSize(speedSnapshot?.uploadBytesPerSec ?? 0).format(
      base: prefs.metricBase,
      unitType: prefs.speedUnitType,
      isRate: true,
      decimals: 1,
    );
    final mobileStr = DataSize(todayTotals?.mobileBytes ?? 0).format(
      base: prefs.metricBase,
      decimals: 1,
    );
    final wifiStr = DataSize(todayTotals?.wifiBytes ?? 0).format(
      base: prefs.metricBase,
      decimals: 1,
    );

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
                  colorScheme.secondary,
                  colorScheme.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: colorScheme.onSecondary,
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
                  : colorScheme.secondaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isGranted ? 'PERMISSION GRANTED' : 'STATUS BAR SPEED METER',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isGranted
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Subtitle
          Text(
            'Live Speed Notification',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Keep an eye on active network activity directly from your Android status bar and notification drawer.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Rendered Notification Shade Mockup
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.speed_rounded,
                          size: 14, color: colorScheme.onPrimary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ByteMeter',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• now',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more_rounded,
                        size: 16, color: colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Download Rate Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_downward_rounded,
                              size: 14, color: colorScheme.onPrimaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            downStr,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Upload Rate Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward_rounded,
                              size: 14, color: colorScheme.onTertiaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            upStr,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Today: $mobileStr Cellular · $wifiStr Wi-Fi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Feature Highlights
          _buildFeatureTile(
            context,
            icon: Icons.flash_on_rounded,
            iconColor: colorScheme.primary,
            title: 'Dynamic Status Bar Icon',
            description:
                'Draws real-time numerical speed digits directly onto your device status bar.',
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            context,
            icon: Icons.sync_alt_rounded,
            iconColor: colorScheme.tertiary,
            title: 'Directional Speed Indicators',
            description:
                'Distinct download and upload gauges let you know when background sync occurs.',
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            context,
            icon: Icons.battery_saver_rounded,
            iconColor: Colors.green,
            title: 'Zero Screen-Off Drain',
            description:
                'Background monitoring automatically pauses when screen turns off.',
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
                          : Icons.notifications_none_rounded,
                      color: isGranted ? colorScheme.primary : colorScheme.secondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isGranted
                            ? 'Notifications Allowed'
                            : 'Notifications Not Allowed',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isGranted
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isGranted
                      ? 'Status bar speed meter is enabled and ready to display real-time traffic.'
                      : 'On Android 13+, notification authorization is needed for the live status bar meter.',
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
                            controller.requestNotificationPermission();
                          },
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Notification Settings'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            AppHaptics.contextClick();
                            controller.requestNotificationPermission();
                          },
                          icon: const Icon(Icons.notifications_active_rounded,
                              size: 18),
                          label: const Text(
                            'Allow Notifications',
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
