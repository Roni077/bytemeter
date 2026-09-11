import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/data_plan_extra.dart';

/// Modal dialog or bottom sheet for adding an extra data booster pack.
class AddExtraPackDialog extends StatefulWidget {
  const AddExtraPackDialog({
    super.key,
    required this.planHashedSubscriberId,
    this.defaultExpiryDate,
  });

  final String planHashedSubscriberId;
  final DateTime? defaultExpiryDate;

  static Future<DataPlanExtra?> show(
    BuildContext context, {
    required String planHashedSubscriberId,
    DateTime? defaultExpiryDate,
  }) {
    return showModalBottomSheet<DataPlanExtra>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExtraPackDialog(
        planHashedSubscriberId: planHashedSubscriberId,
        defaultExpiryDate: defaultExpiryDate,
      ),
    );
  }

  @override
  State<AddExtraPackDialog> createState() => _AddExtraPackDialogState();
}

class _AddExtraPackDialogState extends State<AddExtraPackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '5');
  final _noteController = TextEditingController();

  String _selectedUnit = 'GB';
  late DateTime _startDate;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _expiryDate = widget.defaultExpiryDate ?? _startDate.add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amountNum = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amountNum <= 0) return;

    final int multiplier = (_selectedUnit == 'GB') ? 1024 * 1024 * 1024 : 1024 * 1024;
    final int extraBytes = (amountNum * multiplier).round();

    final extra = DataPlanExtra(
      planHashedSubscriberId: widget.planHashedSubscriberId,
      extraBytes: extraBytes,
      usedBytes: 0,
      startDate: _startDate,
      expiryDate: _expiryDate,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : '+$amountNum $_selectedUnit Booster',
    );

    AppHaptics.contextClick();
    Navigator.of(context).pop(extra);
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate.isAfter(DateTime.now()) ? _expiryDate : DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_shopping_cart_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Booster Pack',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Add extra data allowance to this billing cycle',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quota Amount + Unit Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Data Allowance',
                        hintText: 'e.g. 5',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        prefixIcon: const Icon(Icons.speed_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter amount';
                        }
                        final numVal = double.tryParse(value.trim());
                        if (numVal == null || numVal <= 0) {
                          return 'Enter valid number';
                        }
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'GB', child: Text('GB')),
                        DropdownMenuItem(value: 'MB', child: Text('MB')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedUnit = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Expiry Date Picker
              InkWell(
                onTap: _pickExpiryDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiration Date',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEE, MMM d, yyyy').format(_expiryDate),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickExpiryDate,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Optional Custom Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Custom Note (Optional)',
                  hintText: 'e.g. Weekend Booster, Work pack',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Booster'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
