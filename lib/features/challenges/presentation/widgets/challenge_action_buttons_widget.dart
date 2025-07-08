import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/challenge_entity.dart';

class ChallengeActionButtonsWidget extends StatelessWidget {
  final ChallengeEntity challenge;
  final bool isLoading;
  final VoidCallback? onJoin;
  final VoidCallback? onAddProgress;

  const ChallengeActionButtonsWidget({
    Key? key,
    required this.challenge,
    this.isLoading = false,
    this.onJoin,
    this.onAddProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón principal
        SizedBox(
          width: double.infinity,
          child: _buildPrimaryButton(),
        ),
        
        // Botón secundario (si aplica)
        if (challenge.isParticipating && !challenge.isCompleted) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildSecondaryButton(),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton() {
    String text;
    VoidCallback? onPressed;
    Color backgroundColor;
    IconData icon;

    if (challenge.isCompleted) {
      text = '¡Desafío Completado!';
      backgroundColor = AppColors.success;
      icon = Icons.check_circle;
      onPressed = null;
    } else if (challenge.isExpired) {
      text = 'Desafío Expirado';
      backgroundColor = AppColors.error;
      icon = Icons.access_time;
      onPressed = null;
    } else if (challenge.isParticipating) {
      text = 'Participando';
      backgroundColor = AppColors.primary;
      icon = Icons.play_circle;
      onPressed = null;
    } else {
      text = 'Unirse al Desafío';
      backgroundColor = AppColors.primary;
      icon = Icons.add_circle;
      onPressed = isLoading ? null : onJoin;
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: AppTextStyles.buttonLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: challenge.isCompleted || challenge.isExpired ? 0 : 4,
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onAddProgress,
      icon: Icon(
        Icons.add_task,
        color: AppColors.primary,
      ),
      label: Text(
        'Registrar Progreso',
        style: AppTextStyles.buttonLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primary, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}