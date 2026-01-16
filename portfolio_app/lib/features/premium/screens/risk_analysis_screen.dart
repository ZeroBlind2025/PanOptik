import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../services/analytics_service.dart';
import '../../../providers/subscription_provider.dart';
import '../widgets/premium_guard.dart';
import '../widgets/risk_gauge.dart';

final riskAnalysisProvider = FutureProvider<RiskAnalysis>((ref) async {
  return AnalyticsService().fetchRiskAnalysis();
});

class RiskAnalysisScreen extends ConsumerWidget {
  const RiskAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (!isPremium) {
      return const PremiumGuard(
        feature: 'Risk Analysis',
        description: 'Get personalized risk score and recommendations',
      );
    }

    final riskAsync = ref.watch(riskAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(riskAnalysisProvider);
        },
        child: riskAsync.when(
          data: (risk) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        RiskGauge(score: risk.riskScore),
                        const SizedBox(height: 16),
                        Text(
                          risk.riskCategory,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getRiskColor(risk.riskScore),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Risk Score: ${risk.riskScore}/100',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Risk Factors',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (risk.riskFactors.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No significant risk factors identified',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...risk.riskFactors.map((factor) => _RiskFactorCard(factor: factor)),
                const SizedBox(height: 24),
                Text(
                  'Recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (risk.recommendations.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_up, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your portfolio looks well-diversified!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...risk.recommendations.map(
                    (rec) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                rec,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Disclaimer',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This analysis is for informational purposes only and does not constitute investment advice. '
                          'The risk score reflects current portfolio composition based on general diversification principles. '
                          'Always consult with a qualified financial advisor before making investment decisions.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
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
                const Text('Failed to load risk analysis'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(riskAnalysisProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(int score) {
    if (score < 40) return AppTheme.positiveChange;
    if (score < 70) return Colors.amber;
    return AppTheme.negativeChange;
  }
}

class _RiskFactorCard extends StatelessWidget {
  final RiskFactor factor;

  const _RiskFactorCard({required this.factor});

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    switch (factor.severity.toLowerCase()) {
      case 'high':
        severityColor = AppTheme.negativeChange;
        break;
      case 'medium':
        severityColor = Colors.amber;
        break;
      default:
        severityColor = AppTheme.positiveChange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: severityColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    factor.factor,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    factor.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                factor.severity,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
