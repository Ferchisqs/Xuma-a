import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  
  // Variables para control de video
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  
  @override
  void dispose() {
    // Limpiar recursos del video
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentModel = widget.content is ContentModel ? widget.content as ContentModel : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              
              // Sección de multimedia con soporte para video
              _buildEnhancedMediaSection(contentModel),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.content.description.isNotEmpty) ...[
                      Text(
                        'Descripción',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.content.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    Text(
                      'Contenido',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.content.content,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Botón de completado
        _buildCompletionButton(),
      ],
    );
  }

  Widget _buildEnhancedMediaSection(ContentModel? contentModel) {
    if (contentModel?.hasAnyResolvedMedia != true) {
      return _buildMediaPlaceholder();
    }

    return Container(
      height: 300,
      width: double.infinity,
      child: Stack(
        children: [
          // Contenido principal del media
          _buildMediaContent(contentModel!),
          
          // Overlay con controles
          _buildMediaOverlay(contentModel),
        ],
      ),
    );
  }

  Widget _buildMediaContent(ContentModel contentModel) {
    if (contentModel.hasResolvedMainMedia) {
      final mediaUrl = contentModel.mediaUrl!;
      
      if (contentModel.isMainMediaVideo) {
        return _buildVideoPlayer(mediaUrl, contentModel);
      } else {
        return _buildImageViewer(mediaUrl);
      }
    }
    
    if (contentModel.hasResolvedThumbnailMedia) {
      return _buildImageViewer(contentModel.thumbnailUrl!);
    }
    
    return _buildMediaPlaceholder();
  }

  Widget _buildVideoPlayer(String videoUrl, ContentModel contentModel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail como fondo si está disponible
          if (contentModel.hasResolvedThumbnailMedia)
            _buildVideoThumbnail(contentModel.thumbnailUrl!, videoUrl)
          else
            _buildVideoFallback(),
          
          // Reproductor de video si está inicializado
          if (_isVideoInitialized && _videoController != null)
            _buildVideoPlayerWidget()
          else
            _buildVideoPlayButton(videoUrl),
          
          // Controles de video
          if (_isVideoInitialized)
            _buildVideoControls(),
          
          // Indicador de video
          _buildVideoIndicator(),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail(String thumbnailUrl, String videoUrl) {
    return GestureDetector(
      onTap: () => _initializeAndPlayVideo(videoUrl),
      child: Stack(
        children: [
          Image.network(
            thumbnailUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildVideoFallback(),
          ),
          Container(
            color: Colors.black.withOpacity(0.3),
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerWidget() {
    if (_videoController == null || !_isVideoInitialized) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _toggleVideoPlayback,
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildVideoControls() {
    if (_videoController == null || !_isVideoInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de progreso
            VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white.withOpacity(0.3),
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 8),
            
            // Controles de reproducción
            Row(
              children: [
                IconButton(
                  onPressed: _toggleVideoPlayback,
                  icon: Icon(
                    _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatVideoDuration(_videoController!.value.position, _videoController!.value.duration),
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => _showFullScreenVideo(_videoController!),
                  icon: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayButton(String videoUrl) {
    return GestureDetector(
      onTap: () => _initializeAndPlayVideo(videoUrl),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(20),
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildVideoIndicator() {
    return Positioned(
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
    );
  }

  Future<void> _initializeAndPlayVideo(String videoUrl) async {
    try {
      await _videoController?.dispose();
      
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      
      setState(() {
        _isVideoInitialized = true;
        _isVideoPlaying = true;
      });
      
      await _videoController!.play();
      _videoController!.addListener(_onVideoStateChanged);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar el video: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_isVideoInitialized) return;
    
    setState(() {
      if (_isVideoPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
  }

  void _onVideoStateChanged() {
    if (_videoController == null) return;
    setState(() {
      _isVideoPlaying = _videoController!.value.isPlaying;
    });
  }

  String _formatVideoDuration(Duration position, Duration total) {
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    
    return "${formatDuration(position)} / ${formatDuration(total)}";
  }

  void _showFullScreenVideo(VideoPlayerController controller) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenVideoPlayer(controller: controller),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildImageViewer(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: AppColors.primary,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.error.withOpacity(0.1),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: AppColors.error.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('Error al cargar imagen', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaOverlay(ContentModel contentModel) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: contentModel.isMainMediaVideo ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      contentModel.isMainMediaVideo ? Icons.videocam : Icons.image,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      contentModel.isMainMediaVideo ? 'VIDEO' : 'IMAGEN',
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
              IconButton(
                onPressed: () => _showFullScreenMedia(contentModel),
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPlaceholder() {
    return Container(
      height: 250,
      color: AppColors.primaryLight.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin multimedia',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFallback() {
    return Container(
      color: Colors.black,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenMedia(ContentModel contentModel) {
    // Implementación para mostrar media en pantalla completa
  }

  Widget _buildCompletionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isCompleted = !_isCompleted;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCompleted ? AppColors.success : AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          _isCompleted ? 'Completado ✓' : 'Marcar como completado',
          style: AppTextStyles.buttonLarge,
        ),
      ),
    );
  }
}

// Reproductor de video en pantalla completa
class _FullScreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;

  const _FullScreenVideoPlayer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
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
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}