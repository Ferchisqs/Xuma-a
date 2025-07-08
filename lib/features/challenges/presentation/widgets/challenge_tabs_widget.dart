import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/challenge_entity.dart';

class ChallengeTabsWidget extends StatelessWidget {
  final ChallengeType? currentFilter;
  final Function(ChallengeType?) onFilterChange;
  final int dailyCount;
  final int weeklyCount;
  final int monthlyCount;

  const ChallengeTabsWidget({
    Key? key,
    required this.currentFilter,
    required this.onFilterChange,
    required this.dailyCount,
    required this.weeklyCount,
    required this.monthlyCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipos de Desafíos',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton(
                  'Todos',
                  null,
                  dailyCount + weeklyCount + monthlyCount,
                  currentFilter == null,
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  'Diarios',
                  ChallengeType.daily,
                  dailyCount,
                  currentFilter == ChallengeType.daily,
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  'Semanales',
                  ChallengeType.weekly,
                  weeklyCount,
                  currentFilter == ChallengeType.weekly,
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  'Mensuales',
                  ChallengeType.monthly,
                  monthlyCount,
                  currentFilter == ChallengeType.monthly,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, ChallengeType? type, int count, bool isSelected) {
    return GestureDetector(
      onTap: () => onFilterChange(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary 
              : AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : AppColors.primary.withOpacity(0.3),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected 
                    ? Colors.white 
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected 
                        ? Colors.white 
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}