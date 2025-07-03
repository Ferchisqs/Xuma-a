import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

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
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              'Noticias',
              'Actualidad ambiental',
              Icons.article_rounded,
              AppColors.info,
              () {
                // Navegar a noticias
              },
            ),
            _buildActionCard(
              'Aprendamos',
              'Educación ecológica',
              Icons.school_rounded,
              AppColors.secondary,
              () {
                // Navegar a aprendamos
              },
            ),
            _buildActionCard(
              'Proyectos',
              'Iniciativas verdes',
              Icons.construction_rounded,
              AppColors.warning,
              () {
                // Navegar a proyectos
              },
            ),
            _buildActionCard(
              'Desafíos',
              'Retos ambientales',
              Icons.emoji_events_rounded,
              AppColors.accent,
              () {
                // Navegar a desafíos
              },
            ),
            _buildActionCard(
              'Comunidad',
              'Red de eco-amigos',
              Icons.groups_rounded,
              AppColors.primaryLight,
              () {
                // Navegar a comunidad
              },
            ),
            _buildActionCard(
              'Contacto',
              'Ayuda y soporte',
              Icons.support_agent_rounded,
              AppColors.textSecondary,
              () {
                // Navegar a contacto
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
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