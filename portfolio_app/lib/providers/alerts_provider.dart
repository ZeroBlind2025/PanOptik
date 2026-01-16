import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alert.dart';
import '../services/alerts_service.dart';

final alertsServiceProvider = Provider<AlertsService>((ref) {
  return AlertsService();
});

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AsyncValue<List<Alert>>>((ref) {
  return AlertsNotifier(ref.watch(alertsServiceProvider));
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<Alert>>> {
  final AlertsService _service;

  AlertsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadCachedAlerts();
    fetchAlerts();
  }

  void _loadCachedAlerts() {
    final cached = _service.getCachedAlerts();
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    }
  }

  Future<void> fetchAlerts() async {
    try {
      final alerts = await _service.fetchAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      if (state.hasValue) {
        return;
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createAlert({
    required AlertType type,
    required String message,
    String? assetId,
    String? triggerValue,
    DateTime? nextFire,
    bool recurring = false,
    String? rrule,
  }) async {
    final alert = await _service.createAlert(
      type: type,
      message: message,
      assetId: assetId,
      triggerValue: triggerValue,
      nextFire: nextFire,
      recurring: recurring,
      rrule: rrule,
    );

    state = AsyncValue.data([...state.valueOrNull ?? [], alert]);
  }

  Future<void> updateAlert(
    String id, {
    String? message,
    String? triggerValue,
    DateTime? nextFire,
    bool? recurring,
    String? rrule,
    bool? enabled,
  }) async {
    final alert = await _service.updateAlert(
      id,
      message: message,
      triggerValue: triggerValue,
      nextFire: nextFire,
      recurring: recurring,
      rrule: rrule,
      enabled: enabled,
    );

    state = AsyncValue.data(
      state.valueOrNull?.map((a) => a.id == id ? alert : a).toList() ?? [alert],
    );
  }

  Future<void> toggleAlert(String id, bool enabled) async {
    await updateAlert(id, enabled: enabled);
  }

  Future<void> deleteAlert(String id) async {
    await _service.deleteAlert(id);

    state = AsyncValue.data(
      state.valueOrNull?.where((a) => a.id != id).toList() ?? [],
    );
  }
}

// Provider for active alerts count
final activeAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsProvider).valueOrNull ?? [];
  return alerts.where((a) => a.enabled).length;
});
