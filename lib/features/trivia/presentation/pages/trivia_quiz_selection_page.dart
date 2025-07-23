// lib/features/trivia/presentation/pages/trivia_quiz_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart' as core_styles;
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../cubit/quiz_session_cubit.dart';
import 'trivia_quiz_game_page.dart';

class TriviaQuizSelectionPage extends StatelessWidget {
  final String topicId;
  final String categoryTitle;

  const TriviaQuizSelectionPage({
    Key? key,
    required this.topicId,
    required this.categoryTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QuizSessionCubit>(),
      child: _TriviaQuizSelectionContent(
        topicId: topicId,
        categoryTitle: categoryTitle,
      ),
    );
  }
}

class _TriviaQuizSelectionContent extends StatefulWidget {
  final String topicId;
  final String categoryTitle;

  const _TriviaQuizSelectionContent({
    required this.topicId,
    required this.categoryTitle,
  });

  @override
  State<_TriviaQuizSelectionContent> createState() => 
      _TriviaQuizSelectionContentState();
}

class _TriviaQuizSelectionContentState extends State<_TriviaQuizSelectionContent> {
  @override
  void initState() {
    super.initState();
    // TODO: Aquí llamarías al método para obtener quizzes por topic
    // context.read<QuizSessionCubit>().getQuizzesByTopic(widget.topicId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          'Quizzes: ${widget.categoryTitle}',
          style: core_styles.AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<QuizSessionCubit, QuizSessionState>(
        builder: (context, state) {
          if (state is QuizSessionLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Cargando quizzes...',
              ),
            );
          }
          
          if (state is QuizSessionError) {
            return Center(
              child: EcoErrorWidget(
                message: state.message,
                onRetry: () {
                  // TODO: Retry obtener quizzes
                },
              ),
            );
          }
          
          // Por ahora mostrar quizzes de ejemplo
          return _buildQuizzesList(context);
        },
      ),
    );
  }

  Widget _buildQuizzesList(BuildContext context) {
    // Quizzes de ejemplo basados en el topicId
    final exampleQuizzes = _getExampleQuizzes();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header informativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Desafía tus conocimientos!',
                        style: core_styles.AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Selecciona un quiz para comenzar',
                        style: core_styles.AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Quizzes Disponibles',
            style: core_styles.AppTextStyles.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de quizzes
          Expanded(
            child: ListView.builder(
              itemCount: exampleQuizzes.length,
              itemBuilder: (context, index) {
                final quiz = exampleQuizzes[index];
                return _buildQuizCard(context, quiz, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, Map<String, dynamic> quiz, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: core_styles.AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          quiz['title'],
          style: core_styles.AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              quiz['description'],
              style: core_styles.AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  '${quiz['questions']} preguntas',
                  Icons.quiz,
                  AppColors.info,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  '${quiz['duration']} min',
                  Icons.timer,
                  AppColors.warning,
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'JUGAR',
            style: core_styles.AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TriviaQuizGamePage(
                quizId: quiz['id'],
                topicId: widget.topicId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: core_styles.AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getExampleQuizzes() {
    // Generar quizzes de ejemplo basados en el topicId
    switch (widget.topicId) {
      case 'trivia_cat_1': // Composta
        return [
          {
            'id': 'quiz_composta_basico',
            'title': 'Composta Básica',
            'description': 'Aprende los fundamentos del compostaje casero',
            'questions': 10,
            'duration': 5,
          },
          {
            'id': 'quiz_composta_avanzado',
            'title': 'Composta Avanzada',
            'description': 'Técnicas avanzadas y solución de problemas',
            'questions': 15,
            'duration': 8,
          },
        ];
      case 'trivia_cat_2': // Reciclaje
        return [
          {
            'id': 'quiz_reciclaje_basico',
            'title': 'Reciclaje Básico',
            'description': 'Clasificación y separación de residuos',
            'questions': 12,
            'duration': 6,
          },
          {
            'id': 'quiz_reciclaje_materiales',
            'title': 'Materiales Reciclables',
            'description': 'Identifica qué se puede reciclar',
            'questions': 8,
            'duration': 4,
          },
        ];
      default:
        return [
          {
            'id': 'quiz_${widget.topicId}_general',
            'title': 'Quiz de ${widget.categoryTitle}',
            'description': 'Pon a prueba tus conocimientos',
            'questions': 10,
            'duration': 5,
          },
        ];
    }
  }
}