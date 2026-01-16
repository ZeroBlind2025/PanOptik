import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PremiumGuard extends StatelessWidget {
  final String feature;
  final String description;

  const PremiumGuard({
    super.key,
    required this.feature,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(feature),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 40,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Premium Feature',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.push('/premium'),
                icon: const Icon(Icons.star),
                label: const Text('Upgrade to Premium'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
