import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/trivia_question_entity.dart';
import 'trivia_answer_option.dart';

class TriviaQuestionWidget extends StatelessWidget {
  final TriviaQuestionEntity question;
  final int? selectedAnswer;
  final bool isAnswered;
  final Function(int) onAnswerSelected;
  final VoidCallback onNext;

  const TriviaQuestionWidget({
    Key? key,
    required this.question,
    this.selectedAnswer,
    required this.isAnswered,
    required this.onAnswerSelected,
    required this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
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
        
        // Instrucción
        Text(
          'Selecciona la respuesta correcta',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Opciones de respuesta
        Expanded(
          child: Column(
            children: [
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TriviaAnswerOption(
                    text: option,
                    isSelected: selectedAnswer == index,
                    isCorrect: isAnswered && index == question.correctAnswerIndex,
                    isWrong: isAnswered && 
                             selectedAnswer == index && 
                             index != question.correctAnswerIndex,
                    isDisabled: isAnswered,
                    onTap: () => onAnswerSelected(index),
                  ),
                );
              }).toList(),
              
              const Spacer(),
              
              // Botón siguiente
              if (isAnswered)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuar',
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}