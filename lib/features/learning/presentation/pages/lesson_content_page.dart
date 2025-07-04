// lib/features/learning/presentation/pages/lesson_content_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/lesson_entity.dart';
import '../cubit/lesson_content_cubit.dart';
import '../widgets/lesson_progress_widget.dart';
import '../widgets/lesson_content_widget.dart';
import '../widgets/lesson_completion_widget.dart';

class LessonContentPage extends StatelessWidget {
  final LessonEntity lesson;
  final String userId;

  const LessonContentPage({
    Key? key,
    required this.lesson,
    this.userId = 'user_123', // TODO: Obtener del contexto de autenticación
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LessonContentCubit>()..loadLessonContent(lesson.id, userId),
      child: _LessonContentPageContent(lesson: lesson, userId: userId),
    );
  }
}

class _LessonContentPageContent extends StatelessWidget {
  final LessonEntity lesson;
  final String userId;

  const _LessonContentPageContent({
    required this.lesson,
    required this.userId,
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
      body: BlocConsumer<LessonContentCubit, LessonContentState>(
        listener: (context, state) {
          if (state is LessonContentCompleted) {
            // Mostrar mensaje de felicitación
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡Felicidades! Has ganado ${state.pointsEarned} puntos'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LessonContentLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Cargando contenido...',
              ),
            );
          }

          if (state is LessonContentError) {
            return Center(
              child: EcoErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<LessonContentCubit>().loadLessonContent(lesson.id, userId);
                },
              ),
            );
          }

          if (state is LessonContentLoaded) {
            return Column(
              children: [
                // Header con categoría y título
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
                        'Categorías - Introducción al reciclaje',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Barra de progreso
                      LessonProgressWidget(
                        progress: state.progress?.progress ?? 0.0,
                        onProgressUpdate: (progress) {
                          context.read<LessonContentCubit>().updateProgress(progress, userId);
                        },
                      ),
                    ],
                  ),
                ),
                
                // Contenido de la lección
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        LessonContentWidget(
                          lesson: state.lesson,
                          onComplete: () {
                            context.read<LessonContentCubit>().completeLesson(userId);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is LessonContentCompleted) {
            return LessonCompletionWidget(
              lesson: state.lesson,
              pointsEarned: state.pointsEarned,
              onContinue: () {
                Navigator.of(context).pop();
              },
              onReview: () {
                context.read<LessonContentCubit>().resetToContent();
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}