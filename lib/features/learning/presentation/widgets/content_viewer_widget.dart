// lib/features/learning/presentation/widgets/content_viewer_widget.dart - CON MEDIA SUPPORT
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
  
  @override
  Widget build(BuildContext context) {
    // 🆕 VERIFICAR SI ES ContentModel PARA ACCEDER A MEDIA
    final contentModel = widget.content is ContentModel ? widget.content as ContentModel : null;
    
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
                                  Container(
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
                                          Icons.videocam,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Media',
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.white,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (contentModel.hasMainMedia && contentModel.hasThumbnailMedia)
                                  const SizedBox(width: 4),
                                if (contentModel.hasThumbnailMedia)
                                  Container(
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
                                          Icons.image,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Imagen',
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.white,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
              
              // 🔧 IMAGEN DEL CONTENIDO CON SOPORTE PARA MEDIA RESUELTO
              _buildContentImage(contentModel),
              
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
                          
                          // 🆕 MOSTRAR INFORMACIÓN DE MEDIA SI ESTÁ DISPONIBLE
                          if (contentModel != null && contentModel.hasAnyMedia) ...[
                            Container(
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
                                  const SizedBox(height: 8),
                                  
                                  if (contentModel.mediaUrl != null) ...[
                                    Text(
                                      '📹 Media principal disponible',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  
                                  if (contentModel.thumbnailUrl != null) ...[
                                    Text(
                                      '🖼️ Imagen de portada disponible',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  
                                  if (contentModel.hasAnyMedia && contentModel.mediaUrl == null && contentModel.thumbnailUrl == null) ...[
                                    Text(
                                      '⏳ Multimedia en proceso de carga...',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
        Container(
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
              
              // 🆕 DEBUG INFO PARA MEDIA IDs
              if (contentModel != null && contentModel.hasAnyMedia) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Media Info:',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (contentModel.mainMediaId != null)
                        Text(
                          'Main Media ID: ${contentModel.mainMediaId}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textHint,
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (contentModel.thumbnailMediaId != null)
                        Text(
                          'Thumbnail Media ID: ${contentModel.thumbnailMediaId}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textHint,
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (contentModel.mediaUrl != null)
                        Text(
                          'Resolved Media URL: ✅',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      if (contentModel.thumbnailUrl != null)
                        Text(
                          'Resolved Thumbnail URL: ✅',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Botón de completado
        SizedBox(
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
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  // 🆕 MÉTODO PARA CONSTRUIR IMAGEN CON SOPORTE DE MEDIA
  Widget _buildContentImage(ContentModel? contentModel) {
    String? imageUrl;
    
    // Prioridad: thumbnailUrl > mediaUrl > imageUrl tradicional
    if (contentModel != null) {
      imageUrl = contentModel.thumbnailUrl ?? contentModel.mediaUrl ?? contentModel.imageUrl;
    } else {
      imageUrl = widget.content.imageUrl;
    }
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              print('❌ Error loading image: $exception');
            },
          ),
        ),
        child: Container(
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
          child: Stack(
            children: [
              // 🆕 BADGE PARA INDICAR TIPO DE MEDIA
              if (contentModel != null && contentModel.hasAnyMedia)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
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
                          contentModel.mediaUrl != null ? Icons.videocam : Icons.image,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          contentModel.mediaUrl != null ? 'Video' : 'Imagen',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // Placeholder si no hay imagen
      return Container(
        height: 200,
        width: double.infinity,
        color: AppColors.primaryLight.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'XUMA\'A',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.primary.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (contentModel != null && contentModel.hasAnyMedia) ...[
              const SizedBox(height: 8),
              Text(
                'Multimedia en proceso...',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      );
    }
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