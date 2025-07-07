import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

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
        
        // Stats grid - 🔄 ALTURA FIJA para evitar overflow
        SizedBox(
          height: 200, // 🔄 Altura fija para el grid
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4, // 🔄 Ratio más amplio para evitar overflow
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
        const SizedBox(height: 16),
        
        // Level indicator
        Container(
          padding: const EdgeInsets.all(16),
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
                  mainAxisSize: MainAxisSize.min, // 🔄 Tamaño mínimo
                  children: [
                    Text(
                      'Nivel Actual',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      _userStatsData['currentLevel'] as String,
                      style: AppTextStyles.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
      // 🔄 ALTURA FIJA para cada card
      height: 90,
      padding: const EdgeInsets.all(12), // 🔄 Padding reducido
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
        mainAxisSize: MainAxisSize.min, // 🔄 Tamaño mínimo
        children: [
          Container(
            padding: const EdgeInsets.all(6), // 🔄 Padding reducido
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20, // 🔄 Ícono más pequeño
            ),
          ),
          const SizedBox(height: 8), // 🔄 Espacio reducido
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith( // 🔄 Texto más pequeño
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2), // 🔄 Espacio reducido
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11, // 🔄 Texto más pequeño
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}