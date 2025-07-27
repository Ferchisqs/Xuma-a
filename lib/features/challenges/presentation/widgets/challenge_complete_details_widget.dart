// lib/features/challenges/presentation/widgets/challenge_complete_details_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/challenge_entity.dart';

class ChallengeCompleteDetailsWidget extends StatelessWidget {
  final ChallengeEntity challenge;

  const ChallengeCompleteDetailsWidget({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== INSTRUCCIONES =====
        if (challenge.requirements.isNotEmpty)
          _buildSectionCard(
            title: 'Instrucciones',
            icon: Icons.list_alt,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: challenge.requirements.map((instruction) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          instruction.replaceAll('• ', ''),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
          ),

        const SizedBox(height: 16),

        // ===== INFORMACIÓN GENERAL =====
        _buildSectionCard(
          title: 'Información General',
          icon: Icons.info_outline,
          content: Column(
            children: [
              _buildInfoRow('Categoría', challenge.category),
              _buildInfoRow('Dificultad', _getDifficultyText(challenge.difficulty)),
              _buildInfoRow('Puntos', '${challenge.totalPoints} pts'),
              _buildInfoRow('Duración', challenge.formattedTimeRemaining),
              _buildInfoRow('Progreso requerido', '${challenge.targetProgress} acciones'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== VALIDACIÓN =====
        _buildSectionCard(
          title: 'Criterio de Validación',
          icon: Icons.verified,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Tipo de validación', 'Fotográfica'),
              _buildInfoRow('Evidencia requerida', 'Fotografías del proceso'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deberás subir fotos que demuestren que completaste el desafío',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== PARTICIPACIÓN =====
        _buildSectionCard(
          title: 'Participación',
          icon: Icons.groups,
          content: Column(
            children: [
              _buildInfoRow('Máximo participantes', '100'),
              _buildInfoRow('Participantes actuales', '1'),
              _buildInfoRow('Espacios disponibles', '99'),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 1 / 100, // currentParticipants / maxParticipants
                backgroundColor: AppColors.primary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                '1% de capacidad utilizada',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== FECHAS IMPORTANTES =====
        _buildSectionCard(
          title: 'Fechas Importantes',
          icon: Icons.schedule,
          content: Column(
            children: [
              _buildInfoRow('Fecha de inicio', _formatDate(challenge.startDate)),
              _buildInfoRow('Fecha de finalización', _formatDate(challenge.endDate)),
              _buildInfoRow('Estado actual', _getStatusText(challenge.status)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(challenge.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(challenge.status),
                      color: _getStatusColor(challenge.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStatusMessage(challenge.status),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _getStatusColor(challenge.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== RESTRICCIONES DE EDAD =====
        _buildSectionCard(
          title: 'Restricciones',
          icon: Icons.person,
          content: Column(
            children: [
              _buildInfoRow('Edad mínima', '8 años'),
              _buildInfoRow('Edad máxima', '18 años'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.child_care,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este desafío está diseñado para jóvenes',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyText(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Fácil';
      case ChallengeDifficulty.medium:
        return 'Medio';
      case ChallengeDifficulty.hard:
        return 'Difícil';
    }
  }

  String _getStatusText(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.notStarted:
        return 'No iniciado';
      case ChallengeStatus.active:
        return 'Activo';
      case ChallengeStatus.completed:
        return 'Completado';
      case ChallengeStatus.expired:
        return 'Expirado';
    }
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.notStarted:
        return AppColors.textSecondary;
      case ChallengeStatus.active:
        return AppColors.success;
      case ChallengeStatus.completed:
        return AppColors.primary;
      case ChallengeStatus.expired:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.notStarted:
        return Icons.hourglass_empty;
      case ChallengeStatus.active:
        return Icons.play_circle;
      case ChallengeStatus.completed:
        return Icons.check_circle;
      case ChallengeStatus.expired:
        return Icons.cancel;
    }
  }

  String _getStatusMessage(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.notStarted:
        return 'Puedes unirte cuando quieras';
      case ChallengeStatus.active:
        return 'Desafío en progreso';
      case ChallengeStatus.completed:
        return '¡Desafío completado exitosamente!';
      case ChallengeStatus.expired:
        return 'Este desafío ya no está disponible';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}