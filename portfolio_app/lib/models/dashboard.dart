import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'dashboard.g.dart';

@JsonSerializable()
@HiveType(typeId: 3)
class DashboardData {
  @HiveField(0)
  final double totalValue;

  @HiveField(1)
  final double dailyChange;

  @HiveField(2)
  final double dailyChangePercent;

  @HiveField(3)
  final double weeklyChange;

  @HiveField(4)
  final double weeklyChangePercent;

  @HiveField(5)
  final List<AllocationItem> allocationByType;

  @HiveField(6)
  final List<AllocationItem> allocationByCountry;

  @HiveField(7)
  final List<AllocationItem> allocationBySector;

  @HiveField(8)
  final DateTime lastUpdated;

  DashboardData({
    required this.totalValue,
    required this.dailyChange,
    required this.dailyChangePercent,
    required this.weeklyChange,
    required this.weeklyChangePercent,
    required this.allocationByType,
    required this.allocationByCountry,
    required this.allocationBySector,
    required this.lastUpdated,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardDataToJson(this);

  factory DashboardData.empty() => DashboardData(
        totalValue: 0,
        dailyChange: 0,
        dailyChangePercent: 0,
        weeklyChange: 0,
        weeklyChangePercent: 0,
        allocationByType: [],
        allocationByCountry: [],
        allocationBySector: [],
        lastUpdated: DateTime.now(),
      );
}

@JsonSerializable()
@HiveType(typeId: 4)
class AllocationItem {
  @HiveField(0)
  final String category;

  @HiveField(1)
  final double value;

  @HiveField(2)
  final double percentage;

  AllocationItem({
    required this.category,
    required this.value,
    required this.percentage,
  });

  factory AllocationItem.fromJson(Map<String, dynamic> json) =>
      _$AllocationItemFromJson(json);
  Map<String, dynamic> toJson() => _$AllocationItemToJson(this);
}
