import 'package:hive/hive.dart';

import '../models/alert.dart';
import 'api_service.dart';

class AlertsService {
  static final AlertsService _instance = AlertsService._internal();
  factory AlertsService() => _instance;
  AlertsService._internal();

  final _api = ApiService();
  static const _boxName = 'alerts';

  Box<Alert>? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<Alert>(_boxName);
  }

  // Fetch all alerts
  Future<List<Alert>> fetchAlerts() async {
    final response = await _api.get('/alerts');
    final List<dynamic> data = response.data;
    final alerts = data.map((json) => Alert.fromJson(json)).toList();

    // Cache locally
    await _cacheAlerts(alerts);

    return alerts;
  }

  // Create alert
  Future<Alert> createAlert({
    required AlertType type,
    required String message,
    String? assetId,
    String? triggerValue,
    DateTime? nextFire,
    bool recurring = false,
    String? rrule,
  }) async {
    final response = await _api.post('/alerts', data: {
      'type': type.name,
      'message': message,
      if (assetId != null) 'assetId': assetId,
      if (triggerValue != null) 'triggerValue': triggerValue,
      if (nextFire != null) 'nextFire': nextFire.toIso8601String(),
      'recurring': recurring,
      if (rrule != null) 'rrule': rrule,
    });

    final alert = Alert.fromJson(response.data);

    // Add to cache
    await _box?.put(alert.id, alert);

    return alert;
  }

  // Update alert
  Future<Alert> updateAlert(
    String id, {
    String? message,
    String? triggerValue,
    DateTime? nextFire,
    bool? recurring,
    String? rrule,
    bool? enabled,
  }) async {
    final response = await _api.patch('/alerts/$id', data: {
      if (message != null) 'message': message,
      if (triggerValue != null) 'triggerValue': triggerValue,
      if (nextFire != null) 'nextFire': nextFire.toIso8601String(),
      if (recurring != null) 'recurring': recurring,
      if (rrule != null) 'rrule': rrule,
      if (enabled != null) 'enabled': enabled,
    });

    final alert = Alert.fromJson(response.data);

    // Update cache
    await _box?.put(alert.id, alert);

    return alert;
  }

  // Delete alert
  Future<void> deleteAlert(String id) async {
    await _api.delete('/alerts/$id');

    // Remove from cache
    await _box?.delete(id);
  }

  // Get cached alerts
  List<Alert> getCachedAlerts() {
    return _box?.values.toList() ?? [];
  }

  // Cache alerts
  Future<void> _cacheAlerts(List<Alert> alerts) async {
    await _box?.clear();
    for (final alert in alerts) {
      await _box?.put(alert.id, alert);
    }
  }
}
