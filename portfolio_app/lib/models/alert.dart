import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'alert.g.dart';

enum AlertType {
  @JsonValue('price_above')
  priceAbove,
  @JsonValue('price_below')
  priceBelow,
  @JsonValue('date_reminder')
  dateReminder,
  @JsonValue('recurring_reminder')
  recurringReminder,
}

extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.priceAbove:
        return 'Price Above';
      case AlertType.priceBelow:
        return 'Price Below';
      case AlertType.dateReminder:
        return 'Date Reminder';
      case AlertType.recurringReminder:
        return 'Recurring Reminder';
    }
  }

  bool get isPriceAlert {
    return this == AlertType.priceAbove || this == AlertType.priceBelow;
  }

  bool get requiresPremium {
    return isPriceAlert;
  }
}

@JsonSerializable()
@HiveType(typeId: 2)
class Alert {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String? assetId;

  @HiveField(3)
  final AlertType type;

  @HiveField(4)
  final String? triggerValue;

  @HiveField(5)
  final String message;

  @HiveField(6)
  final DateTime? nextFire;

  @HiveField(7)
  final bool recurring;

  @HiveField(8)
  final String? rrule;

  @HiveField(9)
  final bool enabled;

  @HiveField(10)
  final DateTime createdAt;

  // Denormalized asset info for display
  final String? assetName;
  final String? assetTicker;

  Alert({
    required this.id,
    required this.userId,
    this.assetId,
    required this.type,
    this.triggerValue,
    required this.message,
    this.nextFire,
    this.recurring = false,
    this.rrule,
    this.enabled = true,
    required this.createdAt,
    this.assetName,
    this.assetTicker,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);
  Map<String, dynamic> toJson() => _$AlertToJson(this);

  Alert copyWith({
    String? id,
    String? userId,
    String? assetId,
    AlertType? type,
    String? triggerValue,
    String? message,
    DateTime? nextFire,
    bool? recurring,
    String? rrule,
    bool? enabled,
    DateTime? createdAt,
    String? assetName,
    String? assetTicker,
  }) {
    return Alert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetId: assetId ?? this.assetId,
      type: type ?? this.type,
      triggerValue: triggerValue ?? this.triggerValue,
      message: message ?? this.message,
      nextFire: nextFire ?? this.nextFire,
      recurring: recurring ?? this.recurring,
      rrule: rrule ?? this.rrule,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      assetName: assetName ?? this.assetName,
      assetTicker: assetTicker ?? this.assetTicker,
    );
  }
}
