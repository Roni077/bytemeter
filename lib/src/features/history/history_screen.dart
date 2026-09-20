import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/haptics.dart';
import 'history_controller.dart';
import 'history_state.dart';
import 'widgets/app_list_view.dart';

/// App Data Usages Screen displaying ranked application bandwidth usage separated by network type.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({
    super.key,
    this.scrollController,
  });

  /// Optional scroll controller to coordinate scroll-to-top actions.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final historyState = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final prefs = prefsRepo.current;

    return Scaffold(
      extendBodyBehindAppBar: prefs.enableBlur,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: prefs.enableBlur
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: _buildAppBar(context, ref, colorScheme, theme, true),
                ),
              )
            : _buildAppBar(context, ref, colorScheme, theme, false),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          AppHaptics.selectionTick();
          await controller.loadInitialData(refresh: true);
        },
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            bottom: MediaQuery.paddingOf(context).bottom + 96,
          ),
          children: [
            // Date Navigator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      AppHaptics.selectionTick();
                      controller.adjustDateByDays(-1);
                    },
                  ),
                  Text(
                    _formatDate(historyState.selectedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: AppDateUtils.startOfDay(historyState.selectedDate)
                            .isBefore(AppDateUtils.startOfDay(DateTime.now()))
                        ? () {
                            AppHaptics.selectionTick();
                            controller.adjustDateByDays(1);
                          }
                        : null,
                  ),
                ],
              ),
            ),

            // Segmented View Tab Switch (All | System | User)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SegmentedButton<AppFilterType>(
                segments: const [
                  ButtonSegment<AppFilterType>(
                    value: AppFilterType.all,
                    label: Text('All'),
                  ),
                  ButtonSegment<AppFilterType>(
                    value: AppFilterType.system,
                    label: Text('System'),
                  ),
                  ButtonSegment<AppFilterType>(
                    value: AppFilterType.user,
                    label: Text('User'),
                  ),
                ],
                selected: {historyState.appFilter},
                onSelectionChanged: (selected) {
                  AppHaptics.selectionTick();
                  controller.setAppFilter(selected.first);
                },
              ),
            ),

            const SizedBox(height: 16),

            AppListView(
              apps: historyState.appBreakdown,
              isLoading: historyState.isLoadingDetails,
              isComparisonActive: true,
              primaryLabel: 'Mobile Data',
              secondaryLabel: 'Wi-Fi',
              onQuickFilter: (app) {}, // Removed filtering logic for simplicity
              onLaunchApp: (pkg) => controller.launchApp(pkg),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = AppDateUtils.startOfDay(DateTime.now());
    final selected = AppDateUtils.startOfDay(date);
    if (today == selected) {
      return 'Today';
    } else if (today.subtract(const Duration(days: 1)) == selected) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  AppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    ThemeData theme,
    bool hasBlur,
  ) {
    return AppBar(
      title: const Text('App Data Usages'),
      backgroundColor: hasBlur
          ? colorScheme.surface.withValues(alpha: 0.7)
          : colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    );
  }
}
