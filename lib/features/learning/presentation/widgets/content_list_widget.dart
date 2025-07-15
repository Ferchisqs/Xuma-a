// lib/features/learning/presentation/widgets/content_list_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/content_entity.dart';
import '../../domain/entities/topic_entity.dart';
import 'content_item_widget.dart';

class ContentListWidget extends StatelessWidget {
  final List<ContentEntity> contents;
  final TopicEntity topic;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const ContentListWidget({
    Key? key,
    required this.contents,
    required this.topic,
    this.onLoadMore,
    this.isLoadingMore = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lista de contenidos
        ...contents.asMap().entries.map((entry) {
          final index = entry.key;
          final content = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ContentItemWidget(
              content: content,
              topic: topic,
              index: index + 1, // Numeración empezando en 1
            ),
          );
        }).toList(),
        
        // Botón "Cargar más" o indicador de carga
        if (onLoadMore != null || isLoadingMore) ...[
          const SizedBox(height: 16),
          _buildLoadMoreSection(),
        ],
        
        // Espaciado final
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadMoreSection() {
    if (isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
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
              'Cargando más contenidos...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (onLoadMore != null) {
      return GestureDetector(
        onTap: onLoadMore,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.expand_more_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Cargar más contenidos',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}