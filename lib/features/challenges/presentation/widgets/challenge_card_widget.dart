import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/challenge_entity.dart';
import '../pages/challenge_detail_page.dart';

class ChallengeCardWidget extends StatelessWidget {
  final ChallengeEntity challenge;

  const ChallengeCardWidget({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeDetailPage(challenge: challenge),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con imagen y estado
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: _getChallengeGradient(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildStatusBadge(),
                  ),
                  // Challenge icon
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconData(challenge.iconCode, fontFamily: 'MaterialIcons'),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Points badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${challenge.totalPoints} pts',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Expanded(
                      flex: 2,
                      child: Text(
                        challenge.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Progress (if participating)
                    if (challenge.isParticipating) ...[
                      _buildProgressBar(),
                      const SizedBox(height: 8),
                    ],
                    
                    // Type and time info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTypeColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getTypeText(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _getTypeColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!challenge.isCompleted && !challenge.isExpired)
                          Text(
                            challenge.formattedTimeRemaining,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textHint,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    IconData icon;
    Color color;
    
    if (challenge.isCompleted) {
      icon = Icons.check_circle;
      color = AppColors.success;
    } else if (challenge.isParticipating) {
      icon = Icons.play_circle;
      color = AppColors.warning;
    } else if (challenge.isExpired) {
      icon = Icons.cancel;
      color = AppColors.error;
    } else {
      icon = Icons.radio_button_unchecked;
      color = Colors.white.withOpacity(0.8);
    }
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              '${challenge.currentProgress}/${challenge.targetProgress}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: challenge.progressPercentage,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ],
    );
  }

  LinearGradient _getChallengeGradient() {
    switch (challenge.category) {
      case 'reciclaje':
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'energia':
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'agua':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'compostaje':
        return const LinearGradient(
          colors: [Color(0xFF795548), Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppColors.primaryGradient;
    }
  }

  String _getTypeText() {
    switch (challenge.type) {
      case ChallengeType.daily:
        return 'Diario';
      case ChallengeType.weekly:
        return 'Semanal';
      case ChallengeType.monthly:
        return 'Mensual';
      case ChallengeType.special:
        return 'Especial';
    }
  }

  Color _getTypeColor() {
    switch (challenge.type) {
      case ChallengeType.daily:
        return AppColors.primary;
      case ChallengeType.weekly:
        return AppColors.warning;
      case ChallengeType.monthly:
        return AppColors.error;
      case ChallengeType.special:
        return AppColors.accent;
    }
  }
}