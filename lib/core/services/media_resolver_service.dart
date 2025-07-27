// lib/core/services/media_resolver_service.dart - MEJORADO CON CATEGORÍAS
import 'package:injectable/injectable.dart';
import '../../features/learning/data/datasources/media_remote_datasource.dart';
import '../../features/learning/data/models/content_model.dart';

@Injectable()
class MediaResolverService {
  final MediaRemoteDataSource mediaDataSource;

  MediaResolverService(this.mediaDataSource) {
    print('✅ [MEDIA RESOLVER] Service initialized with enhanced category support');
  }

  /// Resuelve las URLs de media para un ContentModel
  Future<ContentModel> resolveMediaUrls(ContentModel content) async {
    try {
      print('🔧 [MEDIA RESOLVER] === RESOLVING MEDIA WITH ENHANCED CATEGORIES ===');
      print('🔧 [MEDIA RESOLVER] Content: "${content.title}"');
      print('🔧 [MEDIA RESOLVER] Main Media ID: ${content.mainMediaId}');
      print('🔧 [MEDIA RESOLVER] Thumbnail Media ID: ${content.thumbnailMediaId}');

      if (!content.hasAnyMedia) {
        print('ℹ️ [MEDIA RESOLVER] No media IDs to resolve');
        return content;
      }

      String? resolvedMainMediaUrl;
      String? resolvedThumbnailUrl;
      final enhancedMetadata = <String, dynamic>{
        ...(content.mediaMetadata ?? {}),
        'resolution_attempted': true,
        'resolution_timestamp': DateTime.now().toIso8601String(),
      };

      // 🔧 RESOLVER MAIN MEDIA
      if (content.hasMainMedia) {
        print('🎬 [MEDIA RESOLVER] Resolving main media: ${content.mainMediaId}');
        
        try {
          final mainMediaResponse = await mediaDataSource.getMediaResponse(content.mainMediaId!);
          
          if (mainMediaResponse?.isValid == true) {
            resolvedMainMediaUrl = mainMediaResponse!.url;
            
            // 🆕 AGREGAR INFORMACIÓN DETALLADA DEL MEDIA PRINCIPAL
            enhancedMetadata.addAll({
              'main_media_resolved': true,
              'main_media_url': resolvedMainMediaUrl,
              'main_media_type': mainMediaResponse.mimeType,
              'main_media_size': mainMediaResponse.size,
              'main_category': mainMediaResponse.category, // 🆕 CATEGORÍA DE LA API
              'main_is_image': mainMediaResponse.isImage,
              'main_is_video': mainMediaResponse.isVideo,
              'main_is_audio': mainMediaResponse.isAudio, // 🆕
              'main_is_document': mainMediaResponse.isDocument, // 🆕
              'main_media_filename': mainMediaResponse.filename,
              'main_media_metadata': mainMediaResponse.metadata,
            });

            print('✅ [MEDIA RESOLVER] Main media resolved successfully');
            print('✅ [MEDIA RESOLVER] - URL: $resolvedMainMediaUrl');
            print('✅ [MEDIA RESOLVER] - Category: ${mainMediaResponse.category}');
            print('✅ [MEDIA RESOLVER] - Type: ${mainMediaResponse.type}');
            print('✅ [MEDIA RESOLVER] - Is Video: ${mainMediaResponse.isVideo}');
            print('✅ [MEDIA RESOLVER] - Is Image: ${mainMediaResponse.isImage}');
            print('✅ [MEDIA RESOLVER] - Is Audio: ${mainMediaResponse.isAudio}');
            print('✅ [MEDIA RESOLVER] - Is Document: ${mainMediaResponse.isDocument}');
            
          } else {
            print('❌ [MEDIA RESOLVER] Main media resolution failed or invalid response');
            enhancedMetadata['main_media_resolved'] = false;
            enhancedMetadata['main_media_error'] = 'Invalid or null response';
          }
        } catch (e) {
          print('❌ [MEDIA RESOLVER] Error resolving main media: $e');
          enhancedMetadata['main_media_resolved'] = false;
          enhancedMetadata['main_media_error'] = e.toString();
        }
      }

      // 🔧 RESOLVER THUMBNAIL MEDIA
      if (content.hasThumbnailMedia) {
        print('🖼️ [MEDIA RESOLVER] Resolving thumbnail media: ${content.thumbnailMediaId}');
        
        try {
          final thumbnailMediaResponse = await mediaDataSource.getMediaResponse(content.thumbnailMediaId!);
          
          if (thumbnailMediaResponse?.isValid == true) {
            resolvedThumbnailUrl = thumbnailMediaResponse!.url;
            
            // 🆕 AGREGAR INFORMACIÓN DETALLADA DEL THUMBNAIL
            enhancedMetadata.addAll({
              'thumbnail_media_resolved': true,
              'thumbnail_media_url': resolvedThumbnailUrl,
              'thumbnail_media_type': thumbnailMediaResponse.mimeType,
              'thumbnail_media_size': thumbnailMediaResponse.size,
              'thumbnail_category': thumbnailMediaResponse.category, // 🆕 CATEGORÍA DE LA API
              'thumbnail_is_image': thumbnailMediaResponse.isImage,
              'thumbnail_is_video': thumbnailMediaResponse.isVideo,
              'thumbnail_is_audio': thumbnailMediaResponse.isAudio, // 🆕
              'thumbnail_is_document': thumbnailMediaResponse.isDocument, // 🆕
              'thumbnail_media_filename': thumbnailMediaResponse.filename,
              'thumbnail_media_metadata': thumbnailMediaResponse.metadata,
            });

            print('✅ [MEDIA RESOLVER] Thumbnail media resolved successfully');
            print('✅ [MEDIA RESOLVER] - URL: $resolvedThumbnailUrl');
            print('✅ [MEDIA RESOLVER] - Category: ${thumbnailMediaResponse.category}');
            print('✅ [MEDIA RESOLVER] - Type: ${thumbnailMediaResponse.type}');
            
          } else {
            print('❌ [MEDIA RESOLVER] Thumbnail media resolution failed or invalid response');
            enhancedMetadata['thumbnail_media_resolved'] = false;
            enhancedMetadata['thumbnail_media_error'] = 'Invalid or null response';
          }
        } catch (e) {
          print('❌ [MEDIA RESOLVER] Error resolving thumbnail media: $e');
          enhancedMetadata['thumbnail_media_resolved'] = false;
          enhancedMetadata['thumbnail_media_error'] = e.toString();
        }
      }

      // 🔧 CREAR CONTENT MODEL CON MEDIA RESUELTO
      final resolvedContent = ContentModel.withResolvedMedia(
        originalContent: content,
        resolvedMediaUrl: resolvedMainMediaUrl,
        resolvedThumbnailUrl: resolvedThumbnailUrl,
        mediaMetadata: enhancedMetadata,
      );

      print('🎉 [MEDIA RESOLVER] === RESOLUTION COMPLETE ===');
      print('🎉 [MEDIA RESOLVER] - Main media resolved: ${resolvedMainMediaUrl != null}');
      print('🎉 [MEDIA RESOLVER] - Thumbnail resolved: ${resolvedThumbnailUrl != null}');
      print('🎉 [MEDIA RESOLVER] - Enhanced metadata entries: ${enhancedMetadata.keys.length}');
      print('🎉 [MEDIA RESOLVER] - Final image URL: ${resolvedContent.finalImageUrl}');

      return resolvedContent;

    } catch (e, stackTrace) {
      print('❌ [MEDIA RESOLVER] === CRITICAL ERROR IN RESOLUTION ===');
      print('❌ [MEDIA RESOLVER] Error: $e');
      print('❌ [MEDIA RESOLVER] Stack trace: $stackTrace');
      
      // 🔧 RETORNAR CONTENT ORIGINAL CON ERROR EN METADATA
      final errorMetadata = <String, dynamic>{
        ...(content.mediaMetadata ?? {}),
        'resolution_attempted': true,
        'resolution_failed': true,
        'resolution_error': e.toString(),
        'resolution_timestamp': DateTime.now().toIso8601String(),
      };

      return ContentModel.withResolvedMedia(
        originalContent: content,
        mediaMetadata: errorMetadata,
      );
    }
  }

  /// 🆕 MÉTODO PARA RESOLVER SOLO UN MEDIA ID ESPECÍFICO
  Future<String?> resolveSingleMediaUrl(String mediaId) async {
    try {
      print('🔧 [MEDIA RESOLVER] Resolving single media ID: $mediaId');
      
      final mediaResponse = await mediaDataSource.getMediaResponse(mediaId);
      
      if (mediaResponse?.isValid == true) {
        print('✅ [MEDIA RESOLVER] Single media resolved: ${mediaResponse!.url}');
        print('✅ [MEDIA RESOLVER] Category: ${mediaResponse.category}, Type: ${mediaResponse.type}');
        return mediaResponse.url;
      } else {
        print('❌ [MEDIA RESOLVER] Single media resolution failed');
        return null;
      }
    } catch (e) {
      print('❌ [MEDIA RESOLVER] Error resolving single media: $e');
      return null;
    }
  }

  /// 🆕 MÉTODO PARA OBTENER INFORMACIÓN COMPLETA DE MEDIA
  Future<MediaResponse?> getMediaInfo(String mediaId) async {
    try {
      print('🔧 [MEDIA RESOLVER] Getting media info for: $mediaId');
      
      final mediaResponse = await mediaDataSource.getMediaResponse(mediaId);
      
      if (mediaResponse?.isValid == true) {
        print('✅ [MEDIA RESOLVER] Media info retrieved successfully');
        print('✅ [MEDIA RESOLVER] - Category: ${mediaResponse!.category}');
        print('✅ [MEDIA RESOLVER] - Type: ${mediaResponse.type}');
        print('✅ [MEDIA RESOLVER] - Is Video: ${mediaResponse.isVideo}');
        print('✅ [MEDIA RESOLVER] - Is Image: ${mediaResponse.isImage}');
        print('✅ [MEDIA RESOLVER] - Is Audio: ${mediaResponse.isAudio}');
        print('✅ [MEDIA RESOLVER] - Is Document: ${mediaResponse.isDocument}');
      }
      
      return mediaResponse;
    } catch (e) {
      print('❌ [MEDIA RESOLVER] Error getting media info: $e');
      return null;
    }
  }

  /// 🆕 MÉTODO PARA VERIFICAR SI UN MEDIA ES DE CIERTO TIPO
  Future<bool> isMediaOfType(String mediaId, MediaType expectedType) async {
    try {
      final mediaResponse = await mediaDataSource.getMediaResponse(mediaId);
      return mediaResponse?.type == expectedType;
    } catch (e) {
      print('❌ [MEDIA RESOLVER] Error checking media type: $e');
      return false;
    }
  }

  /// 🆕 MÉTODO PARA VERIFICAR SI UN MEDIA ES VIDEO POR SU ID
  Future<bool> isVideoMedia(String mediaId) async {
    try {
      final mediaResponse = await mediaDataSource.getMediaResponse(mediaId);
      return mediaResponse?.isVideo ?? false;
    } catch (e) {
      print('❌ [MEDIA RESOLVER] Error checking if media is video: $e');
      return false;
    }
  }

  /// 🆕 MÉTODO PARA VERIFICAR SI UN MEDIA ES IMAGEN POR SU ID
  Future<bool> isImageMedia(String mediaId) async {
    try {
      final mediaResponse = await mediaDataSource.getMediaResponse(mediaId);
      return mediaResponse?.isImage ?? false;
    } catch (e) {
      print('❌ [MEDIA RESOLVER] Error checking if media is image: $e');
      return false;
    }
  }

  /// 🆕 MÉTODO PARA VERIFICAR SI UN MEDIA ES AUDIO POR SU ID
  Future<bool> isAudioMedia(String mediaId) async {
    try {
      final mediaResponse = await mediaDataSource.getMediaResponse(mediaId);
      return mediaResponse?.isAudio ?? false;
    } catch (e) {
      print('❌ [MEDIA RESOLVER] Error checking if media is audio: $e');
      return false;
    }
  }

  /// 🆕 MÉTODO PARA OBTENER ESTADÍSTICAS DE RESOLUCIÓN
  Map<String, dynamic> getResolutionStats(ContentModel content) {
    final metadata = content.mediaMetadata ?? {};
    
    return {
      'has_main_media': content.hasMainMedia,
      'has_thumbnail_media': content.hasThumbnailMedia,
      'main_media_resolved': metadata['main_media_resolved'] ?? false,
      'thumbnail_media_resolved': metadata['thumbnail_media_resolved'] ?? false,
      'resolution_attempted': metadata['resolution_attempted'] ?? false,
      'resolution_failed': metadata['resolution_failed'] ?? false,
      'main_media_category': metadata['main_category'],
      'thumbnail_media_category': metadata['thumbnail_category'],
      'main_is_video': metadata['main_is_video'] ?? false,
      'main_is_image': metadata['main_is_image'] ?? false,
      'main_is_audio': metadata['main_is_audio'] ?? false,
      'main_is_document': metadata['main_is_document'] ?? false,
      'resolution_timestamp': metadata['resolution_timestamp'],
    };
  }

  /// 🆕 MÉTODO PARA LIMPIAR CACHE DE RESOLUCIÓN (si se implementa cache en el futuro)
  void clearResolutionCache() {
    print('🧹 [MEDIA RESOLVER] Cache clearing would be implemented here');
    // TODO: Implementar si se agrega cache de resolución
  }
}