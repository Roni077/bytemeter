import 'package:flutter/material.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/app_info.dart';
import '../../../data/models/enums.dart';
import '../history_state.dart';
import 'app_search_modal.dart';

/// Modal bottom sheet for configuring Primary and Secondary timeline comparison filters.
class HistoryFilterBottomSheet extends StatefulWidget {
  const HistoryFilterBottomSheet({
    super.key,
    required this.initialPrimaryQuery,
    required this.initialSecondaryQuery,
    required this.isComparisonEnabled,
    required this.installedApps,
    required this.onApply,
    required this.onReset,
  });

  final HistoryQuery initialPrimaryQuery;
  final HistoryQuery initialSecondaryQuery;
  final bool isComparisonEnabled;
  final List<AppInfo> installedApps;
  final void Function(
    HistoryQuery primary,
    HistoryQuery secondary,
    bool comparisonEnabled,
  ) onApply;
  final VoidCallback onReset;

  /// Convenience helper to open the filter bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required HistoryQuery primaryQuery,
    required HistoryQuery secondaryQuery,
    required bool isComparisonEnabled,
    required List<AppInfo> installedApps,
    required void Function(HistoryQuery, HistoryQuery, bool) onApply,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoryFilterBottomSheet(
        initialPrimaryQuery: primaryQuery,
        initialSecondaryQuery: secondaryQuery,
        isComparisonEnabled: isComparisonEnabled,
        installedApps: installedApps,
        onApply: onApply,
        onReset: onReset,
      ),
    );
  }

  @override
  State<HistoryFilterBottomSheet> createState() => _HistoryFilterBottomSheetState();
}

class _HistoryFilterBottomSheetState extends State<HistoryFilterBottomSheet> {
  late HistoryQuery _primaryQuery;
  late HistoryQuery _secondaryQuery;
  late bool _comparisonEnabled;

  @override
  void initState() {
    super.initState();
    _primaryQuery = widget.initialPrimaryQuery;
    _secondaryQuery = widget.initialSecondaryQuery;
    _comparisonEnabled = widget.isComparisonEnabled;
  }

  void _openAppPicker(bool isPrimary) async {
    final currentAppUid = isPrimary ? _primaryQuery.appUid : _secondaryQuery.appUid;
    final selectedApp = await AppSearchModal.show(
      context: context,
      installedApps: widget.installedApps,
      selectedAppUid: currentAppUid,
    );

    setState(() {
      if (isPrimary) {
        _primaryQuery = _primaryQuery.copyWith(
          appUid: () => selectedApp?.uid,
          appInfo: () => selectedApp,
        );
      } else {
        _secondaryQuery = _secondaryQuery.copyWith(
          appUid: () => selectedApp?.uid,
          appInfo: () => selectedApp,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dual Query Filters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppHaptics.contextClick();
                    widget.onReset();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Settings Body
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // -------------------------------------------------------------
                // 1. PRIMARY QUERY CARD
                // -------------------------------------------------------------
                _buildSectionHeader(
                  title: 'PRIMARY QUERY',
                  dotColor: AppColorSchemes.cellularColor,
                  context: context,
                ),
                const SizedBox(height: 8),
                _buildQueryConfigCard(
                  query: _primaryQuery,
                  isPrimary: true,
                  context: context,
                  onNetworkChanged: (type) {
                    setState(() => _primaryQuery = _primaryQuery.copyWith(networkType: () => type));
                  },
                  onDirectionChanged: (dir) {
                    setState(() => _primaryQuery = _primaryQuery.copyWith(direction: dir));
                  },
                ),

                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // 2. SECONDARY QUERY CARD (COMPARISON)
                // -------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(
                      title: 'SECONDARY QUERY (COMPARISON)',
                      dotColor: AppColorSchemes.wifiColor,
                      context: context,
                    ),
                    Switch.adaptive(
                      value: _comparisonEnabled,
                      onChanged: (val) {
                        AppHaptics.toggleTick();
                        setState(() => _comparisonEnabled = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_comparisonEnabled) ...[
                  _buildQueryConfigCard(
                    query: _secondaryQuery,
                    isPrimary: false,
                    context: context,
                    onNetworkChanged: (type) {
                      setState(() => _secondaryQuery = _secondaryQuery.copyWith(networkType: () => type));
                    },
                    onDirectionChanged: (dir) {
                      setState(() => _secondaryQuery = _secondaryQuery.copyWith(direction: dir));
                    },
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Enable comparison to view dual comparative bars (e.g. Mobile vs Wi-Fi, Download vs Upload).',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Footer Action Button
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: FilledButton(
              onPressed: () {
                AppHaptics.contextClick();
                widget.onApply(_primaryQuery, _secondaryQuery, _comparisonEnabled);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSectionHeader({
    required String title,
    required Color dotColor,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQueryConfigCard({
    required HistoryQuery query,
    required bool isPrimary,
    required BuildContext context,
    required void Function(NetworkType?) onNetworkChanged,
    required void Function(DataDirection) onDirectionChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network Selector Segmented Buttons
          Text(
            'Network Interface',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<NetworkType?>(
            segments: const [
              ButtonSegment<NetworkType?>(
                value: NetworkType.mobile,
                label: Text('Mobile'),
                icon: Icon(Icons.signal_cellular_alt_rounded, size: 16),
              ),
              ButtonSegment<NetworkType?>(
                value: NetworkType.wifi,
                label: Text('Wi-Fi'),
                icon: Icon(Icons.wifi_rounded, size: 16),
              ),
              ButtonSegment<NetworkType?>(
                value: null,
                label: Text('Both'),
                icon: Icon(Icons.all_inclusive_rounded, size: 16),
              ),
            ],
            selected: {query.networkType},
            onSelectionChanged: (selected) {
              AppHaptics.selectionTick();
              onNetworkChanged(selected.first);
            },
            showSelectedIcon: false,
          ),

          const SizedBox(height: 14),

          // Direction Segmented Buttons
          Text(
            'Traffic Direction',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<DataDirection>(
            segments: const [
              ButtonSegment<DataDirection>(
                value: DataDirection.bidirectional,
                label: Text('Both'),
                icon: Icon(Icons.swap_vert_rounded, size: 16),
              ),
              ButtonSegment<DataDirection>(
                value: DataDirection.download,
                label: Text('Down'),
                icon: Icon(Icons.arrow_downward_rounded, size: 16),
              ),
              ButtonSegment<DataDirection>(
                value: DataDirection.upload,
                label: Text('Up'),
                icon: Icon(Icons.arrow_upward_rounded, size: 16),
              ),
            ],
            selected: {query.direction},
            onSelectionChanged: (selected) {
              AppHaptics.selectionTick();
              onDirectionChanged(selected.first);
            },
            showSelectedIcon: false,
          ),

          const SizedBox(height: 14),

          // Target Application
          Text(
            'Target Application',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              AppHaptics.contextClick();
              _openAppPicker(isPrimary);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    query.isAllApps ? Icons.apps_rounded : Icons.filter_alt_rounded,
                    size: 20,
                    color: query.isAllApps ? colorScheme.onSurfaceVariant : colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      query.appInfo?.label ?? (query.appUid != null ? 'UID ${query.appUid}' : 'All Applications'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: query.isAllApps ? colorScheme.onSurface : colorScheme.primary,
                      ),
                    ),
                  ),
                  if (!query.isAllApps)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        AppHaptics.contextClick();
                        setState(() {
                          if (isPrimary) {
                            _primaryQuery = _primaryQuery.copyWith(
                              appUid: () => null,
                              appInfo: () => null,
                            );
                          } else {
                            _secondaryQuery = _secondaryQuery.copyWith(
                              appUid: () => null,
                              appInfo: () => null,
                            );
                          }
                        });
                      },
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
