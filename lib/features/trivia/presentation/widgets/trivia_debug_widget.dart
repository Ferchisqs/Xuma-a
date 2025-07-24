// lib/features/trivia/presentation/widgets/trivia_debug_widget.dart
// WIDGET PARA INTEGRAR EN TU PÁGINA PRINCIPAL DE TRIVIA TEMPORALMENTE

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../cubit/trivia_cubit.dart';

class TriviaDebugWidget extends StatelessWidget {
  const TriviaDebugWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'DEBUG MODE - Quiz API Testing',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Current State Info
          BlocBuilder<TriviaCubit, TriviaState>(
            builder: (context, state) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current State: ${state.runtimeType}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    
                    if (state is TriviaLoaded) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Topics loaded: ${state.categories.length}',
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      ...state.categories.take(3).map((cat) => Text(
                        '  • ${cat.title} (ID: ${cat.id})',
                        style: const TextStyle(color: Colors.cyan, fontSize: 11),
                      )).toList(),
                      if (state.categories.length > 3)
                        Text(
                          '  ... and ${state.categories.length - 3} more',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                    ],
                    
                    if (state is TriviaQuizzesLoaded) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Quizzes for ${state.topicId}: ${state.quizzes.length}',
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      ...state.quizzes.take(2).map((quiz) => Text(
                        '  • ${quiz['title'] ?? quiz['name'] ?? 'Unknown'} (${quiz['id']})',
                        style: const TextStyle(color: Colors.yellow, fontSize: 11),
                      )).toList(),
                    ],
                    
                    if (state is TriviaError) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Quick Test Buttons
          Text(
            'Quick Tests:',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Step 1: Load Topics
              _buildTestButton(
                context,
                'Load Topics',
                AppColors.primary,
                () => context.read<TriviaCubit>().loadCategories(),
              ),
              
              // Step 2: Test common topic IDs
              _buildTestButton(
                context,
                'Test "1"',
                AppColors.info,
                () => context.read<TriviaCubit>().loadQuizzesByTopic('1'),
              ),
              
              _buildTestButton(
                context,
                'Test "topic_1"',
                AppColors.info,
                () => context.read<TriviaCubit>().loadQuizzesByTopic('topic_1'),
              ),
              
              _buildTestButton(
                context,
                'Test "reciclaje"',
                AppColors.info,
                () => context.read<TriviaCubit>().loadQuizzesByTopic('reciclaje'),
              ),
              
              // Step 3: Test with first loaded topic
              BlocBuilder<TriviaCubit, TriviaState>(
                builder: (context, state) {
                  if (state is TriviaLoaded && state.categories.isNotEmpty) {
                    final firstTopicId = state.categories.first.id;
                    return _buildTestButton(
                      context,
                      'Use 1st Topic\n($firstTopicId)',
                      AppColors.success,
                      () => context.read<TriviaCubit>().loadQuizzesByTopic(firstTopicId),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Debug actions
              _buildTestButton(
                context,
                'Debug State',
                AppColors.warning,
                () => context.read<TriviaCubit>().debugCurrentState(),
              ),
              
              _buildTestButton(
                context,
                'Print Flow',
                AppColors.secondary,
                () => context.read<TriviaCubit>().printFlowStatus(),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Instructions:\n'
              '1. Tap "Load Topics" first\n'
              '2. Check console logs for API responses\n'
              '3. Try different topic IDs to see which work\n'
              '4. Look for error messages in debug output',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}