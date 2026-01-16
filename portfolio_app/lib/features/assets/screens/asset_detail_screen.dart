import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../providers/assets_provider.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(assetProvider(assetId));
    final totalValue = ref.watch(totalPortfolioValueProvider);

    if (asset == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Asset not found')),
      );
    }

    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final percentageOfPortfolio =
        totalValue > 0 ? (asset.currentValue / totalValue) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/assets/$assetId/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Asset'),
                    content: Text('Are you sure you want to delete ${asset.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await ref.read(assetsProvider.notifier).deleteAsset(assetId);
                  context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      currencyFormatter.format(asset.currentValue),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${percentageOfPortfolio.toStringAsFixed(1)}% of portfolio',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutralChange,
                          ),
                    ),
                    if (asset.priceChangePercent != null) ...[
                      const SizedBox(height: 16),
                      _buildPriceChange(context, asset.priceChange!, asset.priceChangePercent!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, 'Type', asset.type.displayName),
                    if (asset.ticker != null)
                      _buildDetailRow(context, 'Ticker', asset.ticker!),
                    if (asset.quantity != null)
                      _buildDetailRow(context, 'Quantity', asset.quantity!.toString()),
                    if (asset.currentPrice != null)
                      _buildDetailRow(
                        context,
                        'Price',
                        currencyFormatter.format(asset.currentPrice),
                      ),
                    _buildDetailRow(context, 'Currency', asset.currency),
                    if (asset.country != null)
                      _buildDetailRow(context, 'Country', asset.country!),
                    if (asset.sector != null)
                      _buildDetailRow(context, 'Sector', asset.sector!),
                    if (asset.riskCategory != null)
                      _buildDetailRow(context, 'Risk', asset.riskCategory!),
                    _buildDetailRow(
                      context,
                      'Added',
                      DateFormat.yMMMd().format(asset.createdAt),
                    ),
                    _buildDetailRow(
                      context,
                      'Updated',
                      DateFormat.yMMMd().format(asset.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
            if (asset.notes != null && asset.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(asset.notes!),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to add alert for this asset
                context.push('/alerts/add?assetId=$assetId');
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Set Alert'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChange(BuildContext context, double change, double changePercent) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final isPositive = change >= 0;
    final color = isPositive ? AppTheme.positiveChange : AppTheme.negativeChange;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          '${currencyFormatter.format(change.abs())} (${changePercent.abs().toStringAsFixed(2)}%)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          'today',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.neutralChange,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralChange,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
