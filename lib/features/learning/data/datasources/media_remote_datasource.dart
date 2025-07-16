// lib/features/learning/data/datasources/media_remote_datasource.dart
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';

abstract class MediaRemoteDataSource {
  Future<String?> getMediaUrl(String mediaId);
  Future<Map<String, String>> getMultipleMediaUrls(List<String> mediaIds);
}

@Injectable(as: MediaRemoteDataSource)
class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  final ApiClient apiClient;

  MediaRemoteDataSourceImpl(this.apiClient);

  @override
  Future<String?> getMediaUrl(String mediaId) async {
    try {
      print('🎬 [MEDIA API] === FETCHING MEDIA URL ===');
      print('🎬 [MEDIA API] Media ID: $mediaId');
      
      final response = await apiClient.get('/api/media/$mediaId');
      
      print('🎬 [MEDIA API] Response Status: ${response.statusCode}');
      print('🎬 [MEDIA API] Response Type: ${response.data.runtimeType}');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('🎬 [MEDIA API] Response Keys: ${data.keys.toList()}');
        
        // Buscar URL en diferentes campos posibles
        final urlFields = [
          'url', 'media_url', 'file_url', 'download_url',
          'src', 'source', 'path', 'location'
        ];
        
        for (final field in urlFields) {
          final url = data[field];
          if (url != null && url.toString().trim().isNotEmpty) {
            final urlString = url.toString().trim();
            print('✅ [MEDIA API] Found media URL: $urlString');
            return urlString;
          }
        }
        
        // Buscar en data anidado
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          final nestedData = data['data'] as Map<String, dynamic>;
          for (final field in urlFields) {
            final url = nestedData[field];
            if (url != null && url.toString().trim().isNotEmpty) {
              final urlString = url.toString().trim();
              print('✅ [MEDIA API] Found media URL in nested data: $urlString');
              return urlString;
            }
          }
        }
        
        print('⚠️ [MEDIA API] No URL found in response for media ID: $mediaId');
        return null;
      }
      
      print('⚠️ [MEDIA API] Invalid response format for media ID: $mediaId');
      return null;
      
    } catch (e, stackTrace) {
      print('❌ [MEDIA API] === ERROR FETCHING MEDIA URL ===');
      print('❌ [MEDIA API] Media ID: $mediaId');
      print('❌ [MEDIA API] Error: $e');
      print('❌ [MEDIA API] Stack trace: $stackTrace');
      
      // No lanzar excepción, solo retornar null
      // Esto permite que el contenido se muestre sin imagen
      return null;
    }
  }

  @override
  Future<Map<String, String>> getMultipleMediaUrls(List<String> mediaIds) async {
    print('🎬 [MEDIA API] === FETCHING MULTIPLE MEDIA URLs ===');
    print('🎬 [MEDIA API] Media IDs: $mediaIds');
    
    final Map<String, String> urlMap = {};
    
    // Hacer requests en paralelo para mejor performance
    final futures = mediaIds.map((mediaId) async {
      try {
        final url = await getMediaUrl(mediaId);
        if (url != null) {
          return MapEntry(mediaId, url);
        }
        return null;
      } catch (e) {
        print('⚠️ [MEDIA API] Failed to fetch URL for media ID: $mediaId - $e');
        return null;
      }
    });
    
    final results = await Future.wait(futures);
    
    for (final result in results) {
      if (result != null) {
        urlMap[result.key] = result.value;
      }
    }
    
    print('✅ [MEDIA API] Successfully fetched ${urlMap.length}/${mediaIds.length} media URLs');
    return urlMap;
  }

  // 🆕 MÉTODO HELPER PARA RESOLVER MEDIA DE UN CONTENT
  Future<Map<String, String?>> resolveContentMedia({
    String? mainMediaId,
    String? thumbnailMediaId,
  }) async {
    print('🎬 [MEDIA API] === RESOLVING CONTENT MEDIA ===');
    print('🎬 [MEDIA API] Main Media ID: $mainMediaId');
    print('🎬 [MEDIA API] Thumbnail Media ID: $thumbnailMediaId');
    
    final List<String> mediaIdsToFetch = [];
    if (mainMediaId != null && mainMediaId.isNotEmpty) {
      mediaIdsToFetch.add(mainMediaId);
    }
    if (thumbnailMediaId != null && thumbnailMediaId.isNotEmpty) {
      mediaIdsToFetch.add(thumbnailMediaId);
    }
    
    if (mediaIdsToFetch.isEmpty) {
      print('ℹ️ [MEDIA API] No media IDs to resolve');
      return {'mainMediaUrl': null, 'thumbnailMediaUrl': null};
    }
    
    try {
      final urlMap = await getMultipleMediaUrls(mediaIdsToFetch);
      
      final result = {
        'mainMediaUrl': mainMediaId != null ? urlMap[mainMediaId] : null,
        'thumbnailMediaUrl': thumbnailMediaId != null ? urlMap[thumbnailMediaId] : null,
      };
      
      print('✅ [MEDIA API] Resolved media URLs:');
      print('✅ [MEDIA API] - Main: ${result['mainMediaUrl']}');
      print('✅ [MEDIA API] - Thumbnail: ${result['thumbnailMediaUrl']}');
      
      return result;
    } catch (e) {
      print('❌ [MEDIA API] Error resolving content media: $e');
      return {'mainMediaUrl': null, 'thumbnailMediaUrl': null};
    }
  }
}