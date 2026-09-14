import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/data_size.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_icon_avatar.dart';
import '../../../data/models/app_usage.dart';
import '../../../data/models/enums.dart';

enum AppSortMode {
  total('Total'),
  download('Download'),
  upload('Upload');

  const AppSortMode(this.displayName);
  final String displayName;
}

/// On-demand modal bottom sheet displaying full application usage breakdown.
/// Keeps heavy multi-app queries and list rendering completely decoupled
/// from the primary Home dashboard.
class FullAppUsageSheet extends ConsumerStatefulWidget {
  const FullAppUsageSheet({
    super.key,
    required this.networkType,
    required this.date,
  });

  final NetworkType networkType;
  final DateTime date;

  /// Convenience launcher modal
  static Future<void> show({
    required BuildContext context,
    required NetworkType networkType,
    DateTime? date,
  }) {
    AppHaptics.contextClick();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FullAppUsageSheet(
        networkType: networkType,
        date: date ?? DateTime.now(),
      ),
    );
  }

  @override
  ConsumerState<FullAppUsageSheet> createState() => _FullAppUsageSheetState();
}

class _FullAppUsageSheetState extends ConsumerState<FullAppUsageSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<AppUsage> _allApps = const [];
  bool _isLoading = true;
  String? _errorMessage;
  AppSortMode _sortMode = AppSortMode.total;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
    _loadFullApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFullApps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usageRepo = ref.read(networkUsageRepositoryProvider);
      final start = AppDateUtils.startOfDay(widget.date);
      final end = widget.date.day == DateTime.now().day &&
              widget.date.month == DateTime.now().month &&
              widget.date.year == DateTime.now().year
          ? DateTime.now()
          : AppDateUtils.endOfDay(widget.date);

      final apps = await usageRepo.getAppBreakdown(
        startTime: start,
        endTime: end,
        networkType: widget.networkType,
        loadIcons: true,
      );

      if (mounted) {
        setState(() {
          _allApps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load apps: $e';
        });
      }
    }
  }

  List<AppUsage> get _filteredApps {
    var list = List<AppUsage>.from(_allApps);
    if (_searchQuery.isNotEmpty) {
      list = list.where((app) {
        final label = app.appInfo.label.toLowerCase();
        final pkg = app.appInfo.packageName.toLowerCase();
        return label.contains(_searchQuery) || pkg.contains(_searchQuery);
      }).toList();
    }

    switch (_sortMode) {
      case AppSortMode.total:
        list.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
      case AppSortMode.download:
        list.sort((a, b) => b.primaryBytes.compareTo(a.primaryBytes));
      case AppSortMode.upload:
        list.sort((a, b) => b.secondaryBytes.compareTo(a.secondaryBytes));
    }
    return list;
  }

  int get _totalBytes =>
      _allApps.fold<int>(0, (sum, app) => sum + app.totalBytes);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final prefs = prefsRepo.current;
    final mediaQuery = MediaQuery.of(context);

    final filtered = _filteredApps;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.88,
        ),
        child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Applications Today',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.networkType.displayName} · ${_allApps.length} active apps (${DataSize(_totalBytes).format(base: prefs.metricBase)})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar & Sort Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search apps...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Sort Popup
                PopupMenuButton<AppSortMode>(
                  initialValue: _sortMode,
                  onSelected: (mode) {
                    AppHaptics.selectionTick();
                    setState(() {
                      _sortMode = mode;
                    });
                  },
                  tooltip: 'Sort By',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sort_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  itemBuilder: (context) => [
                    for (final mode in AppSortMode.values)
                      PopupMenuItem(
                        value: mode,
                        child: Text(mode.displayName),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Body: List of Apps or Loading / Empty state
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 40,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No matching applications found',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 8,
                              bottom: mediaQuery.padding.bottom + 16,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, indent: 56),
                            itemBuilder: (context, index) {
                              final app = filtered[index];
                              final totalStr = DataSize(app.totalBytes).format(
                                base: prefs.metricBase,
                                decimals: 1,
                              );
                              final downStr = DataSize(app.primaryBytes).format(
                                base: prefs.metricBase,
                                decimals: 1,
                              );
                              final upStr = DataSize(app.secondaryBytes).format(
                                base: prefs.metricBase,
                                decimals: 1,
                              );

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                leading: AppIconAvatar.fromAppInfo(
                                  app: app.appInfo,
                                  size: 44,
                                ),
                                title: Text(
                                  app.appInfo.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      '↓ $downStr',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '↑ $upStr',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  totalStr,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                onTap: () {
                                  AppHaptics.contextClick();
                                  if (app.appInfo.packageName.isNotEmpty &&
                                      !app.appInfo.packageName.startsWith('uid_') &&
                                      !app.appInfo.packageName.startsWith('system.')) {
                                    ref
                                        .read(networkUsageRepositoryProvider)
                                        .launchApp(app.appInfo.packageName);
                                  }
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    ),
  );
  }
}
