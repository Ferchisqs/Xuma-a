// lib/features/learning/data/datasources/media_remote_datasource.dart - CORREGIDO CON CATEGORÍAS
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
  final String? category; // 🆕 AGREGADO: Campo de categoría de la API
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
    this.category, // 🆕 AGREGADO
    this.createdAt,
    this.metadata,
  }) : isValid = url != null && url!.isNotEmpty;

  // 🔧 GETTERS MEJORADOS USANDO CATEGORÍA DE LA API
  bool get isImage => 
    category?.toLowerCase() == 'image' ||
    type == MediaType.image || 
    (mimeType?.startsWith('image/') ?? false);
  
  bool get isVideo => 
    category?.toLowerCase() == 'video' ||
    type == MediaType.video || 
    (mimeType?.startsWith('video/') ?? false);

  bool get isAudio => 
    category?.toLowerCase() == 'audio' ||
    type == MediaType.audio || 
    (mimeType?.startsWith('audio/') ?? false);

  bool get isDocument => 
    category?.toLowerCase() == 'document' ||
    type == MediaType.document || 
    _isDocumentMimeType(mimeType);

  // 🆕 HELPER PARA DOCUMENTOS
  bool _isDocumentMimeType(String? mimeType) {
    if (mimeType == null) return false;
    final docTypes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ];
    return docTypes.any((docType) => mimeType.startsWith(docType));
  }

  @override
  String toString() {
    return 'MediaResponse(url: $url, type: $type, category: $category, isValid: $isValid)';
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
      print('🎬 [MEDIA API] === FETCHING MEDIA WITH ENHANCED CATEGORY DETECTION ===');
      print('🎬 [MEDIA API] Media ID: $mediaId');
      
      final endpoint = '/api/media/files/$mediaId';
      print('🎬 [MEDIA API] Endpoint: $endpoint');
      
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
          
          // 🔧 EXTRAER INFORMACIÓN COMPLETA
          final publicUrl = data['publicUrl'] as String?;
          final category = data['category'] as String?; // 🆕 EXTRAER CATEGORÍA
          final mimeType = data['mimeType'] as String?;
          
          if (publicUrl != null && publicUrl.isNotEmpty) {
            print('✅ [MEDIA API] Found publicUrl: $publicUrl');
            print('✅ [MEDIA API] Category from API: $category'); // 🆕 LOG
            print('✅ [MEDIA API] Media type: $mimeType');
            print('✅ [MEDIA API] File size: ${data['fileSize']}');
            print('✅ [MEDIA API] Original name: ${data['originalName']}');
            
            // 🔧 DETERMINAR TIPO USANDO CATEGORÍA PRIMERO
            final mediaType = _determineTypeFromCategory(category, mimeType);
            print('✅ [MEDIA API] Determined media type: $mediaType');
            
            return MediaResponse(
              url: publicUrl,
              filename: data['originalName'] as String?,
              size: data['fileSize'] as int?,
              type: mediaType,
              mimeType: mimeType,
              fileType: data['fileType'] as String?,
              category: category, // 🆕 INCLUIR CATEGORÍA
              metadata: {
                'id': mediaId,
                'isPublic': data['isPublic'],
                'isProcessed': data['isProcessed'],
                'virusScanStatus': data['virusScanStatus'],
                'category': category, // 🆕 DUPLICAR EN METADATA PARA ACCESO FÁCIL
                'width': data['metadata']?['width'],
                'height': data['metadata']?['height'],
                'duration': data['metadata']?['duration'], // Para videos
                'bitrate': data['metadata']?['bitrate'], // Para videos/audio
                ...?data['metadata'] as Map<String, dynamic>?,
              },
            );
          } else {
            print('❌ [MEDIA API] No publicUrl found in response');
            print('❌ [MEDIA API] Available fields: ${data.keys.toList()}');
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

  // 🆕 MÉTODO MEJORADO PARA DETERMINAR TIPO USANDO CATEGORÍA PRIMERO
  MediaType _determineTypeFromCategory(String? category, String? mimeType) {
    print('🔍 [MEDIA API] Determining type - Category: "$category", MimeType: "$mimeType"');
    
    // 🔧 PRIORIZAR CATEGORÍA DE LA API
    if (category != null) {
      final lowerCategory = category.toLowerCase().trim();
      print('🔍 [MEDIA API] Processing category: "$lowerCategory"');
      
      switch (lowerCategory) {
        case 'image':
          print('✅ [MEDIA API] Detected as IMAGE from category');
          return MediaType.image;
        case 'video':
          print('✅ [MEDIA API] Detected as VIDEO from category');
          return MediaType.video;
        case 'audio':
          print('✅ [MEDIA API] Detected as AUDIO from category');
          return MediaType.audio;
        case 'document':
          print('✅ [MEDIA API] Detected as DOCUMENT from category');
          return MediaType.document;
        default:
          print('⚠️ [MEDIA API] Unknown category: "$lowerCategory", falling back to mimeType');
          break;
      }
    }
    
    // 🔧 FALLBACK A MIMETYPE SI NO HAY CATEGORÍA O ES DESCONOCIDA
    if (mimeType != null) {
      final lowerType = mimeType.toLowerCase();
      print('🔍 [MEDIA API] Processing mimeType: "$lowerType"');
      
      if (lowerType.startsWith('image/')) {
        print('✅ [MEDIA API] Detected as IMAGE from mimeType');
        return MediaType.image;
      }
      if (lowerType.startsWith('video/')) {
        print('✅ [MEDIA API] Detected as VIDEO from mimeType');
        return MediaType.video;
      }
      if (lowerType.startsWith('audio/')) {
        print('✅ [MEDIA API] Detected as AUDIO from mimeType');
        return MediaType.audio;
      }
      
      // Verificar tipos de documento comunes
      final docTypes = [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument',
        'text/plain',
        'application/vnd.ms-excel',
      ];
      
      if (docTypes.any((docType) => lowerType.startsWith(docType))) {
        print('✅ [MEDIA API] Detected as DOCUMENT from mimeType');
        return MediaType.document;
      }
    }
    
    print('⚠️ [MEDIA API] Could not determine type, returning UNKNOWN');
    return MediaType.unknown;
  }
}