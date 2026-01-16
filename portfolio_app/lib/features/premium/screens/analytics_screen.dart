import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/analytics_service.dart';
import '../../../providers/subscription_provider.dart';
import '../../dashboard/widgets/allocation_chart.dart';
import '../widgets/premium_guard.dart';

final exposureProvider = FutureProvider<ExposureData>((ref) async {
  return AnalyticsService().fetchExposure();
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (!isPremium) {
      return const PremiumGuard(
        feature: 'Portfolio Analytics',
        description: 'See detailed country and sector exposure analysis',
      );
    }

    final exposureAsync = ref.watch(exposureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                final url = await AnalyticsService().exportToCsv();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export ready: $url')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Export failed: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(exposureProvider);
        },
        child: exposureAsync.when(
          data: (exposure) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Country Exposure',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Geographic distribution of your investments',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 16),
                AllocationChart(
                  items: exposure.countryExposure,
                  chartType: ChartType.bar,
                ),
                const SizedBox(height: 32),
                Text(
                  'Sector Exposure',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Industry distribution of your investments',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 16),
                AllocationChart(
                  items: exposure.sectorExposure,
                  chartType: ChartType.pie,
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
                const Text('Failed to load analytics'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(exposureProvider),
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
