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
  final String email;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime? updatedAt;

  @HiveField(4)
  final SubscriptionStatus subscriptionStatus;

  @HiveField(5)
  final String? fcmToken;

  User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.updatedAt,
    this.subscriptionStatus = SubscriptionStatus.free,
    this.fcmToken,
  });

  bool get isPremium => subscriptionStatus == SubscriptionStatus.premium;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    SubscriptionStatus? subscriptionStatus,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
