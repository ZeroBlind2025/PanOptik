import 'package:hive/hive.dart';

import '../models/dashboard.dart';
import 'api_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final _api = ApiService();
  static const _boxName = 'dashboard';

  Box<DashboardData>? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<DashboardData>(_boxName);
  }

  // Fetch dashboard data from API
  Future<DashboardData> fetchDashboard() async {
    final response = await _api.get('/dashboard');
    final dashboard = DashboardData.fromJson(response.data);

    // Cache locally
    await _cacheDashboard(dashboard);

    return dashboard;
  }

  // Get cached dashboard data
  DashboardData? getCachedDashboard() {
    return _box?.get('current');
  }

  // Cache dashboard data
  Future<void> _cacheDashboard(DashboardData dashboard) async {
    await _box?.put('current', dashboard);
  }
}
