import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

enum SubscriptionStatus {
  @JsonValue('free')
  free,
  @JsonValue('premium')
  premium,
  @JsonValue('expired')
  expired,
}

@JsonSerializable()
@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String supabaseId;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final SubscriptionStatus subscriptionStatus;

  @HiveField(6)
  final String? fcmToken;

  User({
    required this.id,
    required this.supabaseId,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionStatus = SubscriptionStatus.free,
    this.fcmToken,
  });

  bool get isPremium => subscriptionStatus == SubscriptionStatus.premium;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? supabaseId,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    SubscriptionStatus? subscriptionStatus,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
