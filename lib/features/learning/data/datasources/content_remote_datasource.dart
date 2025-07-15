// lib/features/learning/data/datasources/content_remote_datasource.dart
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/topic_model.dart';
import '../models/content_model.dart';

abstract class ContentRemoteDataSource {
  Future<List<TopicModel>> getTopics();
  Future<ContentModel> getContentById(String id);
}

@Injectable(as: ContentRemoteDataSource)
class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final ApiClient apiClient;

  ContentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TopicModel>> getTopics() async {
    try {
      print('🌐 [CONTENT API] Fetching topics from: ${ApiEndpoints.getContentUrl('/api/content/topics')}');
      
      // Usar el método específico para content service
      final response = await apiClient.getContent('/api/content/topics');
      
      print('🌐 [CONTENT API] Topics response: ${response.data}');
      
      // Manejar diferentes estructuras de respuesta
      List<dynamic> topicsJson;
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        // Buscar en diferentes campos posibles
        if (data.containsKey('data')) {
          topicsJson = data['data'] as List<dynamic>;
        } else if (data.containsKey('topics')) {
          topicsJson = data['topics'] as List<dynamic>;
        } else {
          // Si la respuesta es directamente el objeto, convertirlo a lista
          topicsJson = [data];
        }
      } else if (response.data is List) {
        topicsJson = response.data as List<dynamic>;
      } else {
        throw ServerException('Formato de respuesta inesperado para topics');
      }
      
      print('🌐 [CONTENT API] Processing ${topicsJson.length} topics');
      
      final topics = topicsJson.map((json) {
        try {
          return TopicModel.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('❌ [CONTENT API] Error parsing topic: $e');
          print('❌ [CONTENT API] Topic data: $json');
          throw ServerException('Error parsing topic: $e');
        }
      }).toList();
      
      print('✅ [CONTENT API] Successfully parsed ${topics.length} topics');
      return topics;
      
    } catch (e) {
      print('❌ [CONTENT API] Error fetching topics: $e');
      throw ServerException('Error fetching topics: ${e.toString()}');
    }
  }

  @override
  Future<ContentModel> getContentById(String id) async {
    try {
      print('🌐 [CONTENT API] Fetching content by ID: $id');
      
      final response = await apiClient.getContent('/api/content/$id');
      
      print('🌐 [CONTENT API] Content response: ${response.data}');
      
      Map<String, dynamic> contentJson;
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        // Buscar en diferentes campos posibles
        if (data.containsKey('data')) {
          contentJson = data['data'] as Map<String, dynamic>;
        } else {
          contentJson = data;
        }
      } else {
        throw ServerException('Formato de respuesta inesperado para contenido');
      }
      
      try {
        final content = ContentModel.fromJson(contentJson);
        print('✅ [CONTENT API] Successfully parsed content: ${content.title}');
        return content;
      } catch (e) {
        print('❌ [CONTENT API] Error parsing content: $e');
        print('❌ [CONTENT API] Content data: $contentJson');
        throw ServerException('Error parsing content: $e');
      }
      
    } catch (e) {
      print('❌ [CONTENT API] Error fetching content: $e');
      throw ServerException('Error fetching content: ${e.toString()}');
    }
  }
}