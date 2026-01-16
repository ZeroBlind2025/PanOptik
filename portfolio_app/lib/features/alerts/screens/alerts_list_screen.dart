import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/alert.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/subscription_provider.dart';

class AlertsListScreen extends ConsumerWidget {
  const AlertsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(alertsProvider.notifier).fetchAlerts();
        },
        child: alertsAsync.when(
          data: (alerts) {
            if (alerts.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _AlertCard(
                  alert: alert,
                  onToggle: (enabled) {
                    ref.read(alertsProvider.notifier).toggleAlert(alert.id, enabled);
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Alert'),
                        content: const Text('Are you sure you want to delete this alert?'),
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

                    if (confirm == true) {
                      ref.read(alertsProvider.notifier).deleteAlert(alert.id);
                    }
                  },
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
                const Text('Failed to load alerts'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(alertsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/alerts/add');
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
            Icons.notifications_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No alerts yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create alerts to stay informed about your investments',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralChange,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final Function(bool) onToggle;
  final VoidCallback onDelete;

  const _AlertCard({
    required this.alert,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat.yMMMd().add_jm();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAlertIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.type.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: alert.enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (alert.assetName != null) ...[
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 14,
                    color: AppTheme.neutralChange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alert.assetName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutralChange,
                        ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (alert.nextFire != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppTheme.neutralChange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(alert.nextFire!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutralChange,
                        ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (alert.recurring) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.repeat, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Recurring',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (alert.type) {
      case AlertType.priceAbove:
        icon = Icons.trending_up;
        color = AppTheme.positiveChange;
        break;
      case AlertType.priceBelow:
        icon = Icons.trending_down;
        color = AppTheme.negativeChange;
        break;
      case AlertType.dateReminder:
        icon = Icons.event;
        color = Theme.of(context).colorScheme.primary;
        break;
      case AlertType.recurringReminder:
        icon = Icons.repeat;
        color = Theme.of(context).colorScheme.secondary;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
