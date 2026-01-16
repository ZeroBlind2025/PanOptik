import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/assets_provider.dart';
import '../../../widgets/loading_button.dart';

class EditAssetScreen extends ConsumerStatefulWidget {
  final String assetId;

  const EditAssetScreen({super.key, required this.assetId});

  @override
  ConsumerState<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends ConsumerState<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _manualValueController;
  late TextEditingController _notesController;

  String _currency = 'USD';
  String? _country;
  String? _sector;
  String? _riskCategory;
  bool _isLoading = false;
  bool _initialized = false;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController();
    _manualValueController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _manualValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (_initialized) return;

    final asset = ref.read(assetProvider(widget.assetId));
    if (asset == null) return;

    _nameController.text = asset.name;
    _quantityController.text = asset.quantity?.toString() ?? '';
    _manualValueController.text = asset.manualValue?.toString() ?? '';
    _notesController.text = asset.notes ?? '';
    _currency = asset.currency;
    _country = asset.country;
    _sector = asset.sector;
    _riskCategory = asset.riskCategory;
    _initialized = true;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(assetsProvider.notifier).updateAsset(
            widget.assetId,
            name: _nameController.text.trim(),
            quantity: double.tryParse(_quantityController.text),
            manualValue: double.tryParse(_manualValueController.text),
            currency: _currency,
            country: _country,
            sector: _sector,
            riskCategory: _riskCategory,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset updated successfully')),
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
    final asset = ref.watch(assetProvider(widget.assetId));

    if (asset == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Asset')),
        body: const Center(child: Text('Asset not found')),
      );
    }

    _initializeForm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Asset'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Asset Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              if (asset.type.requiresTicker) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantity'),
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
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._countries.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }),
                ],
                onChanged: (value) {
                  setState(() => _country = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sector,
                decoration: const InputDecoration(labelText: 'Sector (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._sectors.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }),
                ],
                onChanged: (value) {
                  setState(() => _sector = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _riskCategory,
                decoration: const InputDecoration(labelText: 'Risk Category (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._riskCategories.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }),
                ],
                onChanged: (value) {
                  setState(() => _riskCategory = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 32),
              LoadingButton(
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
