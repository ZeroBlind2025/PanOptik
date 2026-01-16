import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'price.g.dart';

@JsonSerializable()
@HiveType(typeId: 5)
class Price {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String ticker;

  @HiveField(2)
  final String assetType;

  @HiveField(3)
  final String currency;

  @HiveField(4)
  final String provider;

  @HiveField(5)
  final double price;

  @HiveField(6)
  final DateTime fetchedAt;

  @HiveField(7)
  final double? previousClose;

  @HiveField(8)
  final double? change;

  @HiveField(9)
  final double? changePercent;

  Price({
    required this.id,
    required this.ticker,
    required this.assetType,
    required this.currency,
    required this.provider,
    required this.price,
    required this.fetchedAt,
    this.previousClose,
    this.change,
    this.changePercent,
  });

  factory Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);
  Map<String, dynamic> toJson() => _$PriceToJson(this);
}

@JsonSerializable()
class TickerSearchResult {
  final String symbol;
  final String name;
  final String type;
  final String? exchange;

  TickerSearchResult({
    required this.symbol,
    required this.name,
    required this.type,
    this.exchange,
  });

  factory TickerSearchResult.fromJson(Map<String, dynamic> json) =>
      _$TickerSearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$TickerSearchResultToJson(this);
}
