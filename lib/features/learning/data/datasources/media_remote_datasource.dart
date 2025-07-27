// lib/features/learning/data/datasources/media_remote_datasource.dart - CORREGIDO CON AUTH
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
      print('🎬 [MEDIA API] === FETCHING MEDIA WITH AUTHENTICATION ===');
      print('🎬 [MEDIA API] Media ID: $mediaId');
      
      // 🔧 USAR EL ApiClient QUE YA TIENE AUTENTICACIÓN CONFIGURADA
      final endpoint = '/api/media/files/$mediaId';
      print('🎬 [MEDIA API] Endpoint: $endpoint');
      
      // 🔧 USAR EL MÉTODO getMedia() QUE YA CONFIGURASTE EN ApiClient
      final response = await apiClient.getMedia(endpoint);
      
      print('🎬 [MEDIA API] Response Status: ${response.statusCode}');
      print('🎬 [MEDIA API] Response Data Type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200 && response.data != null) {
        
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          print('🎬 [MEDIA API] Response keys: ${responseMap.keys.toList()}');
          
          // 🔧 EXTRAER DATA SEGÚN LA ESTRUCTURA DE TU API
          Map<String, dynamic> data;
          if (responseMap.containsKey('data')) {
            data = responseMap['data'] as Map<String, dynamic>;
            print('🎬 [MEDIA API] Data found in response.data');
          } else {
            data = responseMap;
            print('🎬 [MEDIA API] Using response directly as data');
          }
          
          print('🎬 [MEDIA API] Data keys: ${data.keys.toList()}');
          
          // 🔧 EXTRAER publicUrl ESPECÍFICAMENTE
          final publicUrl = data['publicUrl'] as String?;
          
          if (publicUrl != null && publicUrl.isNotEmpty) {
            print('✅ [MEDIA API] Found publicUrl: $publicUrl');
            print('✅ [MEDIA API] Media type: ${data['mimeType']}');
            print('✅ [MEDIA API] File size: ${data['fileSize']}');
            print('✅ [MEDIA API] Original name: ${data['originalName']}');
            
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
                'virusScanStatus': data['virusScanStatus'],
                'category': data['category'], // <-- Add category if present
                'width': data['metadata']?['width'],
                'height': data['metadata']?['height'],
                ...?data['metadata'] as Map<String, dynamic>?,
              },
            );
          } else {
            print('❌ [MEDIA API] No publicUrl found in response');
            print('❌ [MEDIA API] Available fields: ${data.keys.toList()}');
            
            // 🔧 DEBUG: Mostrar todo el data para entender la estructura
            print('🔍 [MEDIA API] Full data object: $data');
            
            return null;
          }
        } else {
          print('❌ [MEDIA API] Response is not a Map: ${response.data.runtimeType}');
          print('🔍 [MEDIA API] Response content: ${response.data}');
          return null;
        }
      }
      
      print('❌ [MEDIA API] Invalid response status: ${response.statusCode}');
      return null;
      
    } catch (e, stackTrace) {
      print('❌ [MEDIA API] === ERROR FETCHING MEDIA ===');
      print('❌ [MEDIA API] Media ID: $mediaId');
      print('❌ [MEDIA API] Error: $e');
      
      // 🔧 MANEJO ESPECÍFICO DE ERRORES DE AUTENTICACIÓN
      if (e.toString().contains('401')) {
        print('🔑 [MEDIA API] Authentication required - check if user is logged in');
        print('🔑 [MEDIA API] Media service requires valid token');
      } else if (e.toString().contains('403')) {
        print('🚫 [MEDIA API] Access forbidden - user may not have permission');
      } else if (e.toString().contains('404')) {
        print('🔍 [MEDIA API] Media not found - ID may not exist: $mediaId');
      } else {
        print('🔍 [MEDIA API] Stack trace: $stackTrace');
      }
      
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