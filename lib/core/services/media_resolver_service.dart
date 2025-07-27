// lib/core/services/media_resolver_service.dart
import '../../features/learning/data/datasources/media_remote_datasource.dart';
import '../../features/learning/data/models/content_model.dart';

class MediaResolverService {
  final MediaRemoteDataSource mediaDataSource;

  MediaResolverService(this.mediaDataSource);

  /// Resuelve las URLs de media para un ContentModel
  Future<ContentModel> resolveMediaUrls(ContentModel content) async {
    print('🎬 [MEDIA RESOLVER] === RESOLVING MEDIA FOR CONTENT ===');
    print('🎬 [MEDIA RESOLVER] Content: ${content.title}');
    print('🎬 [MEDIA RESOLVER] Main Media ID: ${content.mainMediaId}');
    print('🎬 [MEDIA RESOLVER] Thumbnail Media ID: ${content.thumbnailMediaId}');

    if (!content.hasAnyMedia) {
      print('🎬 [MEDIA RESOLVER] No media IDs found, returning original content');
      return content;
    }

    String? resolvedMediaUrl;
    String? resolvedThumbnailUrl;
    final mediaMetadata = <String, dynamic>{
      ...(content.mediaMetadata ?? {}),
    };

    // 🔧 RESOLVER MAIN MEDIA URL
    if (content.hasMainMedia) {
      try {
        print('🎬 [MEDIA RESOLVER] Resolving main media: ${content.mainMediaId}');
        final mediaResponse = await mediaDataSource.getMediaResponse(content.mainMediaId!);
        
        if (mediaResponse != null && mediaResponse.isValid) {
          resolvedMediaUrl = mediaResponse.url;
          print('✅ [MEDIA RESOLVER] Main media resolved: $resolvedMediaUrl');
          
          // Agregar metadata del media principal
          mediaMetadata.addAll({
            'main_media_type': mediaResponse.mimeType,
            'main_is_video': mediaResponse.isVideo,
            'main_is_image': mediaResponse.isImage,
            'main_filename': mediaResponse.filename,
            'main_size': mediaResponse.size,
          });
          // Propagate category if present in metadata
          if (mediaResponse.metadata != null && mediaResponse.metadata!.containsKey('category')) {
            mediaMetadata['main_category'] = mediaResponse.metadata!['category'];
          }
        } else {
          print('❌ [MEDIA RESOLVER] Failed to resolve main media: ${content.mainMediaId}');
        }
      } catch (e) {
        print('❌ [MEDIA RESOLVER] Error resolving main media: $e');
      }
    }

    // 🔧 RESOLVER THUMBNAIL MEDIA URL
    if (content.hasThumbnailMedia) {
      try {
        print('🎬 [MEDIA RESOLVER] Resolving thumbnail media: ${content.thumbnailMediaId}');
        final mediaResponse = await mediaDataSource.getMediaResponse(content.thumbnailMediaId!);
        
        if (mediaResponse != null && mediaResponse.isValid) {
          resolvedThumbnailUrl = mediaResponse.url;
          print('✅ [MEDIA RESOLVER] Thumbnail media resolved: $resolvedThumbnailUrl');
          
          // Agregar metadata del thumbnail
          mediaMetadata.addAll({
            'thumbnail_media_type': mediaResponse.mimeType,
            'thumbnail_is_image': mediaResponse.isImage,
            'thumbnail_filename': mediaResponse.filename,
            'thumbnail_size': mediaResponse.size,
          });
        } else {
          print('❌ [MEDIA RESOLVER] Failed to resolve thumbnail media: ${content.thumbnailMediaId}');
        }
      } catch (e) {
        print('❌ [MEDIA RESOLVER] Error resolving thumbnail media: $e');
      }
    }

    // 🔧 CREAR CONTENT CON MEDIA RESUELTO
    final resolvedContent = ContentModel.withResolvedMedia(
      originalContent: content,
      resolvedMediaUrl: resolvedMediaUrl,
      resolvedThumbnailUrl: resolvedThumbnailUrl,
      mediaMetadata: mediaMetadata,
    );

    print('🎬 [MEDIA RESOLVER] === RESOLUTION COMPLETE ===');
    print('🎬 [MEDIA RESOLVER] Has resolved main media: ${resolvedContent.hasResolvedMainMedia}');
    print('🎬 [MEDIA RESOLVER] Has resolved thumbnail: ${resolvedContent.hasResolvedThumbnailMedia}');
    print('🎬 [MEDIA RESOLVER] Final media URL: ${resolvedContent.mediaUrl}');
    print('🎬 [MEDIA RESOLVER] Final thumbnail URL: ${resolvedContent.thumbnailUrl}');

    return resolvedContent;
  }

  /// Resuelve media para una lista de contenidos
  Future<List<ContentModel>> resolveMediaUrlsForList(List<ContentModel> contents) async {
    print('🎬 [MEDIA RESOLVER] Resolving media for ${contents.length} contents');
    
    final resolvedContents = <ContentModel>[];
    
    for (final content in contents) {
      try {
        final resolved = await resolveMediaUrls(content);
        resolvedContents.add(resolved);
      } catch (e) {
        print('❌ [MEDIA RESOLVER] Failed to resolve media for ${content.id}: $e');
        // Agregar contenido original si falla la resolución
        resolvedContents.add(content);
      }
    }
    
    print('✅ [MEDIA RESOLVER] Resolved media for ${resolvedContents.length} contents');
    return resolvedContents;
  }

  /// Resuelve solo una URL específica (para casos específicos)
  Future<String?> resolveMediaUrl(String mediaId) async {
    try {
      print('🎬 [MEDIA RESOLVER] Resolving single media URL: $mediaId');
      final mediaResponse = await mediaDataSource.getMediaResponse(mediaId);
      
      if (mediaResponse != null && mediaResponse.isValid) {
        print('✅ [MEDIA RESOLVER] Single media resolved: ${mediaResponse.url}');
        return mediaResponse.url;
      }
      
      print('❌ [MEDIA RESOLVER] Failed to resolve single media: $mediaId');
      return null;
    } catch (e) {
      print('❌ [MEDIA RESOLVER] Error resolving single media: $e');
      return null;
    }
  }
}