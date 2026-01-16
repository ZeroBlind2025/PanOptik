import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/asset.dart';
import '../../../providers/assets_provider.dart';
import '../../../widgets/loading_button.dart';
import '../widgets/asset_type_selector.dart';
import '../widgets/ticker_search_field.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  const AddAssetScreen({super.key});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tickerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _manualValueController = TextEditingController();
  final _notesController = TextEditingController();

  AssetType _selectedType = AssetType.stock;
  String _currency = 'USD';
  String? _country;
  String? _sector;
  String? _riskCategory;
  bool _isLoading = false;

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
  final List<String> _countries = [
    'United States',
    'United Kingdom',
    'Germany',
    'Japan',
    'Canada',
    'Australia',
    'China',
    'India',
    'Brazil',
    'Other'
  ];
  final List<String> _sectors = [
    'Technology',
    'Healthcare',
    'Finance',
    'Consumer',
    'Energy',
    'Industrial',
    'Materials',
    'Real Estate',
    'Utilities',
    'Other'
  ];
  final List<String> _riskCategories = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _nameController.dispose();
    _tickerController.dispose();
    _quantityController.dispose();
    _manualValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(assetsProvider.notifier).createAsset(
            type: _selectedType,
            name: _nameController.text.trim(),
            ticker: _selectedType.requiresTicker ? _tickerController.text.trim() : null,
            quantity: _selectedType.requiresTicker
                ? double.tryParse(_quantityController.text)
                : null,
            manualValue: !_selectedType.requiresTicker
                ? double.tryParse(_manualValueController.text)
                : null,
            currency: _currency,
            country: _country,
            sector: _sector,
            riskCategory: _riskCategory,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset added successfully')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Asset'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Asset Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              AssetTypeSelector(
                selectedType: _selectedType,
                onTypeSelected: (type) {
                  setState(() {
                    _selectedType = type;
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Asset Name',
                  hintText: 'e.g., Apple Inc., Bitcoin, Primary Residence',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              if (_selectedType.requiresTicker) ...[
                const SizedBox(height: 16),
                TickerSearchField(
                  controller: _tickerController,
                  assetType: _selectedType,
                  onTickerSelected: (ticker, name) {
                    _tickerController.text = ticker;
                    if (_nameController.text.isEmpty) {
                      _nameController.text = name;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g., 10.5',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _manualValueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Current Value',
                    prefixText: '\$ ',
                    hintText: 'e.g., 50000',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter value';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: _currencies.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (value) {
                  setState(() => _currency = value!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _country,
                decoration: const InputDecoration(labelText: 'Country (optional)'),
                items: _countries.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (value) {
                  setState(() => _country = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sector,
                decoration: const InputDecoration(labelText: 'Sector (optional)'),
                items: _sectors.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (value) {
                  setState(() => _sector = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _riskCategory,
                decoration: const InputDecoration(labelText: 'Risk Category (optional)'),
                items: _riskCategories.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r));
                }).toList(),
                onChanged: (value) {
                  setState(() => _riskCategory = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any additional notes about this asset',
                ),
              ),
              const SizedBox(height: 32),
              LoadingButton(
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                child: const Text('Add Asset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
