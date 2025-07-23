// lib/features/trivia/presentation/pages/trivia_quiz_selection_page.dart - ACTUALIZADA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart' as core_styles;
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../cubit/trivia_cubit.dart';
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
      create: (_) => getIt<TriviaCubit>()..loadQuizzesByTopic(topicId),
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
    print('🎯 [QUIZ SELECTION] Initializing for topic: ${widget.topicId}');
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
        actions: [
          IconButton(
            onPressed: () {
              context.read<TriviaCubit>().debugCurrentState();
              context.read<TriviaCubit>().printFlowStatus();
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      body: BlocBuilder<TriviaCubit, TriviaState>(
        builder: (context, state) {
          print('🔍 [QUIZ SELECTION] Current state: ${state.runtimeType}');
          
          if (state is TriviaQuizzesLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Cargando quizzes...',
              ),
            );
          }
          
          if (state is TriviaError) {
            return Center(
              child: EcoErrorWidget(
                message: state.message,
                onRetry: () {
                  print('🔄 [QUIZ SELECTION] Retrying load quizzes for topic: ${widget.topicId}');
                  context.read<TriviaCubit>().loadQuizzesByTopic(widget.topicId);
                },
              ),
            );
          }
          
          if (state is TriviaQuizzesLoaded) {
            return _buildQuizzesList(context, state.quizzes);
          }
          
          // Estado inicial o desconocido
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.quiz_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparando quizzes...',
                  style: core_styles.AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<TriviaCubit>().loadQuizzesByTopic(widget.topicId);
                  },
                  child: const Text('Cargar Quizzes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizzesList(BuildContext context, List<Map<String, dynamic>> quizzes) {
    print('🎯 [QUIZ SELECTION] Building list with ${quizzes.length} quizzes');
    
    if (quizzes.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header informativo
          _buildInfoHeader(),
          
          const SizedBox(height: 24),
          
          Text(
            'Quizzes Disponibles (${quizzes.length})',
            style: core_styles.AppTextStyles.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de quizzes
          Expanded(
            child: ListView.builder(
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return _buildQuizCard(context, quiz, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
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
                  'Topic: ${widget.categoryTitle}',
                  style: core_styles.AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, Map<String, dynamic> quiz, int index) {
    // Extraer datos del quiz con fallbacks
    final quizId = quiz['id']?.toString() ?? 'quiz_${widget.topicId}_$index';
    final title = quiz['title']?.toString() ?? 
                  quiz['name']?.toString() ?? 
                  'Quiz ${index + 1}';
    final description = quiz['description']?.toString() ?? 
                       'Pon a prueba tus conocimientos sobre ${widget.categoryTitle}';
    final questionsCount = _extractInt(quiz['questionsCount']) ?? 
                          _extractInt(quiz['questions']) ?? 
                          _extractInt(quiz['totalQuestions']) ?? 
                          10;
    final duration = _extractInt(quiz['duration']) ?? 
                    _extractInt(quiz['estimatedTime']) ?? 
                    5;
    final points = _extractInt(quiz['points']) ?? 
                  _extractInt(quiz['totalPoints']) ?? 
                  questionsCount * 5;

    print('🔍 [QUIZ SELECTION] Quiz $index: ID=$quizId, Title=$title, Questions=$questionsCount');

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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  '$questionsCount preguntas',
                  Icons.quiz,
                  AppColors.info,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  '${duration} min',
                  Icons.timer,
                  AppColors.warning,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  '+$points pts',
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
          print('🎯 [QUIZ SELECTION] Starting quiz: $quizId');
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay quizzes disponibles',
              style: core_styles.AppTextStyles.h4.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron quizzes para este tema. Intenta más tarde o selecciona otro tema.',
              style: core_styles.AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TriviaCubit>().loadQuizzesByTopic(widget.topicId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para extraer integers de forma segura
  int? _extractInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}