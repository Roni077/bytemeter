import 'package:flutter/material.dart';
import '../../../core/utils/data_size.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/data_plan.dart';
import '../../../data/models/usage_data.dart';
import 'sim_card_gradients.dart';

/// Interactive visual card representing a carrier SIM Data Plan with real-time quota progress.
class SimCardView extends StatelessWidget {
  const SimCardView({
    super.key,
    required this.plan,
    required this.cycleUsage,
    required this.totalQuotaBytes,
    this.cycleWindow,
    required this.onConfigure,
    this.onEdit,
  });

  final DataPlan plan;
  final UsageData cycleUsage;
  final int totalQuotaBytes;
  final BillingCycleWindow? cycleWindow;
  final VoidCallback onConfigure;
  final VoidCallback? onEdit;

  bool get isConfigured => plan.quotaBytes > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isConfigured) {
      return _buildUnconfiguredCard(context, theme, colorScheme);
    }

    final gradientTheme = SimCardGradients.getTheme(plan.cardColorIndex);
    final usedBytes = cycleUsage.totalBytes;
    final remainingBytes = (totalQuotaBytes - usedBytes).clamp(0, totalQuotaBytes);
    final usageRatio = totalQuotaBytes > 0 ? (usedBytes / totalQuotaBytes).clamp(0.0, 1.0) : 0.0;
    final usedParts = DataSize(usedBytes).toParts();
    final totalFormatted = DataSize(totalQuotaBytes).format();
    final remainingFormatted = DataSize(remainingBytes).format();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradientTheme.gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientTheme.colors.last.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle ambient SIM chip watermarks
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.sim_card_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header Row
                Row(
                  children: [
                    // SIM Chip Icon Graphic
                    _buildSimChip(gradientTheme.chipColor),
                    const SizedBox(width: 12),

                    // Carrier & SIM Slot
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.carrierName.isNotEmpty
                                ? plan.carrierName
                                : 'SIM ${plan.simSlotIndex + 1}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'SIM ${plan.simSlotIndex + 1}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (plan.rolloverEnabled) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.autorenew_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Rollover',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Edit / Configure Action Button
                    IconButton.filledTonal(
                      onPressed: () {
                        AppHaptics.contextClick();
                        onEdit?.call();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      tooltip: 'Configure Plan',
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Center Quota Metric Display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          usedParts.first,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (usedParts.second.isNotEmpty)
                          Text(
                            usedParts.second,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          usedParts.third,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: gradientTheme.accentColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'of $totalFormatted',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 7,
                        color: Colors.white.withValues(alpha: 0.22),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  width: constraints.maxWidth * usageRatio,
                                  decoration: BoxDecoration(
                                    color: (usageRatio >= 0.95)
                                        ? const Color(0xFFEF4444)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Sub-progress labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$remainingFormatted remaining',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                        Text(
                          '${(usageRatio * 100).toStringAsFixed(1)}% used',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: gradientTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Bottom Row Badges (Billing cycle, Excluded apps, Note)
                Row(
                  children: [
                    if (cycleWindow != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cycleWindow!.daysRemaining == 0
                                  ? 'Resets today'
                                  : '${cycleWindow!.daysRemaining}d remaining',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (plan.excludedUids.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.block_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${plan.excludedUids.length} zero-rated',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (plan.customNote.isNotEmpty) ...[
                      const Spacer(),
                      Flexible(
                        child: Text(
                          plan.customNote,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnconfiguredCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sim_card_outlined,
              size: 26,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SIM ${plan.simSlotIndex + 1} Not Configured',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Set up quota, cycle resets, and rollover data',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              AppHaptics.contextClick();
              onConfigure();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Set Up SIM ${plan.simSlotIndex + 1} Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimChip(Color chipColor) {
    return Container(
      width: 32,
      height: 24,
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12, width: 0.8),
      ),
      child: CustomPaint(
        painter: _SimChipPainter(),
      ),
    );
  }
}

class _SimChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Outer chip divider lines
    final midX = size.width / 2;
    final midY = size.height / 2;

    canvas.drawLine(Offset(midX, 2), Offset(midX, size.height - 2), paint);
    canvas.drawLine(Offset(2, midY), Offset(size.width - 2, midY), paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.25, size.height * 0.20, size.width * 0.50, size.height * 0.60),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
