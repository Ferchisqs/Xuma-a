// lib/features/profile/data/model/user_profile_model.dart - VERSIÓN CORREGIDA
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

  // 🆕 AGREGAR GETTER PARA COMPATIBILIDAD
  String? get profilePicture => avatarUrl;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing UserProfileModel from JSON: $json');
      
      // 🆕 PROCESAMIENTO MÁS ROBUSTO DE CADA CAMPO
      
      // IDs con múltiples posibles nombres
      final String id = _parseStringField(
        json['id'] ?? json['userId'] ?? json['user_id'], 
        'temp_id'
      );
      
      // Email
      final String email = _parseStringField(
        json['email'], 
        'usuario@xumaa.com'
      );
      
      // Nombres - 🆕 MEJORADO PARA USAR LOS DATOS REALES DE TU API
      final String firstName = _parseStringField(
        json['firstName'] ?? json['first_name'] ?? json['name'], 
        'Usuario'
      );
      
      final String lastName = _parseStringField(
        json['lastName'] ?? json['last_name'], 
        ''
      );
      
      // 🆕 EDAD - PROCESAMIENTO ESPECIAL
      final int age = _parseAgeField(json['age']);
      
      // Avatar/Profile Picture - 🆕 MÚLTIPLES NOMBRES DE CAMPO
      final String? avatarUrl = _parseOptionalStringField(
        json['avatarUrl'] ?? 
        json['avatar_url'] ?? 
        json['profilePicture'] ?? 
        json['profile_picture'] ??
        json['profileImage'] ??
        json['profilePhoto']
      );
      
      // Bio y Location opcionales
      final String? bio = _parseOptionalStringField(json['bio'] ?? json['description']);
      final String? location = _parseOptionalStringField(json['location'] ?? json['city']);
      
      // Fechas
      final DateTime createdAt = _parseDateTime(
        json['createdAt'] ?? json['created_at']
      ) ?? DateTime.now();
      
      final DateTime? updatedAt = _parseDateTime(
        json['updatedAt'] ?? json['updated_at']
      );
      
      final DateTime? lastLogin = _parseDateTime(
        json['lastLogin'] ?? json['last_login']
      );
      
      // Consentimiento parental
      final bool needsParentalConsent = _parseBoolField(
        json['needsParentalConsent'] ?? json['needs_parental_consent'],
        age < 13 // Default basado en la edad
      );
      
      // Stats del usuario
      final int ecoPoints = _parseIntField(
        json['ecoPoints'] ?? json['eco_points'] ?? json['points'],
        0
      );
      
      final int achievementsCount = _parseIntField(
        json['achievementsCount'] ?? json['achievements_count'] ?? json['achievements'],
        0
      );
      
      final int lessonsCompleted = _parseIntField(
        json['lessonsCompleted'] ?? json['lessons_completed'] ?? json['lessons'],
        0
      );
      
      // Nivel del usuario
      final String level = _parseStringField(
        json['level'],
        _getLevelFromAge(age)
      );
      
      final model = UserProfileModel(
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
      
      print('✅ UserProfileModel parsed successfully:');
      print('   - ID: ${model.id}');
      print('   - Name: ${model.fullName}');
      print('   - Email: ${model.email}');
      print('   - Age: ${model.age}');
      print('   - Level: ${model.level}');
      print('   - Points: ${model.ecoPoints}');
      
      return model;
      
    } catch (e) {
      print('❌ Error parsing UserProfileModel: $e');
      print('📄 Original JSON: $json');
      
      // Crear modelo de fallback con datos mínimos
      return UserProfileModel(
        id: _parseStringField(json['id'] ?? json['userId'], 'error_id'),
        email: _parseStringField(json['email'], 'usuario@xumaa.com'),
        firstName: _parseStringField(json['firstName'] ?? json['first_name'], 'Usuario'),
        lastName: _parseStringField(json['lastName'] ?? json['last_name'], ''),
        age: _parseAgeField(json['age']),
        avatarUrl: null,
        bio: null,
        location: null,
        createdAt: DateTime.now(),
        updatedAt: null,
        lastLogin: null,
        needsParentalConsent: false,
        ecoPoints: 0,
        achievementsCount: 0,
        lessonsCompleted: 0,
        level: 'Eco Explorer',
      );
    }
  }

  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);

  // 🆕 HELPER METHODS MEJORADOS PARA PARSING
  
  static String _parseStringField(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return defaultValue;
  }
  
  static String? _parseOptionalStringField(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return null;
  }
  
  // 🆕 MÉTODO ESPECÍFICO PARA PARSING DE EDAD
  static int _parseAgeField(dynamic value) {
    print('🔍 Parsing age field: $value (type: ${value.runtimeType})');
    
    if (value == null) {
      print('⚠️ Age is null, using default 18');
      return 18;
    }
    
    if (value is int) {
      if (value > 0 && value <= 120) {
        print('✅ Age is valid int: $value');
        return value;
      } else {
        print('⚠️ Age out of range: $value, using 18');
        return 18;
      }
    }
    
    if (value is double) {
      final intValue = value.toInt();
      if (intValue > 0 && intValue <= 120) {
        print('✅ Age converted from double: $intValue');
        return intValue;
      } else {
        print('⚠️ Age (from double) out of range: $intValue, using 18');
        return 18;
      }
    }
    
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null && parsed > 0 && parsed <= 120) {
        print('✅ Age parsed from string: $parsed');
        return parsed;
      } else {
        print('⚠️ Could not parse age from string: "$value", using 18');
        return 18;
      }
    }
    
    print('⚠️ Age has unsupported type: ${value.runtimeType}, using 18');
    return 18;
  }
  
  static int _parseIntField(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }
  
  static bool _parseBoolField(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (value is num) return value != 0;
    return defaultValue;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
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