import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';

class PortfolioValueCard extends StatelessWidget {
  final double totalValue;
  final double dailyChange;
  final double dailyChangePercent;
  final double weeklyChange;
  final double weeklyChangePercent;

  const PortfolioValueCard({
    super.key,
    required this.totalValue,
    required this.dailyChange,
    required this.dailyChangePercent,
    required this.weeklyChange,
    required this.weeklyChangePercent,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final percentFormatter = NumberFormat.decimalPercentPattern(decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Value',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormatter.format(totalValue),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ChangeIndicator(
                    label: 'Today',
                    change: dailyChange,
                    changePercent: dailyChangePercent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ChangeIndicator(
                    label: 'This Week',
                    change: weeklyChange,
                    changePercent: weeklyChangePercent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeIndicator extends StatelessWidget {
  final String label;
  final double change;
  final double changePercent;

  const _ChangeIndicator({
    required this.label,
    required this.change,
    required this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final isPositive = change >= 0;
    final color = isPositive ? AppTheme.positiveChange : AppTheme.negativeChange;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              '${currencyFormatter.format(change.abs())} (${changePercent.abs().toStringAsFixed(2)}%)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
