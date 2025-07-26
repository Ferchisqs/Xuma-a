// lib/features/learning/data/datasources/media_remote_datasource.dart - MEJORADO PARA FILES API
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';

// 🆕 ENUM PARA TIPOS DE MEDIA MEJORADO
enum MediaType {
  image,
  video,
  audio,
  document,
  unknown
}

// 🆕 CLASE PARA RESPUESTA DE MEDIA MEJORADA CON NUEVA ESTRUCTURA
class MediaResponse {
  final String? url;
  final String? publicUrl; // 🆕 NUEVO CAMPO
  final String? filename;
  final String? originalName; // 🆕 NUEVO CAMPO
  final int? size;
  final int? fileSize; // 🆕 NUEVO CAMPO
  final MediaType type;
  final String? mimeType;
  final String? fileType;
  final String? category; // 🆕 NUEVO CAMPO
  final bool? isPublic; // 🆕 NUEVO CAMPO
  final bool? isProcessed; // 🆕 NUEVO CAMPO
  final String? virusScanStatus; // 🆕 NUEVO CAMPO
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final bool isValid;

  MediaResponse({
    this.url,
    this.publicUrl,
    this.filename,
    this.originalName,
    this.size,
    this.fileSize,
    this.type = MediaType.unknown,
    this.mimeType,
    this.fileType,
    this.category,
    this.isPublic,
    this.isProcessed,
    this.virusScanStatus,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  }) : isValid = (url != null && url!.isNotEmpty) || (publicUrl != null && publicUrl!.isNotEmpty);

  // 🆕 GETTER PARA URL FINAL (prioriza publicUrl)
  String? get finalUrl => publicUrl ?? url;

  bool get isImage => type == MediaType.image || 
                     (mimeType?.startsWith('image/') ?? false) ||
                     (fileType?.startsWith('image/') ?? false) ||
                     category == 'image';
  
  bool get isVideo => type == MediaType.video || 
                     (mimeType?.startsWith('video/') ?? false) ||
                     (fileType?.startsWith('video/') ?? false) ||
                     category == 'video';
  
  bool get isAudio => type == MediaType.audio || 
                     (mimeType?.startsWith('audio/') ?? false) ||
                     (fileType?.startsWith('audio/') ?? false) ||
                     category == 'audio';

  bool get isDocument => type == MediaType.document || 
                        (mimeType?.contains('pdf') ?? false) ||
                        (fileType?.contains('document') ?? false) ||
                        category == 'document';

  // 🆕 GETTER PARA TAMAÑO FINAL
  int? get finalSize => fileSize ?? size;

  // 🆕 GETTER PARA NOMBRE FINAL
  String? get finalName => originalName ?? filename;

  // 🆕 MÉTODO PARA DEBUG MEJORADO
  @override
  String toString() {
    return 'MediaResponse('
        'finalUrl: $finalUrl, '
        'type: $type, '
        'category: $category, '
        'mimeType: $mimeType, '
        'fileType: $fileType, '
        'isValid: $isValid, '
        'isPublic: $isPublic, '
        'isProcessed: $isProcessed'
        ')';
  }
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
  
  // 🆕 MÉTODO ESPECÍFICO PARA FILES API MEJORADO
  Future<MediaResponse?> getFileMediaResponse(String fileId);
}

@Injectable(as: MediaRemoteDataSource)
class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  final ApiClient apiClient;

  MediaRemoteDataSourceImpl(this.apiClient);

  @override
  Future<String?> getMediaUrl(String mediaId) async {
    final response = await getMediaResponse(mediaId);
    return response?.finalUrl;
  }

  @override
  Future<String?> getMediaFileUrl(String fileId) async {
    final response = await getFileMediaResponse(fileId);
    return response?.finalUrl;
  }

  // 🔧 MÉTODO PRINCIPAL MEJORADO PARA DETECTAR TIPO DE ID
  @override
  Future<MediaResponse?> getMediaResponse(String mediaId) async {
    try {
      print('🎬 [MEDIA API] === GETTING MEDIA RESPONSE ===');
      print('🎬 [MEDIA API] Media ID: $mediaId');
      
      // 🔧 DETECTAR SI ES FILE ID Y USAR ENDPOINT CORRECTO
      if (_isFileId(mediaId)) {
        print('🎬 [MEDIA API] Detected as file ID, using files endpoint');
        return await getFileMediaResponse(mediaId);
      } else {
        print('🎬 [MEDIA API] Detected as media ID, using media endpoint');
        return await _getRegularMediaResponse(mediaId);
      }
      
    } catch (e, stackTrace) {
      print('❌ [MEDIA API] Error in getMediaResponse: $e');
      print('❌ [MEDIA API] Stack trace: $stackTrace');
      return null;
    }
  }

  // 🆕 MÉTODO ESPECÍFICO PARA FILES API MEJORADO CON NUEVA ESTRUCTURA
  @override
  Future<MediaResponse?> getFileMediaResponse(String fileId) async {
    try {
      print('📁 [MEDIA API] === FETCHING FILE MEDIA RESPONSE ===');
      print('📁 [MEDIA API] File ID: $fileId');
      
      // 🔧 USAR EL ENDPOINT CORRECTO PARA FILES
      final endpoint = '/api/media/files/$fileId';
      print('📁 [MEDIA API] Using endpoint: $endpoint');
      
      final response = await apiClient.get(endpoint);
      
      print('📁 [MEDIA API] Response Status: ${response.statusCode}');
      print('📁 [MEDIA API] Response Data Type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200 && response.data != null) {
        
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          print('📁 [MEDIA API] Response keys: ${responseMap.keys.toList()}');
          
          // 🔧 VERIFICAR ESTRUCTURA DE RESPUESTA
          if (responseMap.containsKey('success') && responseMap['success'] == true) {
            final data = responseMap['data'] as Map<String, dynamic>?;
            if (data != null) {
              print('📁 [MEDIA API] Data keys: ${data.keys.toList()}');
              print('📁 [MEDIA API] Sample data: ${_getSafeDataSample(data)}');
              
              return _buildFileMediaResponseFromNewStructure(data, fileId);
            } else {
              print('⚠️ [MEDIA API] No data field in successful response');
              return null;
            }
          } else {
            // Estructura antigua o directa
            print('📁 [MEDIA API] Using legacy structure');
            return _buildFileMediaResponse(responseMap, fileId);
          }
        } else if (response.data is String) {
          // Si la respuesta es directamente una URL
          final urlString = response.data.toString().trim();
          if (urlString.isNotEmpty && _isValidUrl(urlString)) {
            print('✅ [MEDIA API] Direct URL response: $urlString');
            return MediaResponse(
              publicUrl: urlString,
              type: _determineTypeFromUrl(urlString),
              metadata: {'id': fileId, 'source': 'direct_url'},
            );
          }
        }
      }
      
      print('⚠️ [MEDIA API] Invalid or empty response for file ID: $fileId');
      return null;
      
    } catch (e, stackTrace) {
      print('❌ [MEDIA API] === ERROR FETCHING FILE MEDIA ===');
      print('❌ [MEDIA API] File ID: $fileId');
      print('❌ [MEDIA API] Error: $e');
      print('❌ [MEDIA API] Stack trace: $stackTrace');
      return null;
    }
  }

  // 🆕 CONSTRUIR RESPUESTA DESDE NUEVA ESTRUCTURA DE API
  MediaResponse _buildFileMediaResponseFromNewStructure(Map<String, dynamic> data, String fileId) {
    print('🔧 [MEDIA API] Building file media response from new structure...');
    
    // 🔍 EXTRAER CAMPOS DE LA NUEVA ESTRUCTURA
    final id = _extractStringFromData(data, 'id');
    final originalName = _extractStringFromData(data, 'originalName');
    final fileType = _extractStringFromData(data, 'fileType');
    final mimeType = _extractStringFromData(data, 'mimeType');
    final fileSize = _extractIntFromData(data, 'fileSize');
    final category = _extractStringFromData(data, 'category');
    final publicUrl = _extractStringFromData(data, 'publicUrl'); // 🔥 CAMPO PRINCIPAL
    final isPublic = _extractBoolFromData(data, 'isPublic');
    final isProcessed = _extractBoolFromData(data, 'isProcessed');
    final virusScanStatus = _extractStringFromData(data, 'virusScanStatus');
    final userId = _extractStringFromData(data, 'userId');
    
    // 🔍 PARSEAR FECHAS
    DateTime? createdAt;
    DateTime? updatedAt;
    
    final createdAtStr = _extractStringFromData(data, 'createdAt');
    if (createdAtStr != null) {
      try {
        createdAt = DateTime.parse(createdAtStr);
      } catch (e) {
        print('⚠️ [MEDIA API] Failed to parse createdAt: $createdAtStr');
      }
    }
    
    final updatedAtStr = _extractStringFromData(data, 'updatedAt');
    if (updatedAtStr != null) {
      try {
        updatedAt = DateTime.parse(updatedAtStr);
      } catch (e) {
        print('⚠️ [MEDIA API] Failed to parse updatedAt: $updatedAtStr');
      }
    }
    
    // 🔍 EXTRAER METADATA
    Map<String, dynamic>? metadata;
    if (data.containsKey('metadata') && data['metadata'] is Map<String, dynamic>) {
      metadata = data['metadata'] as Map<String, dynamic>;
    }
    
    // 🔍 DETERMINAR TIPO DE MEDIA
    final type = _determineMediaType(mimeType: mimeType, fileType: fileType, filename: originalName, category: category);
    
    final response = MediaResponse(
      url: publicUrl, // Para compatibilidad
      publicUrl: publicUrl, // 🔥 NUEVO CAMPO PRINCIPAL
      filename: originalName,
      originalName: originalName,
      size: fileSize,
      fileSize: fileSize,
      type: type,
      mimeType: mimeType,
      fileType: fileType,
      category: category,
      isPublic: isPublic,
      isProcessed: isProcessed,
      virusScanStatus: virusScanStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: {
        'id': id ?? fileId,
        'userId': userId,
        'source': 'files_api_new_structure',
        'raw_data': data,
        ...?metadata,
      },
    );
    
    print('🔧 [MEDIA API] Built file response from new structure: $response');
    return response;
  }

  // 🔧 CONSTRUIR RESPUESTA PARA ESTRUCTURA LEGACY
  MediaResponse _buildFileMediaResponse(Map<String, dynamic> data, String fileId) {
    print('🔧 [MEDIA API] Building file media response from legacy structure...');
    
    // 🔍 BUSCAR URL EN MÚLTIPLES CAMPOS POSIBLES
    final urlFields = [
      'publicUrl', 'url', 'fileUrl', 'file_url', 'downloadUrl', 'download_url',
      'accessUrl', 'access_url', 'src', 'source', 'path', 'location', 'link'
    ];
    
    String? url;
    for (final field in urlFields) {
      final value = _extractStringFromData(data, field);
      if (value != null && _isValidUrl(value)) {
        url = value;
        print('✅ [MEDIA API] Found URL in field "$field": $url');
        break;
      }
    }
    
    // Si no encontramos URL en nivel principal, buscar en objetos anidados
    if (url == null) {
      final nestedObjects = ['file', 'media', 'data', 'result'];
      for (final objKey in nestedObjects) {
        if (data.containsKey(objKey) && data[objKey] is Map<String, dynamic>) {
          final nestedData = data[objKey] as Map<String, dynamic>;
          for (final field in urlFields) {
            final value = _extractStringFromData(nestedData, field);
            if (value != null && _isValidUrl(value)) {
              url = value;
              print('✅ [MEDIA API] Found URL in nested "$objKey.$field": $url');
              break;
            }
          }
          if (url != null) break;
        }
      }
    }
    
    // 🔍 EXTRAER METADATA ADICIONAL
    final filename = _extractStringFromData(data, 'filename') ?? 
                    _extractStringFromData(data, 'originalName') ?? 
                    _extractStringFromData(data, 'name');
    
    final sizeStr = _extractStringFromData(data, 'size') ?? 
                   _extractStringFromData(data, 'fileSize');
    final size = sizeStr != null ? int.tryParse(sizeStr.toString()) : null;
    
    final mimeType = _extractStringFromData(data, 'mimeType') ?? 
                    _extractStringFromData(data, 'contentType');
                    
    final fileType = _extractStringFromData(data, 'fileType') ?? 
                    _extractStringFromData(data, 'type');
    
    final category = _extractStringFromData(data, 'category');
    
    final createdAtStr = _extractStringFromData(data, 'createdAt') ?? 
                        _extractStringFromData(data, 'created_at');
    
    // 🔍 DETERMINAR TIPO DE MEDIA
    final type = _determineMediaType(mimeType: mimeType, fileType: fileType, filename: filename, category: category);
    
    // 🔍 PARSEAR FECHA
    DateTime? createdAt;
    if (createdAtStr != null) {
      try {
        createdAt = DateTime.parse(createdAtStr);
      } catch (e) {
        print('⚠️ [MEDIA API] Failed to parse createdAt: $createdAtStr');
      }
    }
    
    final response = MediaResponse(
      url: url,
      publicUrl: url, // Usar la misma URL como publicUrl
      filename: filename,
      originalName: filename,
      size: size,
      fileSize: size,
      type: type,
      mimeType: mimeType,
      fileType: fileType,
      category: category,
      createdAt: createdAt,
      metadata: {
        'id': fileId,
        'source': 'files_api_legacy',
        'raw_data': data,
      },
    );
    
    print('🔧 [MEDIA API] Built file response from legacy structure: $response');
    return response;
  }

  // 🔧 MÉTODO PARA MEDIA REGULAR (NO FILES)
  Future<MediaResponse?> _getRegularMediaResponse(String mediaId) async {
    try {
      print('🎬 [MEDIA API] === FETCHING REGULAR MEDIA ===');
      print('🎬 [MEDIA API] Media ID: $mediaId');
      
      final endpoint = '/api/media/$mediaId';
      final response = await apiClient.get(endpoint);
      
      print('🎬 [MEDIA API] Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return _buildRegularMediaResponse(data, mediaId);
      }
      
      return null;
      
    } catch (e) {
      print('❌ [MEDIA API] Error fetching regular media: $e');
      return null;
    }
  }

  // 🔧 CONSTRUIR RESPUESTA PARA MEDIA REGULAR
  MediaResponse _buildRegularMediaResponse(Map<String, dynamic> data, String mediaId) {
    print('🔧 [MEDIA API] Building regular media response...');
    
    final url = _extractUrlFromData(data, 'media');
    final filename = _extractStringFromData(data, 'filename');
    final sizeStr = _extractStringFromData(data, 'size');
    final size = sizeStr != null ? int.tryParse(sizeStr.toString()) : null;
    final mimeType = _extractStringFromData(data, 'mimeType');
    final type = _determineMediaType(mimeType: mimeType, filename: filename);
    
    return MediaResponse(
      url: url,
      publicUrl: url, // Usar la misma URL como publicUrl
      filename: filename,
      originalName: filename,
      size: size,
      fileSize: size,
      type: type,
      mimeType: mimeType,
      metadata: {
        'id': mediaId,
        'source': 'media_api',
        'raw_data': data,
      },
    );
  }

  // 🔧 MÉTODO MEJORADO PARA DETERMINAR TIPO DE MEDIA
  MediaType _determineMediaType({String? mimeType, String? fileType, String? filename, String? category}) {
    // Prioridad: category > mimeType > fileType > filename
    if (category != null) {
      final lowerCategory = category.toLowerCase();
      if (lowerCategory == 'image') return MediaType.image;
      if (lowerCategory == 'video') return MediaType.video;
      if (lowerCategory == 'audio') return MediaType.audio;
      if (lowerCategory == 'document') return MediaType.document;
    }
    
    final typeToCheck = mimeType ?? fileType;
    
    if (typeToCheck != null) {
      final lowerType = typeToCheck.toLowerCase();
      
      if (lowerType.startsWith('image/')) return MediaType.image;
      if (lowerType.startsWith('video/')) return MediaType.video;
      if (lowerType.startsWith('audio/')) return MediaType.audio;
      if (lowerType.contains('pdf') || 
          lowerType.contains('document') || 
          lowerType.contains('text/')) return MediaType.document;
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
        case 'bmp':
          return MediaType.image;
        case 'mp4':
        case 'avi':
        case 'mov':
        case 'wmv':
        case 'flv':
        case 'webm':
        case 'mkv':
          return MediaType.video;
        case 'mp3':
        case 'wav':
        case 'flac':
        case 'aac':
        case 'ogg':
          return MediaType.audio;
        case 'pdf':
        case 'doc':
        case 'docx':
        case 'txt':
          return MediaType.document;
      }
    }
    
    return MediaType.unknown;
  }

  // 🔧 DETECTAR SI ES FILE ID
  bool _isFileId(String mediaId) {
    // Patrones comunes para file IDs
    return mediaId.contains('file') || 
           mediaId.contains('media') ||
           mediaId.length > 30; // UUIDs suelen ser largos
  }

  // 🔧 DETERMINAR TIPO DESDE URL
  MediaType _determineTypeFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    if (lowerUrl.contains('.jpg') || lowerUrl.contains('.jpeg') || 
        lowerUrl.contains('.png') || lowerUrl.contains('.gif') ||
        lowerUrl.contains('.webp')) {
      return MediaType.image;
    }
    
    if (lowerUrl.contains('.mp4') || lowerUrl.contains('.avi') || 
        lowerUrl.contains('.mov') || lowerUrl.contains('.webm')) {
      return MediaType.video;
    }
    
    if (lowerUrl.contains('.mp3') || lowerUrl.contains('.wav') || 
        lowerUrl.contains('.flac')) {
      return MediaType.audio;
    }
    
    return MediaType.unknown;
  }

  // 🔧 VALIDAR URL
  bool _isValidUrl(String url) {
    return url.isNotEmpty && 
           (url.startsWith('http://') || 
            url.startsWith('https://') || 
            url.startsWith('/') || 
            url.startsWith('data:'));
  }

  // 🔧 EXTRAER STRING DE DATA
  String? _extractStringFromData(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      final stringValue = value.toString().trim();
      if (stringValue != 'null' && stringValue != 'undefined') {
        return stringValue;
      }
    }
    return null;
  }

  // 🆕 EXTRAER INT DE DATA
  int? _extractIntFromData(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value != null) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
    }
    return null;
  }

  // 🆕 EXTRAER BOOL DE DATA
  bool? _extractBoolFromData(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value != null) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value == 1;
    }
    return null;
  }

  // 🔧 EXTRAER URL DE DATA (MÉTODO EXISTENTE MEJORADO)
  String? _extractUrlFromData(Map<String, dynamic> data, String context) {
    final urlFields = [
      'publicUrl', 'url', 'media_url', 'file_url', 'download_url', 'public_url',
      'src', 'source', 'path', 'location', 'link'
    ];
    
    for (final field in urlFields) {
      final url = _extractStringFromData(data, field);
      if (url != null && _isValidUrl(url)) {
        return url;
      }
    }
    
    // Buscar en data anidado
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      final nestedData = data['data'] as Map<String, dynamic>;
      for (final field in urlFields) {
        final url = _extractStringFromData(nestedData, field);
        if (url != null && _isValidUrl(url)) {
          return url;
        }
      }
    }
    
    return null;
  }

  // 🔧 OBTENER MUESTRA SEGURA DE DATA
  String _getSafeDataSample(Map<String, dynamic> data) {
    try {
      final sample = <String, dynamic>{};
      
      // Solo incluir campos importantes para debug
      final importantFields = ['publicUrl', 'url', 'fileUrl', 'originalName', 'mimeType', 'fileType', 'fileSize', 'category'];
      
      for (final field in importantFields) {
        if (data.containsKey(field)) {
          sample[field] = data[field];
        }
      }
      
      final result = sample.toString();
      return result.length > 200 ? '${result.substring(0, 200)}...' : result;
    } catch (e) {
      return 'Error creating sample: $e';
    }
  }

  // ==================== MÉTODOS EXISTENTES ACTUALIZADOS ====================

  @override
  Future<MediaResponse?> getOptimizedMediaUrl(String mediaId, {String? quality}) async {
    try {
      print('🎯 [MEDIA API] === FETCHING OPTIMIZED MEDIA ===');
      print('🎯 [MEDIA API] Media ID: $mediaId, Quality: $quality');
      
      // Intentar obtener versión optimizada primero
      final queryParams = quality != null ? '?quality=$quality' : '';
      final endpoint = '/api/media/$mediaId/optimized$queryParams';
      
      try {
        final response = await apiClient.get(endpoint);
        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          return _buildRegularMediaResponse(response.data, mediaId);
        }
      } catch (e) {
        print('⚠️ [MEDIA API] Optimized endpoint not available: $e');
      }
      
      // Fallback a versión original
      print('🔄 [MEDIA API] Fallback to original media');
      return await getMediaResponse(mediaId);
      
    } catch (e) {
      print('❌ [MEDIA API] Error fetching optimized media: $e');
      return await getMediaResponse(mediaId);
    }
  }

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
      final response = responses.where((r) => r.metadata?['id'] == mediaId).firstOrNull;
      
      if (response?.isValid == true) {
        urlMap[mediaId] = response!.finalUrl!;
      }
    }
    
    return urlMap;
  }

  @override
  Future<Map<String, dynamic>?> getMediaFileInfo(String fileId) async {
    final response = await getFileMediaResponse(fileId);
    if (response == null) return null;
    
    return {
      'id': fileId,
      'url': response.finalUrl,
      'publicUrl': response.publicUrl,
      'filename': response.finalName,
      'originalName': response.originalName,
      'size': response.finalSize,
      'fileSize': response.fileSize,
      'type': response.type.toString(),
      'mime_type': response.mimeType,
      'file_type': response.fileType,
      'category': response.category,
      'is_public': response.isPublic,
      'is_processed': response.isProcessed,
      'virus_scan_status': response.virusScanStatus,
      'created_at': response.createdAt?.toIso8601String(),
      'updated_at': response.updatedAt?.toIso8601String(),
      'metadata': response.metadata,
      'is_image': response.isImage,
      'is_video': response.isVideo,
      'is_audio': response.isAudio,
      'is_document': response.isDocument,
    };
  }
}