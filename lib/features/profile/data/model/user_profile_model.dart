import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_profile_entity.dart';

part 'user_profile_model.g.dart';

@JsonSerializable()
class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    required int age,
    String? avatarUrl,
    String? bio,
    String? location,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    bool needsParentalConsent = false,
    int ecoPoints = 0,
    int achievementsCount = 0,
    int lessonsCompleted = 0,
    String level = 'Eco Explorer',
  }) : super(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    age: age,
    avatarUrl: avatarUrl,
    bio: bio,
    location: location,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastLogin: lastLogin,
    needsParentalConsent: needsParentalConsent,
    ecoPoints: ecoPoints,
    achievementsCount: achievementsCount,
    lessonsCompleted: lessonsCompleted,
    level: level,
  );

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing UserProfileModel from JSON: $json');
      
      // Mapear campos con nombres alternativos
      final model = UserProfileModel(
        id: (json['id'] ?? json['userId'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        firstName: (json['firstName'] ?? json['first_name'] ?? '').toString(),
        lastName: (json['lastName'] ?? json['last_name'] ?? '').toString(),
        age: _parseIntField(json['age'], 18),
        avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
        bio: json['bio']?.toString(),
        location: json['location']?.toString(),
        createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
        lastLogin: _parseDateTime(json['lastLogin'] ?? json['last_login']),
        needsParentalConsent: json['needsParentalConsent'] ?? json['needs_parental_consent'] ?? false,
        ecoPoints: _parseIntField(json['ecoPoints'] ?? json['eco_points'], 0),
        achievementsCount: _parseIntField(json['achievementsCount'] ?? json['achievements_count'], 0),
        lessonsCompleted: _parseIntField(json['lessonsCompleted'] ?? json['lessons_completed'], 0),
        level: json['level']?.toString() ?? _getLevelFromAge(_parseIntField(json['age'], 18)),
      );
      
      print('✅ UserProfileModel parsed successfully: ${model.fullName}');
      return model;
    } catch (e) {
      print('❌ Error parsing UserProfileModel: $e');
      print('📄 Original JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);

  // Helper methods para parsing
  static int _parseIntField(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Error parsing DateTime: $value - $e');
        return null;
      }
    }
    return null;
  }

  static String _getLevelFromAge(int age) {
    if (age < 13) return 'Eco Explorer';
    if (age < 18) return 'Eco Guardian';
    if (age < 25) return 'Eco Warrior';
    return 'Eco Master';
  }

  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      firstName: entity.firstName,
      lastName: entity.lastName,
      age: entity.age,
      avatarUrl: entity.avatarUrl,
      bio: entity.bio,
      location: entity.location,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastLogin: entity.lastLogin,
      needsParentalConsent: entity.needsParentalConsent,
      ecoPoints: entity.ecoPoints,
      achievementsCount: entity.achievementsCount,
      lessonsCompleted: entity.lessonsCompleted,
      level: entity.level,
    );
  }
}