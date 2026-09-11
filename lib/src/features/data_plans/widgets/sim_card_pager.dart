import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/data_plan.dart';
import '../../../data/models/usage_data.dart';
import '../../../core/utils/date_utils.dart';
import 'sim_card_view.dart';

/// Swipeable multi-SIM card carousel with smooth animated page indicator dots.
class SimCardPager extends StatefulWidget {
  const SimCardPager({
    super.key,
    required this.plans,
    required this.selectedIndex,
    required this.cycleUsage,
    required this.totalQuotaBytes,
    this.cycleWindow,
    required this.onPageChanged,
    required this.onConfigurePlan,
    required this.onEditPlan,
  });

  final List<DataPlan> plans;
  final int selectedIndex;
  final UsageData cycleUsage;
  final int totalQuotaBytes;
  final BillingCycleWindow? cycleWindow;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onConfigurePlan;
  final ValueChanged<int> onEditPlan;

  @override
  State<SimCardPager> createState() => _SimCardPagerState();
}

class _SimCardPagerState extends State<SimCardPager> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.selectedIndex.clamp(0, widget.plans.isEmpty ? 0 : widget.plans.length - 1),
      viewportFraction: 0.92,
    );
  }

  @override
  void didUpdateWidget(covariant SimCardPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        _pageController.hasClients &&
        _pageController.page?.round() != widget.selectedIndex) {
      _pageController.animateToPage(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.plans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.plans.length,
            onPageChanged: (index) {
              AppHaptics.selectionTick();
              widget.onPageChanged(index);
            },
            itemBuilder: (context, index) {
              final plan = widget.plans[index];
              return SimCardView(
                plan: plan,
                cycleUsage: (index == widget.selectedIndex) ? widget.cycleUsage : UsageData(),
                totalQuotaBytes: (index == widget.selectedIndex) ? widget.totalQuotaBytes : plan.quotaBytes,
                cycleWindow: (index == widget.selectedIndex) ? widget.cycleWindow : null,
                onConfigure: () => widget.onConfigurePlan(index),
                onEdit: () => widget.onEditPlan(index),
              );
            },
          ),
        ),

        // Animated Page Indicator Dots
        if (widget.plans.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.plans.length, (index) {
              final isSelected = index == widget.selectedIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
