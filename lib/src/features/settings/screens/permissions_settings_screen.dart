import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/haptics.dart';
import '../settings_controller.dart';
import '../widgets/permission_status_card.dart';

/// Nested sub-screen managing Android system permissions, battery optimization
/// exemptions, foreground service status, and real-time native platform diagnostics.
class PermissionsSettingsScreen extends ConsumerWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final prefs = state.preferences;

    final grantedCount = (state.hasUsagePermission ? 1 : 0) +
        (state.isIgnoringBatteryOptimizations ? 1 : 0);
    final allGranted = grantedCount == 2;

    return Scaffold(
      extendBodyBehindAppBar: prefs.enableBlur,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: prefs.enableBlur
                ? ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: AppBar(
              backgroundColor: prefs.enableBlur
                  ? colorScheme.surface.withValues(alpha: 0.75)
                  : colorScheme.surface,
              title: Text(
                'Permissions & Diagnostics',
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
              actions: const [
                SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          AppHaptics.selectionTick();
          await controller.refreshPermissionStatuses();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
        children: [
          // 1. Overall System Health Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: allGranted
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : colorScheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: allGranted
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: allGranted ? colorScheme.primary : colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    allGranted ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                    color: allGranted ? colorScheme.onPrimary : colorScheme.onError,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allGranted
                            ? 'All Systems Fully Authorized'
                            : 'Action Required ($grantedCount/2 Granted)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        allGranted
                            ? 'ByteMeter has complete access to query network usage and run unrestricted background metering.'
                            : 'Grant the missing permissions below to unlock full network monitoring functionality.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Permission Status Detailed Card
          PermissionStatusCard(
            hasUsagePermission: state.hasUsagePermission,
            isIgnoringBatteryOptimizations: state.isIgnoringBatteryOptimizations,
            onRequestUsagePermission: () => controller.requestUsagePermission(),
            onRequestBatteryExemption: () => controller.requestIgnoreBatteryOptimizations(),
          ),

          const SizedBox(height: 16),

          // 3. Native Platform Channel Diagnostic Self-Test Card
          Card(
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
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.speed_rounded,
                          color: colorScheme.onSecondaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Native IPC Diagnostic Test',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Executes a real-time roundtrip ping to ByteMeter Android MethodChannel to verify IPC latency and service responsiveness.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (state.lastDiagnosticMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.lastDiagnosticMessage!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      icon: state.isDiagnosticRunning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(state.isDiagnosticRunning ? 'Testing...' : 'Run Diagnostic Ping'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: state.isDiagnosticRunning
                          ? null
                          : () {
                              AppHaptics.contextClick();
                              controller.runDiagnosticSelfTest();
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
