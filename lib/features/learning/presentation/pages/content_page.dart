// lib/features/learning/presentation/pages/content_page.dart - CORREGIDA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/entities/content_entity.dart';
import '../cubit/content_cubit.dart';
import '../widgets/content_viewer_widget.dart';

class ContentPage extends StatelessWidget {
  final TopicEntity topic;
  final ContentEntity content; // 🆕 AGREGADO: Recibir content específico

  const ContentPage({
    Key? key,
    required this.topic,
    required this.content, // 🆕 REQUERIDO: Content específico
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContentCubit>()..loadContentById(content.id), // 🔧 USAR content.id en lugar de topic.id
      child: _ContentPageContent(topic: topic, content: content),
    );
  }
}

class _ContentPageContent extends StatelessWidget {
  final TopicEntity topic;
  final ContentEntity content; // 🆕 AGREGADO

  const _ContentPageContent({
    required this.topic,
    required this.content, // 🆕 REQUERIDO
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Contenido',
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.article_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
      body: BlocConsumer<ContentCubit, ContentState>(
        listener: (context, state) {
          if (state is ContentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          print('🎯 [CONTENT PAGE] State: $state');
          print('🎯 [CONTENT PAGE] Loading content ID: ${content.id}');
          
          if (state is ContentLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Cargando contenido...',
              ),
            );
          }

          if (state is ContentError) {
            return Center(
              child: EcoErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<ContentCubit>().loadContentById(content.id); // 🔧 USAR content.id
                },
              ),
            );
          }

          if (state is ContentLoaded) {
            return Column(
              children: [
                // Header con información del topic y content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb mejorado
                      Text(
                        'Temas • ${topic.category} • ${content.category}', // 🆕 AGREGADO: categoría del content
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Título del content específico
                      Text(
                        state.content.title, // 🔧 USAR título del content cargado
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Descripción del content específico
                      Text(
                        state.content.description, // 🔧 USAR descripción del content cargado
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // 🆕 INFO DEL CONTENT
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ID: ${content.id.substring(0, 8)}...', // Mostrar parte del ID para debug
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (state.content.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Activo',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Contenido principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ContentViewerWidget(
                      content: state.content, // Pasar el content completo cargado
                      topic: topic,
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}