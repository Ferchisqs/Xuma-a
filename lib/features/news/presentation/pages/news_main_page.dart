// lib/features/news/presentation/pages/news_main_page.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../di/injection.dart';
import '../cubit/news_cubit.dart';
import '../widgets/news_list_widget.dart';
import '../widgets/news_header_widget.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

class NewsMainPage extends StatelessWidget {
  const NewsMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<NewsCubit>()..loadNews(),
      child: const _NewsMainContent(),
    );
  }
}

class _NewsMainContent extends StatelessWidget {
  const _NewsMainContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // 🔧 ELIMINADO: drawer: const SideNavBar(),
      // El drawer se maneja desde MainWrapperPage
      appBar: CustomAppBar(
        title: 'Noticias',
        showDrawerButton: true, // 🔧 MANTENER: esto sí funciona
        showEcoTip: true,
        showInfoButton: true,
        onInfoPressed: () => _showNewsInfoDialog(context),
      ),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          if (state is NewsInitial || state is NewsLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Cargando noticias climáticas...',
              ),
            );
          }
          
          if (state is NewsError && state.cachedNews == null) {
            return Center(
              child: EcoErrorWidget(
                message: state.message,
                onRetry: () => context.read<NewsCubit>().retry(),
                icon: Icons.newspaper_rounded,
              ),
            );
          }
          
          if (state is NewsLoaded || 
              (state is NewsError && state.cachedNews != null)) {
            
            // Si tenemos un error pero hay noticias del cache, mostrarlas
            final news = state is NewsLoaded 
                ? state.news 
                : (state as NewsError).cachedNews!;
            
            final isFromCache = state is NewsLoaded 
                ? state.isFromCache 
                : true;
            
            final hasError = state is NewsError;
            
            return RefreshIndicator(
              onRefresh: () => context.read<NewsCubit>().refreshNews(),
              backgroundColor: AppColors.surface,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header con información
                  SliverToBoxAdapter(
                    child: NewsHeaderWidget(
                      totalNews: news.length,
                      isFromCache: isFromCache,
                      hasError: hasError,
                      errorMessage: hasError ? (state as NewsError).message : null,
                    ),
                  ),
                  
                  // Lista de noticias
                  if (news.isNotEmpty)
                    NewsListWidget(
                      news: news,
                      onLoadMore: state is NewsLoaded && !state.hasReachedMax
                          ? () => context.read<NewsCubit>().loadMoreNews()
                          : null,
                      isLoadingMore: state is NewsLoadingMore,
                    )
                  else
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.newspaper_outlined,
                              size: 64,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay noticias disponibles',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta actualizar o verifica tu conexión',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textHint,
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
          
          return const Center(
            child: EcoLoadingWidget(
              message: 'Preparando noticias...',
            ),
          );
        },
      ),
    );
  }

  void _showNewsInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Acerca de las Noticias'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Las noticias mostradas aquí están relacionadas con el cambio climático, medio ambiente y sostenibilidad.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.nature.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.nature.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pets,
                    color: AppColors.nature,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Xico selecciona las noticias más relevantes para mantenerte informado sobre el planeta.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '• Desliza hacia abajo para actualizar\n'
              '• Toca una noticia para leer más\n'
              '• Las noticias se guardan para lectura offline',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendido',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}