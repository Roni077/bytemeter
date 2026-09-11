import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';

/// Segmented pill toggle allowing seamless switching between Mobile (Cellular) and Wi-Fi networks.
class NetworkTypeSelector extends StatelessWidget {
  const NetworkTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final NetworkType selectedType;
  final ValueChanged<NetworkType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 4) / 2;
          final isMobile = selectedType == NetworkType.mobile;

          return Stack(
            children: [
              // Animated sliding indicator pill
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: isMobile ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: itemWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Segment Buttons
              Row(
                children: [
                  Expanded(
                    child: _SegmentItem(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: 'Mobile Data',
                      isSelected: isMobile,
                      onTap: () {
                        if (!isMobile) {
                          AppHaptics.selectionTick();
                          onChanged(NetworkType.mobile);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: _SegmentItem(
                      icon: Icons.wifi_rounded,
                      label: 'Wi-Fi',
                      isSelected: !isMobile,
                      onTap: () {
                        if (isMobile) {
                          AppHaptics.selectionTick();
                          onChanged(NetworkType.wifi);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final targetColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: theme.textTheme.labelLarge!.copyWith(
            color: targetColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: targetColor,
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
