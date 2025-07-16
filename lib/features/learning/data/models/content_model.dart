// lib/features/learning/data/models/content_model.dart - SUPER ROBUSTO PARA API PROBLEMÁTICA
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/content_entity.dart';

part 'content_model.g.dart';

@JsonSerializable()
class ContentModel extends ContentEntity {
  const ContentModel({
    required String id,
    required String title,
    required String description,
    required String content,
    String? imageUrl,
    required String category,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          title: title,
          description: description,
          content: content,
          imageUrl: imageUrl,
          category: category,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  // 🔧 FACTORY ULTRA ROBUSTO PARA APIs PROBLEMÁTICAS
  factory ContentModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 [CONTENT MODEL] === PROCESSING CONTENT ===');
      print('🔍 [CONTENT MODEL] Raw JSON: $json');
      print('🔍 [CONTENT MODEL] JSON keys: ${json.keys.toList()}');
      
      // 1. EXTRAER ID (OBLIGATORIO)
      final id = _extractRequiredString(json, ['id', '_id', 'contentId', 'content_id']);
      print('🔍 [CONTENT MODEL] Extracted ID: $id');
      
      // 2. EXTRAER TÍTULO/NOMBRE
      final title = _extractString(json, ['name', 'title', 'content_name', 'heading'], fallback: 'Contenido sin título');
      print('🔍 [CONTENT MODEL] Extracted title: $title');
      
      // 3. EXTRAER DESCRIPCIÓN
      final description = _extractString(json, ['description', 'desc', 'summary', 'excerpt'], fallback: 'Sin descripción disponible');
      
      // 4. EXTRAER CONTENIDO PRINCIPAL
      final content = _extractContent(json, description);
      print('🔍 [CONTENT MODEL] Extracted content length: ${content.length} chars');
      
      // 5. EXTRAER URL DE IMAGEN
      final imageUrl = _extractStringOrNull(json, ['icon_url', 'image_url', 'imageUrl', 'thumbnail', 'image', 'media_url']);
      
      // 6. EXTRAER CATEGORÍA - HEREDAR DEL TOPIC SI ES POSIBLE
      final category = _extractCategoryFromContent(json);
      print('🔍 [CONTENT MODEL] Extracted category: $category');
      
      // 7. EXTRAER ESTADO ACTIVO
      final isActive = _extractBool(json, ['is_active', 'active', 'enabled', 'published', 'is_published'], fallback: true);
      
      // 8. EXTRAER FECHAS
      final createdAt = _extractDateTime(json, ['created_at', 'createdAt', 'date_created', 'published_at']);
      final updatedAt = _extractDateTime(json, ['updated_at', 'updatedAt', 'date_updated', 'modified_at']);
      
      final contentModel = ContentModel(
        id: id,
        title: title,
        description: description,
        content: content,
        imageUrl: imageUrl,
        category: category,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      print('✅ [CONTENT MODEL] Successfully created content: "${contentModel.title}" (Category: ${contentModel.category})');
      return contentModel;
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT MODEL] CRITICAL ERROR parsing content: $e');
      print('❌ [CONTENT MODEL] Stack trace: $stackTrace');
      print('❌ [CONTENT MODEL] Raw JSON: $json');
      
      // 🆘 FALLBACK ULTRA ROBUSTO
      print('🆘 [CONTENT MODEL] Creating fallback content...');
      
      try {
        return ContentModel(
          id: json['id']?.toString() ?? 'fallback_${DateTime.now().millisecondsSinceEpoch}',
          title: json['name']?.toString() ?? json['title']?.toString() ?? 'Contenido educativo',
          description: json['description']?.toString() ?? 'Contenido sobre medio ambiente y sostenibilidad',
          content: _createDefaultContent(json),
          imageUrl: null,
          category: 'educacion',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        );
      } catch (fallbackError) {
        print('❌ [CONTENT MODEL] Even fallback failed: $fallbackError');
        rethrow;
      }
    }
  }

  // 🔧 EXTRACTOR DE CONTENIDO ROBUSTO
  static String _extractContent(Map<String, dynamic> json, String description) {
    final contentFields = [
      'content', 'body', 'text', 'article_content', 
      'full_text', 'detailed_content', 'lesson_content',
      'html_content', 'markdown_content'
    ];
    
    for (final field in contentFields) {
      final value = json[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        final stringValue = value.toString().trim();
        if (stringValue != 'string' && stringValue != 'null' && stringValue.length > 10) {
          return stringValue;
        }
      }
    }
    
    // Si no hay contenido específico, usar descripción expandida
    if (description.isNotEmpty && description != 'Sin descripción disponible') {
      return _expandDescription(description, json);
    }
    
    // Contenido por defecto basado en el JSON disponible
    return _createDefaultContent(json);
  }

  // 🔧 EXPANDIR DESCRIPCIÓN A CONTENIDO COMPLETO
  static String _expandDescription(String description, Map<String, dynamic> json) {
    final title = json['name']?.toString() ?? json['title']?.toString() ?? 'Tema de aprendizaje';
    
    return '''
# $title

## Descripción
$description

## Información importante
Este contenido forma parte del programa educativo de XUMA'A para el cuidado del medio ambiente.

### Objetivos de aprendizaje:
• Comprender los conceptos fundamentales
• Aplicar el conocimiento en la vida diaria
• Contribuir al cuidado del planeta
• Desarrollar hábitos sostenibles

### ¿Por qué es importante?
Cada pequeña acción cuenta para proteger nuestro planeta. Al aprender sobre estos temas, te conviertes en parte de la solución para un futuro más sostenible.

¡Aprende con Xico y marca la diferencia! 🌱
    ''';
  }

  // 🔧 CREAR CONTENIDO POR DEFECTO
  static String _createDefaultContent(Map<String, dynamic> json) {
    final title = json['name']?.toString() ?? json['title']?.toString() ?? 'Contenido educativo';
    final category = _extractCategoryFromContent(json);
    
    return '''
# $title

## Bienvenido a este contenido educativo

Este es un tema importante sobre **$category** que te ayudará a comprender mejor cómo cuidar nuestro medio ambiente.

### Lo que aprenderás:
- Conceptos fundamentales sobre el tema
- Acciones prácticas que puedes implementar
- Cómo contribuir al cuidado del planeta
- Tips y recomendaciones útiles

### ¿Sabías que...?
Cada persona puede hacer una diferencia significativa en el cuidado del medio ambiente con pequeñas acciones diarias.

### Mensaje de Xico 🐆
"Proteger el medio ambiente es proteger nuestro futuro. ¡Cada acción cuenta!"

---
*Contenido generado por XUMA'A - Tu compañero en el cuidado del medio ambiente*
    ''';
  }

  // 🔧 EXTRACTOR DE CATEGORÍA ESPECÍFICO PARA CONTENIDO
  static String _extractCategoryFromContent(Map<String, dynamic> json) {
    print('🔍 [CONTENT MODEL] === EXTRACTING CATEGORY FROM CONTENT ===');
    
    // 1. Buscar categoría directa en el contenido
    final categoryFields = [
      'category', 'categoria', 'type', 'content_type',
      'subject', 'topic', 'area', 'classification'
    ];
    
    for (final field in categoryFields) {
      final value = json[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        final stringValue = value.toString().trim().toLowerCase();
        if (stringValue != 'string' && stringValue != 'null') {
          final mapped = _mapContentCategory(stringValue);
          print('✅ [CONTENT MODEL] Found direct category: $stringValue -> $mapped');
          return mapped;
        }
      }
    }
    
    // 2. Buscar en relaciones de topic (contentTopics, primaryTopic)
    if (json.containsKey('contentTopics')) {
      final contentTopics = json['contentTopics'];
      if (contentTopics is List && contentTopics.isNotEmpty) {
        final firstTopic = contentTopics[0];
        if (firstTopic is Map<String, dynamic>) {
          print('🔍 [CONTENT MODEL] Checking contentTopics...');
          return _extractCategoryFromContent(firstTopic);
        }
      }
    }
    
    if (json.containsKey('primaryTopic')) {
      final primaryTopic = json['primaryTopic'];
      if (primaryTopic is Map<String, dynamic>) {
        print('🔍 [CONTENT MODEL] Checking primaryTopic...');
        return _extractCategoryFromContent(primaryTopic);
      }
    }
    
    // 3. Buscar por topic_id para hacer inferencia
    if (json.containsKey('topic_id')) {
      final topicId = json['topic_id'].toString();
      final inferredCategory = _inferCategoryFromTopicId(topicId);
      if (inferredCategory != 'general') {
        print('🧠 [CONTENT MODEL] Inferred category from topic_id: $inferredCategory');
        return inferredCategory;
      }
    }
    
    // 4. Deducir de título o descripción
    final title = (json['name'] ?? json['title'] ?? '').toString().toLowerCase();
    final description = (json['description'] ?? '').toString().toLowerCase();
    final textCategory = _deduceCategoryFromText('$title $description');
    
    if (textCategory != 'general') {
      print('🧠 [CONTENT MODEL] Deduced category from text: $textCategory');
      return textCategory;
    }
    
    print('⚠️ [CONTENT MODEL] No category found, using default: educacion');
    return 'educacion';
  }

  // 🗺️ MAPEAR CATEGORÍAS DE CONTENIDO
  static String _mapContentCategory(String category) {
    final mapping = {
      // Tipos de contenido
      'article': 'educacion',
      'video': 'multimedia',
      'interactive': 'interactivo',
      'lesson': 'educacion',
      'tutorial': 'educacion',
      'guide': 'educacion',
      
      // Categorías temáticas
      'environment': 'medio-ambiente',
      'climate': 'clima',
      'recycling': 'reciclaje',
      'energy': 'energia',
      'water': 'agua',
      'nature': 'naturaleza',
      'conservation': 'conservacion',
      'sustainability': 'sostenibilidad',
      
      // En español
      'educacion': 'educacion',
      'medio-ambiente': 'medio-ambiente',
      'medioambiente': 'medio-ambiente',
      'reciclaje': 'reciclaje',
      'energia': 'energia',
      'agua': 'agua',
      'naturaleza': 'naturaleza',
      'conservacion': 'conservacion',
      'sostenibilidad': 'sostenibilidad',
    };
    
    return mapping[category] ?? category;
  }

  // 🔍 INFERIR CATEGORÍA DESDE TOPIC ID
  static String _inferCategoryFromTopicId(String topicId) {
    // Patrones comunes en IDs de topics
    final patterns = {
      'recicl': 'reciclaje',
      'water': 'agua',
      'agua': 'agua',
      'energy': 'energia',
      'energia': 'energia',
      'climate': 'clima',
      'clima': 'clima',
      'nature': 'naturaleza',
      'natura': 'naturaleza',
      'conserv': 'conservacion',
      'sustain': 'sostenibilidad',
      'environ': 'medio-ambiente',
    };
    
    final lowerTopicId = topicId.toLowerCase();
    
    for (final entry in patterns.entries) {
      if (lowerTopicId.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 'general';
  }

  // 🧠 DEDUCIR CATEGORÍA DESDE TEXTO
  static String _deduceCategoryFromText(String text) {
    final keywords = {
      'reciclaje': ['recicl', 'reus', 'residuo', 'basura', 'desecho', 'waste'],
      'agua': ['agua', 'water', 'hidric', 'lluvia', 'rio', 'mar', 'ocean'],
      'energia': ['energia', 'energy', 'electric', 'solar', 'renov', 'combustible'],
      'clima': ['clima', 'climate', 'calent', 'temperatura', 'carbon', 'emision'],
      'naturaleza': ['naturaleza', 'nature', 'bosque', 'forest', 'arbol', 'tree', 'plant', 'animal', 'biodiv'],
      'conservacion': ['conserv', 'protect', 'preserve', 'mantener', 'cuidar'],
      'sostenibilidad': ['sustain', 'sostenib', 'ecologic', 'verde', 'green'],
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

  // 🔧 HELPERS ROBUSTOS REUTILIZADOS
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
          print('⚠️ [CONTENT MODEL] Error parsing date from $key: $value');
          continue;
        }
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => _$ContentModelToJson(this);

  factory ContentModel.fromEntity(ContentEntity entity) {
    return ContentModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      content: entity.content,
      imageUrl: entity.imageUrl,
      category: entity.category,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}