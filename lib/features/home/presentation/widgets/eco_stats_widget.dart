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
        
        // Stats grid - 🔄 ALTURA AUMENTADA para evitar solapamiento
        Container(
          height: 200, // 🔄 Altura aumentada
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8, // 🔄 Ratio más ancho para evitar solapamiento
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
        const SizedBox(height: 20), // 🔄 Más espacio entre grid y nivel
        
        // Level indicator - 🔄 ALTURA AUMENTADA Y MEJOR DISTRIBUCIÓN
        Container(
          height: 80, // 🔄 Altura aumentada
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 🔄 Padding ajustado
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
                  mainAxisAlignment: MainAxisAlignment.center, // 🔄 Centrar verticalmente
                  children: [
                    Text(
                      'Nivel Actual',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11, // 🔄 Texto ligeramente más grande
                      ),
                    ),
                    const SizedBox(height: 2), // 🔄 Pequeño espacio
                    Text(
                      _userStatsData['currentLevel'] as String,
                      style: AppTextStyles.h4.copyWith( // 🔄 Usar h4 para mejor jerarquía
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16, // 🔄 Tamaño adecuado
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
      // 🔄 SIN altura fija aquí, se maneja con el grid
      padding: const EdgeInsets.all(10), // 🔄 Padding aumentado
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
        mainAxisSize: MainAxisSize.min, // 🔄 Tamaño mínimo para evitar overflow
        children: [
          Container(
            padding: const EdgeInsets.all(6), // 🔄 Padding aumentado
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18, // 🔄 Ícono ligeramente más grande
            ),
          ),
          const SizedBox(height: 6), // 🔄 Espacio aumentado
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith( // 🔄 Texto más pequeño pero legible
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2), // 🔄 Espacio mínimo
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10, // 🔄 Texto legible
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