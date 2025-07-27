// lib/features/trivia/presentation/pages/trivia_quiz_game_page.dart - CORREGIDA PARA USAR ESTRUCTURA REAL
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../cubit/quiz_session_cubit.dart';
import '../widgets/trivia_timer_widget.dart';
import '../widgets/trivia_progress_widget.dart';

class TriviaQuizGamePage extends StatelessWidget {
  final String quizId;
  final String topicId;

  const TriviaQuizGamePage({
    Key? key,
    required this.quizId,
    required this.topicId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QuizSessionCubit>(),
      child: _TriviaQuizGameContent(quizId: quizId, topicId: topicId),
    );
  }
}

class _TriviaQuizGameContent extends StatefulWidget {
  final String quizId;
  final String topicId;

  const _TriviaQuizGameContent({
    required this.quizId,
    required this.topicId,
  });

  @override
  State<_TriviaQuizGameContent> createState() => _TriviaQuizGameContentState();
}

class _TriviaQuizGameContentState extends State<_TriviaQuizGameContent> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startQuiz() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      print('🧠 [QUIZ] Starting quiz with userId: ${authState.user.id}');
      context.read<QuizSessionCubit>().startQuiz(
        quizId: widget.quizId,
        userId: authState.user.id,
      );
    } else {
      print('⚠️ [QUIZ] No authenticated user found, using demo user');
      // Para desarrollo, usar un userId de ejemplo
      context.read<QuizSessionCubit>().startQuiz(
        quizId: widget.quizId,
        userId: 'demo_user_123',
      );
    }
  }

  void _startTimer(int timeRemaining) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining <= 0) {
        context.read<QuizSessionCubit>().timeUp();
        timer.cancel();
      } else {
        timeRemaining--;
        context.read<QuizSessionCubit>().updateTimer(timeRemaining);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _showExitDialog(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: Text(
          'Quiz Challenge',
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<QuizSessionCubit, QuizSessionState>(
        listener: (context, state) {
          if (state is QuizSessionStarted && !state.isAnswerSubmitted) {
            _startTimer(state.timeRemaining);
          } else if (state is QuizSessionStarted && state.isAnswerSubmitted) {
            _timer?.cancel();
          } else if (state is QuizSessionCompleted) {
            _timer?.cancel();
            _showResultsDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is QuizSessionLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Preparando quiz...',
              ),
            );
          }
          
          if (state is QuizSessionError) {
            return Center(
              child: EcoErrorWidget(
                message: state.message,
                onRetry: () => _startQuiz(),
              ),
            );
          }
          
          if (state is QuizSessionStarted) {
            return _buildQuizContent(context, state);
          }
          
          return Center(
            child: Text(
              'Preparando quiz...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizContent(BuildContext context, QuizSessionStarted state) {
    final question = state.currentQuestion;
    
    return Column(
      children: [
        // Header con progreso y timer
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Progreso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TriviaProgressWidget(
                    currentQuestion: state.currentQuestionIndex + 1,
                    totalQuestions: state.questions.length,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${question.points}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Timer
              TriviaTimerWidget(
                timeRemaining: state.timeRemaining,
                totalTime: question.timeLimit,
              ),
            ],
          ),
        ),
        
        // Pregunta y opciones
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pregunta
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    question.question,
                    style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  'Selecciona la respuesta correcta',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 🔧 OPCIONES CORREGIDAS PARA USAR LA ESTRUCTURA REAL
                Expanded(
                  child: ListView.builder(
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      // 🔧 GENERAR OPTION ID BASADO EN LA PREGUNTA Y EL ÍNDICE
                      final optionId = '${question.id}_option_$index';
                      final isSelected = state.currentSelectedAnswer == optionId;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAnswerOption(
                          context,
                          option,
                          optionId,
                          index,
                          isSelected,
                          state.isAnswerSubmitted,
                          state,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerOption(
    BuildContext context,
    String option,
    String optionId,
    int index,
    bool isSelected,
    bool isAnswerSubmitted,
    QuizSessionStarted state,
  ) {
    Color backgroundColor = AppColors.surface;
    Color borderColor = AppColors.primary.withOpacity(0.3);
    Color textColor = AppColors.textPrimary;
    
    // 🔧 MOSTRAR RESPUESTA CORRECTA E INCORRECTA DESPUÉS DE RESPONDER
    if (isAnswerSubmitted) {
      if (index == state.currentQuestion.correctAnswerIndex) {
        // Esta es la respuesta correcta
        backgroundColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success;
        textColor = AppColors.success;
      } else if (isSelected) {
        // Esta fue la respuesta seleccionada pero incorrecta
        backgroundColor = AppColors.error.withOpacity(0.1);
        borderColor = AppColors.error;
        textColor = AppColors.error;
      }
    } else if (isSelected) {
      // Respuesta seleccionada pero aún no enviada
      backgroundColor = AppColors.primary.withOpacity(0.1);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: isAnswerSubmitted ? null : () {
        print('🧠 [QUIZ] Option selected: $optionId (index: $index)');
        context.read<QuizSessionCubit>().selectAnswer(optionId);
        
        // Auto-submit después de seleccionar
        context.read<QuizSessionCubit>().submitAnswer(
          timeTakenSeconds: state.currentQuestion.timeLimit - state.timeRemaining,
          answerConfidence: 5, // Confianza media por defecto
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 🔧 ICONOS MEJORADOS
            if (isAnswerSubmitted && index == state.currentQuestion.correctAnswerIndex)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else if (isAnswerSubmitted && isSelected && index != state.currentQuestion.correctAnswerIndex)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else if (isSelected && !isAnswerSubmitted)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Salir del quiz?',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Perderás todo tu progreso actual. ¿Estás seguro?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancelar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: Text(
              'Salir',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultsDialog(BuildContext context, QuizSessionCompleted state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Estrella de éxito con animación
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.rotate(
                      angle: value * 2 * 3.14159,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.earthGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              Text(
                '¡Quiz Completado!',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Mostrar resultados con mejor formato
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.eco,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Puntos Ganados',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _extractPointsFromResults(state.results),
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '🐾 ¡Usa tus puntos para comprar compañeros!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Estadísticas adicionales si están disponibles
              if (state.results.containsKey('accuracy') || 
                  state.results.containsKey('correctAnswers'))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (state.results.containsKey('correctAnswers'))
                        _buildStatItem(
                          'Correctas',
                          '${state.results['correctAnswers']}',
                          Icons.check_circle,
                        ),
                      if (state.results.containsKey('accuracy'))
                        _buildStatItem(
                          'Precisión',
                          '${state.results['accuracy']}%',
                          Icons.percent,
                        ),
                      _buildStatItem(
                        'Tiempo',
                        _formatDuration(state.results['duration'] ?? 0),
                        Icons.timer,
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Column(
                children: [
                  // Botón principal - Ver compañeros
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pop();
                        // TODO: Navegar a compañeros si tienes NavigationCubit
                        // context.read<NavigationCubit>().goToCompanion();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        'Ver mis Compañeros',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botón secundario - Continuar con quizzes
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continuar con Quizzes',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.info,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _extractPointsFromResults(Map<String, dynamic> results) {
    // Intentar extraer puntos de diferentes campos posibles
    final points = results['points'] ?? 
                  results['pointsEarned'] ?? 
                  results['score'] ?? 
                  results['totalPoints'] ?? 
                  0;
    return '+ $points pts';
  }

  String _formatDuration(dynamic duration) {
    if (duration is int) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
    return '0:00';
  }
}