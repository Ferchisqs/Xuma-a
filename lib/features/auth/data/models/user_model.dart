// lib/features/auth/data/models/user_model.dart - ACTUALIZADO

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    required int age,
    String? profilePicture,
    required DateTime createdAt,
    DateTime? lastLogin,
    bool needsParentalConsent = false,
    bool isEmailVerified = false, // 🆕 AGREGADO
  }) : super(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    age: age,
    profilePicture: profilePicture,
    createdAt: createdAt,
    lastLogin: lastLogin,
    needsParentalConsent: needsParentalConsent,
    isEmailVerified: isEmailVerified, // 🆕 AGREGADO
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      firstName: entity.firstName,
      lastName: entity.lastName,
      age: entity.age,
      profilePicture: entity.profilePicture,
      createdAt: entity.createdAt,
      lastLogin: entity.lastLogin,
      needsParentalConsent: entity.needsParentalConsent,
      isEmailVerified: entity.isEmailVerified, // 🆕 AGREGADO
    );
  }
}