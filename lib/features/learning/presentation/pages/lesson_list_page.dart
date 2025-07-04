import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/category_entity.dart';
import '../cubit/lesson_list_cubit.dart';
import '../widgets/learning_search_widget.dart';
import '../widgets/lesson_list_widget.dart';

class LessonListPage extends StatelessWidget {
  final CategoryEntity category;

  const LessonListPage({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LessonListCubit>()..loadLessons(category),
      child: _LessonListContent(category: category),
    );
  }
}

class _LessonListContent extends StatelessWidget {
  final CategoryEntity category;

  const _LessonListContent({required this.category});

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
          'Aprendamos',
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
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
      body: BlocBuilder<LessonListCubit, LessonListState>(
        builder: (context, state) {
          if (state is LessonListLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Cargando lecciones...',
              ),
            );
          }

          if (state is LessonListError) {
            return Center(
              child: EcoErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<LessonListCubit>().loadLessons(category);
                },
              ),
            );
          }

          if (state is LessonListLoaded) {
            return Column(
              children: [
                // Header con información de categoría
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
                      Text(
                        'Categorías - ${category.title}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.title,
                                  style: AppTextStyles.h4.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.filteredLessons.length} lecciones disponibles',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
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
                    child: Column(
                      children: [
                        // Barra de búsqueda
                        LearningSearchWidget(
                          onSearch: (query) {
                            context.read<LessonListCubit>().searchLessons(query);
                          },
                          onClear: () {
                            context.read<LessonListCubit>().clearSearch();
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Lista de lecciones
                        LessonListWidget(
                          lessons: state.filteredLessons,
                          category: category,
                        ),
                      ],
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