import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'app.dart';
import 'config/environment.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize API service
  ApiService().initialize();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM
  await NotificationService.initialize();

  // Initialize PostHog
  if (Environment.posthogApiKey.isNotEmpty) {
    final posthogConfig = PostHogConfig(Environment.posthogApiKey);
    posthogConfig.host = 'https://app.posthog.com';
    await Posthog().setup(posthogConfig);
  }

  // Initialize Sentry and run app
  if (Environment.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = Environment.sentryDsn;
        options.tracesSampleRate = 1.0;
        options.environment = Environment.isProduction ? 'production' : 'development';
      },
      appRunner: () => runApp(
        const ProviderScope(
          child: PortfolioApp(),
        ),
      ),
    );
  } else {
    runApp(
      const ProviderScope(
        child: PortfolioApp(),
      ),
    );
  }
}
