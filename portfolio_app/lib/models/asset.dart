import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'asset.g.dart';

enum AssetType {
  @JsonValue('stock')
  stock,
  @JsonValue('etf')
  etf,
  @JsonValue('crypto')
  crypto,
  @JsonValue('fund')
  fund,
  @JsonValue('bond')
  bond,
  @JsonValue('real_estate')
  realEstate,
  @JsonValue('cash')
  cash,
  @JsonValue('commodity')
  commodity,
}

extension AssetTypeExtension on AssetType {
  String get displayName {
    switch (this) {
      case AssetType.stock:
        return 'Stock';
      case AssetType.etf:
        return 'ETF';
      case AssetType.crypto:
        return 'Cryptocurrency';
      case AssetType.fund:
        return 'Mutual Fund';
      case AssetType.bond:
        return 'Bond';
      case AssetType.realEstate:
        return 'Real Estate';
      case AssetType.cash:
        return 'Cash / Savings';
      case AssetType.commodity:
        return 'Commodity';
    }
  }

  bool get hasLivePricing {
    switch (this) {
      case AssetType.stock:
      case AssetType.etf:
      case AssetType.crypto:
      case AssetType.commodity:
        return true;
      default:
        return false;
    }
  }

  bool get requiresTicker {
    switch (this) {
      case AssetType.stock:
      case AssetType.etf:
      case AssetType.crypto:
      case AssetType.commodity:
        return true;
      default:
        return false;
    }
  }
}

@JsonSerializable()
@HiveType(typeId: 1)
class Asset {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final AssetType type;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String? ticker;

  @HiveField(5)
  final double? quantity;

  @HiveField(6)
  final double? manualValue;

  @HiveField(7)
  final double? costBasis;

  @HiveField(8)
  final String currency;

  @HiveField(9)
  final String? country;

  @HiveField(10)
  final String? sector;

  @HiveField(11)
  final String? riskCategory;

  @HiveField(12)
  final String? notes;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  // Computed from live price, not stored
  final double? currentPrice;
  final double? priceChange;
  final double? priceChangePercent;

  Asset({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    this.ticker,
    this.quantity,
    this.manualValue,
    this.costBasis,
    this.currency = 'USD',
    this.country,
    this.sector,
    this.riskCategory,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.currentPrice,
    this.priceChange,
    this.priceChangePercent,
  });

  double get currentValue {
    if (type.hasLivePricing && quantity != null && currentPrice != null) {
      return quantity! * currentPrice!;
    }
    return manualValue ?? 0;
  }

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
  Map<String, dynamic> toJson() => _$AssetToJson(this);

  Asset copyWith({
    String? id,
    String? userId,
    AssetType? type,
    String? name,
    String? ticker,
    double? quantity,
    double? manualValue,
    double? costBasis,
    String? currency,
    String? country,
    String? sector,
    String? riskCategory,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? currentPrice,
    double? priceChange,
    double? priceChangePercent,
  }) {
    return Asset(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      ticker: ticker ?? this.ticker,
      quantity: quantity ?? this.quantity,
      manualValue: manualValue ?? this.manualValue,
      costBasis: costBasis ?? this.costBasis,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      sector: sector ?? this.sector,
      riskCategory: riskCategory ?? this.riskCategory,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentPrice: currentPrice ?? this.currentPrice,
      priceChange: priceChange ?? this.priceChange,
      priceChangePercent: priceChangePercent ?? this.priceChangePercent,
    );
  }
}
