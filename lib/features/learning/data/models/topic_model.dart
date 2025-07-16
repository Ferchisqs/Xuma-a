// lib/features/learning/data/models/topic_model.dart - SUPER ROBUSTO PARA API PROBLEMÁTICA
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

  // 🔧 FACTORY ULTRA ROBUSTO PARA APIs PROBLEMÁTICAS
  factory TopicModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 [TOPIC MODEL] === PROCESSING TOPIC ===');
      print('🔍 [TOPIC MODEL] Raw JSON: $json');
      print('🔍 [TOPIC MODEL] JSON keys: ${json.keys.toList()}');
      
      // 1. EXTRAER ID (OBLIGATORIO)
      final id = _extractRequiredString(json, ['id', '_id', 'topicId', 'topic_id']);
      print('🔍 [TOPIC MODEL] Extracted ID: $id');
      
      // 2. EXTRAER TÍTULO/NOMBRE
      final title = _extractString(json, ['name', 'title', 'topic_name'], fallback: 'Tema sin título');
      print('🔍 [TOPIC MODEL] Extracted title: $title');
      
      // 3. EXTRAER DESCRIPCIÓN
      final description = _extractString(json, ['description', 'desc', 'summary'], fallback: 'Sin descripción disponible');
      print('🔍 [TOPIC MODEL] Extracted description: ${description.substring(0, description.length > 50 ? 50 : description.length)}...');
      
      // 4. EXTRAER URL DE IMAGEN
      final imageUrl = _extractStringOrNull(json, ['icon_url', 'image_url', 'imageUrl', 'thumbnail', 'image']);
      print('🔍 [TOPIC MODEL] Extracted imageUrl: $imageUrl');
      
      // 5. EXTRAER CATEGORÍA - MUY IMPORTANTE PARA TU CASO
      final category = _extractCategory(json);
      print('🔍 [TOPIC MODEL] Extracted category: $category');
      
      // 6. EXTRAER ESTADO ACTIVO
      final isActive = _extractBool(json, ['is_active', 'active', 'enabled', 'published'], fallback: true);
      print('🔍 [TOPIC MODEL] Extracted isActive: $isActive');
      
      // 7. EXTRAER FECHAS
      final createdAt = _extractDateTime(json, ['created_at', 'createdAt', 'date_created']);
      final updatedAt = _extractDateTime(json, ['updated_at', 'updatedAt', 'date_updated', 'modified_at']);
      print('🔍 [TOPIC MODEL] Extracted dates - Created: $createdAt, Updated: $updatedAt');
      
      final topic = TopicModel(
        id: id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        category: category,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      print('✅ [TOPIC MODEL] Successfully created topic: "${topic.title}" (Category: ${topic.category})');
      return topic;
      
    } catch (e, stackTrace) {
      print('❌ [TOPIC MODEL] CRITICAL ERROR parsing topic: $e');
      print('❌ [TOPIC MODEL] Stack trace: $stackTrace');
      print('❌ [TOPIC MODEL] Raw JSON: $json');
      
      // 🆘 FALLBACK ULTRA ROBUSTO - CREAR TOPIC BÁSICO
      print('🆘 [TOPIC MODEL] Creating fallback topic...');
      
      try {
        return TopicModel(
          id: json['id']?.toString() ?? 'fallback_${DateTime.now().millisecondsSinceEpoch}',
          title: json['name']?.toString() ?? json['title']?.toString() ?? 'Tema de aprendizaje',
          description: json['description']?.toString() ?? 'Tema educativo sobre medio ambiente',
          imageUrl: null,
          category: 'educacion', // Categoría por defecto
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        );
      } catch (fallbackError) {
        print('❌ [TOPIC MODEL] Even fallback failed: $fallbackError');
        rethrow;
      }
    }
  }

  // 🔧 EXTRACTOR DE CATEGORÍA ULTRA ROBUSTO
  static String _extractCategory(Map<String, dynamic> json) {
    print('🔍 [TOPIC MODEL] === EXTRACTING CATEGORY ===');
    
    // Lista de posibles campos para categoría
    final categoryFields = [
      'category', 'categoria', 'cat', 'type', 'topic_type', 
      'subject', 'area', 'section', 'classification',
      'slug', // Muchas APIs usan slug como categoría
    ];
    
    for (final field in categoryFields) {
      final value = json[field];
      print('🔍 [TOPIC MODEL] Checking field "$field": $value (${value.runtimeType})');
      
      if (value != null) {
        String stringValue = value.toString().trim().toLowerCase();
        
        // Filtrar valores placeholder
        if (stringValue.isNotEmpty && 
            stringValue != 'string' && 
            stringValue != 'null' && 
            stringValue != 'undefined') {
          
          // Mapear categorías conocidas
          final mappedCategory = _mapCategory(stringValue);
          print('✅ [TOPIC MODEL] Found category "$stringValue" -> mapped to "$mappedCategory"');
          return mappedCategory;
        }
      }
    }
    
    // Si hay campos anidados, buscar ahí también
    if (json.containsKey('attributes')) {
      final attributes = json['attributes'];
      if (attributes is Map<String, dynamic>) {
        print('🔍 [TOPIC MODEL] Checking nested attributes...');
        return _extractCategory(attributes);
      }
    }
    
    if (json.containsKey('metadata')) {
      final metadata = json['metadata'];
      if (metadata is Map<String, dynamic>) {
        print('🔍 [TOPIC MODEL] Checking nested metadata...');
        return _extractCategory(metadata);
      }
    }
    
    // Intentar deducir categoría del título o descripción
    final title = (json['name'] ?? json['title'] ?? '').toString().toLowerCase();
    final deducedCategory = _deduceCategoryFromText(title);
    if (deducedCategory != 'general') {
      print('🧠 [TOPIC MODEL] Deduced category from title "$title": $deducedCategory');
      return deducedCategory;
    }
    
    print('⚠️ [TOPIC MODEL] No category found, using default: "educacion"');
    return 'educacion'; // Categoría por defecto
  }

  // 🧠 MAPEAR CATEGORÍAS CONOCIDAS
  static String _mapCategory(String category) {
    final mapping = {
      // Categorías en inglés
      'education': 'educacion',
      'environment': 'medio-ambiente',
      'climate': 'clima',
      'recycling': 'reciclaje',
      'energy': 'energia',
      'water': 'agua',
      'sustainability': 'sostenibilidad',
      'nature': 'naturaleza',
      'conservation': 'conservacion',
      'ecology': 'ecologia',
      
      // Categorías en español
      'educación': 'educacion',
      'medioambiente': 'medio-ambiente',
      'medio-ambiente': 'medio-ambiente',
      'medio_ambiente': 'medio-ambiente',
      'cambio-climatico': 'clima',
      'cambio_climatico': 'clima',
      'sostenibilidad': 'sostenibilidad',
      'conservación': 'conservacion',
      'ecología': 'ecologia',
      
      // Categorías de tu sistema
      'introduccion': 'educacion',
      'basico': 'educacion',
      'avanzado': 'educacion',
      'beginner': 'educacion',
      'intermediate': 'educacion',
      'advanced': 'educacion',
    };
    
    return mapping[category] ?? category;
  }

  // 🧠 DEDUCIR CATEGORÍA DESDE TEXTO
  static String _deduceCategoryFromText(String text) {
    final keywords = {
      'reciclaje': ['recicl', 'reus', 'residuo', 'basura', 'desecho'],
      'agua': ['agua', 'hidric', 'lluvia', 'rio', 'mar', 'ocean'],
      'energia': ['energia', 'electric', 'solar', 'renov', 'combustible'],
      'clima': ['clima', 'calent', 'temperatura', 'carbon', 'emision'],
      'naturaleza': ['naturaleza', 'bosque', 'arbol', 'plant', 'animal', 'biodiv'],
    };
    
    for (final entry in keywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return 'general';
  }

  // 🔧 HELPERS ROBUSTOS
  static String _extractRequiredString(Map<String, dynamic> json, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        final stringValue = value.toString().trim();
        if (stringValue != 'string' && stringValue != 'null') {
          return stringValue;
        }
      }
    }
    throw Exception('Required string field not found in keys: $possibleKeys');
  }

  static String _extractString(Map<String, dynamic> json, List<String> possibleKeys, {String? fallback}) {
    for (final key in possibleKeys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        final stringValue = value.toString().trim();
        if (stringValue != 'string' && stringValue != 'null') {
          return stringValue;
        }
      }
    }
    return fallback ?? '';
  }

  static String? _extractStringOrNull(Map<String, dynamic> json, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        final stringValue = value.toString().trim();
        if (stringValue != 'string' && stringValue != 'null') {
          return stringValue;
        }
      }
    }
    return null;
  }

  static bool _extractBool(Map<String, dynamic> json, List<String> possibleKeys, {bool fallback = false}) {
    for (final key in possibleKeys) {
      final value = json[key];
      if (value != null) {
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        if (value is int) return value == 1;
      }
    }
    return fallback;
  }

  static DateTime _extractDateTime(Map<String, dynamic> json, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          print('⚠️ [TOPIC MODEL] Error parsing date from $key: $value');
          continue;
        }
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