import '../models/dashboard.dart';
import 'api_service.dart';

class RiskFactor {
  final String factor;
  final String description;
  final String severity; // low, medium, high

  RiskFactor({
    required this.factor,
    required this.description,
    required this.severity,
  });

  factory RiskFactor.fromJson(Map<String, dynamic> json) {
    return RiskFactor(
      factor: json['factor'],
      description: json['description'],
      severity: json['severity'],
    );
  }
}

class RiskAnalysis {
  final int riskScore;
  final String riskCategory;
  final List<RiskFactor> riskFactors;
  final List<String> recommendations;

  RiskAnalysis({
    required this.riskScore,
    required this.riskCategory,
    required this.riskFactors,
    required this.recommendations,
  });

  factory RiskAnalysis.fromJson(Map<String, dynamic> json) {
    return RiskAnalysis(
      riskScore: json['riskScore'],
      riskCategory: json['riskCategory'],
      riskFactors: (json['riskFactors'] as List)
          .map((f) => RiskFactor.fromJson(f))
          .toList(),
      recommendations: List<String>.from(json['recommendations']),
    );
  }
}

class ExposureData {
  final List<AllocationItem> countryExposure;
  final List<AllocationItem> sectorExposure;

  ExposureData({
    required this.countryExposure,
    required this.sectorExposure,
  });

  factory ExposureData.fromJson(Map<String, dynamic> json) {
    return ExposureData(
      countryExposure: (json['countryExposure'] as List)
          .map((item) => AllocationItem.fromJson(item))
          .toList(),
      sectorExposure: (json['sectorExposure'] as List)
          .map((item) => AllocationItem.fromJson(item))
          .toList(),
    );
  }
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final _api = ApiService();

  // Get exposure analysis (premium only)
  Future<ExposureData> fetchExposure() async {
    final response = await _api.get('/analytics/exposure');
    return ExposureData.fromJson(response.data);
  }

  // Get risk analysis (premium only)
  Future<RiskAnalysis> fetchRiskAnalysis() async {
    final response = await _api.get('/analytics/risk');
    return RiskAnalysis.fromJson(response.data);
  }

  // Export portfolio to CSV (premium only)
  Future<String> exportToCsv() async {
    final response = await _api.get('/export/csv');
    return response.data['downloadUrl'];
  }
}
