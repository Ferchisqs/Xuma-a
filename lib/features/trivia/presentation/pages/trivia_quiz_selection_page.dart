// lib/features/trivia/presentation/pages/trivia_quiz_selection_page.dart - ACTUALIZADO
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart' as core_styles;
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../cubit/trivia_cubit.dart'; // 🔧 CAMBIO: Usar TriviaCubit en lugar de QuizSessionCubit
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
      create: (_) => getIt<TriviaCubit>()..loadQuizzesByTopic(topicId), // 🔧 USAR NUEVO MÉTODO
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
      body: BlocBuilder<TriviaCubit, TriviaState>(
        builder: (context, state) {
          print('🎯 [QUIZ SELECTION] Current state: ${state.runtimeType}');
          
          if (state is TriviaQuizzesLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Cargando quizzes desde el servidor...',
              ),
            );
          }
          
          if (state is TriviaError) {
            return Center(
              child: EcoErrorWidget(
                message: state.message,
                onRetry: () {
                  print('🔄 [QUIZ SELECTION] Retrying quiz fetch for topic: ${widget.topicId}');
                  context.read<TriviaCubit>().loadQuizzesByTopic(widget.topicId);
                },
              ),
            );
          }
          
          if (state is TriviaQuizzesLoaded) {
            print('✅ [QUIZ SELECTION] Quizzes loaded: ${state.quizzes.length}');
            return _buildQuizzesFromServer(context, state.quizzes);
          }
          
          // 🔧 FALLBACK: Si no hay quizzes del servidor, mostrar ejemplos
          return _buildQuizzesList(context);
        },
      ),
    );
  }

  // 🆕 NUEVO MÉTODO: Construir lista de quizzes desde el servidor
  Widget _buildQuizzesFromServer(BuildContext context, List<Map<String, dynamic>> quizzes) {
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
                        '¡Quizzes disponibles desde el servidor!',
                        style: core_styles.AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Conectado con la API de quiz-challenge-service',
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
            'Quizzes del Servidor (${quizzes.length})',
            style: core_styles.AppTextStyles.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de quizzes del servidor
          Expanded(
            child: ListView.builder(
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return _buildServerQuizCard(context, quiz, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 NUEVO MÉTODO: Card de quiz desde servidor
  Widget _buildServerQuizCard(BuildContext context, Map<String, dynamic> quiz, int index) {
    // 🔧 EXTRAER DATOS DEL QUIZ DEL SERVIDOR
    final quizId = quiz['id']?.toString() ?? 'quiz_$index';
    final title = quiz['title']?.toString() ?? quiz['name']?.toString() ?? 'Quiz ${index + 1}';
    final description = quiz['description']?.toString() ?? 'Quiz sobre ${widget.categoryTitle}';
    final questionsCount = quiz['questionsCount'] ?? quiz['questions_count'] ?? 10;
    final duration = quiz['duration'] ?? quiz['timeLimit'] ?? 5;
    final difficulty = quiz['difficulty']?.toString() ?? 'medium';
    final points = quiz['pointsPerQuestion'] ?? quiz['points'] ?? 5;

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
          title,
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
              description,
              style: core_styles.AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildInfoChip(
                  '$questionsCount preguntas',
                  Icons.quiz,
                  AppColors.info,
                ),
                _buildInfoChip(
                  '${duration} min',
                  Icons.timer,
                  AppColors.warning,
                ),
                _buildInfoChip(
                  difficulty,
                  Icons.trending_up,
                  _getDifficultyColor(difficulty),
                ),
                _buildInfoChip(
                  '$points pts',
                  Icons.eco,
                  AppColors.success,
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
          print('🎮 [QUIZ SELECTION] Starting server quiz: $quizId');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TriviaQuizGamePage(
                quizId: quizId,
                topicId: widget.topicId,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'facil':
        return AppColors.success;
      case 'medium':
      case 'medio':
        return AppColors.warning;
      case 'hard':
      case 'dificil':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  // 🔧 MÉTODO EXISTENTE: Fallback con ejemplos locales
  Widget _buildQuizzesList(BuildContext context) {
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
                        'Quizzes de ejemplo (modo desarrollo)',
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
            'Quizzes de Ejemplo',
            style: core_styles.AppTextStyles.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de quizzes de ejemplo
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
    return [
      {
        'id': 'example_quiz_${widget.topicId}_1',
        'title': 'Quiz Básico de ${widget.categoryTitle}',
        'description': 'Pon a prueba tus conocimientos básicos',
        'questions': 10,
        'duration': 5,
      },
      {
        'id': 'example_quiz_${widget.topicId}_2',
        'title': 'Quiz Avanzado de ${widget.categoryTitle}',
        'description': 'Desafío para expertos en el tema',
        'questions': 15,
        'duration': 8,
      },
    ];
  }
}