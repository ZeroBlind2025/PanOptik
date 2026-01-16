import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/asset.dart';
import '../../../providers/assets_provider.dart';
import '../../../providers/subscription_provider.dart';

class AssetsListScreen extends ConsumerWidget {
  const AssetsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsProvider);
    final assetCount = ref.watch(assetCountProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
        actions: [
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('$assetCount/10'),
                backgroundColor: assetCount >= 10
                    ? Theme.of(context).colorScheme.error.withOpacity(0.2)
                    : null,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(assetsProvider.notifier).fetchAssets();
        },
        child: assetsAsync.when(
          data: (assets) {
            if (assets.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return _AssetCard(
                  asset: asset,
                  onTap: () => context.push('/assets/${asset.id}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text('Failed to load assets'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(assetsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!isPremium && assetCount >= 10) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Upgrade to Premium for unlimited assets'),
              ),
            );
            context.push('/premium');
            return;
          }
          context.push('/assets/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No assets yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first asset',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralChange,
                ),
          ),
        ],
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback onTap;

  const _AssetCard({
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAssetIcon(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (asset.ticker != null) ...[
                          Text(
                            asset.ticker!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            asset.type.displayName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormatter.format(asset.currentValue),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (asset.priceChangePercent != null) ...[
                    const SizedBox(height: 4),
                    _buildChangeIndicator(context),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (asset.type) {
      case AssetType.stock:
      case AssetType.etf:
        icon = Icons.show_chart;
        color = const Color(0xFF2563EB);
        break;
      case AssetType.crypto:
        icon = Icons.currency_bitcoin;
        color = const Color(0xFFF59E0B);
        break;
      case AssetType.fund:
        icon = Icons.pie_chart;
        color = const Color(0xFF8B5CF6);
        break;
      case AssetType.bond:
        icon = Icons.account_balance;
        color = const Color(0xFF10B981);
        break;
      case AssetType.realEstate:
        icon = Icons.home;
        color = const Color(0xFFEC4899);
        break;
      case AssetType.cash:
        icon = Icons.savings;
        color = const Color(0xFF06B6D4);
        break;
      case AssetType.commodity:
        icon = Icons.diamond;
        color = const Color(0xFFF97316);
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildChangeIndicator(BuildContext context) {
    final change = asset.priceChangePercent ?? 0;
    final isPositive = change >= 0;
    final color = isPositive ? AppTheme.positiveChange : AppTheme.negativeChange;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          '${change.abs().toStringAsFixed(2)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
