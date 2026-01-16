import 'package:flutter/material.dart';

import '../../../models/asset.dart';

class AssetTypeSelector extends StatelessWidget {
  final AssetType selectedType;
  final Function(AssetType) onTypeSelected;

  const AssetTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AssetType.values.map((type) {
        final isSelected = type == selectedType;

        return ChoiceChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (_) => onTypeSelected(type),
          avatar: isSelected ? null : Icon(_getIconForType(type), size: 18),
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForType(AssetType type) {
    switch (type) {
      case AssetType.stock:
      case AssetType.etf:
        return Icons.show_chart;
      case AssetType.crypto:
        return Icons.currency_bitcoin;
      case AssetType.fund:
        return Icons.pie_chart;
      case AssetType.bond:
        return Icons.account_balance;
      case AssetType.realEstate:
        return Icons.home;
      case AssetType.cash:
        return Icons.savings;
      case AssetType.commodity:
        return Icons.diamond;
    }
  }
}
