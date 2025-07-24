// lib/features/trivia/presentation/pages/trivia_game_page.dart - CON FALLBACK
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../cubit/trivia_game_cubit.dart';
import '../widgets/trivia_question_widget.dart';
import '../widgets/trivia_timer_widget.dart';
import '../widgets/trivia_progress_widget.dart';
import '../widgets/animated_trivia_completion_dialog.dart';

class TriviaGamePage extends StatelessWidget {
  final TriviaCategoryEntity category;

  const TriviaGamePage({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TriviaGameCubit>()..startTrivia(category),
      child: _TriviaGameContent(category: category),
    );
  }
}

class _TriviaGameContent extends StatefulWidget {
  final TriviaCategoryEntity category;

  const _TriviaGameContent({required this.category});

  @override
  State<_TriviaGameContent> createState() => _TriviaGameContentState();
}

class _TriviaGameContentState extends State<_TriviaGameContent> {
  Timer? _timer;
  int _currentTime = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int initialTime) {
    _timer?.cancel();
    _currentTime = initialTime;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime <= 0) {
        context.read<TriviaGameCubit>().timeUp();
        timer.cancel();
      } else {
        _currentTime--;
        context.read<TriviaGameCubit>().updateTimer(_currentTime);
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
          widget.category.title,
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<TriviaGameCubit, TriviaGameState>(
        listener: (context, state) {
          if (state is TriviaGameReady && !state.isAnswered) {
            _startTimer(state.timeRemaining);
          } else if (state is TriviaGameReady && state.isAnswered) {
            _timer?.cancel();
          } else if (state is TriviaGameCompleted) {
            _timer?.cancel();
            _showAnimatedCompletionDialog(context, state);
          } else if (state is TriviaGameError) {
            _timer?.cancel();
            // Mostrar error pero permitir reintentar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Reintentar',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<TriviaGameCubit>().startTrivia(widget.category);
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TriviaGameLoading) {
            return _buildLoadingState();
          }

          if (state is TriviaGameError) {
            return _buildErrorState(context, state.message);
          }

          if (state is TriviaGameReady) {
            return _buildGameContent(context, state);
          }

          if (state is TriviaGameCompleted) {
            return _buildCompletedState(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Header decorativo
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.quiz_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Preparando Trivia',
                    style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.category.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        
        // Loading content
        const Expanded(
          child: Center(
            child: EcoLoadingWidget(
              message: 'Cargando preguntas...',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Column(
      children: [
        // Header con error
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Error al cargar',
                    style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Error content
        Expanded(
          child: Center(
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
                    'No se pudieron cargar las preguntas',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verifica tu conexión a internet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<TriviaGameCubit>().startTrivia(widget.category);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Volver a categorías',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameContent(BuildContext context, TriviaGameReady state) {
    return Column(
      children: [
        // Header con progreso y puntos
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
              // Progreso y timer
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
                          '${state.currentQuestion.points}',
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
                totalTime: widget.category.timePerQuestion,
              ),
            ],
          ),
        ),
        
        // Pregunta
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TriviaQuestionWidget(
              question: state.currentQuestion,
              selectedAnswer: state.selectedAnswer,
              isAnswered: state.isAnswered,
              onAnswerSelected: (index) {
                context.read<TriviaGameCubit>().selectAnswer(index);
              },
              onNext: () {
                context.read<TriviaGameCubit>().nextQuestion();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedState(BuildContext context, TriviaGameCompleted state) {
    return Column(
      children: [
        // Header de completado
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.earthGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '¡Trivia Completada!',
                    style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Contenido de completado
        const Expanded(
          child: Center(
            child: EcoLoadingWidget(
              message: 'Procesando resultados...',
            ),
          ),
        ),
      ],
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
            Text(
              '¿Salir de la trivia?',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
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

  void _showAnimatedCompletionDialog(BuildContext context, TriviaGameCompleted state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AnimatedTriviaCompletionDialog(
        result: state.result,
        onContinue: () {
          Navigator.of(context).pop(); // Cerrar la página de trivia
        },
      ),
    );
  }
}