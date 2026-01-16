import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../widgets/portfolio_value_card.dart';
import '../widgets/allocation_chart.dart';
import '../widgets/premium_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).refresh();
        },
        child: dashboardAsync.when(
          data: (dashboard) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PortfolioValueCard(
                  totalValue: dashboard.totalValue,
                  dailyChange: dashboard.dailyChange,
                  dailyChangePercent: dashboard.dailyChangePercent,
                  weeklyChange: dashboard.weeklyChange,
                  weeklyChangePercent: dashboard.weeklyChangePercent,
                ),
                const SizedBox(height: 24),
                if (!isPremium) ...[
                  PremiumBanner(
                    onTap: () => context.go('/premium'),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Allocation by Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                AllocationChart(
                  items: dashboard.allocationByType,
                  chartType: ChartType.pie,
                ),
                const SizedBox(height: 24),
                Text(
                  'Allocation by Country',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                AllocationChart(
                  items: dashboard.allocationByCountry,
                  chartType: ChartType.bar,
                ),
                const SizedBox(height: 24),
                Text(
                  'Allocation by Sector',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                AllocationChart(
                  items: dashboard.allocationBySector,
                  chartType: ChartType.bar,
                ),
                const SizedBox(height: 16),
                Text(
                  'Last updated: ${DateFormat.yMd().add_jm().format(dashboard.lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutralChange,
                      ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load dashboard'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
