import 'package:flutter/material.dart';

/// Smooth animated page indicator displaying active wizard slide dots.
class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
    this.dotColor,
    this.activeDotColor,
  });

  final int currentPage;
  final int pageCount;
  final Color? dotColor;
  final Color? activeDotColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = activeDotColor ?? colorScheme.primary;
    final inactive = dotColor ?? colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        final isSelected = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSelected ? active : inactive,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
