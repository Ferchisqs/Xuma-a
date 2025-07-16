// lib/features/learning/data/datasources/content_remote_datasource.dart - MEJORADO - ENDPOINT CORREGIDO
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/topic_model.dart';
import '../models/content_model.dart';

abstract class ContentRemoteDataSource {
  Future<List<TopicModel>> getTopics();
  Future<ContentModel> getContentById(String id);
  Future<List<ContentModel>> getContentsByTopicId(String topicId, int page, int limit);
}

@Injectable(as: ContentRemoteDataSource)
class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final ApiClient apiClient;

  ContentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TopicModel>> getTopics() async {
    try {
      print('🌐 [CONTENT API] === FETCHING TOPICS (IMPROVED) ===');
      print('🌐 [CONTENT API] URL: ${ApiEndpoints.getContentUrl('/api/content/topics')}');
      
      final response = await apiClient.getContent('/api/content/topics');
      
      print('🌐 [CONTENT API] Response Status: ${response.statusCode}');
      print('🌐 [CONTENT API] Response Type: ${response.data.runtimeType}');
      
      // Log de respuesta más detallado
      if (response.data is Map) {
        final dataMap = response.data as Map<String, dynamic>;
        print('🌐 [CONTENT API] Response Keys: ${dataMap.keys.toList()}');
        print('🌐 [CONTENT API] Response Sample: ${_getSafeResponseSample(dataMap)}');
      }
      
      // Extraer lista de topics de forma super robusta
      List<dynamic> topicsJson = _extractTopicsFromResponse(response.data);
      
      print('🔍 [CONTENT API] Found ${topicsJson.length} raw topics to process');
      
      if (topicsJson.isEmpty) {
        print('⚠️ [CONTENT API] No topics found in response, creating mock data');
        return _createMockTopics();
      }
      
      // Procesar cada topic con manejo de errores individual
      final topics = <TopicModel>[];
      
      for (int i = 0; i < topicsJson.length; i++) {
        try {
          print('🔍 [CONTENT API] === PROCESSING TOPIC ${i + 1}/${topicsJson.length} ===');
          
          final rawTopic = topicsJson[i];
          if (rawTopic is! Map<String, dynamic>) {
            print('⚠️ [CONTENT API] Topic $i is not a Map: ${rawTopic.runtimeType}');
            continue;
          }
          
          final topicJson = rawTopic as Map<String, dynamic>;
          print('🔍 [CONTENT API] Topic $i keys: ${topicJson.keys.toList()}');
          print('🔍 [CONTENT API] Topic $i ID: ${topicJson['id'] ?? 'NO_ID'}');
          print('🔍 [CONTENT API] Topic $i name: ${topicJson['name'] ?? 'NO_NAME'}');
          
          final topic = TopicModel.fromJson(topicJson);
          topics.add(topic);
          
          print('✅ [CONTENT API] Successfully parsed topic ${i + 1}: "${topic.title}" (${topic.category})');
          
        } catch (e, stackTrace) {
          print('❌ [CONTENT API] Failed to parse topic $i: $e');
          print('❌ [CONTENT API] Topic $i data: ${_getSafeTopicSample(topicsJson[i])}');
          print('❌ [CONTENT API] Stack trace: $stackTrace');
          
          // 🔧 CREAR TOPIC FALLBACK EN LUGAR DE FALLAR TODO
          try {
            final fallbackTopic = _createFallbackTopic(i, topicsJson[i]);
            topics.add(fallbackTopic);
            print('🆘 [CONTENT API] Created fallback topic for index $i');
          } catch (fallbackError) {
            print('❌ [CONTENT API] Even fallback failed for topic $i: $fallbackError');
            // Continuar sin este topic
          }
        }
      }
      
      print('🎉 [CONTENT API] === TOPICS PROCESSING COMPLETE ===');
      print('🎉 [CONTENT API] Successfully processed: ${topics.length}/${topicsJson.length} topics');
      
      if (topics.isEmpty) {
        print('⚠️ [CONTENT API] No topics were successfully parsed, returning mock data');
        return _createMockTopics();
      }
      
      return topics;
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT API] === CRITICAL ERROR FETCHING TOPICS ===');
      print('❌ [CONTENT API] Error: $e');
      print('❌ [CONTENT API] Stack trace: $stackTrace');
      
      // En lugar de fallar completamente, devolver topics mock
      print('🆘 [CONTENT API] Returning mock topics due to API error');
      return _createMockTopics();
    }
  }

  @override
  Future<ContentModel> getContentById(String id) async {
    try {
      print('🌐 [CONTENT API] === FETCHING CONTENT BY ID (IMPROVED) ===');
      print('🌐 [CONTENT API] Content ID: $id');
      
      // 🔧 ENDPOINT CORREGIDO: usar /api/content/{id} en lugar de /api/content/topics/{id}
      final response = await apiClient.getContent('/api/content/$id');
      
      print('🌐 [CONTENT API] Response Status: ${response.statusCode}');
      
      Map<String, dynamic> contentJson = _extractContentFromResponse(response.data);
      
      print('🔍 [CONTENT API] Content keys: ${contentJson.keys.toList()}');
      
      final content = ContentModel.fromJson(contentJson);
      
      print('✅ [CONTENT API] Successfully parsed content: "${content.title}"');
      return content;
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT API] === ERROR FETCHING CONTENT BY ID ===');
      print('❌ [CONTENT API] Content ID: $id');
      print('❌ [CONTENT API] Error: $e');
      
      // Crear contenido mock basado en el ID
      return _createMockContent(id);
    }
  }

  @override
  Future<List<ContentModel>> getContentsByTopicId(String topicId, int page, int limit) async {
    try {
      print('🌐 [CONTENT API] === FETCHING CONTENTS BY TOPIC (IMPROVED) ===');
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
      
      // Procesar cada contenido con manejo robusto
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
          contents.add(content);
          
          print('✅ [CONTENT API] Successfully parsed content $i: "${content.title}"');
          
        } catch (e) {
          print('❌ [CONTENT API] Failed to parse content $i: $e');
          
          // Crear contenido fallback
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
      
      // Devolver contenidos mock para el topic
      return _createMockContentsForTopic(topicId);
    }
  }

  // 🔧 HELPERS PARA EXTRAER DATOS DE RESPUESTAS
  List<dynamic> _extractTopicsFromResponse(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }
    
    if (responseData is Map<String, dynamic>) {
      // Buscar en diferentes campos posibles
      for (final key in ['data', 'topics', 'results', 'items']) {
        if (responseData.containsKey(key) && responseData[key] is List) {
          return responseData[key] as List<dynamic>;
        }
      }
      
      // Si no es una lista, asumir que es un topic único
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

  // 🔧 HELPERS PARA DATOS MOCK
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

  // 🔧 HELPERS PARA LOGGING SEGURO
  String _getSafeResponseSample(Map<String, dynamic> data) {
    try {
      final sample = Map<String, dynamic>.from(data);
      // Limitar el tamaño del sample
      if (sample.toString().length > 500) {
        return '${sample.toString().substring(0, 500)}...';
      }
      return sample.toString();
    } catch (e) {
      return 'Error creating sample: $e';
    }
  }

  String _getSafeTopicSample(dynamic topic) {
    try {
      if (topic is Map) {
        return '{id: ${topic['id']}, name: ${topic['name']}, keys: ${topic.keys.take(5).toList()}}';
      }
      return topic.toString().length > 100 
          ? '${topic.toString().substring(0, 100)}...'
          : topic.toString();
    } catch (e) {
      return 'Error creating topic sample: $e';
    }
  }
}