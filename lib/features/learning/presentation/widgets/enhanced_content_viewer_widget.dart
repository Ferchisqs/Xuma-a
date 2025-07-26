// lib/features/learning/presentation/widgets/enhanced_content_viewer_widget.dart - COMPLETO Y CORREGIDO
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/content_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../data/models/content_model.dart';
import '../../data/datasources/media_remote_datasource.dart';

class EnhancedContentViewerWidget extends StatefulWidget {
  final ContentEntity content;
  final TopicEntity topic;

  const EnhancedContentViewerWidget({
    Key? key,
    required this.content,
    required this.topic,
  }) : super(key: key);

  @override
  State<EnhancedContentViewerWidget> createState() => _EnhancedContentViewerWidgetState();
}

class _EnhancedContentViewerWidgetState extends State<EnhancedContentViewerWidget> {
  bool _isCompleted = false;
  bool _showMediaDetails = false;
  MediaResponse? _resolvedMainMedia;
  MediaResponse? _resolvedThumbnailMedia;
  bool _isLoadingMedia = false;
  String? _mediaError;
  MediaRemoteDataSource? _mediaDataSource;
  
  @override
  void initState() {
    super.initState();
    _initializeMediaDataSource();
  }

  // 🔧 INICIALIZAR EL DATASOURCE DE MEDIA
  void _initializeMediaDataSource() {
    try {
      _mediaDataSource = getIt<MediaRemoteDataSource>();
      print('✅ [ENHANCED CONTENT VIEWER] MediaDataSource initialized');
      _loadMediaIfAvailable();
    } catch (e) {
      print('❌ [ENHANCED CONTENT VIEWER] Error initializing MediaDataSource: $e');
      setState(() {
        _mediaError = 'Error inicializando servicio de media: $e';
      });
    }
  }

  // 🔧 CARGAR MEDIA SI ESTÁ DISPONIBLE
  Future<void> _loadMediaIfAvailable() async {
    if (_mediaDataSource == null) {
      print('❌ [ENHANCED CONTENT VIEWER] MediaDataSource not available');
      return;
    }

    final contentModel = widget.content is ContentModel ? widget.content as ContentModel : null;
    
    if (contentModel?.hasAnyMedia != true) {
      print('ℹ️ [ENHANCED CONTENT VIEWER] No media IDs available');
      return;
    }

    setState(() {
      _isLoadingMedia = true;
      _mediaError = null;
    });

    try {
      print('🔄 [ENHANCED CONTENT VIEWER] Loading media for content: ${widget.content.title}');
      print('🔄 [ENHANCED CONTENT VIEWER] Main Media ID: ${contentModel!.mainMediaId}');
      print('🔄 [ENHANCED CONTENT VIEWER] Thumbnail Media ID: ${contentModel.thumbnailMediaId}');

      // 🔧 RESOLVER MAIN MEDIA
      if (contentModel.hasMainMedia) {
        try {
          print('🔄 [ENHANCED CONTENT VIEWER] Resolving main media: ${contentModel.mainMediaId}');
          final mainResponse = await _mediaDataSource!.getFileMediaResponse(contentModel.mainMediaId!);
          
          if (mainResponse?.isValid == true) {
            _resolvedMainMedia = mainResponse;
            print('✅ [ENHANCED CONTENT VIEWER] Main media resolved: ${mainResponse!.finalUrl}');
          } else {
            print('❌ [ENHANCED CONTENT VIEWER] Main media resolution failed');
          }
        } catch (e) {
          print('❌ [ENHANCED CONTENT VIEWER] Error resolving main media: $e');
        }
      }

      // 🔧 RESOLVER THUMBNAIL MEDIA
      if (contentModel.hasThumbnailMedia) {
        try {
          print('🔄 [ENHANCED CONTENT VIEWER] Resolving thumbnail media: ${contentModel.thumbnailMediaId}');
          final thumbnailResponse = await _mediaDataSource!.getFileMediaResponse(contentModel.thumbnailMediaId!);
          
          if (thumbnailResponse?.isValid == true) {
            _resolvedThumbnailMedia = thumbnailResponse;
            print('✅ [ENHANCED CONTENT VIEWER] Thumbnail media resolved: ${thumbnailResponse!.finalUrl}');
          } else {
            print('❌ [ENHANCED CONTENT VIEWER] Thumbnail media resolution failed');
          }
        } catch (e) {
          print('❌ [ENHANCED CONTENT VIEWER] Error resolving thumbnail media: $e');
        }
      }

    } catch (e, stackTrace) {
      print('❌ [ENHANCED CONTENT VIEWER] General error loading media: $e');
      print('❌ [ENHANCED CONTENT VIEWER] Stack trace: $stackTrace');
      setState(() {
        _mediaError = 'Error cargando multimedia: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMedia = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final contentModel = widget.content is ContentModel ? widget.content as ContentModel : null;
    
    print('🔍 [ENHANCED CONTENT VIEWER] Building enhanced widget for content: ${widget.content.title}');
    print('🔍 [ENHANCED CONTENT VIEWER] Has content model: ${contentModel != null}');
    print('🔍 [ENHANCED CONTENT VIEWER] Has any media: ${contentModel?.hasAnyMedia}');
    print('🔍 [ENHANCED CONTENT VIEWER] Is loading media: $_isLoadingMedia');
    print('🔍 [ENHANCED CONTENT VIEWER] Resolved main media: ${_resolvedMainMedia?.finalUrl}');
    print('🔍 [ENHANCED CONTENT VIEWER] Resolved thumbnail media: ${_resolvedThumbnailMedia?.finalUrl}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta principal del contenido
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título del contenido
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: _buildContentHeader(contentModel),
              ),
              
              // 🔧 SECCIÓN DE MULTIMEDIA MEJORADA
              _buildEnhancedMediaSection(contentModel),
              
              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildContentBody(contentModel),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 🆕 INFORMACIÓN DETALLADA DE MEDIA (EXPANDIBLE)
        if (contentModel?.hasAnyMedia == true || _resolvedMainMedia != null || _resolvedThumbnailMedia != null)
          _buildMediaDetailsSection(contentModel),
        
        const SizedBox(height: 24),
        
        // Botón de completado
        _buildCompletionButton(),
        
        const SizedBox(height: 32),
      ],
    );
  }

  // 🆕 HEADER DEL CONTENIDO MEJORADO
  Widget _buildContentHeader(ContentModel? contentModel) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.content.title,
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Badges de categoría y media
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildBadge(widget.content.category, Icons.category),
                  if (_isLoadingMedia)
                    _buildBadge('Cargando...', Icons.hourglass_empty),
                  if (_resolvedMainMedia != null) ...[
                    _buildBadge(
                      _resolvedMainMedia!.isVideo ? 'Video' : _resolvedMainMedia!.isImage ? 'Imagen' : 'Media',
                      _resolvedMainMedia!.isVideo ? Icons.videocam : Icons.perm_media,
                    ),
                  ],
                  if (_resolvedThumbnailMedia != null)
                    _buildBadge('Miniatura', Icons.image),
                  if (_mediaError != null)
                    _buildBadge('Error', Icons.error, color: Colors.red.withOpacity(0.8)),
                ],
              ),
            ],
          ),
        ),
        Icon(
          Icons.article_outlined,
          color: Colors.white.withOpacity(0.8),
          size: 32,
        ),
      ],
    );
  }

  // 🆕 BADGE HELPER MEJORADO
  Widget _buildBadge(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 SECCIÓN DE MULTIMEDIA MEJORADA CON NUEVA API
  Widget _buildEnhancedMediaSection(ContentModel? contentModel) {
    // Si está cargando
    if (_isLoadingMedia) {
      return _buildLoadingMediaSection();
    }

    // Si hay error
    if (_mediaError != null) {
      return _buildMediaErrorSection();
    }

    // Si no hay media resuelta
    if (_resolvedMainMedia == null && _resolvedThumbnailMedia == null) {
      return _buildMediaPlaceholder(contentModel);
    }

    // Decidir qué mostrar: main media o thumbnail
    final mediaToShow = _resolvedMainMedia ?? _resolvedThumbnailMedia!;
    
    return Container(
      height: 300,
      width: double.infinity,
      child: Stack(
        children: [
          // Media principal
          if (mediaToShow.isVideo)
            _buildVideoPlayer(mediaToShow)
          else if (mediaToShow.isImage)
            _buildImageViewer(mediaToShow)
          else
            _buildGenericMediaViewer(mediaToShow),
          
          // Overlay con información
          _buildMediaOverlay(mediaToShow),
        ],
      ),
    );
  }

  // 🆕 SECCIÓN DE CARGA DE MEDIA
  Widget _buildLoadingMediaSection() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando multimedia...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conectando con la API de archivos',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 SECCIÓN DE ERROR DE MEDIA
  Widget _buildMediaErrorSection() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Error cargando multimedia',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _mediaError ?? 'Error desconocido',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _loadMediaIfAvailable();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 REPRODUCTOR DE VIDEO MEJORADO
  Widget _buildVideoPlayer(MediaResponse mediaResponse) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo con información
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill,
                  color: Colors.white.withOpacity(0.9),
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  mediaResponse.finalName ?? 'Video',
                  style: AppTextStyles.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (mediaResponse.finalSize != null)
                  Text(
                    _formatFileSize(mediaResponse.finalSize!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          
          // Botón de play
          Positioned(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => _showVideoDialog(mediaResponse),
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 VISUALIZADOR DE IMAGEN MEJORADO
  Widget _buildImageViewer(MediaResponse mediaResponse) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ClipRRect(
        child: Image.network(
          mediaResponse.finalUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('✅ [ENHANCED CONTENT VIEWER] Image loaded successfully: ${mediaResponse.finalUrl}');
              return child;
            }
            
            return _buildImageLoadingIndicator(loadingProgress);
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ [ENHANCED CONTENT VIEWER] Error loading image: $error');
            print('❌ [ENHANCED CONTENT VIEWER] Failed URL: ${mediaResponse.finalUrl}');
            
            return _buildImageErrorFallback(mediaResponse);
          },
        ),
      ),
    );
  }

  // 🆕 VISUALIZADOR GENÉRICO DE MEDIA
  Widget _buildGenericMediaViewer(MediaResponse mediaResponse) {
    IconData icon;
    String label;
    Color color;

    if (mediaResponse.isAudio) {
      icon = Icons.audiotrack;
      label = 'Audio';
      color = Colors.purple;
    } else if (mediaResponse.isDocument) {
      icon = Icons.description;
      label = 'Documento';
      color = Colors.blue;
    } else {
      icon = Icons.insert_drive_file;
      label = 'Archivo';
      color = Colors.grey;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: color.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTextStyles.h4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mediaResponse.finalName ?? 'Archivo multimedia',
            style: AppTextStyles.bodyMedium.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          if (mediaResponse.finalSize != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatFileSize(mediaResponse.finalSize!),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 OVERLAY DE MEDIA CON INFORMACIÓN MEJORADO
  Widget _buildMediaOverlay(MediaResponse mediaResponse) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Tipo de media y estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMediaTypeColor(mediaResponse),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getMediaTypeIcon(mediaResponse),
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getMediaTypeLabel(mediaResponse),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Estado de procesamiento
              if (mediaResponse.isProcessed == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        'Procesado',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const Spacer(),
              
              // Botones de acción
              Row(
                children: [
                  // Botón de información
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _showMediaDetails = !_showMediaDetails;
                        });
                      },
                      icon: Icon(
                        _showMediaDetails ? Icons.info : Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Botón de pantalla completa
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => _showFullScreenMedia(mediaResponse),
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 PLACEHOLDER DE MEDIA MEJORADO
  Widget _buildMediaPlaceholder(ContentModel? contentModel) {
    final hasMediaIds = contentModel?.hasAnyMedia == true;
    
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasMediaIds ? Icons.hourglass_empty : Icons.image_not_supported,
            size: 64,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'XUMA\'A',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.primary.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasMediaIds
                ? 'Procesando multimedia...'
                : 'Sin multimedia disponible',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          if (hasMediaIds) ...[
            const SizedBox(height: 12),
            Text(
              'Main ID: ${contentModel?.mainMediaId ?? "N/A"}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'Thumb ID: ${contentModel?.thumbnailMediaId ?? "N/A"}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 SECCIÓN DE DETALLES DE MEDIA EXPANDIBLE CON NUEVA API
  Widget _buildMediaDetailsSection(ContentModel? contentModel) {
    if (!_showMediaDetails) return const SizedBox.shrink();

    final mediaInfo = <String, String>{};
    
    // Información del content model
    if (contentModel != null) {
      mediaInfo.addAll({
        'Main Media ID': contentModel.mainMediaId ?? 'N/A',
        'Thumbnail Media ID': contentModel.thumbnailMediaId ?? 'N/A',
        'Has Main Media': contentModel.hasMainMedia.toString(),
        'Has Thumbnail Media': contentModel.hasThumbnailMedia.toString(),
      });
    }

    // Información de la media resuelta
    if (_resolvedMainMedia != null) {
      mediaInfo.addAll({
        'Main URL': _resolvedMainMedia!.finalUrl ?? 'N/A',
        'Main Type': _resolvedMainMedia!.type.toString(),
        'Main Size': _resolvedMainMedia!.finalSize != null ? _formatFileSize(_resolvedMainMedia!.finalSize!) : 'N/A',
        'Main MIME': _resolvedMainMedia!.mimeType ?? 'N/A',
        'Main Public': _resolvedMainMedia!.isPublic?.toString() ?? 'N/A',
        'Main Processed': _resolvedMainMedia!.isProcessed?.toString() ?? 'N/A',
      });
    }

    if (_resolvedThumbnailMedia != null) {
      mediaInfo.addAll({
        'Thumbnail URL': _resolvedThumbnailMedia!.finalUrl ?? 'N/A',
        'Thumbnail Type': _resolvedThumbnailMedia!.type.toString(),
        'Thumbnail Size': _resolvedThumbnailMedia!.finalSize != null ? _formatFileSize(_resolvedThumbnailMedia!.finalSize!) : 'N/A',
      });
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Información de multimedia',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...mediaInfo.entries.map((entry) {
            return _buildInfoRow(entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  // Helper methods
  Color _getMediaTypeColor(MediaResponse mediaResponse) {
    if (mediaResponse.isVideo) return Colors.red;
    if (mediaResponse.isImage) return Colors.blue;
    if (mediaResponse.isAudio) return Colors.purple;
    if (mediaResponse.isDocument) return Colors.green;
    return Colors.grey;
  }

  IconData _getMediaTypeIcon(MediaResponse mediaResponse) {
    if (mediaResponse.isVideo) return Icons.videocam;
    if (mediaResponse.isImage) return Icons.image;
    if (mediaResponse.isAudio) return Icons.audiotrack;
    if (mediaResponse.isDocument) return Icons.description;
    return Icons.insert_drive_file;
  }

  String _getMediaTypeLabel(MediaResponse mediaResponse) {
    if (mediaResponse.isVideo) return 'VIDEO';
    if (mediaResponse.isImage) return 'IMAGEN';
    if (mediaResponse.isAudio) return 'AUDIO';
    if (mediaResponse.isDocument) return 'DOCUMENTO';
    return 'ARCHIVO';
  }

  Widget _buildImageLoadingIndicator(ImageChunkEvent loadingProgress) {
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
        : null;
    
    return Container(
      color: AppColors.primaryLight.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            Text(
              'Cargando imagen...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorFallback(MediaResponse mediaResponse) {
    return Container(
      color: AppColors.error.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 64,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Error al cargar imagen',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mediaResponse.finalName ?? 'Imagen no disponible',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoDialog(MediaResponse mediaResponse) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reproductor de video',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mediaResponse.finalName ?? 'Video',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'URL del video:',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mediaResponse.finalUrl ?? 'No disponible',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.6),
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Funcionalidad de video disponible próximamente',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenMedia(MediaResponse mediaResponse) {
    if (mediaResponse.isVideo) {
      _showVideoDialog(mediaResponse);
      return;
    }

    if (mediaResponse.isImage) {
      showDialog(
        context: context,
        builder: (context) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    mediaResponse.finalUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar la imagen',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mediaResponse.finalUrl ?? 'URL no disponible',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withOpacity(0.7),
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Para otros tipos de archivos, mostrar información
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Información del archivo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Nombre', mediaResponse.finalName ?? 'N/A'),
              _buildInfoRow('Tipo', _getMediaTypeLabel(mediaResponse)),
              _buildInfoRow('Tamaño', mediaResponse.finalSize != null ? _formatFileSize(mediaResponse.finalSize!) : 'N/A'),
              _buildInfoRow('URL', mediaResponse.finalUrl ?? 'N/A'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildContentBody(ContentModel? contentModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descripción
        if (widget.content.description.isNotEmpty) ...[
          Text(
            'Descripción',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryLight.withOpacity(0.3),
              ),
            ),
            child: Text(
              widget.content.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        // Contenido principal
        Text(
          'Contenido',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryLight.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.content.content.isNotEmpty 
                    ? widget.content.content 
                    : _getDefaultContent(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 20),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Cada pequeña acción cuenta para proteger nuestro planeta! 🌱',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isCompleted = !_isCompleted;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(_isCompleted ? '¡Contenido marcado como leído!' : 'Contenido desmarcado'),
                ],
              ),
              backgroundColor: _isCompleted ? AppColors.success : AppColors.primary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: Icon(
          _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
          color: Colors.white,
        ),
        label: Text(
          _isCompleted ? 'Contenido leído ✓' : 'Marcar como leído',
          style: AppTextStyles.buttonLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCompleted ? AppColors.success : AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isCompleted ? 4 : 2,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getDefaultContent() {
    return '''
En este contenido aprenderás sobre ${widget.content.title.toLowerCase()}.

Este tema es fundamental para comprender cómo podemos contribuir al cuidado del medio ambiente en nuestra vida diaria.

Puntos clave:
• Comprender los conceptos básicos
• Identificar oportunidades de aplicación
• Desarrollar hábitos sostenibles
• Contribuir al cuidado del medio ambiente

¡Gracias por aprender con XUMA'A y cuidar nuestro planeta! 🌱
    ''';
  }
}