// lib/features/learning/presentation/widgets/content_viewer_widget.dart - MEJORADO PARA MOSTRAR MEDIA
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
  
  @override
  Widget build(BuildContext context) {
    // 🆕 VERIFICAR SI ES ContentModel PARA ACCEDER A MEDIA
    final contentModel = widget.content is ContentModel ? widget.content as ContentModel : null;
    
    print('🔍 [CONTENT VIEWER] Building widget for content: ${widget.content.title}');
    print('🔍 [CONTENT VIEWER] Is ContentModel: ${contentModel != null}');
    if (contentModel != null) {
      print('🔍 [CONTENT VIEWER] Has any media: ${contentModel.hasAnyMedia}');
      print('🔍 [CONTENT VIEWER] Main media URL: ${contentModel.mediaUrl}');
      print('🔍 [CONTENT VIEWER] Thumbnail URL: ${contentModel.thumbnailUrl}');
      print('🔍 [CONTENT VIEWER] Final image URL: ${contentModel.finalImageUrl}');
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
                child: Row(
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.content.category,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          // 🆕 MOSTRAR INFO DE MEDIA SI EXISTE
                          if (contentModel != null && contentModel.hasAnyMedia) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (contentModel.hasMainMedia)
                                  _buildMediaBadge('Media', Icons.videocam),
                                if (contentModel.hasMainMedia && contentModel.hasThumbnailMedia)
                                  const SizedBox(width: 4),
                                if (contentModel.hasThumbnailMedia)
                                  _buildMediaBadge('Imagen', Icons.image),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.article_outlined,
                      color: Colors.white.withOpacity(0.8),
                      size: 32,
                    ),
                  ],
                ),
              ),
              
              // 🔧 IMAGEN/VIDEO DEL CONTENIDO CON SOPORTE MEJORADO
              _buildContentMedia(contentModel),
              
              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
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
                          
                          // 🆕 INFORMACIÓN DE ESTADO DE MEDIA
                          if (contentModel != null && contentModel.hasAnyMedia) ...[
                            _buildMediaInfoSection(contentModel),
                            const SizedBox(height: 20),
                          ],
                          
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
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Información adicional del contenido
        _buildContentInfoSection(contentModel),
        
        const SizedBox(height: 24),
        
        // Botón de completado
        _buildCompletionButton(),
        
        const SizedBox(height: 32),
      ],
    );
  }

  // 🆕 MÉTODO PARA CONSTRUIR MEDIA BADGE
  Widget _buildMediaBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 MÉTODO MEJORADO PARA CONSTRUIR MEDIA
  Widget _buildContentMedia(ContentModel? contentModel) {
    String? imageUrl;
    bool hasResolvedMedia = false;
    
    // Prioridad: thumbnailUrl > mediaUrl > imageUrl tradicional
    if (contentModel != null) {
      imageUrl = contentModel.thumbnailUrl ?? contentModel.mediaUrl ?? contentModel.imageUrl;
      hasResolvedMedia = contentModel.thumbnailUrl != null || contentModel.mediaUrl != null;
      
      print('🔍 [CONTENT VIEWER] Building media section:');
      print('🔍 [CONTENT VIEWER] - Selected URL: $imageUrl');
      print('🔍 [CONTENT VIEWER] - Has resolved media: $hasResolvedMedia');
    } else {
      imageUrl = widget.content.imageUrl;
    }
    
    if (imageUrl != null && imageUrl.isNotEmpty && !_imageLoadError) {
      return Container(
        height: 250, // Altura aumentada para mejor visualización
        width: double.infinity,
        child: Stack(
          children: [
            // Imagen principal
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    print('✅ [CONTENT VIEWER] Image loaded successfully: $imageUrl');
                    return child;
                  }
                  
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
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Cargando multimedia...',
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
                  
                  return _buildMediaPlaceholder(
                    hasResolvedMedia, 
                    'Error al cargar multimedia',
                    Icons.error_outline,
                    AppColors.error,
                  );
                },
              ),
            ),
            
            // Overlay con gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            
            // 🆕 BADGES PARA INDICAR TIPO DE MEDIA
            if (hasResolvedMedia) ...[
              Positioned(
                top: 12,
                left: 12,
                child: _buildMediaTypeBadge(contentModel!),
              ),
            ],
            
            // 🆕 BOTÓN DE PANTALLA COMPLETA
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _showFullScreenMedia(imageUrl!),
                  icon: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Placeholder mejorado si no hay imagen o hay error
      return _buildMediaPlaceholder(
        hasResolvedMedia,
        _imageLoadError ? 'Error al cargar multimedia' : 'Multimedia en proceso...',
        _imageLoadError ? Icons.error_outline : Icons.hourglass_empty,
        _imageLoadError ? AppColors.error : AppColors.primary,
      );
    }
  }

  // 🆕 MÉTODO PARA CONSTRUIR PLACEHOLDER DE MEDIA
  Widget _buildMediaPlaceholder(bool hasResolvedMedia, String message, IconData icon, Color color) {
    return Container(
      height: 250,
      width: double.infinity,
      color: AppColors.primaryLight.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: color.withOpacity(0.5),
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
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          if (hasResolvedMedia && !_imageLoadError) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 MÉTODO PARA CONSTRUIR BADGE DE TIPO DE MEDIA
  Widget _buildMediaTypeBadge(ContentModel contentModel) {
    String label;
    IconData icon;
    
    if (contentModel.mediaUrl != null) {
      label = 'Video';
      icon = Icons.videocam;
    } else if (contentModel.thumbnailUrl != null) {
      label = 'Imagen';
      icon = Icons.image;
    } else {
      label = 'Media';
      icon = Icons.perm_media;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 MÉTODO PARA MOSTRAR MEDIA EN PANTALLA COMPLETA
  void _showFullScreenMedia(String mediaUrl) {
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

  // 🆕 MÉTODO PARA CONSTRUIR SECCIÓN DE INFO DE MEDIA
  Widget _buildMediaInfoSection(ContentModel contentModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.perm_media,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recursos multimedia',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Estado de media principal
          if (contentModel.hasMainMedia) ...[
            Row(
              children: [
                Icon(
                  contentModel.mediaUrl != null ? Icons.check_circle : Icons.pending,
                  color: contentModel.mediaUrl != null ? AppColors.success : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contentModel.mediaUrl != null 
                        ? '📹 Media principal cargado correctamente'
                        : '⏳ Media principal en proceso...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Estado de thumbnail
          if (contentModel.hasThumbnailMedia) ...[
            Row(
              children: [
                Icon(
                  contentModel.thumbnailUrl != null ? Icons.check_circle : Icons.pending,
                  color: contentModel.thumbnailUrl != null ? AppColors.success : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contentModel.thumbnailUrl != null 
                        ? '🖼️ Imagen de portada cargada correctamente'
                        : '⏳ Imagen de portada en proceso...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Si no hay URLs resueltas pero hay IDs
          if (contentModel.hasAnyMedia && contentModel.mediaUrl == null && contentModel.thumbnailUrl == null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los recursos multimedia están siendo procesados y estarán disponibles pronto.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 MÉTODO PARA CONSTRUIR SECCIÓN DE INFO DEL CONTENIDO
  Widget _buildContentInfoSection(ContentModel? contentModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del contenido',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Actualizado: ${_formatDate(widget.content.updatedAt)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 🆕 DEBUG INFO PARA MEDIA IDs (solo en desarrollo)
          if (contentModel != null && contentModel.hasAnyMedia) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Información técnica',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (contentModel.mainMediaId != null)
                        _buildDebugInfo('Main Media ID', contentModel.mainMediaId!),
                      if (contentModel.thumbnailMediaId != null)
                        _buildDebugInfo('Thumbnail Media ID', contentModel.thumbnailMediaId!),
                      if (contentModel.mediaUrl != null)
                        _buildDebugInfo('Resolved Media URL', '✅ Disponible'),
                      if (contentModel.thumbnailUrl != null)
                        _buildDebugInfo('Resolved Thumbnail URL', '✅ Disponible'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 MÉTODO HELPER PARA INFO DE DEBUG
  Widget _buildDebugInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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

  // 🆕 MÉTODO PARA CONSTRUIR BOTÓN DE COMPLETADO
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
              content: Text(_isCompleted ? '¡Contenido marcado como leído!' : 'Contenido desmarcado'),
              backgroundColor: _isCompleted ? AppColors.success : AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        icon: Icon(
          _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
          color: Colors.white,
        ),
        label: Text(
          _isCompleted ? 'Contenido leído' : 'Marcar como leído',
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
          elevation: 2,
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

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}