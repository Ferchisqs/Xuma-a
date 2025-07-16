// lib/features/learning/data/models/content_model.dart - CON MEDIA IDs
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/content_entity.dart';

part 'content_model.g.dart';

@JsonSerializable()
class ContentModel extends ContentEntity {
  // 🆕 CAMPOS DE MEDIA
  final String? mainMediaId;
  final String? thumbnailMediaId;
  final String? mediaUrl; // URL resuelto del main_media
  final String? thumbnailUrl; // URL resuelto del thumbnail_media

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
    // 🆕 NUEVOS CAMPOS
    this.mainMediaId,
    this.thumbnailMediaId,
    this.mediaUrl,
    this.thumbnailUrl,
  }) : super(
          id: id,
          title: title,
          description: description,
          content: content,
          imageUrl: imageUrl ?? thumbnailUrl, // 🔧 Usar thumbnailUrl como fallback
          category: category,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  // 🔧 FACTORY ULTRA ROBUSTO PARA APIs PROBLEMÁTICAS + MEDIA IDs
  factory ContentModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 [CONTENT MODEL] === PROCESSING CONTENT WITH MEDIA ===');
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
      
      // 5. 🆕 EXTRAER MEDIA IDs
      final mainMediaId = _extractStringOrNull(json, ['main_media_id', 'mainMediaId', 'media_id']);
      final thumbnailMediaId = _extractStringOrNull(json, ['thumbnail_media_id', 'thumbnailMediaId', 'thumb_id']);
      print('🔍 [CONTENT MODEL] Media IDs - Main: $mainMediaId, Thumbnail: $thumbnailMediaId');
      
      // 6. EXTRAER URL DE IMAGEN (fallback tradicional)
      final imageUrl = _extractStringOrNull(json, ['icon_url', 'image_url', 'imageUrl', 'thumbnail', 'image', 'media_url']);
      
      // 7. EXTRAER CATEGORÍA
      final category = _extractCategoryFromContent(json);
      print('🔍 [CONTENT MODEL] Extracted category: $category');
      
      // 8. EXTRAER ESTADO ACTIVO
      final isActive = _extractBool(json, ['is_active', 'active', 'enabled', 'published', 'is_published'], fallback: true);
      
      // 9. EXTRAER FECHAS
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
        // 🆕 NUEVOS CAMPOS DE MEDIA
        mainMediaId: mainMediaId,
        thumbnailMediaId: thumbnailMediaId,
        mediaUrl: null, // Se poblará por separado si se busca en API de media
        thumbnailUrl: null, // Se poblará por separado si se busca en API de media
      );
      
      print('✅ [CONTENT MODEL] Successfully created content: "${contentModel.title}" (Category: ${contentModel.category})');
      print('✅ [CONTENT MODEL] Media info - Main ID: ${contentModel.mainMediaId}, Thumbnail ID: ${contentModel.thumbnailMediaId}');
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
          // Fallback sin media IDs
          mainMediaId: null,
          thumbnailMediaId: null,
          mediaUrl: null,
          thumbnailUrl: null,
        );
      } catch (fallbackError) {
        print('❌ [CONTENT MODEL] Even fallback failed: $fallbackError');
        rethrow;
      }
    }
  }

  // 🆕 FACTORY PARA CREAR CONTENT CON MEDIA URLs RESUELTOS
  factory ContentModel.withResolvedMedia({
    required ContentModel originalContent,
    String? resolvedMediaUrl,
    String? resolvedThumbnailUrl,
  }) {
    return ContentModel(
      id: originalContent.id,
      title: originalContent.title,
      description: originalContent.description,
      content: originalContent.content,
      imageUrl: resolvedThumbnailUrl ?? originalContent.imageUrl,
      category: originalContent.category,
      isActive: originalContent.isActive,
      createdAt: originalContent.createdAt,
      updatedAt: originalContent.updatedAt,
      mainMediaId: originalContent.mainMediaId,
      thumbnailMediaId: originalContent.thumbnailMediaId,
      mediaUrl: resolvedMediaUrl,
      thumbnailUrl: resolvedThumbnailUrl,
    );
  }

  // 🆕 GETTERS PARA VERIFICAR SI TIENE MEDIA IDs
  bool get hasMainMedia => mainMediaId != null && mainMediaId!.isNotEmpty;
  bool get hasThumbnailMedia => thumbnailMediaId != null && thumbnailMediaId!.isNotEmpty;
  bool get hasAnyMedia => hasMainMedia || hasThumbnailMedia;

  // 🆕 GETTER PARA URL DE IMAGEN FINAL
  String? get finalImageUrl {
    return thumbnailUrl ?? mediaUrl ?? imageUrl;
  }

  // [RESTO DE MÉTODOS IGUALES - SOLO AGREGO LOS NUEVOS CAMPOS AL toJson]

  @override
  Map<String, dynamic> toJson() {
    final json = _$ContentModelToJson(this);
    // Agregar campos personalizados que no están en el generador
    json['mainMediaId'] = mainMediaId;
    json['thumbnailMediaId'] = thumbnailMediaId;
    json['mediaUrl'] = mediaUrl;
    json['thumbnailUrl'] = thumbnailUrl;
    return json;
  }

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
      // Sin media IDs cuando se crea desde entity
      mainMediaId: null,
      thumbnailMediaId: null,
      mediaUrl: null,
      thumbnailUrl: null,
    );
  }

  // === MÉTODOS HELPER REUTILIZADOS (IGUALES QUE ANTES) ===
  
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
    
    if (description.isNotEmpty && description != 'Sin descripción disponible') {
      return _expandDescription(description, json);
    }
    
    return _createDefaultContent(json);
  }

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

  static String _extractCategoryFromContent(Map<String, dynamic> json) {
    print('🔍 [CONTENT MODEL] === EXTRACTING CATEGORY FROM CONTENT ===');
    
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
    
    // Buscar en relaciones de topic
    if (json.containsKey('contentTopics')) {
      final contentTopics = json['contentTopics'];
      if (contentTopics is List && contentTopics.isNotEmpty) {
        final firstTopic = contentTopics[0];
        if (firstTopic is Map<String, dynamic>) {
          return _extractCategoryFromContent(firstTopic);
        }
      }
    }
    
    if (json.containsKey('primaryTopic')) {
      final primaryTopic = json['primaryTopic'];
      if (primaryTopic is Map<String, dynamic>) {
        return _extractCategoryFromContent(primaryTopic);
      }
    }
    
    // Buscar por topic_id para hacer inferencia
    if (json.containsKey('topic_id')) {
      final topicId = json['topic_id'].toString();
      final inferredCategory = _inferCategoryFromTopicId(topicId);
      if (inferredCategory != 'general') {
        return inferredCategory;
      }
    }
    
    // Deducir de título o descripción
    final title = (json['name'] ?? json['title'] ?? '').toString().toLowerCase();
    final description = (json['description'] ?? '').toString().toLowerCase();
    final textCategory = _deduceCategoryFromText('$title $description');
    
    if (textCategory != 'general') {
      return textCategory;
    }
    
    return 'educacion';
  }

  static String _mapContentCategory(String category) {
    final mapping = {
      'article': 'educacion',
      'video': 'multimedia',
      'interactive': 'interactivo',
      'lesson': 'educacion',
      'tutorial': 'educacion',
      'guide': 'educacion',
      'environment': 'medio-ambiente',
      'climate': 'clima',
      'recycling': 'reciclaje',
      'energy': 'energia',
      'water': 'agua',
      'nature': 'naturaleza',
      'conservation': 'conservacion',
      'sustainability': 'sostenibilidad',
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

  static String _inferCategoryFromTopicId(String topicId) {
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
          continue;
        }
      }
    }
    return DateTime.now();
  }
}