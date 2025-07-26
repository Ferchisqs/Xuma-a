// lib/features/learning/data/models/content_model.dart - CORREGIDO CON ESTRUCTURA CORRECTA
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/content_entity.dart';
import '../datasources/media_remote_datasource.dart'; // 🔧 IMPORT NECESARIO

part 'content_model.g.dart';

@JsonSerializable()
class ContentModel extends ContentEntity {
  // 🆕 CAMPOS DE MEDIA IDs
  final String? mainMediaId;
  final String? thumbnailMediaId;
  
  // 🆕 CAMPOS DE MEDIA URLs RESUELTOS
  final String? mediaUrl;
  final String? thumbnailUrl;
  
  // 🆕 METADATA DE MEDIA
  final Map<String, dynamic>? mediaMetadata;

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
    // Media fields
    this.mainMediaId,
    this.thumbnailMediaId,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaMetadata,
  }) : super(
          id: id,
          title: title,
          description: description,
          content: content,
          imageUrl: imageUrl ?? thumbnailUrl, // Usar thumbnailUrl como fallback
          category: category,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  // 🆕 FACTORY MEJORADO PARA APIs PROBLEMÁTICAS + MEDIA IDs
  factory ContentModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 [CONTENT MODEL] === PROCESSING CONTENT WITH ENHANCED MEDIA ===');
      print('🔍 [CONTENT MODEL] Raw JSON keys: ${json.keys.toList()}');
      
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
      
      // 5. 🆕 EXTRAER MEDIA IDs CON DETECCIÓN MEJORADA
      final mediaInfo = _extractMediaIds(json);
      print('🔍 [CONTENT MODEL] Media IDs extracted: $mediaInfo');
      
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
        // 🆕 CAMPOS DE MEDIA
        mainMediaId: mediaInfo['mainMediaId'],
        thumbnailMediaId: mediaInfo['thumbnailMediaId'],
        mediaUrl: null, // Se populará cuando se resuelva
        thumbnailUrl: null, // Se populará cuando se resuelva
        mediaMetadata: mediaInfo['metadata'],
      );
      
      print('✅ [CONTENT MODEL] Successfully created content with enhanced media support');
      print('✅ [CONTENT MODEL] - Title: "${contentModel.title}"');
      print('✅ [CONTENT MODEL] - Category: ${contentModel.category}');
      print('✅ [CONTENT MODEL] - Main Media ID: ${contentModel.mainMediaId}');
      print('✅ [CONTENT MODEL] - Thumbnail Media ID: ${contentModel.thumbnailMediaId}');
      print('✅ [CONTENT MODEL] - Has any media: ${contentModel.hasAnyMedia}');
      
      return contentModel;
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT MODEL] CRITICAL ERROR parsing content: $e');
      print('❌ [CONTENT MODEL] Stack trace: $stackTrace');
      print('❌ [CONTENT MODEL] Raw JSON: $json');
      
      return _createFallbackContent(json);
    }
  }

  // 🆕 FACTORY MEJORADO PARA CREAR CONTENT CON MEDIA URLs RESUELTOS
  factory ContentModel.withResolvedMedia({
    required ContentModel originalContent,
    String? resolvedMediaUrl,
    String? resolvedThumbnailUrl,
    Map<String, dynamic>? mediaMetadata,
  }) {
    // Combinar metadata existente con nueva
    final combinedMetadata = <String, dynamic>{
      ...(originalContent.mediaMetadata ?? {}),
      ...(mediaMetadata ?? {}),
      'resolution_timestamp': DateTime.now().toIso8601String(),
    };

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
      mediaMetadata: combinedMetadata,
    );
  }

  // 🆕 MÉTODO PARA RESOLVER MEDIA CON NUEVA API
  Future<ContentModel> resolveMediaWithNewApi(MediaRemoteDataSource mediaDataSource) async {
    if (!hasAnyMedia) return this;
    
    print('🔄 [CONTENT MODEL] Resolving media with new API...');
    
    String? resolvedMediaUrl;
    String? resolvedThumbnailUrl;
    Map<String, dynamic> enhancedMetadata = {};
    
    try {
      // Resolver main media
      if (mainMediaId != null && mainMediaId!.isNotEmpty) {
        print('🔄 [CONTENT MODEL] Resolving main media: $mainMediaId');
        final mainResponse = await mediaDataSource.getFileMediaResponse(mainMediaId!);
        
        if (mainResponse?.isValid == true) {
          resolvedMediaUrl = mainResponse!.finalUrl;
          enhancedMetadata['main_media'] = {
            'url': mainResponse.finalUrl,
            'publicUrl': mainResponse.publicUrl,
            'type': mainResponse.type.toString(),
            'category': mainResponse.category,
            'fileName': mainResponse.finalName,
            'fileSize': mainResponse.finalSize,
            'isProcessed': mainResponse.isProcessed,
            'virusScanStatus': mainResponse.virusScanStatus,
            'mimeType': mainResponse.mimeType,
          };
          
          print('✅ [CONTENT MODEL] Main media resolved: ${mainResponse.finalUrl}');
        } else {
          print('❌ [CONTENT MODEL] Failed to resolve main media');
        }
      }
      
      // Resolver thumbnail media
      if (thumbnailMediaId != null && thumbnailMediaId!.isNotEmpty) {
        print('🔄 [CONTENT MODEL] Resolving thumbnail media: $thumbnailMediaId');
        final thumbResponse = await mediaDataSource.getFileMediaResponse(thumbnailMediaId!);
        
        if (thumbResponse?.isValid == true) {
          resolvedThumbnailUrl = thumbResponse!.finalUrl;
          enhancedMetadata['thumbnail_media'] = {
            'url': thumbResponse.finalUrl,
            'publicUrl': thumbResponse.publicUrl,
            'type': thumbResponse.type.toString(),
            'category': thumbResponse.category,
            'fileName': thumbResponse.finalName,
            'fileSize': thumbResponse.finalSize,
            'isProcessed': thumbResponse.isProcessed,
            'mimeType': thumbResponse.mimeType,
          };
          
          print('✅ [CONTENT MODEL] Thumbnail media resolved: ${thumbResponse.finalUrl}');
        } else {
          print('❌ [CONTENT MODEL] Failed to resolve thumbnail media');
        }
      }
      
      // Crear content con media resuelta
      return ContentModel.withResolvedMedia(
        originalContent: this,
        resolvedMediaUrl: resolvedMediaUrl,
        resolvedThumbnailUrl: resolvedThumbnailUrl,
        mediaMetadata: {
          ...(mediaMetadata ?? {}),
          ...enhancedMetadata,
          'resolution_timestamp': DateTime.now().toIso8601String(),
          'api_version': 'files_api_v2',
        },
      );
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT MODEL] Error resolving media: $e');
      print('❌ [CONTENT MODEL] Stack trace: $stackTrace');
      
      // Retornar el contenido original si hay error
      return this;
    }
  }

  // 🆕 GETTERS MEJORADOS PARA VERIFICAR MEDIA
  bool get hasMainMedia => mainMediaId != null && mainMediaId!.isNotEmpty;
  bool get hasThumbnailMedia => thumbnailMediaId != null && thumbnailMediaId!.isNotEmpty;
  bool get hasAnyMedia => hasMainMedia || hasThumbnailMedia;
  
  // 🆕 GETTERS PARA VERIFICAR MEDIA RESUELTO
  bool get hasResolvedMainMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  bool get hasResolvedThumbnailMedia => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;
  bool get hasAnyResolvedMedia => hasResolvedMainMedia || hasResolvedThumbnailMedia;

  // 🆕 GETTER PARA URL DE IMAGEN FINAL MEJORADO
  String? get finalImageUrl {
    return thumbnailUrl ?? mediaUrl ?? imageUrl;
  }

  // 🆕 GETTERS PARA INFORMACIÓN DE MEDIA DESDE METADATA
  bool get isMainMediaVideo {
    return mediaMetadata?['main_is_video'] == true ||
           mediaMetadata?['main_media_type']?.toString().contains('video') == true ||
           mediaMetadata?['main_media']?['type']?.toString().contains('video') == true;
  }

  bool get isThumbnailImage {
    return mediaMetadata?['thumbnail_is_image'] == true ||
           mediaMetadata?['thumbnail_media_type']?.toString().contains('image') == true ||
           mediaMetadata?['thumbnail_media']?['type']?.toString().contains('image') == true;
  }

  String? get mainMediaType {
    return mediaMetadata?['main_media_type']?.toString() ??
           mediaMetadata?['main_media']?['type']?.toString();
  }

  String? get thumbnailMediaType {
    return mediaMetadata?['thumbnail_media_type']?.toString() ??
           mediaMetadata?['thumbnail_media']?['type']?.toString();
  }

  // 🆕 MÉTODO PARA OBTENER INFORMACIÓN COMPLETA DE MEDIA
  Map<String, dynamic> getMediaInfo() {
    return {
      'hasMainMedia': hasMainMedia,
      'hasThumbnailMedia': hasThumbnailMedia,
      'hasAnyMedia': hasAnyMedia,
      'hasResolvedMainMedia': hasResolvedMainMedia,
      'hasResolvedThumbnailMedia': hasResolvedThumbnailMedia,
      'hasAnyResolvedMedia': hasAnyResolvedMedia,
      'mainMediaId': mainMediaId,
      'thumbnailMediaId': thumbnailMediaId,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'finalImageUrl': finalImageUrl,
      'isMainMediaVideo': isMainMediaVideo,
      'isThumbnailImage': isThumbnailImage,
      'mainMediaType': mainMediaType,
      'thumbnailMediaType': thumbnailMediaType,
      'metadata': mediaMetadata,
    };
  }

  @override
  Map<String, dynamic> toJson() {
    final json = _$ContentModelToJson(this);
    // Agregar campos personalizados que no están en el generador
    json['mainMediaId'] = mainMediaId;
    json['thumbnailMediaId'] = thumbnailMediaId;
    json['mediaUrl'] = mediaUrl;
    json['thumbnailUrl'] = thumbnailUrl;
    json['mediaMetadata'] = mediaMetadata;
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
      mediaMetadata: null,
    );
  }

  // ==================== MÉTODOS HELPER PARA EXTRACCIÓN ====================

  // 🆕 MÉTODO PARA EXTRAER MEDIA IDs MEJORADO
  static Map<String, dynamic> _extractMediaIds(Map<String, dynamic> json) {
    print('🔍 [CONTENT MODEL] === EXTRACTING MEDIA IDs ===');
    
    String? mainMediaId;
    String? thumbnailMediaId;
    final metadata = <String, dynamic>{};
    
    // 🔍 BUSCAR MAIN MEDIA ID
    final mainMediaFields = [
      'main_media_id', 'mainMediaId', 'media_id', 'mediaId',
      'primary_media_id', 'primaryMediaId', 'content_media_id',
      'video_id', 'videoId', 'file_id', 'fileId'
    ];
    
    for (final field in mainMediaFields) {
      final value = _extractStringOrNull(json, [field]);
      if (value != null) {
        mainMediaId = value;
        metadata['main_media_source_field'] = field;
        print('✅ [CONTENT MODEL] Found main media ID in "$field": $value');
        break;
      }
    }
    
    // 🔍 BUSCAR THUMBNAIL MEDIA ID
    final thumbnailMediaFields = [
      'thumbnail_media_id', 'thumbnailMediaId', 'thumb_id', 'thumbId',
      'preview_media_id', 'previewMediaId', 'cover_id', 'coverId',
      'thumbnail_id', 'thumbnailId', 'image_id', 'imageId'
    ];
    
    for (final field in thumbnailMediaFields) {
      final value = _extractStringOrNull(json, [field]);
      if (value != null) {
        thumbnailMediaId = value;
        metadata['thumbnail_media_source_field'] = field;
        print('✅ [CONTENT MODEL] Found thumbnail media ID in "$field": $value');
        break;
      }
    }
    
    // 🔍 BUSCAR EN OBJETOS ANIDADOS
    if ((mainMediaId == null || thumbnailMediaId == null)) {
      final nestedObjects = ['media', 'files', 'attachments', 'resources'];
      
      for (final objKey in nestedObjects) {
        if (json.containsKey(objKey)) {
          final nestedData = json[objKey];
          
          if (nestedData is Map<String, dynamic>) {
            print('🔍 [CONTENT MODEL] Searching in nested object: $objKey');
            
            if (mainMediaId == null) {
              for (final field in mainMediaFields) {
                final value = _extractStringOrNull(nestedData, [field]);
                if (value != null) {
                  mainMediaId = value;
                  metadata['main_media_source_field'] = '$objKey.$field';
                  print('✅ [CONTENT MODEL] Found main media ID in nested "$objKey.$field": $value');
                  break;
                }
              }
            }
            
            if (thumbnailMediaId == null) {
              for (final field in thumbnailMediaFields) {
                final value = _extractStringOrNull(nestedData, [field]);
                if (value != null) {
                  thumbnailMediaId = value;
                  metadata['thumbnail_media_source_field'] = '$objKey.$field';
                  print('✅ [CONTENT MODEL] Found thumbnail media ID in nested "$objKey.$field": $value');
                  break;
                }
              }
            }
          } else if (nestedData is List && nestedData.isNotEmpty) {
            print('🔍 [CONTENT MODEL] Searching in nested list: $objKey');
            
            for (int i = 0; i < nestedData.length; i++) {
              final item = nestedData[i];
              if (item is Map<String, dynamic>) {
                // Para listas, tomar el primer item como main media y el segundo como thumbnail
                if (mainMediaId == null && i == 0) {
                  final id = _extractStringOrNull(item, ['id', 'file_id', 'media_id']);
                  if (id != null) {
                    mainMediaId = id;
                    metadata['main_media_source_field'] = '$objKey[$i].id';
                    print('✅ [CONTENT MODEL] Found main media ID in list "$objKey[$i]": $id');
                  }
                } else if (thumbnailMediaId == null && i == 1) {
                  final id = _extractStringOrNull(item, ['id', 'file_id', 'media_id']);
                  if (id != null) {
                    thumbnailMediaId = id;
                    metadata['thumbnail_media_source_field'] = '$objKey[$i].id';
                    print('✅ [CONTENT MODEL] Found thumbnail media ID in list "$objKey[$i]": $id');
                  }
                }
              }
            }
          }
        }
      }
    }
    
    // 🔍 FALLBACK: Si no encontramos IDs específicos, buscar cualquier ID que parezca media
    if (mainMediaId == null && thumbnailMediaId == null) {
      print('🔍 [CONTENT MODEL] No specific media IDs found, searching for generic media IDs...');
      
      final genericMediaFields = ['id', 'file_id', 'attachment_id', 'resource_id'];
      
      for (final field in genericMediaFields) {
        final value = _extractStringOrNull(json, [field]);
        if (value != null && _looksLikeMediaId(value)) {
          if (mainMediaId == null) {
            mainMediaId = value;
            metadata['main_media_source_field'] = field;
            metadata['main_media_is_generic'] = true;
            print('🔍 [CONTENT MODEL] Using generic ID as main media: $value');
          }
          break;
        }
      }
    }
    
    metadata['extraction_timestamp'] = DateTime.now().toIso8601String();
    
    print('🔍 [CONTENT MODEL] Media extraction complete:');
    print('🔍 [CONTENT MODEL] - Main Media ID: $mainMediaId');
    print('🔍 [CONTENT MODEL] - Thumbnail Media ID: $thumbnailMediaId');
    print('🔍 [CONTENT MODEL] - Metadata: $metadata');
    
    return {
      'mainMediaId': mainMediaId,
      'thumbnailMediaId': thumbnailMediaId,
      'metadata': metadata,
    };
  }

  // 🔧 VERIFICAR SI UN ID PARECE SER DE MEDIA
  static bool _looksLikeMediaId(String id) {
    // UUIDs, hashes largos, etc.
    return id.length > 16 && 
           (id.contains('-') || // UUID format
            RegExp(r'^[a-fA-F0-9]+$').hasMatch(id)); // Hex hash
  }

  // 🔧 CREAR CONTENIDO FALLBACK
  static ContentModel _createFallbackContent(Map<String, dynamic> json) {
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
        mediaMetadata: {'fallback': true},
      );
    } catch (fallbackError) {
      print('❌ [CONTENT MODEL] Even fallback failed: $fallbackError');
      rethrow;
    }
  }

  // ==================== MÉTODOS HELPER REUTILIZADOS ====================
  
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