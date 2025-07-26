// lib/features/learning/data/datasources/content_remote_datasource.dart - MEJORADO PARA MEDIA API
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/topic_model.dart';
import '../models/content_model.dart';
import 'media_remote_datasource.dart';

abstract class ContentRemoteDataSource {
  Future<List<TopicModel>> getTopics();
  Future<ContentModel> getContentById(String id);
  Future<List<ContentModel>> getContentsByTopicId(String topicId, int page, int limit);
}

@Injectable(as: ContentRemoteDataSource)
class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final ApiClient apiClient;
  final MediaRemoteDataSource mediaDataSource;

  ContentRemoteDataSourceImpl(this.apiClient, this.mediaDataSource);

  @override
  Future<List<TopicModel>> getTopics() async {
    try {
      print('🌐 [CONTENT API] === FETCHING TOPICS ===');
      print('🌐 [CONTENT API] URL: ${ApiEndpoints.getContentUrl('/api/content/topics')}');
      
      final response = await apiClient.getContent('/api/content/topics');
      
      print('🌐 [CONTENT API] Response Status: ${response.statusCode}');
      
      List<dynamic> topicsJson = _extractTopicsFromResponse(response.data);
      
      print('🔍 [CONTENT API] Found ${topicsJson.length} raw topics to process');
      
      if (topicsJson.isEmpty) {
        print('⚠️ [CONTENT API] No topics found in response, creating mock data');
        return _createMockTopics();
      }
      
      final topics = <TopicModel>[];
      
      for (int i = 0; i < topicsJson.length; i++) {
        try {
          final rawTopic = topicsJson[i];
          if (rawTopic is! Map<String, dynamic>) {
            print('⚠️ [CONTENT API] Topic $i is not a Map: ${rawTopic.runtimeType}');
            continue;
          }
          
          final topicJson = rawTopic as Map<String, dynamic>;
          final topic = TopicModel.fromJson(topicJson);
          topics.add(topic);
          
          print('✅ [CONTENT API] Successfully parsed topic ${i + 1}: "${topic.title}"');
          
        } catch (e, stackTrace) {
          print('❌ [CONTENT API] Failed to parse topic $i: $e');
          
          try {
            final fallbackTopic = _createFallbackTopic(i, topicsJson[i]);
            topics.add(fallbackTopic);
            print('🆘 [CONTENT API] Created fallback topic for index $i');
          } catch (fallbackError) {
            print('❌ [CONTENT API] Even fallback failed for topic $i: $fallbackError');
          }
        }
      }
      
      print('🎉 [CONTENT API] Successfully processed: ${topics.length}/${topicsJson.length} topics');
      
      if (topics.isEmpty) {
        return _createMockTopics();
      }
      
      return topics;
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT API] === CRITICAL ERROR FETCHING TOPICS ===');
      print('❌ [CONTENT API] Error: $e');
      return _createMockTopics();
    }
  }

  @override
  Future<ContentModel> getContentById(String id) async {
    try {
      print('🌐 [CONTENT API] === FETCHING CONTENT BY ID WITH ENHANCED MEDIA ===');
      print('🌐 [CONTENT API] Content ID: $id');
      
      final response = await apiClient.getContent('/api/content/$id');
      
      print('🌐 [CONTENT API] Response Status: ${response.statusCode}');
      
      Map<String, dynamic> contentJson = _extractContentFromResponse(response.data);
      
      print('🔍 [CONTENT API] Content keys: ${contentJson.keys.toList()}');
      
      final content = ContentModel.fromJson(contentJson);
      
      print('✅ [CONTENT API] Successfully parsed content: "${content.title}"');
      
      // 🔧 RESOLVER MEDIA URLS CON DETECCIÓN MEJORADA
      if (content.hasAnyMedia) {
        print('🎬 [CONTENT API] Content has media, resolving URLs with enhanced detection...');
        print('🎬 [CONTENT API] Main Media ID: ${content.mainMediaId}');
        print('🎬 [CONTENT API] Thumbnail Media ID: ${content.thumbnailMediaId}');
        
        return await _resolveContentMedia(content);
      } else {
        print('ℹ️ [CONTENT API] Content has no media IDs to resolve');
        return content;
      }
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT API] === ERROR FETCHING CONTENT BY ID ===');
      print('❌ [CONTENT API] Content ID: $id');
      print('❌ [CONTENT API] Error: $e');
      
      return _createMockContent(id);
    }
  }

  @override
  Future<List<ContentModel>> getContentsByTopicId(String topicId, int page, int limit) async {
    try {
      print('🌐 [CONTENT API] === FETCHING CONTENTS BY TOPIC WITH MEDIA ===');
      print('🌐 [CONTENT API] Topic ID: $topicId, Page: $page, Limit: $limit');
      
      final endpoint = '/api/content/by-topic/$topicId?page=$page&limit=$limit';
      final response = await apiClient.getContent(endpoint);
      
      print('🌐 [CONTENT API] Response Status: ${response.statusCode}');
      
      List<dynamic> contentsJson = _extractContentsFromResponse(response.data);
      
      print('🔍 [CONTENT API] Found ${contentsJson.length} raw contents to process');
      
      if (contentsJson.isEmpty) {
        print('⚠️ [CONTENT API] No contents found, creating mock data for topic: $topicId');
        return _createMockContentsForTopic(topicId);
      }
      
      final contents = <ContentModel>[];
      
      for (int i = 0; i < contentsJson.length; i++) {
        try {
          final rawContent = contentsJson[i];
          if (rawContent is! Map<String, dynamic>) {
            print('⚠️ [CONTENT API] Content $i is not a Map, skipping');
            continue;
          }
          
          final contentJson = rawContent as Map<String, dynamic>;
          print('🔍 [CONTENT API] Processing content $i: ${contentJson['name'] ?? 'NO_NAME'}');
          
          final content = ContentModel.fromJson(contentJson);
          
          // 🔧 RESOLVER MEDIA PARA CADA CONTENIDO CON OPTIMIZACIÓN
          ContentModel finalContent;
          if (content.hasAnyMedia) {
            print('🎬 [CONTENT API] Content $i has media, resolving...');
            finalContent = await _resolveContentMediaOptimized(content, isList: true);
          } else {
            finalContent = content;
          }
          
          contents.add(finalContent);
          
          print('✅ [CONTENT API] Successfully processed content $i: "${finalContent.title}"');
          
        } catch (e) {
          print('❌ [CONTENT API] Failed to parse content $i: $e');
          
          try {
            final fallbackContent = _createFallbackContent(i, topicId, contentsJson[i]);
            contents.add(fallbackContent);
            print('🆘 [CONTENT API] Created fallback content for index $i');
          } catch (fallbackError) {
            print('❌ [CONTENT API] Even fallback failed for content $i');
          }
        }
      }
      
      print('🎉 [CONTENT API] Successfully processed: ${contents.length}/${contentsJson.length} contents');
      
      if (contents.isEmpty) {
        return _createMockContentsForTopic(topicId);
      }
      
      return contents;
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT API] === CRITICAL ERROR FETCHING CONTENTS BY TOPIC ===');
      print('❌ [CONTENT API] Topic ID: $topicId');
      print('❌ [CONTENT API] Error: $e');
      
      return _createMockContentsForTopic(topicId);
    }
  }

  // ==================== MÉTODOS DE RESOLUCIÓN DE MEDIA MEJORADOS ====================

  /// Resolver media para un contenido individual (completo)
  Future<ContentModel> _resolveContentMedia(ContentModel content) async {
    try {
      print('🎬 [CONTENT API] === RESOLVING CONTENT MEDIA ===');
      print('🎬 [CONTENT API] Content: ${content.title}');
      print('🎬 [CONTENT API] Main Media ID: ${content.mainMediaId}');
      print('🎬 [CONTENT API] Thumbnail Media ID: ${content.thumbnailMediaId}');
      
      String? resolvedMediaUrl;
      String? resolvedThumbnailUrl;
      MediaResponse? mainMediaResponse;
      MediaResponse? thumbnailMediaResponse;
      
      // Resolver main media si existe
      if (content.mainMediaId != null && content.mainMediaId!.isNotEmpty) {
        print('🎬 [CONTENT API] Resolving main media...');
        mainMediaResponse = await mediaDataSource.getMediaResponse(content.mainMediaId!);
        resolvedMediaUrl = mainMediaResponse?.url;
        
        if (mainMediaResponse != null) {
          print('✅ [CONTENT API] Main media resolved: ${mainMediaResponse.isValid ? "✅" : "❌"}');
          print('✅ [CONTENT API] Main media type: ${mainMediaResponse.type}');
          print('✅ [CONTENT API] Main media MIME: ${mainMediaResponse.mimeType}');
          print('✅ [CONTENT API] Main media file type: ${mainMediaResponse.fileType}');
        } else {
          print('❌ [CONTENT API] Failed to resolve main media');
        }
      }
      
      // Resolver thumbnail si existe
      if (content.thumbnailMediaId != null && content.thumbnailMediaId!.isNotEmpty) {
        print('🎬 [CONTENT API] Resolving thumbnail media...');
        thumbnailMediaResponse = await mediaDataSource.getMediaResponse(content.thumbnailMediaId!);
        resolvedThumbnailUrl = thumbnailMediaResponse?.url;
        
        if (thumbnailMediaResponse != null) {
          print('✅ [CONTENT API] Thumbnail resolved: ${thumbnailMediaResponse.isValid ? "✅" : "❌"}');
          print('✅ [CONTENT API] Thumbnail type: ${thumbnailMediaResponse.type}');
        } else {
          print('❌ [CONTENT API] Failed to resolve thumbnail media');
        }
      }
      
      // Crear content con URLs resueltos y metadata adicional
      final resolvedContent = ContentModel.withResolvedMedia(
        originalContent: content,
        resolvedMediaUrl: resolvedMediaUrl,
        resolvedThumbnailUrl: resolvedThumbnailUrl,
        mediaMetadata: {
          'main_media_response': mainMediaResponse?.toString(),
          'thumbnail_media_response': thumbnailMediaResponse?.toString(),
          'main_media_type': mainMediaResponse?.type.toString(),
          'thumbnail_media_type': thumbnailMediaResponse?.type.toString(),
          'main_is_video': mainMediaResponse?.isVideo ?? false,
          'thumbnail_is_image': thumbnailMediaResponse?.isImage ?? false,
        },
      );
      
      print('🎬 [CONTENT API] Media resolution complete');
      print('🎬 [CONTENT API] Final main URL: ${resolvedContent.mediaUrl != null ? "✅ Available" : "❌ Not available"}');
      print('🎬 [CONTENT API] Final thumbnail URL: ${resolvedContent.thumbnailUrl != null ? "✅ Available" : "❌ Not available"}');
      
      return resolvedContent;
      
    } catch (mediaError) {
      print('⚠️ [CONTENT API] Failed to resolve media: $mediaError');
      return content;
    }
  }

  Future<ContentModel> _resolveContentMediaEnhanced(ContentModel content) async {
  try {
    print('🎬 [CONTENT API] === RESOLVING CONTENT MEDIA WITH NEW API ===');
    print('🎬 [CONTENT API] Content: ${content.title}');
    
    if (!content.hasAnyMedia) {
      print('ℹ️ [CONTENT API] No media to resolve');
      return content;
    }
    
    // Usar el nuevo método del ContentModel
    final resolvedContent = await content.resolveMediaWithNewApi(mediaDataSource);
    
    print('🎬 [CONTENT API] Media resolution complete');
    print('🎬 [CONTENT API] Main URL resolved: ${resolvedContent.mediaUrl != null ? "✅" : "❌"}');
    print('🎬 [CONTENT API] Thumbnail URL resolved: ${resolvedContent.thumbnailUrl != null ? "✅" : "❌"}');
    
    return resolvedContent;
    
  } catch (e, stackTrace) {
    print('❌ [CONTENT API] Error in enhanced media resolution: $e');
    print('❌ [CONTENT API] Stack trace: $stackTrace');
    return content;
  }
}

  /// Resolver media optimizado para listas (solo thumbnails por defecto)
  Future<ContentModel> _resolveContentMediaOptimized(ContentModel content, {bool isList = false}) async {
    try {
      if (isList) {
        // Para listas, solo resolver thumbnail para mejor rendimiento
        print('🎬 [CONTENT API] Resolving thumbnail for list item: ${content.title}');
        
        if (content.thumbnailMediaId != null && content.thumbnailMediaId!.isNotEmpty) {
          final thumbnailResponse = await mediaDataSource.getMediaResponse(content.thumbnailMediaId!);
          
          return ContentModel.withResolvedMedia(
            originalContent: content,
            resolvedMediaUrl: null, // No resolver main media en listas
            resolvedThumbnailUrl: thumbnailResponse?.url,
          );
        }
        
        return content;
      } else {
        // Para vista individual, resolver todo
        return await _resolveContentMedia(content);
      }
    } catch (e) {
      print('⚠️ [CONTENT API] Failed to resolve optimized media: $e');
      return content;
    }
  }

  // ==================== MÉTODOS HELPER EXISTENTES ====================

  List<dynamic> _extractTopicsFromResponse(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }
    
    if (responseData is Map<String, dynamic>) {
      for (final key in ['data', 'topics', 'results', 'items']) {
        if (responseData.containsKey(key) && responseData[key] is List) {
          return responseData[key] as List<dynamic>;
        }
      }
      return [responseData];
    }
    
    return [];
  }

  Map<String, dynamic> _extractContentFromResponse(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') && responseData['data'] is Map) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return responseData;
    }
    
    throw ServerException('Invalid content response format');
  }

  List<dynamic> _extractContentsFromResponse(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }
    
    if (responseData is Map<String, dynamic>) {
      for (final key in ['data', 'contents', 'results', 'items']) {
        if (responseData.containsKey(key) && responseData[key] is List) {
          return responseData[key] as List<dynamic>;
        }
      }
      return [responseData];
    }
    
    return [];
  }

  // ==================== MOCK DATA METHODS ====================

  List<TopicModel> _createMockTopics() {
    return [
      TopicModel(
        id: 'topic_recic_001',
        title: 'Introducción al Reciclaje',
        description: 'Aprende los conceptos básicos del reciclaje y su importancia para el medio ambiente.',
        category: 'reciclaje',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TopicModel(
        id: 'topic_agua_001',
        title: 'Cuidado del Agua',
        description: 'Descubre cómo conservar este recurso vital para nuestro planeta.',
        category: 'agua',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TopicModel(
        id: 'topic_energia_001',
        title: 'Energía Sostenible',
        description: 'Conoce las fuentes de energía renovable y cómo usarlas.',
        category: 'energia',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  ContentModel _createMockContent(String id) {
    return ContentModel(
      id: id,
      title: 'Contenido Educativo',
      description: 'Este es contenido educativo sobre medio ambiente y sostenibilidad.',
      content: '''
# Contenido Educativo

## Bienvenido a XUMA'A

Este contenido te ayudará a aprender sobre la importancia del cuidado del medio ambiente.

### Puntos importantes:
- Reduce, reutiliza y recicla
- Cuida el agua
- Usa energía renovable
- Protege la biodiversidad

¡Cada acción cuenta para proteger nuestro planeta! 🌱
      ''',
      category: 'educacion',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    );
  }

  List<ContentModel> _createMockContentsForTopic(String topicId) {
    final categoryMap = {
      'topic_recic': 'reciclaje',
      'topic_agua': 'agua',
      'topic_energia': 'energia',
    };
    
    final category = categoryMap.entries
        .firstWhere(
          (entry) => topicId.contains(entry.key),
          orElse: () => const MapEntry('default', 'educacion'),
        )
        .value;
    
    return [
      ContentModel(
        id: '${topicId}_content_001',
        title: 'Conceptos Básicos',
        description: 'Introducción a los conceptos fundamentales del tema.',
        content: 'Contenido educativo sobre los conceptos básicos...',
        category: category,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      ContentModel(
        id: '${topicId}_content_002',
        title: 'Aplicación Práctica',
        description: 'Cómo aplicar estos conocimientos en la vida diaria.',
        content: 'Aprende a aplicar estos conceptos en tu día a día...',
        category: category,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  TopicModel _createFallbackTopic(int index, dynamic rawData) {
    final id = rawData is Map ? (rawData['id']?.toString() ?? 'fallback_topic_$index') : 'fallback_topic_$index';
    final name = rawData is Map ? (rawData['name']?.toString() ?? 'Tema de Aprendizaje $index') : 'Tema de Aprendizaje $index';
    
    return TopicModel(
      id: id,
      title: name,
      description: 'Contenido educativo sobre medio ambiente y sostenibilidad.',
      category: 'educacion',
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: index + 1)),
      updatedAt: DateTime.now(),
    );
  }

  ContentModel _createFallbackContent(int index, String topicId, dynamic rawData) {
    final id = rawData is Map ? (rawData['id']?.toString() ?? '${topicId}_fallback_$index') : '${topicId}_fallback_$index';
    final name = rawData is Map ? (rawData['name']?.toString() ?? 'Contenido $index') : 'Contenido $index';
    
    return ContentModel(
      id: id,
      title: name,
      description: 'Contenido educativo relacionado con el tema.',
      content: 'Este es contenido educativo sobre medio ambiente.',
      category: 'educacion',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    );
  }
}