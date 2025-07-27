// lib/features/trivia/presentation/pages/trivia_category_detail_page.dart - NAVEGACIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../cubit/trivia_game_cubit.dart';
import '../widgets/trivia_difficulty_badge.dart';
import 'trivia_quiz_selection_page.dart'; // 🔧 CAMBIO: Ir a selección de quizzes

class TriviaCategoryDetailPage extends StatelessWidget {
  final TriviaCategoryEntity category;

  const TriviaCategoryDetailPage({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TriviaGameCubit>(),
      child: _CategoryDetailContent(category: category),
    );
  }
}

class _CategoryDetailContent extends StatelessWidget {
  final TriviaCategoryEntity category;

  const _CategoryDetailContent({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar personalizada con imagen de fondo
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                category.title,
                style: AppTextStyles.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: _getCategoryGradient(),
                ),
                child: Stack(
                  children: [
                    // Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    // Icono grande con animación
                    Center(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(seconds: 2),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Contenido principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información básica de la categoría
                  _buildCategoryInfo(),
                  
                  const SizedBox(height: 24),
                  
                  // 🔧 CAMBIO: Botón para ver quizzes en lugar de iniciar trivia directamente
                  _buildViewQuizzesButton(context),
                  
                  const SizedBox(height: 24),
                  
                  // Información adicional
                  _buildAdditionalInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Estadísticas
          Row(
            children: [
              TrivaDifficultyBadge(difficulty: category.difficulty),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatChip(
                      'Ver quizzes disponibles',
                      Icons.quiz,
                      AppColors.info,
                    ),
                    _buildStatChip(
                      '${category.pointsPerQuestion} pts por pregunta',
                      Icons.eco,
                      AppColors.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 CAMBIO PRINCIPAL: Botón para ver quizzes
  Widget _buildViewQuizzesButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            print('🎯 [CATEGORY DETAIL] Navigating to quiz selection for: ${category.id}');
            print('🎯 [CATEGORY DETAIL] Category title: ${category.title}');
            
            // 🔧 CAMBIO: Ir a la página de selección de quizzes
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TriviaQuizSelectionPage(
                  topicId: category.id,
                  categoryTitle: category.title,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 24,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.list_alt, // 🔧 CAMBIO: Icono de lista
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Ver Quizzes Disponibles!', // 🔧 CAMBIO: Texto más claro
                        style: AppTextStyles.h4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Explora las opciones de trivia', // 🔧 CAMBIO: Descripción más clara
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acerca de esta Categoría',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Cards de información
        _buildInfoCard(
          icon: Icons.quiz_rounded,
          title: 'Quizzes variados',
          value: 'Diferentes niveles de dificultad',
          color: AppColors.info,
        ),
        const SizedBox(height: 12),
        
        _buildInfoCard(
          icon: Icons.star,
          title: 'Puntos por pregunta',
          value: '${category.pointsPerQuestion} puntos',
          color: AppColors.success,
        ),
        const SizedBox(height: 12),
        
        _buildInfoCard(
          icon: Icons.explore,
          title: 'Contenido educativo',
          value: 'Aprende mientras juegas',
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getCategoryGradient() {
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
      return AppColors.primaryGradient;
    }
  }
}