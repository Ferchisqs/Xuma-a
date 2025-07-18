// lib/features/learning/data/datasources/media_remote_datasource.dart
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';

// 🆕 ENUM PARA TIPOS DE MEDIA
enum MediaType {
  image,
  video,
  audio,
  document,
  unknown
}

// 🆕 CLASE PARA RESPUESTA DE MEDIA
class MediaResponse {
  final String? url;
  final String? filename;
  final int? size;
  final MediaType type;
  final String? mimeType;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  MediaResponse({
    this.url,
    this.filename,
    this.size,
    this.type = MediaType.unknown,
    this.mimeType,
    this.createdAt,
    this.metadata,
  });

  bool get isValid => url != null && url!.isNotEmpty;
  bool get isImage => type == MediaType.image;
  bool get isVideo => type == MediaType.video;
}

abstract class MediaRemoteDataSource {
  Future<String?> getMediaUrl(String mediaId);
  Future<Map<String, String>> getMultipleMediaUrls(List<String> mediaIds);
  Future<String?> getMediaFileUrl(String fileId);
  Future<Map<String, dynamic>?> getMediaFileInfo(String fileId);
  
  // 🆕 MÉTODOS MEJORADOS
  Future<MediaResponse?> getMediaResponse(String mediaId);
  Future<List<MediaResponse>> getMultipleMediaResponses(List<String> mediaIds);
  Future<MediaResponse?> getOptimizedMediaUrl(String mediaId, {String? quality});
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
  Future<String?> getMediaFileUrl(String fileId) async {
    try {
      print('📁 [MEDIA API] === FETCHING MEDIA FILE URL ===');
      print('📁 [MEDIA API] File ID: $fileId');
      
      final response = await apiClient.get('/api/media/files/$fileId');
      
      print('📁 [MEDIA API] Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          return _extractUrlFromData(data, 'file');
        } else if (response.data is String) {
          final urlString = response.data.toString().trim();
          if (urlString.isNotEmpty) {
            print('✅ [MEDIA API] Direct URL response: $urlString');
            return urlString;
          }
        }
      }
      
      print('⚠️ [MEDIA API] Invalid or empty response for file ID: $fileId');
      return null;
      
    } catch (e, stackTrace) {
      print('❌ [MEDIA API] === ERROR FETCHING MEDIA FILE URL ===');
      print('❌ [MEDIA API] File ID: $fileId');
      print('❌ [MEDIA API] Error: $e');
      return null;
    }
  }

  // 🆕 MÉTODO MEJORADO PARA OBTENER RESPUESTA COMPLETA
  @override
  Future<MediaResponse?> getMediaResponse(String mediaId) async {
    try {
      print('🎬 [MEDIA API] === FETCHING MEDIA RESPONSE ===');
      print('🎬 [MEDIA API] Media ID: $mediaId');
      
      // 🔧 DETERMINAR ENDPOINT CORRECTO
      final endpoint = isFileId(mediaId) 
        ? '/api/media/files/$mediaId' 
        : '/api/media/$mediaId';
      
      final response = await apiClient.get(endpoint);
      
      print('🎬 [MEDIA API] Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return _buildMediaResponse(data, mediaId);
      }
      
      // 🔄 FALLBACK: Si falla, intentar el otro endpoint
      if (isFileId(mediaId)) {
        print('🔄 [MEDIA API] Fallback to regular media endpoint');
        final fallbackResponse = await apiClient.get('/api/media/$mediaId');
        if (fallbackResponse.statusCode == 200 && fallbackResponse.data is Map<String, dynamic>) {
          return _buildMediaResponse(fallbackResponse.data, mediaId);
        }
      } else {
        print('🔄 [MEDIA API] Fallback to file endpoint');
        final fallbackResponse = await apiClient.get('/api/media/files/$mediaId');
        if (fallbackResponse.statusCode == 200 && fallbackResponse.data is Map<String, dynamic>) {
          return _buildMediaResponse(fallbackResponse.data, mediaId);
        }
      }
      
      return null;
      
    } catch (e, stackTrace) {
      print('❌ [MEDIA API] Error fetching media response: $e');
      return null;
    }
  }

  // 🆕 MÉTODO PARA OBTENER MEDIA OPTIMIZADA
  @override
  Future<MediaResponse?> getOptimizedMediaUrl(String mediaId, {String? quality}) async {
    try {
      print('🎯 [MEDIA API] === FETCHING OPTIMIZED MEDIA ===');
      print('🎯 [MEDIA API] Media ID: $mediaId, Quality: $quality');
      
      final queryParams = quality != null ? '?quality=$quality' : '';
      final endpoint = isFileId(mediaId) 
        ? '/api/media/files/$mediaId/optimized$queryParams' 
        : '/api/media/$mediaId/optimized$queryParams';
      
      final response = await apiClient.get(endpoint);
      
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return _buildMediaResponse(response.data, mediaId);
      }
      
      // 🔄 FALLBACK: Si no hay versión optimizada, usar la original
      print('🔄 [MEDIA API] Fallback to original media');
      return await getMediaResponse(mediaId);
      
    } catch (e) {
      print('❌ [MEDIA API] Error fetching optimized media: $e');
      // 🔄 FALLBACK: Si falla, intentar obtener la versión original
      return await getMediaResponse(mediaId);
    }
  }

  // 🆕 MÉTODO PARA MÚLTIPLES MEDIA CON RESPUESTAS COMPLETAS
  @override
  Future<List<MediaResponse>> getMultipleMediaResponses(List<String> mediaIds) async {
    print('🎬 [MEDIA API] === FETCHING MULTIPLE MEDIA RESPONSES ===');
    print('🎬 [MEDIA API] Media IDs: $mediaIds');
    
    final futures = mediaIds.map((mediaId) async {
      try {
        return await getMediaResponse(mediaId);
      } catch (e) {
        print('⚠️ [MEDIA API] Failed to fetch media response for ID: $mediaId - $e');
        return null;
      }
    });
    
    final results = await Future.wait(futures);
    final validResults = results.where((result) => result != null).cast<MediaResponse>().toList();
    
    print('✅ [MEDIA API] Successfully fetched ${validResults.length}/${mediaIds.length} media responses');
    return validResults;
  }

  @override
  Future<Map<String, String>> getMultipleMediaUrls(List<String> mediaIds) async {
    final responses = await getMultipleMediaResponses(mediaIds);
    final urlMap = <String, String>{};
    
    for (int i = 0; i < mediaIds.length; i++) {
      final mediaId = mediaIds[i];
      final response = responses.firstWhere(
        (r) => r.metadata?['id'] == mediaId,
        orElse: () => MediaResponse(),
      );
      
      if (response.isValid) {
        urlMap[mediaId] = response.url!;
      }
    }
    
    return urlMap;
  }

  @override
  Future<Map<String, dynamic>?> getMediaFileInfo(String fileId) async {
    final response = await getMediaResponse(fileId);
    if (response == null) return null;
    
    return {
      'id': fileId,
      'url': response.url,
      'filename': response.filename,
      'size': response.size,
      'type': response.type.toString(),
      'mime_type': response.mimeType,
      'created_at': response.createdAt?.toIso8601String(),
      'metadata': response.metadata,
    };
  }

  // 🔧 MÉTODO PRIVADO PARA EXTRAER URL DE DATA
  String? _extractUrlFromData(Map<String, dynamic> data, String context) {
    final urlFields = context == 'file' 
      ? ['file_url', 'download_url', 'url', 'src', 'path', 'media_url', 'content_url', 'direct_url', 'public_url']
      : ['url', 'media_url', 'file_url', 'download_url', 'src', 'source', 'path', 'location'];
    
    // 🔍 BUSCAR EN NIVEL PRINCIPAL
    for (final field in urlFields) {
      final url = data[field];
      if (url != null && url.toString().trim().isNotEmpty) {
        final urlString = url.toString().trim();
        print('✅ [MEDIA API] Found ${context} URL: $urlString');
        return urlString;
      }
    }
    
    // 🔍 BUSCAR EN DATA ANIDADO
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      final nestedData = data['data'] as Map<String, dynamic>;
      for (final field in urlFields) {
        final url = nestedData[field];
        if (url != null && url.toString().trim().isNotEmpty) {
          final urlString = url.toString().trim();
          print('✅ [MEDIA API] Found ${context} URL in nested data: $urlString');
          return urlString;
        }
      }
    }
    
    // 🔍 BUSCAR EN OBJETO ESPECÍFICO
    final objectKey = context == 'file' ? 'file' : 'media';
    if (data.containsKey(objectKey) && data[objectKey] is Map<String, dynamic>) {
      final objectData = data[objectKey] as Map<String, dynamic>;
      for (final field in urlFields) {
        final url = objectData[field];
        if (url != null && url.toString().trim().isNotEmpty) {
          final urlString = url.toString().trim();
          print('✅ [MEDIA API] Found ${context} URL in ${objectKey} object: $urlString');
          return urlString;
        }
      }
    }
    
    return null;
  }

  // 🔧 MÉTODO PRIVADO PARA CONSTRUIR MEDIARESPONSE
  MediaResponse _buildMediaResponse(Map<String, dynamic> data, String mediaId) {
    final url = _extractUrlFromData(data, isFileId(mediaId) ? 'file' : 'media');
    
    // 🔍 EXTRAER INFORMACIÓN ADICIONAL
    final filename = _extractField(data, ['filename', 'name', 'original_name', 'file_name']);
    final sizeStr = _extractField(data, ['size', 'file_size', 'content_length']);
    final size = sizeStr != null ? int.tryParse(sizeStr.toString()) : null;
    final mimeType = _extractField(data, ['mime_type', 'mimetype', 'content_type', 'type']);
    final createdAtStr = _extractField(data, ['created_at', 'createdAt', 'date_created']);
    
    // 🔍 DETERMINAR TIPO DE MEDIA
    final type = _determineMediaType(mimeType, filename);
    
    // 🔍 PARSEAR FECHA
    DateTime? createdAt;
    if (createdAtStr != null) {
      try {
        createdAt = DateTime.parse(createdAtStr.toString());
      } catch (e) {
        print('⚠️ [MEDIA API] Failed to parse created_at: $createdAtStr');
      }
    }
    
    return MediaResponse(
      url: url,
      filename: filename,
      size: size,
      type: type,
      mimeType: mimeType,
      createdAt: createdAt,
      metadata: {
        'id': mediaId,
        'raw_data': data,
      },
    );
  }

  // 🔧 MÉTODO PRIVADO PARA EXTRAER CAMPO
  String? _extractField(Map<String, dynamic> data, List<String> fieldNames) {
    for (final field in fieldNames) {
      final value = data[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    
    // 🔍 BUSCAR EN DATA ANIDADO
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      final nestedData = data['data'] as Map<String, dynamic>;
      for (final field in fieldNames) {
        final value = nestedData[field];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }
    
    return null;
  }

  // 🔧 MÉTODO PRIVADO PARA DETERMINAR TIPO DE MEDIA
  MediaType _determineMediaType(String? mimeType, String? filename) {
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) return MediaType.image;
      if (mimeType.startsWith('video/')) return MediaType.video;
      if (mimeType.startsWith('audio/')) return MediaType.audio;
      if (mimeType.startsWith('application/pdf') || 
          mimeType.startsWith('application/msword') || 
          mimeType.startsWith('application/vnd.openxmlformats')) {
        return MediaType.document;
      }
    }
    
    if (filename != null) {
      final extension = filename.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'webp':
        case 'svg':
          return MediaType.image;
        case 'mp4':
        case 'avi':
        case 'mov':
        case 'wmv':
        case 'flv':
        case 'webm':
          return MediaType.video;
        case 'mp3':
        case 'wav':
        case 'flac':
        case 'aac':
          return MediaType.audio;
        case 'pdf':
        case 'doc':
        case 'docx':
        case 'xls':
        case 'xlsx':
        case 'ppt':
        case 'pptx':
          return MediaType.document;
      }
    }
    
    return MediaType.unknown;
  }

  // 🔧 MÉTODO MEJORADO PARA RESOLVER MEDIA DE CONTENIDO
  Future<Map<String, String?>> resolveContentMediaWithFiles({
    String? mainMediaId,
    String? thumbnailMediaId,
    String? quality,
  }) async {
    print('🎬 [MEDIA API] === RESOLVING CONTENT MEDIA WITH FILES ===');
    print('🎬 [MEDIA API] Main Media ID: $mainMediaId');
    print('🎬 [MEDIA API] Thumbnail Media ID: $thumbnailMediaId');
    print('🎬 [MEDIA API] Quality: $quality');
    
    String? mainMediaUrl;
    String? thumbnailMediaUrl;
    
    // 🔧 RESOLVER MAIN MEDIA
    if (mainMediaId != null && mainMediaId.isNotEmpty) {
      final mainResponse = await getOptimizedMediaUrl(mainMediaId, quality: quality);
      mainMediaUrl = mainResponse?.url;
      print('✅ [MEDIA API] Main media resolved: ${mainMediaUrl != null ? 'YES' : 'NO'}');
    }
    
    // 🔧 RESOLVER THUMBNAIL MEDIA
    if (thumbnailMediaId != null && thumbnailMediaId.isNotEmpty) {
      final thumbnailResponse = await getOptimizedMediaUrl(thumbnailMediaId, quality: 'thumbnail');
      thumbnailMediaUrl = thumbnailResponse?.url;
      print('✅ [MEDIA API] Thumbnail media resolved: ${thumbnailMediaUrl != null ? 'YES' : 'NO'}');
    }
    
    final result = {
      'mainMediaUrl': mainMediaUrl,
      'thumbnailMediaUrl': thumbnailMediaUrl,
    };
    
    print('✅ [MEDIA API] Final resolved URLs:');
    print('✅ [MEDIA API] - Main: ${result['mainMediaUrl']}');
    print('✅ [MEDIA API] - Thumbnail: ${result['thumbnailMediaUrl']}');
    
    return result;
  }

  // 🔧 MÉTODO MEJORADO PARA VERIFICAR SI UN ID ES DE ARCHIVO
  bool isFileId(String mediaId) {
    return mediaId.contains('file_') || 
           mediaId.contains('media_file') || 
           mediaId.startsWith('f_') ||
           mediaId.startsWith('mf_');
  }
}