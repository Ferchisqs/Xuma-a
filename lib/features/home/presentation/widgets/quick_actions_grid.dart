import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explorar',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 🔧 CORREGIDO: Grid con mejor aspect ratio para evitar overflow
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio:
              1.3, // 🔧 AUMENTADO de 1.1 a 1.3 para dar más espacio horizontal
          children: [
            _buildActionCard(
              context,
              'Aprendamos',
              'Educación ecológica',
              Icons.school_rounded,
              AppColors.secondary,
              () {
                context.read<NavigationCubit>().goToLearn();
              },
            ),
            _buildActionCard(
              context,
              'Trivias',
              'Pon a prueba tus conocimientos',
              Icons.quiz_rounded,
              AppColors.warning,
              () {
                context.read<NavigationCubit>().goToTrivia();
              },
            ),
            _buildActionCard(
              context,
              'Desafíos',
              'Retos ambientales',
              Icons.emoji_events_rounded,
              AppColors.accent,
              () {
                context.read<NavigationCubit>().goToChallenges();
              },
            ),
            _buildActionCard(
              context,
              'Compañeros',
              'Cuida a tu mascota virtual',
              Icons.pets_rounded,
              AppColors.primaryLight,
              () {
                context.read<NavigationCubit>().goToCompanion();
              },
            ),
            _buildActionCard(
              context,
              'Noticias',
              'Actualidad climática',
              Icons.newspaper_rounded,
              AppColors.info,
              () {
                context.read<NavigationCubit>().goToNews();
              },
            ),
            // 🆕 NUEVO: Botón de Contacto
            _buildActionCard(
              context,
              'Contacto',
              'Soporte y ayuda',
              Icons.support_agent_rounded,
              AppColors.info,
              () {
                context.read<NavigationCubit>().goToContact();
              },
            ),
          
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12), // 🔧 REDUCIDO de 16 a 12
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8), // 🔧 REDUCIDO de 12 a 8
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24, // 🔧 REDUCIDO de 28 a 24
              ),
            ),
            const SizedBox(height: 8), // 🔧 REDUCIDO de 12 a 8
            Text(
              title,
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14, // 🔧 REDUCIDO de 16 a 14
              ),
              textAlign: TextAlign.center,
              maxLines: 1, // 🔧 LIMITAR A 1 LÍNEA
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2), // 🔧 REDUCIDO de 4 a 2
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11, // 🔧 REDUCIDO para que quepa mejor
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
