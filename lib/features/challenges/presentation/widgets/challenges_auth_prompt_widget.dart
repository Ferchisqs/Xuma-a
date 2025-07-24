// lib/features/challenges/presentation/widgets/challenges_auth_prompt_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ChallengesAuthPromptWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;

  const ChallengesAuthPromptWidget({
    Key? key,
    required this.message,
    this.onLogin,
    this.onRegister,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icono principal
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Título
          Text(
            'Únete a XUMA\'A',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Mensaje
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Beneficios
          _buildBenefitsList(),
          
          const SizedBox(height: 32),
          
          // Botones
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {
        'icon': Icons.emoji_events,
        'title': 'Gana Puntos',
        'description': 'Completa desafíos y acumula puntos eco',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Sigue tu Progreso',
        'description': 'Monitorea tu impacto ambiental',
      },
      {
        'icon': Icons.groups,
        'title': 'Únete a la Comunidad',
        'description': 'Conecta con otros eco-warriors',
      },
      {
        'icon': Icons.pets,
        'title': 'Cuida a Xico',
        'description': 'Tu mascota virtual te acompañará',
      },
    ];

    return Column(
      children: benefits.map((benefit) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                benefit['icon'] as IconData,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit['title'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    benefit['description'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón principal - Registrarse
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRegister,
            icon: const Icon(
              Icons.person_add,
              color: Colors.white,
            ),
            label: Text(
              'Crear Cuenta Gratis',
              style: AppTextStyles.buttonLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.4),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botón secundario - Iniciar sesión
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onLogin,
            icon: Icon(
              Icons.login,
              color: AppColors.primary,
            ),
            label: Text(
              'Ya Tengo Cuenta',
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
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Texto adicional
        Text(
          'Es gratis y solo toma 2 minutos',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}