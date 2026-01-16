import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardData>>((ref) {
  return DashboardNotifier(ref.watch(dashboardServiceProvider));
});

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardData>> {
  final DashboardService _service;

  DashboardNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadCachedDashboard();
    fetchDashboard();
  }

  void _loadCachedDashboard() {
    final cached = _service.getCachedDashboard();
    if (cached != null) {
      state = AsyncValue.data(cached);
    }
  }

  Future<void> fetchDashboard() async {
    try {
      final dashboard = await _service.fetchDashboard();
      state = AsyncValue.data(dashboard);
    } catch (e, st) {
      // Keep cached data if available
      if (state.hasValue) {
        return;
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchDashboard();
  }
}
