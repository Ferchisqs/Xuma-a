// lib/features/learning/presentation/widgets/content_viewer_widget.dart - MEJORADO PARA MULTIMEDIA
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/content_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../../learning/data/models/content_model.dart';

class ContentViewerWidget extends StatefulWidget {
  final ContentEntity content;
  final TopicEntity topic;

  const ContentViewerWidget({
    Key? key,
    required this.content,
    required this.topic,
  }) : super(key: key);

  @override
  State<ContentViewerWidget> createState() => _ContentViewerWidgetState();
}

class _ContentViewerWidgetState extends State<ContentViewerWidget> {
  bool _isCompleted = false;
  bool _imageLoadError = false;
  bool _showMediaDetails = false;
  
  @override
  Widget build(BuildContext context) {
    // 🆕 VERIFICAR SI ES ContentModel PARA ACCEDER A MEDIA MEJORADO
    final contentModel = widget.content is ContentModel ? widget.content as ContentModel : null;
    
    print('🔍 [CONTENT VIEWER] Building enhanced widget for content: ${widget.content.title}');
    if (contentModel != null) {
      print('🔍 [CONTENT VIEWER] Enhanced media info: ${contentModel.getMediaInfo()}');
    }
    
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
        
        const SizedBox(height: 32),
        
        // 🆕 INFORMACIÓN DETALLADA DE MEDIA (EXPANDIBLE)
        if (contentModel != null && contentModel.hasAnyMedia)
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
                  if (contentModel?.hasAnyMedia == true) ...[
                    if (contentModel!.hasMainMedia)
                      _buildBadge(
                        contentModel.isMainMediaVideo ? 'Video' : 'Media',
                        contentModel.isMainMediaVideo ? Icons.videocam : Icons.perm_media,
                      ),
                    if (contentModel.hasThumbnailMedia)
                      _buildBadge('Imagen', Icons.image),
                  ],
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

  // 🆕 BADGE HELPER
  Widget _buildBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
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

  // 🔧 SECCIÓN DE MULTIMEDIA MEJORADA
  Widget _buildEnhancedMediaSection(ContentModel? contentModel) {
    if (contentModel?.hasAnyResolvedMedia != true) {
      return _buildMediaPlaceholder(contentModel);
    }

    // Decidir qué mostrar: video principal o imagen thumbnail
    final showMainMedia = contentModel!.hasResolvedMainMedia;
    final mediaUrl = showMainMedia ? contentModel.mediaUrl! : contentModel.thumbnailUrl!;
    final isVideo = showMainMedia && contentModel.isMainMediaVideo;

    return Container(
      height: 300, // Altura aumentada para mejor visualización
      width: double.infinity,
      child: Stack(
        children: [
          // Media principal
          if (isVideo)
            _buildVideoPlayer(mediaUrl, contentModel)
          else
            _buildImageViewer(mediaUrl, contentModel),
          
          // Overlay con información
          _buildMediaOverlay(contentModel, isVideo),
        ],
      ),
    );
  }

  // 🆕 REPRODUCTOR DE VIDEO PLACEHOLDER (mejorar con video_player si es necesario)
  Widget _buildVideoPlayer(String videoUrl, ContentModel contentModel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail si está disponible
          if (contentModel.hasResolvedThumbnailMedia)
            Image.network(
              contentModel.thumbnailUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildVideoFallback(),
            )
          else
            _buildVideoFallback(),
          
          // Botón de play
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _showVideoDialog(videoUrl),
              icon: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          
          // Indicador de video
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'VIDEO',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 VISUALIZADOR DE IMAGEN MEJORADO
  Widget _buildImageViewer(String imageUrl, ContentModel contentModel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('✅ [CONTENT VIEWER] Image loaded successfully: $imageUrl');
            return child;
          }
          
          return _buildLoadingIndicator(loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ [CONTENT VIEWER] Error loading image: $error');
          print('❌ [CONTENT VIEWER] Failed URL: $imageUrl');
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _imageLoadError = true;
              });
            }
          });
          
          return _buildImageErrorFallback();
        },
      ),
    );
  }

  // 🆕 OVERLAY DE MEDIA CON INFORMACIÓN
  Widget _buildMediaOverlay(ContentModel contentModel, bool isVideo) {
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
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Tipo de media
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isVideo ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideo ? Icons.videocam : Icons.image,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVideo ? 'VIDEO' : 'IMAGEN',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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
                      onPressed: () => _showFullScreenMedia(
                        isVideo ? contentModel.mediaUrl! : 
                        (contentModel.hasResolvedMainMedia ? contentModel.mediaUrl! : contentModel.thumbnailUrl!),
                        isVideo,
                      ),
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
    final hasResolvedMedia = contentModel?.hasAnyResolvedMedia == true;
    
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
          if (hasMediaIds && !hasResolvedMedia) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${contentModel?.mainMediaId ?? contentModel?.thumbnailMediaId ?? "N/A"}',
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

  // 🆕 SECCIÓN DE DETALLES DE MEDIA EXPANDIBLE
  Widget _buildMediaDetailsSection(ContentModel contentModel) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showMediaDetails ? null : 0,
      child: _showMediaDetails
          ? Container(
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
                  
                  ...contentModel.getMediaInfo().entries.map((entry) {
                    return _buildInfoRow(entry.key, entry.value?.toString() ?? 'N/A');
                  }).toList(),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // 🆕 FILA DE INFORMACIÓN
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

  // 🆕 CONTENIDO DEL CUERPO
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

  // 🆕 INDICADOR DE CARGA PARA IMÁGENES
  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
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

  // 🆕 FALLBACK PARA ERROR DE IMAGEN
  Widget _buildImageErrorFallback() {
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
              'Verifique su conexión a internet',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 FALLBACK PARA VIDEO
  Widget _buildVideoFallback() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Contenido de video',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 MOSTRAR VIDEO EN DIÁLOGO
  void _showVideoDialog(String videoUrl) {
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
                    'Funcionalidad disponible próximamente',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'URL: ${videoUrl.length > 50 ? "${videoUrl.substring(0, 50)}..." : videoUrl}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
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

  // 🆕 MOSTRAR MEDIA EN PANTALLA COMPLETA
  void _showFullScreenMedia(String mediaUrl, bool isVideo) {
    if (isVideo) {
      _showVideoDialog(mediaUrl);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  mediaUrl,
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
  }

  // 🆕 BOTÓN DE COMPLETADO MEJORADO
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