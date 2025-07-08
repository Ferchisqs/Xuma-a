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
import '../widgets/trivia_completion_dialog.dart';

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
            _showCompletionDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is TriviaGameLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Preparando trivia...',
              ),
            );
          }

          if (state is TriviaGameError) {
            return Center(
              child: EcoErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<TriviaGameCubit>().startTrivia(widget.category);
                },
              ),
            );
          }

          if (state is TriviaGameReady) {
            return Column(
              children: [
                // Header con progreso y puntos
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
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
                                  '100',
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

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir de la trivia?'),
        content: const Text('Perderás todo tu progreso actual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, TriviaGameCompleted state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TriviaCompletionDialog(
        result: state.result,
        onContinue: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}