import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/data_size.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';
import '../settings_controller.dart';

/// Sub-screen configuring Android status bar numeric speed indicator,
/// dynamic Canvas bitmap icon style, silent auto-hide threshold, and AOD battery conservation.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final prefs = state.preferences;

    return Scaffold(
      extendBodyBehindAppBar: prefs.enableBlur,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: prefs.enableBlur
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: _buildAppBar(context, theme, colorScheme, true),
                ),
              )
            : _buildAppBar(context, theme, colorScheme, false),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // 1. Service Status Live Banner
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: (!state.isServiceRunning && prefs.persistentNotificationEnabled && !state.isTogglingService)
                  ? () {
                      AppHaptics.selectionTick();
                      controller.setPersistentNotificationEnabled(true);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: state.isServiceRunning
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: state.isServiceRunning
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: state.isServiceRunning
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.isServiceRunning ? Icons.bolt_rounded : Icons.pause_rounded,
                        color: state.isServiceRunning
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isServiceRunning
                                ? 'Foreground Service Active'
                                : (prefs.persistentNotificationEnabled
                                    ? 'Service Inactive (Tap to Start)'
                                    : 'Service Stopped'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.isServiceRunning
                                ? 'Sub-second bandwidth polling enabled with dynamic status bar icon.'
                                : (prefs.persistentNotificationEnabled
                                    ? 'Notifications enabled. Tap here to start foreground speed meter.'
                                    : 'Enable the master switch below to start real-time monitoring.'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!state.isServiceRunning && prefs.persistentNotificationEnabled) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Notification Shade Preview
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Notification Shade Panel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const _NotificationPreviewCard(),

          const SizedBox(height: 16),

          // 3. Master Persistent Notification Switch
          Card(
            child: SwitchListTile.adaptive(
              value: prefs.persistentNotificationEnabled,
              title: Text(
                'Live Status Bar Meter',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Displays current transfer rate dynamically inside Android status bar and notification shade.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              secondary: Icon(
                Icons.speed_rounded,
                color: colorScheme.primary,
              ),
              onChanged: state.isTogglingService
                  ? null
                  : (enabled) {
                      AppHaptics.selectionTick();
                      controller.setPersistentNotificationEnabled(enabled);
                    },
            ),
          ),

          const SizedBox(height: 16),

          // 3. Status Bar Icon Style
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.art_track_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Status Bar Icon Style',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how the live speed digits are rendered onto the dynamic in-memory bitmap.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<NotificationIconStyle>(
                      segments: const [
                        ButtonSegment<NotificationIconStyle>(
                          value: NotificationIconStyle.combined,
                          label: Text('Combined Speed'),
                          icon: Icon(Icons.numbers_rounded, size: 16),
                        ),
                        ButtonSegment<NotificationIconStyle>(
                          value: NotificationIconStyle.separateUpDown,
                          label: Text('Separate Up/Down'),
                          icon: Icon(Icons.swap_vert_rounded, size: 16),
                        ),
                      ],
                      selected: {prefs.notificationIconStyle},
                      onSelectionChanged: (selected) {
                        AppHaptics.selectionTick();
                        controller.setNotificationIconStyle(selected.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. Silent / Auto-Hide Speed Threshold Slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_off_outlined,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Auto-Hide Threshold',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          prefs.silentSpeedThresholdKb == 0
                              ? 'Always Visible'
                              : '< ${prefs.silentSpeedThresholdKb} KB/s',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Automatically hides the status bar icon when bandwidth consumption falls below this rate.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      showValueIndicator: ShowValueIndicator.onDrag,
                    ),
                    child: Slider(
                      value: prefs.silentSpeedThresholdKb.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: prefs.silentSpeedThresholdKb == 0
                          ? 'Always Visible'
                          : '${prefs.silentSpeedThresholdKb} KB/s',
                      onChanged: (value) {
                        AppHaptics.selectionTick();
                        controller.setSilentSpeedThresholdKb(value.round());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 5. AOD / Screen-off Mode Toggle
          Card(
            child: SwitchListTile.adaptive(
              value: prefs.aodModeEnabled,
              title: Text(
                'Always-On Display (AOD) Updates',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'When disabled, speed polling halts immediately when the screen is locked to guarantee zero battery drain.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              secondary: Icon(
                Icons.bedtime_outlined,
                color: colorScheme.primary,
              ),
              onChanged: (enabled) {
                AppHaptics.selectionTick();
                controller.setAodModeEnabled(enabled);
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool hasBlur,
  ) {
    return AppBar(
      backgroundColor: hasBlur
          ? colorScheme.surface.withValues(alpha: 0.75)
          : colorScheme.surface,
      title: Text(
        'Status Bar Meter',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          AppHaptics.contextClick();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _NotificationPreviewCard extends ConsumerWidget {
  const _NotificationPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131720),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification System Header
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.signal_cellular_alt_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ByteMeter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  ' · Now',
                  style: TextStyle(
                    color: Color(0xFF8E95A3),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Color(0xFF8E95A3),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 4-Column Metric Grid
            Row(
              children: [
                _buildMetricColumn(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF00E5FF),
                  label: 'Down',
                  value: downStr,
                ),
                _buildMetricColumn(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFF536DFE),
                  label: 'Up',
                  value: upStr,
                ),
                _buildMetricColumn(
                  icon: Icons.signal_cellular_alt_rounded,
                  iconColor: const Color(0xFF42A5F5),
                  label: 'Mobile',
                  value: mobileStr,
                ),
                _buildMetricColumn(
                  icon: Icons.wifi_rounded,
                  iconColor: const Color(0xFF29B6F6),
                  label: 'WiFi',
                  value: wifiStr,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(
              color: Color(0xFF222836),
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: 8),
            // Footer Row
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ByteMeter  |  Real-time network monitoring',
                  style: TextStyle(
                    color: Color(0xFF7A808C),
                    fontSize: 10,
                  ),
                ),
                Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF9AA0A6),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMetricColumn({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9AA0A6),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

