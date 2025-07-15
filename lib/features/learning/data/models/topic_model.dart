// lib/features/learning/data/models/topic_model.dart - SUPER ROBUSTO
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/topic_entity.dart';

part 'topic_model.g.dart';

@JsonSerializable()
class TopicModel extends TopicEntity {
  const TopicModel({
    required String id,
    required String title,
    required String description,
    String? imageUrl,
    required String category,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          title: title,
          description: description,
          imageUrl: imageUrl,
          category: category,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  // 🔧 FACTORY SUPER ROBUSTO PARA TU API
  factory TopicModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 [TOPIC MODEL] Raw JSON: $json');
      
      // Extraer y limpiar cada campo de forma segura
      final id = _extractString(json, 'id', required: true);
      final name = _extractString(json, 'name', fallback: 'Sin título');
      final description = _extractString(json, 'description', fallback: 'Sin descripción');
      final iconUrl = _extractStringOrNull(json, 'icon_url');
      final category = _extractString(json, 'category', fallback: _extractString(json, 'slug', fallback: 'general'));
      final isActive = _extractBool(json, 'is_active', fallback: true);
      final createdAt = _extractDateTime(json, 'created_at');
      final updatedAt = _extractDateTime(json, 'updated_at');
      
      print('🔍 [TOPIC MODEL] Extracted values:');
      print('  - id: $id');
      print('  - name: $name');
      print('  - description: $description');
      print('  - iconUrl: $iconUrl');
      print('  - category: $category');
      print('  - isActive: $isActive');
      
      return TopicModel(
        id: id,
        title: name,
        description: description,
        imageUrl: iconUrl,
        category: category,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e, stackTrace) {
      print('❌ [TOPIC MODEL] Error parsing topic: $e');
      print('❌ [TOPIC MODEL] Stack trace: $stackTrace');
      print('❌ [TOPIC MODEL] JSON: $json');
      rethrow;
    }
  }

  // Helper para extraer string obligatorio
  static String _extractString(Map<String, dynamic> json, String key, {String? fallback, bool required = false}) {
    final value = json[key];
    
    if (value == null) {
      if (required) {
        throw Exception('Required field $key is missing');
      }
      return fallback ?? '';
    }
    
    if (value is String) {
      // 🔧 FILTRAR VALORES PLACEHOLDER
      if (value.isEmpty || value.toLowerCase() == 'string' || value.toLowerCase() == 'null') {
        return fallback ?? '';
      }
      return value;
    }
    
    // Convertir otros tipos a string
    return value.toString();
  }
  
  // Helper para extraer string opcional (puede ser null)
  static String? _extractStringOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    
    if (value == null) return null;
    
    if (value is String) {
      // 🔧 FILTRAR VALORES PLACEHOLDER
      if (value.isEmpty || value.toLowerCase() == 'string' || value.toLowerCase() == 'null') {
        return null;
      }
      return value;
    }
    
    final stringValue = value.toString();
    if (stringValue.toLowerCase() == 'string' || stringValue.toLowerCase() == 'null') {
      return null;
    }
    
    return stringValue;
  }
  
  // Helper para extraer boolean
  static bool _extractBool(Map<String, dynamic> json, String key, {bool fallback = false}) {
    final value = json[key];
    
    if (value == null) return fallback;
    
    if (value is bool) return value;
    
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    
    if (value is int) {
      return value == 1;
    }
    
    return fallback;
  }
  
  // Helper para extraer DateTime
  static DateTime _extractDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    
    if (value == null) return DateTime.now();
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ [TOPIC MODEL] Error parsing date $key: $value');
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => _$TopicModelToJson(this);

  factory TopicModel.fromEntity(TopicEntity entity) {
    return TopicModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      imageUrl: entity.imageUrl,
      category: entity.category,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}