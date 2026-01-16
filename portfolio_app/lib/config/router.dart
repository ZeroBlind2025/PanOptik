import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/assets/screens/assets_list_screen.dart';
import '../features/assets/screens/asset_detail_screen.dart';
import '../features/assets/screens/add_asset_screen.dart';
import '../features/assets/screens/edit_asset_screen.dart';
import '../features/alerts/screens/alerts_list_screen.dart';
import '../features/alerts/screens/add_alert_screen.dart';
import '../features/premium/screens/subscription_screen.dart';
import '../features/premium/screens/analytics_screen.dart';
import '../features/premium/screens/risk_analysis_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app routes
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/assets',
            builder: (context, state) => const AssetsListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddAssetScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => AssetDetailScreen(
                  assetId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => EditAssetScreen(
                      assetId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddAlertScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/premium',
            builder: (context, state) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/risk',
            builder: (context, state) => const RiskAnalysisScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Assets',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Premium',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/assets')) return 1;
    if (location.startsWith('/alerts')) return 2;
    if (location.startsWith('/premium') ||
        location.startsWith('/analytics') ||
        location.startsWith('/risk')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/assets');
        break;
      case 2:
        context.go('/alerts');
        break;
      case 3:
        context.go('/premium');
        break;
    }
  }
}
