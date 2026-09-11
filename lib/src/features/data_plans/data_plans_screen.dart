import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/data_plan.dart';
import 'plan_config_screen.dart';
import 'plans_controller.dart';
import 'widgets/add_extra_pack_dialog.dart';
import 'widgets/daily_budget_card.dart';
import 'widgets/data_safety_card.dart';
import 'widgets/extra_packs_section.dart';
import 'widgets/sim_card_pager.dart';

/// Main screen displaying the Multi-SIM Carousel, dynamic daily allowance budgets,
/// Data Safety health indicators, and active booster addon packs.
class DataPlansScreen extends ConsumerWidget {
  const DataPlansScreen({
    super.key,
    this.scrollController,
  });

  /// Optional scroll controller to coordinate scroll-to-top actions.
  final ScrollController? scrollController;

  void _openPlanConfig(BuildContext context, WidgetRef ref, {DataPlan? plan, int slotIndex = 0}) {
    AppHaptics.contextClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanConfigScreen(
          initialPlan: plan,
          initialSlotIndex: slotIndex,
        ),
      ),
    );
  }

  Future<void> _openAddExtraPack(BuildContext context, WidgetRef ref, String planHashedId) async {
    final extra = await AddExtraPackDialog.show(
      context,
      planHashedSubscriberId: planHashedId,
    );

    if (extra != null) {
      await ref.read(plansControllerProvider.notifier).addExtraPack(extra);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(plansControllerProvider);
    final controller = ref.read(plansControllerProvider.notifier);

    final selectedPlan = state.selectedPlan;
    final isConfigured = state.isConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Plans',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add / Configure SIM',
            onPressed: () {
              final nextSlotIndex = state.plans.length;
              _openPlanConfig(context, ref, slotIndex: nextSlotIndex);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Plans',
            onPressed: () {
              AppHaptics.selectionTick();
              controller.refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.only(
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 96,
          ),
          children: [
            // Error Banner (if any)
            if (state.errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Material(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Multi-SIM Swipeable Carousel
            SimCardPager(
              plans: state.plans,
              selectedIndex: state.selectedPlanIndex,
              cycleUsage: state.activeCycleUsage,
              totalQuotaBytes: state.totalAvailableQuota,
              cycleWindow: state.billingCycleWindow,
              onPageChanged: (index) => controller.selectPlan(index),
              onConfigurePlan: (index) {
                final plan = state.plans[index];
                _openPlanConfig(context, ref, plan: plan, slotIndex: index);
              },
              onEditPlan: (index) {
                final plan = state.plans[index];
                _openPlanConfig(context, ref, plan: plan, slotIndex: index);
              },
            ),

            const SizedBox(height: 16),

            // Plan-Specific Insights & Metrics
            if (isConfigured) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Data Safety Pacing Card
                    DataSafetyCard(
                      safetyState: state.dataSafetyState,
                      delta: state.safetyDelta,
                      usageRatio: state.totalUsageRatio,
                      elapsedRatio: state.billingCycleWindow?.elapsedRatio ?? 0.0,
                    ),

                    const SizedBox(height: 14),

                    // 2. Dynamic Daily Budget Card
                    DailyBudgetCard(
                      dailyBudget: state.dailyBudget,
                      todayRemainingBudget: state.todayRemainingBudget,
                      todayUsedBytes: state.todayUsage.totalBytes,
                      daysRemaining: state.billingCycleWindow?.daysRemaining ?? 0,
                    ),

                    const SizedBox(height: 16),

                    // 3. Addon Booster Packs Section
                    ExtraPacksSection(
                      extraPacks: state.extraPacks,
                      onAddPack: () {
                        if (selectedPlan != null) {
                          _openAddExtraPack(context, ref, selectedPlan.hashedSubscriberId);
                        }
                      },
                      onDeletePack: (id) => controller.deleteExtraPack(id),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Unconfigured Onboarding Guide Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Multi-SIM Tracking & Safety',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.sim_card_outlined,
                          color: colorScheme.primary,
                          title: 'Track Multi-Carrier Quotas',
                          description:
                              'Set custom quotas, rollover settings, and billing reset cycles for SIM 1 & SIM 2.',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.shield_outlined,
                          color: colorScheme.tertiary,
                          title: 'Predictive Data Safety',
                          description:
                              'Real-time pacing alerts ensure you never exhaust data before billing renewal.',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.autorenew_rounded,
                          color: colorScheme.secondary,
                          title: 'Automated Rollover',
                          description:
                              'Unused data automatically converts to a booster pack in your next cycle.',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              _openPlanConfig(
                                context,
                                ref,
                                plan: selectedPlan,
                                slotIndex: state.selectedPlanIndex,
                              );
                            },
                            icon: const Icon(Icons.tune_rounded),
                            label: Text(
                              'Configure SIM ${state.selectedPlanIndex + 1} Plan',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
