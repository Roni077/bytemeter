import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/data_plan.dart';
import '../../data/models/enums.dart';
import 'plans_controller.dart';
import 'widgets/excluded_apps_sheet.dart';
import 'widgets/sim_card_gradients.dart';

/// Screen allowing the user to configure SIM carrier parameters, quota amount,
/// cycle start date, interval type, rollover rules, zero-rated apps, and card theme.
class PlanConfigScreen extends ConsumerStatefulWidget {
  const PlanConfigScreen({
    super.key,
    this.initialPlan,
    this.initialSlotIndex = 0,
  });

  final DataPlan? initialPlan;
  final int initialSlotIndex;

  @override
  ConsumerState<PlanConfigScreen> createState() => _PlanConfigScreenState();
}

class _PlanConfigScreenState extends ConsumerState<PlanConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _carrierController;
  late TextEditingController _quotaController;
  late TextEditingController _customDaysController;
  late TextEditingController _noteController;

  late int _simSlotIndex;
  late String _selectedUnit;
  late int _billingCycleStartDay;
  late TimeIntervalType _cycleInterval;
  late bool _rolloverEnabled;
  late List<int> _excludedUids;
  late int _cardColorIndex;

  static const List<String> _carrierPresets = [
    'Jio',
    'Airtel',
    'Vi',
    'Verizon',
    'T-Mobile',
    'AT&T',
    'Vodafone',
  ];

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;

    _simSlotIndex = plan?.simSlotIndex ?? widget.initialSlotIndex;
    _carrierController = TextEditingController(text: plan?.carrierName ?? '');

    // Decompose quota bytes into initial value + unit
    if (plan != null && plan.quotaBytes > 0) {
      if (plan.quotaBytes >= 1024 * 1024 * 1024 * 1024) {
        _selectedUnit = 'TB';
        _quotaController = TextEditingController(
          text: (plan.quotaBytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1).replaceAll('.0', ''),
        );
      } else if (plan.quotaBytes >= 1024 * 1024 * 1024) {
        _selectedUnit = 'GB';
        _quotaController = TextEditingController(
          text: (plan.quotaBytes / (1024 * 1024 * 1024)).toStringAsFixed(1).replaceAll('.0', ''),
        );
      } else {
        _selectedUnit = 'MB';
        _quotaController = TextEditingController(
          text: (plan.quotaBytes / (1024 * 1024)).toStringAsFixed(0),
        );
      }
    } else {
      _selectedUnit = 'GB';
      _quotaController = TextEditingController(text: '30');
    }

    _billingCycleStartDay = plan?.billingCycleStartDay ?? 1;
    _cycleInterval = plan?.cycleInterval ?? TimeIntervalType.monthly;
    _customDaysController = TextEditingController(
      text: (plan?.customIntervalDays ?? 28).toString(),
    );
    _rolloverEnabled = plan?.rolloverEnabled ?? false;
    _excludedUids = List<int>.from(plan?.excludedUids ?? const []);
    _cardColorIndex = plan?.cardColorIndex ?? (_simSlotIndex % SimCardGradients.themes.length);
    _noteController = TextEditingController(text: plan?.customNote ?? '');
  }

  @override
  void dispose() {
    _carrierController.dispose();
    _quotaController.dispose();
    _customDaysController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _calculateQuotaBytes() {
    final numVal = double.tryParse(_quotaController.text.trim()) ?? 0;
    if (numVal <= 0) return 0;

    switch (_selectedUnit) {
      case 'TB':
        return (numVal * 1024 * 1024 * 1024 * 1024).round();
      case 'GB':
        return (numVal * 1024 * 1024 * 1024).round();
      case 'MB':
        return (numVal * 1024 * 1024).round();
      default:
        return (numVal * 1024 * 1024 * 1024).round();
    }
  }

  Future<void> _pickExcludedApps() async {
    final state = ref.read(plansControllerProvider);
    final selected = await ExcludedAppsSheet.show(
      context,
      installedApps: state.installedApps,
      initialExcludedUids: _excludedUids,
    );

    if (selected != null) {
      setState(() {
        _excludedUids = selected;
      });
    }
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final quotaBytes = _calculateQuotaBytes();
    final customDays = int.tryParse(_customDaysController.text.trim()) ?? 28;
    final now = DateTime.now();

    final plan = DataPlan(
      hashedSubscriberId: widget.initialPlan?.hashedSubscriberId ?? 'sim_slot_$_simSlotIndex',
      encryptedSubscriberId: widget.initialPlan?.encryptedSubscriberId,
      simSlotIndex: _simSlotIndex,
      carrierName: _carrierController.text.trim().isNotEmpty
          ? _carrierController.text.trim()
          : 'SIM ${_simSlotIndex + 1}',
      quotaBytes: quotaBytes,
      billingCycleStartDay: _billingCycleStartDay,
      cycleInterval: _cycleInterval,
      customIntervalDays: customDays,
      rolloverEnabled: _rolloverEnabled,
      excludedUids: _excludedUids,
      cardColorIndex: _cardColorIndex,
      customNote: _noteController.text.trim(),
      createdAt: widget.initialPlan?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(plansControllerProvider.notifier).savePlan(plan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${plan.carrierName}" data plan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _deletePlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Data Plan?'),
        content: const Text(
          'This will remove this SIM data plan and any associated booster packs. Your historical network stats will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.initialPlan != null) {
      await ref
          .read(plansControllerProvider.notifier)
          .deletePlan(widget.initialPlan!.hashedSubscriberId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.initialPlan != null && widget.initialPlan!.quotaBytes > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Configure Data Plan' : 'Set Up SIM Plan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.icon(
              onPressed: _savePlan,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // SIM Slot Selector
            Text(
              'SIM CARD SLOT',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('SIM 1 (Slot 1)')),
                ButtonSegment(value: 1, label: Text('SIM 2 (Slot 2)')),
              ],
              selected: {_simSlotIndex},
              onSelectionChanged: (set) {
                AppHaptics.selectionTick();
                setState(() {
                  _simSlotIndex = set.first;
                });
              },
            ),

            const SizedBox(height: 20),

            // Carrier Name Input & Presets
            Text(
              'CARRIER NAME',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _carrierController,
              decoration: InputDecoration(
                labelText: 'Carrier Name',
                hintText: 'e.g. Verizon, Jio, Airtel',
                prefixIcon: const Icon(Icons.cell_tower_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _carrierPresets.map((carrier) {
                return ActionChip(
                  label: Text(carrier),
                  onPressed: () {
                    AppHaptics.selectionTick();
                    setState(() {
                      _carrierController.text = carrier;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Quota Amount & Unit
            Text(
              'DATA QUOTA LIMIT',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _quotaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Total Quota Amount',
                      hintText: 'e.g. 50',
                      prefixIcon: const Icon(Icons.pie_chart_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter quota';
                      final numVal = double.tryParse(val.trim());
                      if (numVal == null || numVal <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GB', child: Text('GB')),
                      DropdownMenuItem(value: 'MB', child: Text('MB')),
                      DropdownMenuItem(value: 'TB', child: Text('TB')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedUnit = val);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Billing Cycle Bounds
            Text(
              'BILLING CYCLE & INTERVAL',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TimeIntervalType>(
              segments: const [
                ButtonSegment(value: TimeIntervalType.monthly, label: Text('Monthly')),
                ButtonSegment(value: TimeIntervalType.daily, label: Text('Daily')),
                ButtonSegment(value: TimeIntervalType.custom, label: Text('Custom Days')),
              ],
              selected: {_cycleInterval},
              onSelectionChanged: (set) {
                AppHaptics.selectionTick();
                setState(() => _cycleInterval = set.first);
              },
            ),

            const SizedBox(height: 12),

            if (_cycleInterval == TimeIntervalType.monthly) ...[
              DropdownButtonFormField<int>(
                initialValue: _billingCycleStartDay,
                decoration: InputDecoration(
                  labelText: 'Cycle Reset Day of Month',
                  prefixIcon: const Icon(Icons.calendar_today_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: List.generate(31, (i) => i + 1).map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text('Day $day of every month'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _billingCycleStartDay = val);
                  }
                },
              ),
            ] else if (_cycleInterval == TimeIntervalType.custom) ...[
              TextFormField(
                controller: _customDaysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cycle Duration (Days)',
                  hintText: 'e.g. 28, 56, 84',
                  prefixIcon: const Icon(Icons.timelapse_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  final numVal = int.tryParse(val ?? '');
                  if (numVal == null || numVal <= 0) return 'Enter valid days';
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            // Rollover Option
            Text(
              'DATA ROLLOVER',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                value: _rolloverEnabled,
                onChanged: (val) {
                  AppHaptics.selectionTick();
                  setState(() => _rolloverEnabled = val);
                },
                secondary: Icon(
                  Icons.autorenew_rounded,
                  color: _rolloverEnabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                title: const Text(
                  'Auto Data Rollover',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Automatically convert unspent data at cycle reset into next cycle booster',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Card Color Palette
            Text(
              'CARD THEME GRADIENT',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: SimCardGradients.themes.map((t) {
                final isSelected = t.id == _cardColorIndex;
                return InkWell(
                  onTap: () {
                    AppHaptics.selectionTick();
                    setState(() => _cardColorIndex = t.id);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: t.gradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: t.colors.last.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Zero-Rated Excluded Apps
            Text(
              'ZERO-RATED APPLICATIONS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(Icons.block_rounded, color: colorScheme.primary),
                title: const Text('Zero-Rated App Exclusions', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  _excludedUids.isEmpty
                      ? 'No applications excluded'
                      : '${_excludedUids.length} applications excluded from quota',
                ),
                trailing: FilledButton.tonal(
                  onPressed: _pickExcludedApps,
                  child: Text(_excludedUids.isEmpty ? 'Select' : 'Edit (${_excludedUids.length})'),
                ),
                onTap: _pickExcludedApps,
              ),
            ),

            const SizedBox(height: 24),

            // Custom Note
            Text(
              'NOTE / DESCRIPTION (OPTIONAL)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Custom Note',
                hintText: 'e.g. Primary SIM, Work Data',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 32),

            // Delete Plan Option (if editing)
            if (isEditing) ...[
              OutlinedButton.icon(
                onPressed: _deletePlan,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete This Data Plan'),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}
