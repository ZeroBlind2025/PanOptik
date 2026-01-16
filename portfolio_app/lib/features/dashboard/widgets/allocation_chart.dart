import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/dashboard.dart';

enum ChartType { pie, bar }

class AllocationChart extends StatelessWidget {
  final List<AllocationItem> items;
  final ChartType chartType;

  const AllocationChart({
    super.key,
    required this.items,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutralChange,
                  ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: chartType == ChartType.pie
            ? _buildPieChart(context)
            : _buildBarChart(context),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final color = AppTheme.chartColors[index % AppTheme.chartColors.length];

                return PieChartSectionData(
                  color: color,
                  value: item.percentage,
                  title: '${item.percentage.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  radius: 60,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final currencyFormatter = NumberFormat.compactCurrency(symbol: '\$');

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: items.map((i) => i.percentage).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = items[group.x.toInt()];
                    return BarTooltipItem(
                      '${item.category}\n${currencyFormatter.format(item.value)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= items.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          items[index].category.length > 6
                              ? '${items[index].category.substring(0, 6)}...'
                              : items[index].category,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final color = AppTheme.chartColors[index % AppTheme.chartColors.length];

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: item.percentage,
                      color: color,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final currencyFormatter = NumberFormat.compactCurrency(symbol: '\$');

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final color = AppTheme.chartColors[index % AppTheme.chartColors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${item.category} (${currencyFormatter.format(item.value)})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}
