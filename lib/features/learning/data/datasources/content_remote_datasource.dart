// lib/features/learning/data/datasources/content_remote_datasource.dart - CON BY-TOPIC
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/topic_model.dart';
import '../models/content_model.dart';

abstract class ContentRemoteDataSource {
  Future<List<TopicModel>> getTopics();
  Future<ContentModel> getContentById(String id);
  
  // 🆕 NUEVO MÉTODO PARA CONTENIDOS POR TOPIC
  Future<List<ContentModel>> getContentsByTopicId(String topicId, int page, int limit);
}

@Injectable(as: ContentRemoteDataSource)
class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final ApiClient apiClient;

  ContentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TopicModel>> getTopics() async {
    try {
      print('🌐 [CONTENT API] === FETCHING TOPICS ===');
      print('🌐 [CONTENT API] URL: ${ApiEndpoints.getContentUrl('/api/content/topics')}');
      
      final response = await apiClient.getContent('/api/content/topics');
      
      print('🌐 [CONTENT API] Response Status: ${response.statusCode}');
      print('🌐 [CONTENT API] Response Type: ${response.data.runtimeType}');
      print('🌐 [CONTENT API] Response Data: ${response.data}');
      
      // Extraer la lista de topics de forma robusta
      List<dynamic> topicsJson = [];
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('🔍 [CONTENT API] Response is Map, keys: ${data.keys.toList()}');
        
        // Buscar la lista en diferentes campos posibles
        if (data.containsKey('data') && data['data'] is List) {
          topicsJson = data['data'] as List<dynamic>;
          print('✅ [CONTENT API] Found topics in data field');
        } else if (data.containsKey('topics') && data['topics'] is List) {
          topicsJson = data['topics'] as List<dynamic>;
          print('✅ [CONTENT API] Found topics in topics field');
        } else if (data.containsKey('results') && data['results'] is List) {
          topicsJson = data['results'] as List<dynamic>;
          print('✅ [CONTENT API] Found topics in results field');
        } else {
          // Si no encontramos una lista, usar toda la respuesta como un topic
          topicsJson = [data];
          print('✅ [CONTENT API] Using whole response as single topic');
        }
      } else if (response.data is List) {
        topicsJson = response.data as List<dynamic>;
        print('✅ [CONTENT API] Response is already a List');
      } else {
        print('❌ [CONTENT API] Unexpected response format: ${response.data.runtimeType}');
        throw ServerException('Formato de respuesta inesperado para topics');
      }
      
      print('🔍 [CONTENT API] Found ${topicsJson.length} raw topics to process');
      
      // Procesar cada topic de forma robusta
      final topics = <TopicModel>[];
      
      for (int i = 0; i < topicsJson.length; i++) {
        try {
          print('🔍 [CONTENT API] === PROCESSING TOPIC $i ===');
          
          final rawTopic = topicsJson[i];
          if (rawTopic is! Map<String, dynamic>) {
            print('⚠️ [CONTENT API] Topic $i is not a Map, skipping: ${rawTopic.runtimeType}');
            continue;
          }
          
          final topicJson = rawTopic as Map<String, dynamic>;
          print('🔍 [CONTENT API] Topic $i JSON keys: ${topicJson.keys.toList()}');
          print('🔍 [CONTENT API] Topic $i name: ${topicJson['name'] ?? 'NO NAME'}');
          print('🔍 [CONTENT API] Topic $i category: ${topicJson['category'] ?? 'NO CATEGORY'}');
          print('🔍 [CONTENT API] Topic $i is_active: ${topicJson['is_active'] ?? 'NO IS_ACTIVE'}');
          
          final topic = TopicModel.fromJson(topicJson);
          topics.add(topic);
          
          print('✅ [CONTENT API] Successfully parsed topic $i: "${topic.title}"');
          print('   - ID: ${topic.id}');
          print('   - Category: ${topic.category}');
          print('   - Active: ${topic.isActive}');
          
        } catch (e, stackTrace) {
          print('❌ [CONTENT API] Failed to parse topic $i: $e');
          print('❌ [CONTENT API] Topic $i data: ${topicsJson[i]}');
          print('❌ [CONTENT API] Stack trace: $stackTrace');
          
          // 🔧 EN LUGAR DE FALLAR TODO, CONTINUAMOS CON EL SIGUIENTE
          continue;
        }
      }
      
      print('🎉 [CONTENT API] === TOPICS PROCESSING COMPLETE ===');
      print('🎉 [CONTENT API] Successfully processed: ${topics.length}/${topicsJson.length} topics');
      
      if (topics.isEmpty) {
        print('⚠️ [CONTENT API] No topics were successfully parsed!');
        throw ServerException('No se pudieron procesar los topics');
      }
      
      return topics;
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT API] === CRITICAL ERROR FETCHING TOPICS ===');
      print('❌ [CONTENT API] Error: $e');
      print('❌ [CONTENT API] Stack trace: $stackTrace');
      throw ServerException('Error fetching topics: ${e.toString()}');
    }
  }

  @override
  Future<ContentModel> getContentById(String id) async {
    try {
      print('🌐 [CONTENT API] === FETCHING CONTENT BY ID ===');
      print('🌐 [CONTENT API] Topic ID: $id');
      print('🌐 [CONTENT API] URL: ${ApiEndpoints.getContentUrl('/api/content/topics/$id')}');
      
      final response = await apiClient.getContent('/api/content/topics/$id');
      
      print('🌐 [CONTENT API] Response Status: ${response.statusCode}');
      print('🌐 [CONTENT API] Response Type: ${response.data.runtimeType}');
      print('🌐 [CONTENT API] Response Data: ${response.data}');
      
      Map<String, dynamic> contentJson;
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('🔍 [CONTENT API] Response is Map, keys: ${data.keys.toList()}');
        
        // Buscar el contenido en diferentes campos posibles
        if (data.containsKey('data') && data['data'] is Map) {
          contentJson = data['data'] as Map<String, dynamic>;
          print('✅ [CONTENT API] Found content in data field');
        } else {
          contentJson = data;
          print('✅ [CONTENT API] Using whole response as content');
        }
      } else {
        print('❌ [CONTENT API] Unexpected response format for content');
        throw ServerException('Formato de respuesta inesperado para contenido');
      }
      
      print('🔍 [CONTENT API] Content JSON keys: ${contentJson.keys.toList()}');
      print('🔍 [CONTENT API] Content name: ${contentJson['name'] ?? 'NO NAME'}');
      
      final content = ContentModel.fromJson(contentJson);
      
      print('✅ [CONTENT API] Successfully parsed content: "${content.title}"');
      print('   - ID: ${content.id}');
      print('   - Category: ${content.category}');
      print('   - Active: ${content.isActive}');
      
      return content;
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT API] === CRITICAL ERROR FETCHING CONTENT ===');
      print('❌ [CONTENT API] Topic ID: $id');
      print('❌ [CONTENT API] Error: $e');
      print('❌ [CONTENT API] Stack trace: $stackTrace');
      throw ServerException('Error fetching content: ${e.toString()}');
    }
  }

  // 🆕 IMPLEMENTACIÓN PARA CONTENIDOS POR TOPIC
  @override
  Future<List<ContentModel>> getContentsByTopicId(String topicId, int page, int limit) async {
    try {
      print('🌐 [CONTENT API] === FETCHING CONTENTS BY TOPIC ===');
      print('🌐 [CONTENT API] Topic ID: $topicId');
      print('🌐 [CONTENT API] Page: $page, Limit: $limit');
      
      final endpoint = '/api/content/by-topic/$topicId?page=$page&limit=$limit';
      print('🌐 [CONTENT API] URL: ${ApiEndpoints.getContentUrl(endpoint)}');
      
      final response = await apiClient.getContent(endpoint);
      
      print('🌐 [CONTENT API] Response Status: ${response.statusCode}');
      print('🌐 [CONTENT API] Response Type: ${response.data.runtimeType}');
      print('🌐 [CONTENT API] Response Data: ${response.data}');
      
      List<dynamic> contentsJson = [];
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('🔍 [CONTENT API] Response is Map, keys: ${data.keys.toList()}');
        
        // Buscar la lista en diferentes campos posibles
        if (data.containsKey('data') && data['data'] is List) {
          contentsJson = data['data'] as List<dynamic>;
          print('✅ [CONTENT API] Found contents in data field');
        } else if (data.containsKey('contents') && data['contents'] is List) {
          contentsJson = data['contents'] as List<dynamic>;
          print('✅ [CONTENT API] Found contents in contents field');
        } else if (data.containsKey('results') && data['results'] is List) {
          contentsJson = data['results'] as List<dynamic>;
          print('✅ [CONTENT API] Found contents in results field');
        } else {
          contentsJson = [data];
          print('✅ [CONTENT API] Using whole response as single content');
        }
      } else if (response.data is List) {
        contentsJson = response.data as List<dynamic>;
        print('✅ [CONTENT API] Response is already a List');
      } else {
        print('❌ [CONTENT API] Unexpected response format: ${response.data.runtimeType}');
        throw ServerException('Formato de respuesta inesperado para contenidos');
      }
      
      print('🔍 [CONTENT API] Found ${contentsJson.length} raw contents to process');
      
      // Procesar cada contenido de forma robusta
      final contents = <ContentModel>[];
      
      for (int i = 0; i < contentsJson.length; i++) {
        try {
          print('🔍 [CONTENT API] === PROCESSING CONTENT $i ===');
          
          final rawContent = contentsJson[i];
          if (rawContent is! Map<String, dynamic>) {
            print('⚠️ [CONTENT API] Content $i is not a Map, skipping: ${rawContent.runtimeType}');
            continue;
          }
          
          final contentJson = rawContent as Map<String, dynamic>;
          print('🔍 [CONTENT API] Content $i JSON keys: ${contentJson.keys.toList()}');
          print('🔍 [CONTENT API] Content $i name: ${contentJson['name'] ?? 'NO NAME'}');
          
          final content = ContentModel.fromJson(contentJson);
          contents.add(content);
          
          print('✅ [CONTENT API] Successfully parsed content $i: "${content.title}"');
          print('   - ID: ${content.id}');
          print('   - Category: ${content.category}');
          
        } catch (e, stackTrace) {
          print('❌ [CONTENT API] Failed to parse content $i: $e');
          print('❌ [CONTENT API] Content $i data: ${contentsJson[i]}');
          print('❌ [CONTENT API] Stack trace: $stackTrace');
          
          // Continuar con el siguiente contenido
          continue;
        }
      }
      
      print('🎉 [CONTENT API] === CONTENTS BY TOPIC PROCESSING COMPLETE ===');
      print('🎉 [CONTENT API] Successfully processed: ${contents.length}/${contentsJson.length} contents');
      
      return contents; 
      
    } catch (e, stackTrace) {
      print('❌ [CONTENT API] === CRITICAL ERROR FETCHING CONTENTS BY TOPIC ===');
      print('❌ [CONTENT API] Topic ID: $topicId');
      print('❌ [CONTENT API] Error: $e');
      print('❌ [CONTENT API] Stack trace: $stackTrace');
      throw ServerException('Error fetching contents by topic: ${e.toString()}');
    }
  }
}