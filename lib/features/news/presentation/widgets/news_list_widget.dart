import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/news_entity.dart';
import '../cubit/news_cubit.dart';
import 'news_card_widget.dart';
import '../../../../core/constants/app_colors.dart';

class NewsListWidget extends StatelessWidget {
  final List<NewsEntity> news;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const NewsListWidget({
    Key? key,
    required this.news,
    this.onLoadMore,
    this.isLoadingMore = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Si estamos en el último elemento y podemos cargar más
            if (index == news.length) {
              if (isLoadingMore) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cargando más noticias...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (onLoadMore != null) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: onLoadMore,
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Cargar más noticias'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No hay más noticias por mostrar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                );
              }
            }
            
            // Verificar si necesitamos cargar más cuando llegamos cerca del final
            if (index == news.length - 3 && onLoadMore != null && !isLoadingMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onLoadMore!();
              });
            }
            
            final newsItem = news[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NewsCardWidget(news: newsItem),
            );
          },
          childCount: news.length + (onLoadMore != null ? 1 : 0),
        ),
      ),
    );
  }
}