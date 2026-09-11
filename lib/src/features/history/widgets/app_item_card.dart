import 'package:flutter/material.dart';
import '../../../core/constants/special_uids.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../core/utils/data_size.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/app_info.dart';
import '../../../data/models/app_usage.dart';
import '../../charts/comparative_line_chart.dart';

/// Expandable card representing a ranked data-consuming application with comparative bar charts,
/// detailed stats, quick timeline filtering, and app launcher action.
class AppItemCard extends StatefulWidget {
  const AppItemCard({
    super.key,
    required this.appUsage,
    required this.rank,
    required this.isComparisonActive,
    this.primaryLabel,
    this.secondaryLabel,
    required this.onQuickFilter,
    required this.onLaunchApp,
  });

  final AppUsage appUsage;
  final int rank;
  final bool isComparisonActive;
  final String? primaryLabel;
  final String? secondaryLabel;
  final void Function(AppInfo app) onQuickFilter;
  final void Function(String packageName) onLaunchApp;

  @override
  State<AppItemCard> createState() => _AppItemCardState();
}

class _AppItemCardState extends State<AppItemCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    AppHaptics.contextClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Widget _buildAppIcon(AppInfo app, ColorScheme colorScheme) {
    if (app.iconBytes != null && app.iconBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          app.iconBytes!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(app, colorScheme),
        ),
      );
    }
    return _buildFallbackIcon(app, colorScheme);
  }

  Widget _buildFallbackIcon(AppInfo app, ColorScheme colorScheme) {
    IconData iconData = Icons.android_rounded;
    Color iconColor = colorScheme.primary;

    if (app.uid == SpecialUids.uidTethering) {
      iconData = Icons.wifi_tethering_rounded;
      iconColor = colorScheme.secondary;
    } else if (app.uid == SpecialUids.uidRemoved) {
      iconData = Icons.delete_sweep_rounded;
      iconColor = colorScheme.error;
    } else if (app.uid == SpecialUids.uidOtherUsers) {
      iconData = Icons.devices_other_rounded;
      iconColor = colorScheme.tertiary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final app = widget.appUsage.appInfo;
    final usage = widget.appUsage;

    final isLaunchable = app.packageName.isNotEmpty &&
        !app.packageName.startsWith('uid_') &&
        !app.isSpecial;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: _isExpanded ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isExpanded
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Rank + Icon + App Name + Total Badge + Expand Chevron
              Row(
                children: [
                  // Rank indicator
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.rank <= 3
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.rank}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.rank <= 3
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // App Icon
                  _buildAppIcon(app, colorScheme),
                  const SizedBox(width: 12),

                  // App Name & Package
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          app.packageName.isNotEmpty ? app.packageName : 'UID ${app.uid}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Total Usage Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DataSize(usage.totalBytes).format(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Expand Chevron
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Comparative Horizontal Line Bar
              ComparativeLineChart(
                primaryBytes: usage.primaryBytes,
                secondaryBytes: usage.secondaryBytes,
                primaryColor: widget.isComparisonActive
                    ? AppColorSchemes.cellularColor
                    : AppColorSchemes.downloadColor,
                secondaryColor: widget.isComparisonActive
                    ? AppColorSchemes.wifiColor
                    : AppColorSchemes.uploadColor,
                primaryLabel: widget.primaryLabel,
                secondaryLabel: widget.secondaryLabel,
                height: 24.0,
                borderRadius: 8.0,
              ),

              // Expandable Detail Area
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Metrics Grid (Primary / Secondary / Total / % of Day)
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  label: widget.isComparisonActive ? 'Primary' : 'Download',
                                  bytes: usage.primaryBytes,
                                  color: widget.isComparisonActive
                                      ? AppColorSchemes.cellularColor
                                      : AppColorSchemes.downloadColor,
                                  context: context,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricTile(
                                  label: widget.isComparisonActive ? 'Secondary' : 'Upload',
                                  bytes: usage.secondaryBytes,
                                  color: widget.isComparisonActive
                                      ? AppColorSchemes.wifiColor
                                      : AppColorSchemes.uploadColor,
                                  context: context,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricTile(
                                  label: 'Share of Day',
                                  customValue: '${(usage.percentage * 100).toStringAsFixed(1)}%',
                                  color: colorScheme.primary,
                                  context: context,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Action Buttons: Quick Filter Timeline & Open App
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  AppHaptics.contextClick();
                                  widget.onQuickFilter(app);
                                },
                                icon: const Icon(Icons.filter_alt_rounded, size: 16),
                                label: const Text('Filter Timeline'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              if (isLaunchable) ...[
                                const SizedBox(width: 8),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    AppHaptics.contextClick();
                                    widget.onLaunchApp(app.packageName);
                                  },
                                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                  label: const Text('Open App'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    int? bytes,
    String? customValue,
    required Color color,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final valueText = customValue ?? (bytes != null ? DataSize(bytes).format() : '0 B');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
