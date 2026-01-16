import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/alert.dart';
import '../../../models/asset.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/assets_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../widgets/loading_button.dart';

class AddAlertScreen extends ConsumerStatefulWidget {
  const AddAlertScreen({super.key});

  @override
  ConsumerState<AddAlertScreen> createState() => _AddAlertScreenState();
}

class _AddAlertScreenState extends ConsumerState<AddAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _triggerValueController = TextEditingController();

  AlertType _selectedType = AlertType.dateReminder;
  String? _selectedAssetId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isRecurring = false;
  String _rruleFrequency = 'weekly';
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _triggerValueController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      DateTime? nextFire;
      String? rrule;

      if (_selectedType == AlertType.dateReminder ||
          _selectedType == AlertType.recurringReminder) {
        nextFire = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        if (_isRecurring) {
          rrule = 'FREQ=${_rruleFrequency.toUpperCase()}';
        }
      }

      await ref.read(alertsProvider.notifier).createAlert(
            type: _selectedType,
            message: _messageController.text.trim(),
            assetId: _selectedType.isPriceAlert ? _selectedAssetId : null,
            triggerValue:
                _selectedType.isPriceAlert ? _triggerValueController.text : null,
            nextFire: nextFire,
            recurring: _isRecurring,
            rrule: rrule,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final assets = ref.watch(assetsProvider).valueOrNull ?? [];
    final tickerAssets = assets.where((a) => a.type.hasLivePricing).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Alert'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Alert Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AlertType.values.map((type) {
                  final isSelected = type == _selectedType;
                  final isDisabled = type.requiresPremium && !isPremium;

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.displayName),
                        if (isDisabled) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: isDisabled
                        ? null
                        : (_) {
                            setState(() {
                              _selectedType = type;
                            });
                          },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  );
                }).toList(),
              ),
              if (_selectedType.requiresPremium && !isPremium) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.amber.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Premium Feature'),
                              Text(
                                'Price alerts require a premium subscription',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/premium'),
                          child: const Text('Upgrade'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_selectedType.isPriceAlert) ...[
                DropdownButtonFormField<String>(
                  value: _selectedAssetId,
                  decoration: const InputDecoration(labelText: 'Select Asset'),
                  items: tickerAssets.map((asset) {
                    return DropdownMenuItem(
                      value: asset.id,
                      child: Text('${asset.name} (${asset.ticker})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAssetId = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an asset';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _triggerValueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _selectedType == AlertType.priceAbove
                        ? 'Alert when price is above'
                        : 'Alert when price is below',
                    prefixText: '\$ ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(_selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() => _selectedTime = time);
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recurring'),
                  subtitle: const Text('Repeat this alert'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() => _isRecurring = value);
                  },
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _rruleFrequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (value) {
                      setState(() => _rruleFrequency = value!);
                    },
                  ),
                ],
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _messageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'What should the alert say?',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              LoadingButton(
                onPressed: (!_selectedType.requiresPremium || isPremium)
                    ? _handleSubmit
                    : null,
                isLoading: _isLoading,
                child: const Text('Create Alert'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
