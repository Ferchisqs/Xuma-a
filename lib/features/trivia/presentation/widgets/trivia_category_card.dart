// lib/features/trivia/presentation/widgets/trivia_category_card.dart - NAVEGACIÓN CORREGIDA
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../pages/trivia_quiz_selection_page.dart'; // 🔧 CAMBIO: Ir a selección de quizzes

class TriviaCategoryCard extends StatelessWidget {
  final TriviaCategoryEntity category;

  const TriviaCategoryCard({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('🎯 [CATEGORY CARD] Navigating to quiz selection for category: ${category.id}');
        print('🎯 [CATEGORY CARD] Category title: ${category.title}');
        
        // 🔧 CAMBIO PRINCIPAL: Navegar a la página de selección de quizzes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TriviaQuizSelectionPage(
              topicId: category.id,        // 🔧 Usar el ID del topic
              categoryTitle: category.title, // 🔧 Pasar el título
            ),
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
            // Imagen de la categoría
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: _getCategoryGradient(),
                ),
                child: Stack(
                  children: [
                    // Overlay
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
                    // Icono
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // 🔧 AGREGAR INDICADOR DE NAVEGACIÓN
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ver Quizzes',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Título
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Text(
                        category.title,
                        style: AppTextStyles.bodyMedium.copyWith(
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
            ),
            
            // Información
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔧 CAMBIAR TEXTO PARA SER MÁS CLARO
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ver quizzes disponibles',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.eco,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${category.pointsPerQuestion} pts por pregunta',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 🔧 AGREGAR INDICADOR DE ACCIÓN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'EXPLORAR',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.primary,
                                size: 10,
                              ),
                            ],
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

  LinearGradient _getCategoryGradient() {
    // Gradientes basados en el título de la categoría
    final title = category.title.toLowerCase();
    
    if (title.contains('agua') || title.contains('water')) {
      return const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (title.contains('reciclaje') || title.contains('residuo')) {
      return const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (title.contains('energia') || title.contains('energy')) {
      return const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (title.contains('clima') || title.contains('climate')) {
      return const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Gradiente por defecto basado en el ID
      final hash = category.id.hashCode;
      final colors = [
        [Color(0xFF795548), Color(0xFF8D6E63)], // Marrón
        [Color(0xFF607D8B), Color(0xFF78909C)], // Azul gris
        [Color(0xFF009688), Color(0xFF26A69A)], // Teal
        [Color(0xFF3F51B5), Color(0xFF5C6BC0)], // Indigo
        [Color(0xFFE91E63), Color(0xFFF06292)], // Rosa
      ];
      final selectedColors = colors[hash.abs() % colors.length];
      return LinearGradient(
        colors: selectedColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }
}