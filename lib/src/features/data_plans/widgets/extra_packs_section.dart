import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/data_plan_extra.dart';
import '../../charts/extra_pack_progress_chart.dart';

/// Interactive UI section displaying active booster addon packs and add/delete actions.
class ExtraPacksSection extends StatelessWidget {
  const ExtraPacksSection({
    super.key,
    required this.extraPacks,
    required this.onAddPack,
    required this.onDeletePack,
  });

  final List<DataPlanExtra> extraPacks;
  final VoidCallback onAddPack;
  final ValueChanged<int> onDeletePack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final activePacks = extraPacks.where((p) => p.isValidAt(now)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Booster Packs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (activePacks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activePacks.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            TextButton.icon(
              onPressed: () {
                AppHaptics.contextClick();
                onAddPack();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Booster'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (activePacks.isEmpty) ...[
          // Empty State
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.data_saver_on_rounded,
                  size: 36,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No Active Booster Packs',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add extra quota packs that expire on specific dates',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    AppHaptics.contextClick();
                    onAddPack();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Pack'),
                ),
              ],
            ),
          ),
        ] else ...[
          // Horizontal Booster Pack Cards
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activePacks.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final pack = activePacks[index];
                final expiryStr = 'Expires ${DateFormat('MMM d').format(pack.expiryDate)}';

                return Container(
                  width: 170,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Delete Action
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            AppHaptics.contextClick();
                            onDeletePack(pack.id);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),

                      // Circular Arc Progress Chart
                      Align(
                        alignment: Alignment.center,
                        child: ExtraPackProgressChart(
                          usedBytes: pack.usedBytes,
                          totalBytes: pack.extraBytes,
                          name: pack.note.isNotEmpty ? pack.note : 'Booster Pack',
                          size: 130,
                          strokeWidth: 10,
                          expiryLabel: expiryStr,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
