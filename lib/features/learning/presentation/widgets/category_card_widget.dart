// lib/features/learning/presentation/widgets/category_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/category_entity.dart';
import '../pages/lesson_list_page.dart';

class CategoryCardWidget extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback? onTap;

  const CategoryCardWidget({
    Key? key,
    required this.category,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 🚨 NAVEGACIÓN CORREGIDA
        debugPrint('🎯 Navegando a categoría: ${category.title}');
        
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonListPage(category: category),
            ),
          );
        } catch (e) {
          debugPrint('❌ Error navegando: $e');
          
          // Mostrar error al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al abrir ${category.title}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Container(
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
            // Imagen de la categoría
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: _getCategoryGradient(category.id),
              ),
              child: Stack(
                children: [
                  // Overlay con gradiente
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Icono de la categoría
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Título sobre la imagen
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      category.title,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido de la card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción
                  Text(
                    category.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Información de lecciones
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${category.lessonsCount} lecciones',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        category.estimatedTime,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  
                  // Barra de progreso (si hay progreso)
                  if (category.completedLessons > 0) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${(category.progressPercentage * 100).round()}%',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: category.progressPercentage,
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    // Botón de empezar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Empezar',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getCategoryGradient(String categoryId) {
    switch (categoryId) {
      case 'cat_1':
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cat_2':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cat_3':
        return const LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cat_4':
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cat_5':
        return const LinearGradient(
          colors: [Color(0xFF795548), Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cat_6':
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppColors.primaryGradient;
    }
  }
}