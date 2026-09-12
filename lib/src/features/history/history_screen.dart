import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/haptics.dart';
import '../charts/scrollable_bar_chart.dart';
import 'history_controller.dart';
import 'history_state.dart';
import 'widgets/app_list_view.dart';
import 'widgets/history_filter_bottom_sheet.dart';
import 'widgets/history_legend_badge.dart';
import 'widgets/hour_list_view.dart';

/// 90-Day Historical Network Analytics Screen with interactive fling timeline,
/// dual-query comparison engine, ranked application breakdown, and 2-hour interval time buckets.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({
    super.key,
    this.scrollController,
  });

  /// Optional scroll controller to coordinate scroll-to-top actions.
  final ScrollController? scrollController;

  void _openFilterBottomSheet(BuildContext context, WidgetRef ref) {
    final state = ref.read(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);

    HistoryFilterBottomSheet.show(
      context: context,
      primaryQuery: state.primaryQuery,
      secondaryQuery: state.secondaryQuery,
      isComparisonEnabled: state.isComparisonEnabled,
      installedApps: state.installedApps,
      onApply: (primary, secondary, enabled) {
        controller.updatePrimaryQuery(primary);
        controller.updateSecondaryQuery(secondary, isComparisonEnabled: enabled);
      },
      onReset: () {
        controller.resetFilters();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final historyState = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final prefs = prefsRepo.current;

    final primaryLabel = historyState.primaryQuery.networkType?.displayName ?? 'Primary';
    final secondaryLabel = historyState.secondaryQuery.networkType?.displayName ?? 'Secondary';

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
            // 1. 90-Day Fling-Scrollable Timeline Bar Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 260,
                child: historyState.isLoadingTimeline && historyState.timelineData.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ScrollableBarChart(
                        historyData: historyState.timelineData,
                        selectedDate: historyState.selectedDate,
                        onDateSelected: (date, data) {
                          controller.selectDate(date, debounce: true);
                        },
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // 2. Dual Query Legend Header & Filter Badges
            HistoryLegendBadge(
              primaryQuery: historyState.primaryQuery,
              secondaryQuery: historyState.secondaryQuery,
              isComparisonEnabled: historyState.isComparisonEnabled,
              onOpenFilters: () => _openFilterBottomSheet(context, ref),
              onClearAppFilter: () => controller.clearAppFilter(),
            ),

            const SizedBox(height: 12),

            // 3. Segmented View Tab Switch (Apps Breakdown vs 2-Hour Intervals)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SegmentedButton<HistoryViewTab>(
                segments: const [
                  ButtonSegment<HistoryViewTab>(
                    value: HistoryViewTab.apps,
                    label: Text('Apps Breakdown'),
                    icon: Icon(Icons.apps_rounded, size: 16),
                  ),
                  ButtonSegment<HistoryViewTab>(
                    value: HistoryViewTab.hours,
                    label: Text('2-Hour Intervals'),
                    icon: Icon(Icons.access_time_rounded, size: 16),
                  ),
                ],
                selected: {historyState.activeTab},
                onSelectionChanged: (selected) {
                  AppHaptics.selectionTick();
                  controller.switchViewTab(selected.first);
                },
              ),
            ),

            const SizedBox(height: 16),

            // 4. Detail Breakdown Body (Apps or Hours)
            if (historyState.activeTab == HistoryViewTab.apps) ...[
              AppListView(
                apps: historyState.appBreakdown,
                isLoading: historyState.isLoadingDetails,
                isComparisonActive: historyState.isComparisonEnabled,
                primaryLabel: primaryLabel,
                secondaryLabel: secondaryLabel,
                onQuickFilter: (app) => controller.setQuickFilterApp(app),
                onLaunchApp: (pkg) => controller.launchApp(pkg),
              ),
            ] else ...[
              HourListView(
                buckets: historyState.hourlyBuckets,
                isLoading: historyState.isLoadingDetails,
                isComparisonActive: historyState.isComparisonEnabled,
                primaryLabel: primaryLabel,
                secondaryLabel: secondaryLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    ThemeData theme,
    bool hasBlur,
  ) {
    return AppBar(
      title: const Text('History & Analytics'),
      backgroundColor: hasBlur
          ? colorScheme.surface.withValues(alpha: 0.7)
          : colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Filter & Compare',
          onPressed: () => _openFilterBottomSheet(context, ref),
        ),
      ],
    );
  }
}
