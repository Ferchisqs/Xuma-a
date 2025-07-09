// lib/features/trivia/presentation/widgets/trivia_difficulty_badge.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/trivia_category_entity.dart';

class TrivaDifficultyBadge extends StatelessWidget {
  final TriviaDifficulty difficulty;

  const TrivaDifficultyBadge({
    Key? key,
    required this.difficulty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final difficultyData = _getDifficultyData();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: difficultyData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: difficultyData['color'],
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            difficultyData['icon'],
            color: difficultyData['color'],
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            difficultyData['text'],
            style: AppTextStyles.bodySmall.copyWith(
              color: difficultyData['color'],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDifficultyData() {
    switch (difficulty) {
      case TriviaDifficulty.easy:
        return {
          'text': 'Fácil',
          'color': AppColors.success,
          'icon': Icons.sentiment_satisfied,
        };
      case TriviaDifficulty.medium:
        return {
          'text': 'Medio',
          'color': AppColors.warning,
          'icon': Icons.sentiment_neutral,
        };
      case TriviaDifficulty.hard:
        return {
          'text': 'Difícil',
          'color': AppColors.error,
          'icon': Icons.sentiment_very_dissatisfied,
        };
    }
  }
}