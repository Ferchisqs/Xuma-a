// lib/features/learning/presentation/pages/topic_contents_page.dart - CORREGIDO
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/topic_entity.dart';
import '../cubit/topic_contents_cubit.dart';
import '../widgets/content_list_widget.dart';

class TopicContentsPage extends StatelessWidget {
  final TopicEntity topic;

  const TopicContentsPage({
    Key? key,
    required this.topic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        print('🔧 [TOPIC_CONTENTS_PAGE] Creating TopicContentsCubit for topic: ${topic.title}');
        
        // 🛡️ VERIFICACIÓN DE SEGURIDAD
        if (!getIt.isRegistered<TopicContentsCubit>()) {
          print('❌ [TOPIC_CONTENTS_PAGE] TopicContentsCubit not registered in GetIt!');
          throw Exception('TopicContentsCubit not registered. Check your dependency injection setup.');
        }
        
        try {
          final cubit = getIt<TopicContentsCubit>();
          print('✅ [TOPIC_CONTENTS_PAGE] TopicContentsCubit created successfully');
          
          // 🔄 CARGAR CONTENIDOS DEL TOPIC
          cubit.loadTopicContents(topic);
          
          return cubit;
        } catch (e, stackTrace) {
          print('❌ [TOPIC_CONTENTS_PAGE] Error creating TopicContentsCubit: $e');
          print('❌ [TOPIC_CONTENTS_PAGE] Stack trace: $stackTrace');
          rethrow;
        }
      },
      child: _TopicContentsPageContent(topic: topic),
    );
  }
}

class _TopicContentsPageContent extends StatelessWidget {
  final TopicEntity topic;

  const _TopicContentsPageContent({required this.topic});

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
          'Contenidos',
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
      body: BlocConsumer<TopicContentsCubit, TopicContentsState>(
        listener: (context, state) {
          if (state is TopicContentsError) {
            print('❌ [TOPIC_CONTENTS_PAGE] Error state: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Reintentar',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<TopicContentsCubit>().loadTopicContents(topic);
                  },
                ),
              ),
            );
          }
          
          if (state is TopicContentsLoaded) {
            print('✅ [TOPIC_CONTENTS_PAGE] Loaded ${state.contents.length} contents for topic: ${topic.title}');
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Header con información del topic
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
                    // Breadcrumb
                    Text(
                      'Aprendamos • ${topic.category}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Título del topic
                    Text(
                      topic.title,
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Descripción del topic
                    Text(
                      topic.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Información de contenidos
                    if (state is TopicContentsLoaded) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${state.contents.length} contenidos disponibles',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Contenido principal
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TopicContentsState state) {
    print('🔍 [TOPIC_CONTENTS_PAGE] Building content for state: ${state.runtimeType}');
    
    if (state is TopicContentsLoading) {
      return const Center(
        child: EcoLoadingWidget(
          message: 'Cargando contenidos...',
        ),
      );
    }

    if (state is TopicContentsError) {
      return Center(
        child: EcoErrorWidget(
          message: state.message,
          onRetry: () {
            print('🔄 [TOPIC_CONTENTS_PAGE] Retrying to load contents for topic: ${topic.title}');
            context.read<TopicContentsCubit>().loadTopicContents(topic);
          },
        ),
      );
    }

    if (state is TopicContentsLoaded) {
      if (state.contents.isEmpty) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: () async {
          print('🔄 [TOPIC_CONTENTS_PAGE] Refreshing contents for topic: ${topic.title}');
          context.read<TopicContentsCubit>().refreshContents();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Para permitir refresh incluso con poco contenido
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la sección
              Row(
                children: [
                  Icon(
                    Icons.article_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Contenidos',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (state.hasMorePages || state.isLoadingMore) ...[
                    Text(
                      'Página ${state.currentPage}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Lista de contenidos
              ContentListWidget(
                contents: state.contents,
                topic: topic,
                onLoadMore: state.hasMorePages && !state.isLoadingMore
                    ? () {
                        print('📄 [TOPIC_CONTENTS_PAGE] Loading more contents (page ${state.currentPage + 1})');
                        context.read<TopicContentsCubit>().loadMoreContents();
                      }
                    : null,
                isLoadingMore: state.isLoadingMore,
              ),
              
              // 🔄 INDICADOR DE CARGA PARA MÁS CONTENIDOS
              if (state.isLoadingMore) ...[
                const SizedBox(height: 16),
                const Center(
                  child: EcoLoadingWidget(
                    message: 'Cargando más contenidos...',
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 📄 INDICADOR DE FIN DE PÁGINA
              if (!state.hasMorePages && state.contents.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '¡Has visto todos los contenidos!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      );
    }

    // 🔍 ESTADO INICIAL O DESCONOCIDO
    return const Center(
      child: EcoLoadingWidget(
        message: 'Preparando contenidos...',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.article_outlined,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin contenidos',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Este tema aún no tiene contenidos disponibles. ¡Pronto tendremos más!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pets,
                    color: AppColors.info,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Xico está preparando contenido especial para este tema',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 🔄 BOTÓN PARA REINTENTAR
            ElevatedButton.icon(
              onPressed: () {
                print('🔄 [TOPIC_CONTENTS_PAGE] Manual retry for topic: ${topic.title}');
                context.read<TopicContentsCubit>().loadTopicContents(topic);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}