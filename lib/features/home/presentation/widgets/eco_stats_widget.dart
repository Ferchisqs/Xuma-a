import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';

class EcoStatsWidget extends StatelessWidget {
  const EcoStatsWidget({Key? key}) : super(key: key);

  // 🆕 Datos estáticos de estadísticas del usuario
  static const Map<String, dynamic> _userStatsData = {
    'totalPoints': 1250,
    'completedActivities': 23,
    'streak': 7,
    'currentLevel': 'Protector Verde',
    'recycledItems': 45,
    'carbonSaved': 12.5,
    'achievements': ['Primera Semana', 'Reciclador Pro', 'Ahorrador de Energía'],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu Impacto Ambiental',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Stats grid - 🔄 ALTURA FIJA AUMENTADA
        SizedBox(
          height: 150, // 🔄 Altura fija aumentada de 120 a 150
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2, // 🔄 Ratio más ancho para mejor distribución
            children: [
              _buildStatCard(
                'Puntos',
                '${_userStatsData['totalPoints']}',
                Icons.eco_rounded,
                AppColors.primary,
              ),
              _buildStatCard(
                'Actividades',
                '${_userStatsData['completedActivities']}',
                Icons.check_circle_rounded,
                AppColors.success,
              ),
              _buildStatCard(
                'Racha',
                '${_userStatsData['streak']} días',
                Icons.local_fire_department_rounded,
                AppColors.warning,
              ),
              _buildStatCard(
                'CO₂ Ahorrado',
                '${_userStatsData['carbonSaved']} kg',
                Icons.cloud_rounded,
                AppColors.info,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24), // 🔄 Más espacio entre grid y nivel
        
        // Level indicator - 🔄 ALTURA AUMENTADA Y MEJOR DISTRIBUCIÓN
        Container(
          width: double.infinity, // 🔄 Asegurar ancho completo
          height: 70, // 🔄 Altura fija
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.earthGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.military_tech_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nivel Actual',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userStatsData['currentLevel'] as String,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start, // 🔄 Alinear a la izquierda
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}