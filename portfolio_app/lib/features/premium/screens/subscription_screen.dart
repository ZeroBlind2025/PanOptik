import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../providers/subscription_provider.dart';
import '../../../widgets/loading_button.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final offeringsAsync = ref.watch(offeringsProvider);
    final subscriptionState = ref.watch(subscriptionProvider);

    if (isPremium) {
      return _buildPremiumActiveView(context, ref);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildFeatureComparison(context),
            const SizedBox(height: 32),
            offeringsAsync.when(
              data: (offerings) {
                final current = offerings.current;
                if (current == null) {
                  return const Center(child: Text('No offerings available'));
                }
                return _buildPricingOptions(context, ref, current);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  children: [
                    const Text('Failed to load pricing'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.refresh(offeringsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: subscriptionState.isLoading
                  ? null
                  : () async {
                      await ref.read(subscriptionProvider.notifier).restorePurchases();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchases restored')),
                        );
                      }
                    },
              child: const Text('Restore Purchases'),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment will be charged to your App Store or Google Play account. '
              'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // Open terms of service
                  },
                  child: const Text('Terms of Service'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    // Open privacy policy
                  },
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActiveView(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'You\'re Premium!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy all premium features',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFeatureRow(context, 'Unlimited Assets', true),
                    _buildFeatureRow(context, 'Price Alerts', true),
                    _buildFeatureRow(context, 'Risk Analysis', true),
                    _buildFeatureRow(context, 'Country Exposure', true),
                    _buildFeatureRow(context, 'Sector Exposure', true),
                    _buildFeatureRow(context, 'CSV Export', true),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/analytics'),
                  icon: const Icon(Icons.pie_chart),
                  label: const Text('Analytics'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/risk'),
                  icon: const Icon(Icons.shield),
                  label: const Text('Risk Score'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.star, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'Unlock Premium',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get deeper insights into your portfolio',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Free',
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Pro',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildComparisonRow(context, 'Assets', '10', 'Unlimited'),
            _buildComparisonRow(context, 'Live Pricing', true, true),
            _buildComparisonRow(context, 'Dashboard', true, true),
            _buildComparisonRow(context, 'Reminders', true, true),
            _buildComparisonRow(context, 'Price Alerts', false, true),
            _buildComparisonRow(context, 'Risk Analysis', false, true),
            _buildComparisonRow(context, 'Country Exposure', false, true),
            _buildComparisonRow(context, 'Sector Exposure', false, true),
            _buildComparisonRow(context, 'CSV Export', false, true),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
      BuildContext context, String feature, dynamic free, dynamic pro) {
    Widget buildValue(dynamic value) {
      if (value is bool) {
        return value
            ? const Icon(Icons.check, color: Colors.green, size: 20)
            : const Icon(Icons.close, color: Colors.red, size: 20);
      }
      return Text(
        value.toString(),
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(child: buildValue(free)),
          ),
          SizedBox(
            width: 60,
            child: Center(child: buildValue(pro)),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOptions(BuildContext context, WidgetRef ref, Offering offering) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final isLoading = subscriptionState.isLoading;

    final monthlyPackage = offering.monthly;
    final annualPackage = offering.annual;

    return Column(
      children: [
        if (annualPackage != null)
          _PricingCard(
            title: 'Annual',
            price: annualPackage.storeProduct.priceString,
            period: '/year',
            savings: 'Save 33%',
            isRecommended: true,
            onTap: isLoading
                ? null
                : () async {
                    await ref.read(subscriptionProvider.notifier).purchase(annualPackage);
                  },
          ),
        const SizedBox(height: 12),
        if (monthlyPackage != null)
          _PricingCard(
            title: 'Monthly',
            price: monthlyPackage.storeProduct.priceString,
            period: '/month',
            isRecommended: false,
            onTap: isLoading
                ? null
                : () async {
                    await ref.read(subscriptionProvider.notifier).purchase(monthlyPackage);
                  },
          ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildFeatureRow(BuildContext context, String feature, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(feature),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? savings;
  final bool isRecommended;
  final VoidCallback? onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    this.savings,
    required this.isRecommended,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isRecommended
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isRecommended ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Best Value',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (savings != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      savings!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  period,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
