class Environment {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
  static const revenueCatApiKey = String.fromEnvironment('REVENUECAT_API_KEY');
  static const posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static const isProduction = bool.fromEnvironment('dart.vm.product');
}
