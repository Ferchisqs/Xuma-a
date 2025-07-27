// lib/features/learning/data/datasources/media_remote_datasource.dart - CORREGIDO PARA publicUrl
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_endpoints.dart';

enum MediaType {
  image,
  video,
  audio,
  document,
  unknown
}

class MediaResponse {
  final String? url;
  final String? filename;
  final int? size;
  final MediaType type;
  final String? mimeType;
  final String? fileType;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;
  final bool isValid;

  MediaResponse({
    this.url,
    this.filename,
    this.size,
    this.type = MediaType.unknown,
    this.mimeType,
    this.fileType,
    this.createdAt,
    this.metadata,
  }) : isValid = url != null && url!.isNotEmpty;

  bool get isImage => type == MediaType.image || 
                     (mimeType?.startsWith('image/') ?? false);
  
  bool get isVideo => type == MediaType.video || 
                     (mimeType?.startsWith('video/') ?? false);

  @override
  String toString() {
    return 'MediaResponse(url: $url, type: $type, isValid: $isValid)';
  }
}

abstract class MediaRemoteDataSource {
  Future<String?> getMediaUrl(String mediaId);
  Future<MediaResponse?> getMediaResponse(String mediaId);
}

@Injectable(as: MediaRemoteDataSource)
class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  final ApiClient apiClient;

  MediaRemoteDataSourceImpl(this.apiClient);

  @override
  Future<String?> getMediaUrl(String mediaId) async {
    final response = await getMediaResponse(mediaId);
    return response?.url;
  }

  @override
  Future<MediaResponse?> getMediaResponse(String mediaId) async {
    try {
      print('🎬 [MEDIA API] Fetching media ID: $mediaId');
      
      // 🔧 USAR EL ENDPOINT CORRECTO CON EL MÉTODO ESPECÍFICO
      final endpoint = '/api/media/files/$mediaId';
      final response = await apiClient.getMedia(endpoint);
      
      print('🎬 [MEDIA API] Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          print('🎬 [MEDIA API] Response keys: ${responseMap.keys.toList()}');
          
          // 🔧 EXTRAER DATA SEGÚN LA ESTRUCTURA DE TU API
          Map<String, dynamic> data;
          if (responseMap.containsKey('data')) {
            data = responseMap['data'] as Map<String, dynamic>;
          } else {
            data = responseMap;
          }
          
          print('🎬 [MEDIA API] Data keys: ${data.keys.toList()}');
          
          // 🔧 EXTRAER publicUrl ESPECÍFICAMENTE
          final publicUrl = data['publicUrl'] as String?;
          
          if (publicUrl != null && publicUrl.isNotEmpty) {
            print('✅ [MEDIA API] Found publicUrl: $publicUrl');
            
            return MediaResponse(
              url: publicUrl,
              filename: data['originalName'] as String?,
              size: data['fileSize'] as int?,
              type: _determineTypeFromMimeType(data['mimeType'] as String?),
              mimeType: data['mimeType'] as String?,
              fileType: data['fileType'] as String?,
              metadata: {
                'id': mediaId,
                'isPublic': data['isPublic'],
                'isProcessed': data['isProcessed'],
                ...?data['metadata'] as Map<String, dynamic>?,
              },
            );
          } else {
            print('❌ [MEDIA API] No publicUrl found in response');
            return null;
          }
        }
      }
      
      print('❌ [MEDIA API] Invalid response for media ID: $mediaId');
      return null;
      
    } catch (e, stackTrace) {
      print('❌ [MEDIA API] Error fetching media: $e');
      return null;
    }
  }

  MediaType _determineTypeFromMimeType(String? mimeType) {
    if (mimeType == null) return MediaType.unknown;
    
    final lowerType = mimeType.toLowerCase();
    if (lowerType.startsWith('image/')) return MediaType.image;
    if (lowerType.startsWith('video/')) return MediaType.video;
    if (lowerType.startsWith('audio/')) return MediaType.audio;
    
    return MediaType.unknown;
  }
}