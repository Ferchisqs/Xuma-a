import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class TriviaTimerWidget extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;

  const TriviaTimerWidget({
    Key? key,
    required this.timeRemaining,
    required this.totalTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = timeRemaining / totalTime;
    final isLowTime = timeRemaining <= 5;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiempo',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '00:${timeRemaining.toString().padLeft(2, '0')}',
              style: AppTextStyles.h4.copyWith(
                color: isLowTime ? AppColors.warning : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Barra de progreso del tiempo
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: isLowTime ? AppColors.warning : Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
